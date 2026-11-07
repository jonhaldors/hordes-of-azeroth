//! The tuned Bevy boot: the `DefaultPlugins` set every benilla binary stands on. The engine tuning
//! is shared; the `Window` is the caller's.

use bevy::app::{PluginGroupBuilder, TaskPoolOptions, TaskPoolPlugin};
use bevy::prelude::*;

use crate::thread_qos;

/// `DefaultPlugins` with benilla's engine tuning applied, around the caller's primary window.
pub fn tuned_default_plugins(primary_window: Window) -> PluginGroupBuilder {
    DefaultPlugins
        .set(WindowPlugin {
            primary_window: Some(primary_window),
            ..default()
        })
        // Deliberately no `AssetPlugin::file_path`: a baked source path resolves only on the build
        // machine. Every shader is embedded (`embedded://<crate>/shaders/…`), so no root is read.
        // Quiet wgpu/naga; the ring keeps the last stderr lines for the crash report (`log_ring`).
        .set(bevy::log::LogPlugin {
            filter: "wgpu=error,naga=warn".into(),
            custom_layer: |_| Some(Box::new(crate::log_ring::LogRing)),
            ..default()
        })
        // Asset loads parse synchronously on the IO pool, and Bevy's default 4 threads saturate on
        // a dense teleport. Workers spawn at default QoS, behind any background build:
        // compute is user-interactive, IO and async compute user-initiated, and
        // `ThreadQosPlugin` promotes the render thread from inside.
        .set(TaskPoolPlugin {
            task_pool_options: TaskPoolOptions {
                io: bevy::app::TaskPoolThreadAssignmentPolicy {
                    min_threads: 2,
                    max_threads: 8,
                    percent: 0.5,
                    on_thread_spawn: Some(std::sync::Arc::new(|| {
                        thread_qos::promote_current_thread(thread_qos::QosClass::UserInitiated)
                    })),
                    on_thread_destroy: None,
                },
                async_compute: bevy::app::TaskPoolThreadAssignmentPolicy {
                    on_thread_spawn: Some(std::sync::Arc::new(|| {
                        thread_qos::promote_current_thread(thread_qos::QosClass::UserInitiated)
                    })),
                    ..TaskPoolOptions::default().async_compute
                },
                compute: bevy::app::TaskPoolThreadAssignmentPolicy {
                    on_thread_spawn: Some(std::sync::Arc::new(|| {
                        thread_qos::promote_current_thread(thread_qos::QosClass::UserInteractive)
                    })),
                    // `WOW_THREADS=1` serialises the frame's systems, a diagnostic: a defect that
                    // survives it is not a race between two systems.
                    max_threads: match std::env::var("WOW_THREADS").ok().as_deref() {
                        Some("1") => 1,
                        _ => TaskPoolOptions::default().compute.max_threads,
                    },
                    ..TaskPoolOptions::default().compute
                },
                ..default()
            },
        })
        // Sound is kira behind our own mixer; `bevy_audio` is off by feature (workspace
        // `Cargo.toml`). Kept though they look idle: gizmos (bowstring, fishing line), sprites (the
        // FrameXML quad pass), picking, TextPlugin (glue text), PostProcessPlugin (glow bloom) and
        // ScenePlugin (avian's collider backend reads `SceneSpawner`); the ForwardDecal family is
        // registered inside `PbrPlugin::build`, so it cannot be disabled on its own.
        //
        // M2/WMO/ADT load through our own `mpq://` loaders; there is no glTF.
        .disable::<bevy::gltf::GltfPlugin>()
        // No bevy AA: no Fxaa/TAA/SMAA/CAS component anywhere (MSAA is core render, unaffected).
        .disable::<bevy::anti_alias::AntiAliasPlugin>()
        // No gamepad input; 1.12's bindings are keyboard/mouse.
        .disable::<bevy::gilrs::GilrsPlugin>()
        .set(bevy::render::RenderPlugin {
            render_creation: render_settings().into(),
            ..default()
        })
}

fn render_settings() -> bevy::render::settings::WgpuSettings {
    let mut settings = bevy::render::settings::WgpuSettings::default();
    let backends = settings.backends.unwrap_or(wgpu::Backends::all());
    if backends.contains(wgpu::Backends::GL) && !has_adapter_besides_gl(backends) {
        settings.constrained_limits = Some(gl_limits());
    }
    settings
}

fn has_adapter_besides_gl(backends: wgpu::Backends) -> bool {
    let others = backends - wgpu::Backends::GL;
    if others.is_empty() {
        return false;
    }
    let instance = wgpu::Instance::new(&wgpu::InstanceDescriptor {
        backends: others,
        ..default()
    });
    instance
        .enumerate_adapters(others)
        .iter()
        .any(|adapter| adapter.get_info().device_type != wgpu::DeviceType::Cpu)
}

fn gl_limits() -> wgpu::Limits {
    let most = u32::MAX;
    wgpu::Limits {
        max_texture_dimension_1d: most,
        max_texture_dimension_2d: most,
        max_texture_dimension_3d: most,
        max_texture_array_layers: most,
        max_bind_groups: most,
        max_bindings_per_bind_group: most,
        max_dynamic_uniform_buffers_per_pipeline_layout: most,
        max_dynamic_storage_buffers_per_pipeline_layout: most,
        max_sampled_textures_per_shader_stage: most,
        max_samplers_per_shader_stage: most,
        max_storage_buffers_per_shader_stage: most,
        max_storage_textures_per_shader_stage: 4,
        max_uniform_buffers_per_shader_stage: most,
        max_binding_array_elements_per_shader_stage: most,
        max_binding_array_sampler_elements_per_shader_stage: most,
        max_uniform_buffer_binding_size: most,
        max_storage_buffer_binding_size: most,
        max_vertex_buffers: most,
        max_buffer_size: u64::MAX,
        max_vertex_attributes: most,
        max_vertex_buffer_array_stride: most,
        min_uniform_buffer_offset_alignment: 1,
        min_storage_buffer_offset_alignment: 1,
        max_inter_stage_shader_components: most,
        max_color_attachments: most,
        max_color_attachment_bytes_per_sample: most,
        max_compute_workgroup_storage_size: most,
        max_compute_invocations_per_workgroup: most,
        max_compute_workgroup_size_x: most,
        max_compute_workgroup_size_y: most,
        max_compute_workgroup_size_z: most,
        max_compute_workgroups_per_dimension: most,
        min_subgroup_size: 0,
        max_subgroup_size: most,
        max_push_constant_size: most,
        max_non_sampler_bindings: most,
        max_task_workgroup_total_count: most,
        max_task_workgroups_per_dimension: most,
        max_mesh_output_layers: most,
        max_mesh_multiview_count: most,
        max_blas_primitive_count: most,
        max_blas_geometry_count: most,
        max_tlas_instance_count: most,
        max_acceleration_structures_per_shader_stage: most,
    }
}
