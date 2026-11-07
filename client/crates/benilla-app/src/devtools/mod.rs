//! Developer tools over benilla's own Lua VM: hot reload of addon code, a live per-addon
//! profiler and an inspector of the live Lua state, drawn in the dev overlay. Dev builds only.

use bevy::prelude::*;
use bevy_egui::EguiPrimaryContextPass;

mod hot_reload;
mod inspector;
mod owners;
mod profiler;

pub(crate) struct DevtoolsPlugin;

impl Plugin for DevtoolsPlugin {
    fn build(&self, app: &mut App) {
        app.init_resource::<hot_reload::HotReload>()
            .init_resource::<profiler::AddonProfiler>()
            .init_resource::<inspector::LuaInspector>()
            .add_systems(
                Update,
                (
                    hot_reload::poll,
                    profiler::toggle,
                    profiler::sample.after(profiler::toggle),
                    inspector::toggle,
                ),
            )
            .add_systems(
                EguiPrimaryContextPass,
                (profiler::panel_ui, inspector::panel_ui),
            );
    }
}
