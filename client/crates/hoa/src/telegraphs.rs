use std::collections::HashMap;

use benilla_app::Objects;
use bevy::asset::RenderAssetUsages;
use bevy::image::{ImageSampler, ImageSamplerDescriptor};
use bevy::prelude::*;
use bevy::render::render_resource::{Extent3d, TextureDimension, TextureFormat};
use benilla_world::decal::{DecalFrame, WorldDecal};
use benilla_world::particles::buffer::{EffectVertex, WorldEffectDraw};
use benilla_world::sky_order::Rung;
use benilla_world::view::WorldCamera;

use crate::server_draw::{MarkSpec, Shape, TELEGRAPH_KEY_PREFIX};

const LINE_HALF_WIDTH: f32 = 1.5;
const SHORTEST_LINE_YARDS: f32 = 1.0;
const LONGEST_LINE_YARDS: f32 = 72.0;
const CONE_HALF_ANGLE: f32 = std::f32::consts::FRAC_PI_4;
const RING_INNER_SHARE: f32 = 0.3;
const RING_SWEEP_LEAD: f32 = 0.05;
const RING_SWEEP_REACH: f32 = 1.05;
const RING_SPLIT_YARDS: f32 = 1.5;
const RING_SPLIT_DEPTH: u32 = 16;
const RIM_YARDS: f32 = 0.3;
const SMALLEST_REACH_YARDS: f32 = 4.0;
const REACH_PER_YARD_OF_SIZE: f32 = 0.6;
const FADING_SHARE_OF_REACH: f32 = 0.75;
const LINE_REACH_OFF_PROFILE_YARDS: f32 = 2.0;
const PROFILE_STEP_YARDS: f32 = 1.0;
const PROFILE_SEARCH_YARDS: f32 = 4.0;
const WALL_UPRIGHTNESS: f32 = 0.5;
const STEP_RISE_YARDS: f32 = 1.0;
const PIXELS_PER_YARD: f32 = 12.0;
const MIN_TEXTURE_PIXELS: u32 = 64;
const MAX_TEXTURE_PIXELS: u32 = 512;
const SMALLEST_FILL: f32 = 0.02;
const TEXTURE_SIZE_STEPS_PER_YARD: f32 = 2.0;
const FOLLOW_MOVE_YARDS: f32 = 0.05;

#[derive(Clone, Copy)]
struct Palette {
    rim: [f32; 3],
    wash: [f32; 3],
}

const PALETTES: [Palette; 5] = [
    Palette {
        rim: [1.0, 0.30, 0.18],
        wash: [0.85, 0.04, 0.02],
    },
    Palette {
        rim: [0.75, 0.55, 1.0],
        wash: [0.35, 0.20, 0.90],
    },
    Palette {
        rim: [0.55, 1.0, 0.45],
        wash: [0.15, 0.75, 0.10],
    },
    Palette {
        rim: [0.65, 0.90, 1.0],
        wash: [0.20, 0.55, 0.95],
    },
    Palette {
        rim: [0.85, 0.10, 0.10],
        wash: [0.45, 0.02, 0.02],
    },
];

const GROUND_PALETTES: [Palette; 5] = [
    Palette {
        rim: [1.0, 0.72, 0.18],
        wash: [0.75, 0.36, 0.03],
    },
    Palette {
        rim: [0.70, 0.50, 1.0],
        wash: [0.15, 0.05, 0.35],
    },
    Palette {
        rim: [0.45, 0.95, 0.35],
        wash: [0.03, 0.20, 0.02],
    },
    Palette {
        rim: [0.55, 0.85, 1.0],
        wash: [0.02, 0.12, 0.30],
    },
    Palette {
        rim: [0.60, 0.05, 0.06],
        wash: [0.25, 0.0, 0.02],
    },
];

const GROUND_HAZE_ALPHA: f32 = 0.5;
const GROUND_HAZE_CURVE: f32 = 1.8;
const GROUND_RIM_ALPHA: f32 = 0.6;
const GROUND_RIM_SOFT_YARDS: f32 = 0.5;
const GROUND_MAX_ALPHA: f32 = 0.8;
const GROUND_EDGE_FADE_YARDS: f32 = 0.25;
const GROUND_WOBBLE_PER_YARD: f32 = 0.04;
const GROUND_WOBBLE_MAX_YARDS: f32 = 0.6;
const OUTLINE_RIM_ALPHA: f32 = 0.95;
const OUTLINE_WASH_ALPHA: f32 = 0.12;
const FILL_WASH_ALPHA: f32 = 0.38;
const FILL_FRONT_ALPHA: f32 = 0.7;

#[derive(Clone, Copy, PartialEq, Eq, Hash)]
enum Layer {
    Outline,
    Fill,
    Ground,
}

#[derive(Clone, Copy, PartialEq, Eq, Hash)]
struct TextureKey {
    shape: Shape,
    size_steps: u32,
    style: u8,
    layer: Layer,
}

struct Mark {
    spec: MarkSpec,
    started: f32,
    surfaces: usize,
    verts: Vec<EffectVertex>,
}

#[derive(Resource, Default)]
pub struct Telegraphs {
    live: HashMap<String, Mark>,
    baked: HashMap<TextureKey, Handle<Image>>,
    loaded: HashMap<String, Handle<Image>>,
}

impl Telegraphs {
    pub fn add(&mut self, spec: MarkSpec, now: f32) {
        self.live.insert(
            spec.key.clone(),
            Mark {
                started: now - spec.done,
                spec,
                surfaces: 0,
                verts: Vec::new(),
            },
        );
    }

    pub fn remove(&mut self, key: &str) {
        self.live.remove(key);
    }

    pub fn len(&self) -> usize {
        self.live.len()
    }

    pub fn clear_all(&mut self) {
        self.live.clear();
    }

    pub fn clear_telegraphs(&mut self) {
        self.live.retain(|key, _| !key.starts_with(TELEGRAPH_KEY_PREFIX));
    }
}

fn line_length(size: f32) -> f32 {
    size.clamp(SHORTEST_LINE_YARDS, LONGEST_LINE_YARDS)
}

fn drawn_size(spec: &MarkSpec) -> f32 {
    match spec.shape {
        Shape::Line => line_length(spec.size),
        Shape::Circle | Shape::Cone | Shape::Ring => spec.size.max(0.5),
    }
}

fn extents(shape: Shape, size: f32) -> (f32, f32, f32, f32) {
    match shape {
        Shape::Circle | Shape::Cone | Shape::Ring => (-size, size, -size, size),
        Shape::Line => (-LINE_HALF_WIDTH, LINE_HALF_WIDTH, -size, 0.0),
    }
}

fn reach_for(size: f32) -> f32 {
    (size * REACH_PER_YARD_OF_SIZE).max(SMALLEST_REACH_YARDS)
}

fn reach_fade(height_off: f32, reach: f32) -> f32 {
    ((reach - height_off.abs()) / (FADING_SHARE_OF_REACH * reach)).clamp(0.0, 1.0)
}

fn frame_for(spec: &MarkSpec, below: f32, above: f32) -> DecalFrame {
    let (min_x, max_x, min_z, max_z) = extents(spec.shape, drawn_size(spec));
    let (sin, cos) = spec.yaw.sin_cos();
    DecalFrame {
        center: spec.at,
        sin,
        cos,
        min_x,
        max_x,
        min_z,
        max_z,
        min_y: below,
        max_y: above,
    }
}

fn is_wall([a, b, c]: [Vec3; 3]) -> bool {
    let normal = (b - a).cross(c - a);
    let area = normal.length();
    if area <= f32::EPSILON {
        return false;
    }
    let rise = a.y.max(b.y).max(c.y) - a.y.min(b.y).min(c.y);
    normal.y.abs() / area < WALL_UPRIGHTNESS && rise > STEP_RISE_YARDS
}

fn point_along_line(spec: &MarkSpec, distance: f32) -> Vec3 {
    let (sin, cos) = spec.yaw.sin_cos();
    spec.at + Vec3::new(-distance * sin, 0.0, -distance * cos)
}

fn line_profile(spec: &MarkSpec, surface_height_near: impl Fn(Vec3, f32) -> Option<f32>) -> Vec<f32> {
    let length = drawn_size(spec);
    let steps = (length / PROFILE_STEP_YARDS).ceil().max(1.0) as usize;
    let mut height = spec.at.y;
    let mut profile = Vec::with_capacity(steps + 1);
    profile.push(0.0);
    for step in 1..=steps {
        let distance = (step as f32 * PROFILE_STEP_YARDS).min(length);
        let probe = point_along_line(spec, distance).with_y(height);
        height = surface_height_near(probe, PROFILE_SEARCH_YARDS).unwrap_or(height);
        profile.push(height - spec.at.y);
    }
    profile
}

fn profile_height_at(profile: &[f32], distance: f32) -> f32 {
    let last = profile.len() - 1;
    let along = (distance / PROFILE_STEP_YARDS).clamp(0.0, last as f32);
    let before = (along.floor() as usize).min(last);
    let after = (before + 1).min(last);
    let blend = along - before as f32;
    profile[before] + (profile[after] - profile[before]) * blend
}

fn fill_uv(shape: Shape, uv: [f32; 2], progress: f32) -> [f32; 2] {
    let p = progress.max(SMALLEST_FILL);
    match shape {
        Shape::Circle | Shape::Cone => [0.5 + (uv[0] - 0.5) / p, 0.5 + (uv[1] - 0.5) / p],
        Shape::Ring => ring_sweep_uv(uv, progress),
        Shape::Line => [uv[0], 1.0 - (1.0 - uv[1]) / p],
    }
}

fn ring_sweep_uv(uv: [f32; 2], progress: f32) -> [f32; 2] {
    let radius_share = 2.0 * (uv[0] - 0.5).hypot(uv[1] - 0.5);
    let behind_front = progress.clamp(0.0, 1.0) - radius_share;
    [
        radius_share / RING_SWEEP_REACH,
        (behind_front + RING_SWEEP_LEAD) / (1.0 + RING_SWEEP_LEAD),
    ]
}

fn ring_sweep_alpha(size: f32, radius: f32, front: f32) -> f32 {
    let inside = distance_inside(Shape::Ring, size, radius, 0.0);
    if radius > front || inside <= 0.0 {
        return 0.0;
    }
    FILL_WASH_ALPHA + (FILL_FRONT_ALPHA - FILL_WASH_ALPHA) * band(front - radius)
}

fn split_long_edges(verts: Vec<EffectVertex>, longest_uv: f32) -> Vec<EffectVertex> {
    let mut out = Vec::with_capacity(verts.len());
    for tri in verts.chunks_exact(3) {
        split_triangle([tri[0], tri[1], tri[2]], longest_uv, RING_SPLIT_DEPTH, &mut out);
    }
    out
}

fn split_triangle(tri: [EffectVertex; 3], longest_uv: f32, depth: u32, out: &mut Vec<EffectVertex>) {
    let edge = |a: &EffectVertex, b: &EffectVertex| (a.uv[0] - b.uv[0]).hypot(a.uv[1] - b.uv[1]);
    let lengths = [edge(&tri[0], &tri[1]), edge(&tri[1], &tri[2]), edge(&tri[2], &tri[0])];
    let (longest, length) = (0..3).map(|i| (i, lengths[i])).fold((0, 0.0), |best, next| if next.1 > best.1 { next } else { best });
    if depth == 0 || length <= longest_uv {
        out.extend_from_slice(&tri);
        return;
    }
    let (a, b, c) = (tri[longest], tri[(longest + 1) % 3], tri[(longest + 2) % 3]);
    let middle = midpoint(&a, &b);
    split_triangle([a, middle, c], longest_uv, depth - 1, out);
    split_triangle([middle, b, c], longest_uv, depth - 1, out);
}

fn midpoint(a: &EffectVertex, b: &EffectVertex) -> EffectVertex {
    EffectVertex {
        pos: std::array::from_fn(|i| (a.pos[i] + b.pos[i]) * 0.5),
        uv: std::array::from_fn(|i| (a.uv[i] + b.uv[i]) * 0.5),
        color: std::array::from_fn(|i| (a.color[i] + b.color[i]) * 0.5),
    }
}

fn band(distance_inside: f32) -> f32 {
    (1.0 - (distance_inside / RIM_YARDS - 1.0).abs()).clamp(0.0, 1.0)
}

fn distance_inside(shape: Shape, size: f32, x: f32, z: f32) -> f32 {
    match shape {
        Shape::Circle => size - (x * x + z * z).sqrt(),
        Shape::Cone => {
            let radius = (x * x + z * z).sqrt();
            let along = -z;
            let across = x.abs();
            let (sin, cos) = CONE_HALF_ANGLE.sin_cos();
            let to_edge = along * sin - across * cos;
            (size - radius).min(to_edge)
        }
        Shape::Line => (LINE_HALF_WIDTH - x.abs()).min(-z).min(size + z),
        Shape::Ring => {
            let radius = (x * x + z * z).sqrt();
            (size - radius).min(radius - size * RING_INNER_SHARE)
        }
    }
}

fn edge_wobble(size: f32, x: f32, z: f32) -> f32 {
    let angle = z.atan2(x);
    let amplitude = (size * GROUND_WOBBLE_PER_YARD).min(GROUND_WOBBLE_MAX_YARDS);
    amplitude * (0.6 * (5.0 * angle).sin() + 0.4 * (11.0 * angle + 1.3).sin())
}

fn ground_texel(key: TextureKey, size: f32, x: f32, z: f32) -> ([f32; 3], f32) {
    let palette = GROUND_PALETTES[usize::from(key.style).min(GROUND_PALETTES.len() - 1)];
    let inside = distance_inside(key.shape, size, x, z) + edge_wobble(size, x, z);
    if inside <= 0.0 {
        return (palette.wash, 0.0);
    }
    let toward_edge = (1.0 - inside / size.max(0.1)).clamp(0.0, 1.0);
    let haze = GROUND_HAZE_ALPHA * toward_edge.powf(GROUND_HAZE_CURVE);
    let rim = (-(inside / GROUND_RIM_SOFT_YARDS).powi(2)).exp();
    let fade = (inside / GROUND_EDGE_FADE_YARDS).clamp(0.0, 1.0);
    let light = toward_edge.max(rim);
    let colour = std::array::from_fn(|i| palette.wash[i] + (palette.rim[i] - palette.wash[i]) * light);
    (colour, (haze + GROUND_RIM_ALPHA * rim).min(GROUND_MAX_ALPHA) * fade)
}

fn texel(key: TextureKey, size: f32, x: f32, z: f32) -> [u8; 4] {
    let palette = PALETTES[usize::from(key.style).min(PALETTES.len() - 1)];
    let inside = distance_inside(key.shape, size, x, z);
    let (colour, alpha) = if key.layer == Layer::Ground {
        ground_texel(key, size, x, z)
    } else if inside <= 0.0 {
        (palette.wash, 0.0)
    } else {
        match key.layer {
            Layer::Outline => {
                let rim = band(inside);
                let colour = std::array::from_fn(|i| palette.wash[i] + (palette.rim[i] - palette.wash[i]) * rim);
                (colour, OUTLINE_WASH_ALPHA + (OUTLINE_RIM_ALPHA - OUTLINE_WASH_ALPHA) * rim)
            }
            Layer::Fill | Layer::Ground => {
                let front = band(inside);
                (palette.wash, FILL_WASH_ALPHA + (FILL_FRONT_ALPHA - FILL_WASH_ALPHA) * front)
            }
        }
    };
    rgba(colour, alpha)
}

fn rgba(colour: [f32; 3], alpha: f32) -> [u8; 4] {
    let byte = |v: f32| (v.clamp(0.0, 1.0) * 255.0).round() as u8;
    [byte(colour[0]), byte(colour[1]), byte(colour[2]), byte(alpha)]
}

fn texture_pixels(yards: f32) -> u32 {
    ((yards * PIXELS_PER_YARD) as u32).clamp(MIN_TEXTURE_PIXELS, MAX_TEXTURE_PIXELS)
}

fn bake_ring_sweep(key: TextureKey, size: f32) -> Image {
    let palette = PALETTES[usize::from(key.style).min(PALETTES.len() - 1)];
    let reach = size * RING_SWEEP_REACH;
    let width = texture_pixels(reach);
    let height = texture_pixels(size * (1.0 + RING_SWEEP_LEAD));
    let mut data = Vec::with_capacity((width * height * 4) as usize);
    for row in 0..height {
        let v = (row as f32 + 0.5) / height as f32;
        let behind_front = size * (v * (1.0 + RING_SWEEP_LEAD) - RING_SWEEP_LEAD);
        for column in 0..width {
            let radius = reach * (column as f32 + 0.5) / width as f32;
            data.extend_from_slice(&rgba(palette.wash, ring_sweep_alpha(size, radius, radius + behind_front)));
        }
    }
    image_from(width, height, data)
}

fn image_from(width: u32, height: u32, data: Vec<u8>) -> Image {
    let mut image = Image::new(
        Extent3d {
            width,
            height,
            depth_or_array_layers: 1,
        },
        TextureDimension::D2,
        data,
        TextureFormat::Rgba8UnormSrgb,
        RenderAssetUsages::RENDER_WORLD,
    );
    image.sampler = ImageSampler::Descriptor(ImageSamplerDescriptor::linear());
    image
}

fn bake(key: TextureKey) -> Image {
    let size = key.size_steps as f32 / TEXTURE_SIZE_STEPS_PER_YARD;
    if key.shape == Shape::Ring && key.layer == Layer::Fill {
        return bake_ring_sweep(key, size);
    }
    let (min_x, max_x, min_z, max_z) = extents(key.shape, size);
    let (width, height) = (texture_pixels(max_x - min_x), texture_pixels(max_z - min_z));
    let mut data = Vec::with_capacity((width * height * 4) as usize);
    for row in 0..height {
        let v = (row as f32 + 0.5) / height as f32;
        let z = min_z + v * (max_z - min_z);
        for column in 0..width {
            let u = (column as f32 + 0.5) / width as f32;
            let x = min_x + u * (max_x - min_x);
            let edge = row == 0 || column == 0 || row + 1 == height || column + 1 == width;
            let pixel = if edge { [0; 4] } else { texel(key, size, x, z) };
            data.extend_from_slice(&pixel);
        }
    }
    image_from(width, height, data)
}

fn mpq_path(texture: &str) -> String {
    format!("mpq://{}", texture.replace('\\', "/").to_lowercase())
}

impl Telegraphs {
    fn baked_texture(&mut self, images: &mut Assets<Image>, spec: &MarkSpec, layer: Layer) -> AssetId<Image> {
        let key = TextureKey {
            shape: spec.shape,
            size_steps: (drawn_size(spec) * TEXTURE_SIZE_STEPS_PER_YARD).round().max(1.0) as u32,
            style: spec.style,
            layer,
        };
        self.baked
            .entry(key)
            .or_insert_with(|| images.add(bake(key)))
            .id()
    }

    fn game_texture(&mut self, assets: &AssetServer, texture: &str) -> AssetId<Image> {
        self.loaded
            .entry(texture.to_string())
            .or_insert_with(|| assets.load::<Image>(mpq_path(texture)))
            .id()
    }
}

pub fn expire_telegraphs(mut telegraphs: ResMut<Telegraphs>, time: Res<Time>) {
    let now = time.elapsed_secs();
    telegraphs
        .live
        .retain(|_, m| m.spec.duration.is_none_or(|d| now - m.started < d));
}

pub fn follow_marks(mut telegraphs: ResMut<Telegraphs>, objects: Objects, transforms: Query<&GlobalTransform>) {
    for mark in telegraphs.live.values_mut() {
        if mark.spec.follow == 0 {
            continue;
        }
        let Some(at) = objects
            .entity(mark.spec.follow)
            .and_then(|e| transforms.get(e).ok())
            .map(GlobalTransform::translation)
        else {
            continue;
        };
        if at.distance(mark.spec.at) > FOLLOW_MOVE_YARDS {
            mark.spec.at = at;
            mark.verts.clear();
        }
    }
}

pub fn project_telegraphs(mut telegraphs: ResMut<Telegraphs>, decals: WorldDecal) {
    let surfaces = decals.receiver_count();
    for mark in telegraphs.live.values_mut() {
        if mark.surfaces == surfaces && !mark.verts.is_empty() {
            continue;
        }
        mark.surfaces = surfaces;
        mark.verts.clear();
        let keep_floor = |triangle: [Vec3; 3]| !is_wall(triangle);
        if mark.spec.shape == Shape::Line {
            let profile = line_profile(&mark.spec, |at, reach| decals.surface_height_near(at, reach));
            let lowest = profile.iter().copied().fold(0.0_f32, f32::min);
            let highest = profile.iter().copied().fold(0.0_f32, f32::max);
            let reach = LINE_REACH_OFF_PROFILE_YARDS;
            let frame = frame_for(&mark.spec, lowest - reach, highest + reach);
            decals.project_where(
                &mut mark.verts,
                &frame,
                keep_floor,
                |p| reach_fade(p.y - profile_height_at(&profile, -p.z), reach),
                |x, z| frame.rect_uv(x, z),
            );
        } else {
            let reach = reach_for(drawn_size(&mark.spec));
            let frame = frame_for(&mark.spec, -reach, reach);
            decals.project_where(
                &mut mark.verts,
                &frame,
                keep_floor,
                |p| reach_fade(p.y, reach),
                |x, z| frame.rect_uv(x, z),
            );
            if mark.spec.shape == Shape::Ring {
                let longest_uv = RING_SPLIT_YARDS / (2.0 * drawn_size(&mark.spec));
                mark.verts = split_long_edges(std::mem::take(&mut mark.verts), longest_uv);
            }
        }
    }
}

pub fn push_telegraphs(
    mut telegraphs: ResMut<Telegraphs>,
    mut images: ResMut<Assets<Image>>,
    assets: Res<AssetServer>,
    time: Res<Time>,
    cam: Query<Entity, With<WorldCamera>>,
    mut draw: WorldEffectDraw,
) {
    let Ok(cam) = cam.single() else { return };
    let now = time.elapsed_secs();
    let keys: Vec<String> = telegraphs.live.keys().cloned().collect();
    for key in keys {
        let Some(spec) = telegraphs.live.get(&key).map(|m| m.spec.clone()) else {
            continue;
        };
        let (outline, fill) = match &spec.texture {
            Some(texture) => (telegraphs.game_texture(&assets, texture), None),
            None if spec.ground_effect => (telegraphs.baked_texture(&mut images, &spec, Layer::Ground), None),
            None => (
                telegraphs.baked_texture(&mut images, &spec, Layer::Outline),
                (!spec.outline_only).then(|| telegraphs.baked_texture(&mut images, &spec, Layer::Fill)),
            ),
        };
        let mark = &telegraphs.live[&key];
        if mark.verts.is_empty() {
            continue;
        }
        let white = |v: &EffectVertex, uv: [f32; 2]| EffectVertex {
            pos: v.pos,
            uv,
            color: [1.0, 1.0, 1.0, v.color[3] * spec.opacity],
        };
        let batch = draw
            .batch(cam, outline)
            .anchored(spec.at)
            .rung(Rung::RETICLE, Rung::DECAL_RASTER);
        let mut batch = if spec.additive { batch.additive() } else { batch };
        batch.extend(mark.verts.iter().map(|v| white(v, v.uv)));
        batch.tris();
        let Some(fill) = fill else { continue };
        let progress = spec
            .duration
            .map_or(1.0, |d| ((now - mark.started) / d.max(0.05)).clamp(0.0, 1.0));
        let mut batch = draw
            .batch(cam, fill)
            .anchored(spec.at)
            .rung(Rung::RETICLE, Rung::DECAL_RASTER);
        batch.extend(mark.verts.iter().map(|v| white(v, fill_uv(spec.shape, v.uv, progress))));
        batch.tris();
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn line_spec(yaw: f32, size: f32) -> MarkSpec {
        MarkSpec {
            key: "t1".into(),
            shape: Shape::Line,
            at: Vec3::new(10.0, 5.0, -3.0),
            yaw,
            size,
            duration: Some(1.0),
            outline_only: false,
            additive: false,
            ground_effect: false,
            style: 0,
            follow: 0,
            texture: None,
            done: 0.0,
            opacity: 1.0,
        }
    }

    #[test]
    fn a_line_is_as_long_as_sent_up_to_seventy_two_yards() {
        assert_eq!(line_length(0.5), 1.0);
        assert_eq!(line_length(10.0), 10.0);
        assert_eq!(line_length(70.0), 70.0);
        assert_eq!(line_length(80.0), 72.0);
    }

    #[test]
    fn a_line_probes_along_its_own_forward_axis() {
        let spec = line_spec(0.7, 10.0);
        let frame = frame_for(&spec, -1.0, 1.0);
        let probe = point_along_line(&spec, 6.0);
        let (dx, dz) = (probe.x - spec.at.x, probe.z - spec.at.z);
        let x_in_frame = dx * frame.cos - dz * frame.sin;
        let z_in_frame = dz * frame.cos + dx * frame.sin;
        assert!(x_in_frame.abs() < 1e-4);
        assert!((z_in_frame + 6.0).abs() < 1e-4);
    }

    #[test]
    fn a_line_profile_climbs_a_ramp_and_keeps_its_last_height_past_a_gap() {
        let spec = line_spec(0.0, 6.0);
        let ramp = |at: Vec3, reach: f32| {
            let distance = spec.at.z - at.z;
            let ground = spec.at.y + 0.8 * distance;
            (distance < 4.5 && (ground - at.y).abs() <= reach).then_some(ground)
        };
        let profile = line_profile(&spec, ramp);
        assert_eq!(profile.len(), 7);
        assert!((profile[3] - 2.4).abs() < 1e-4);
        assert!((profile[6] - 3.2).abs() < 1e-4);
        assert!((profile_height_at(&profile, 2.5) - 2.0).abs() < 1e-4);
    }

    #[test]
    fn a_reach_grows_with_the_shape_and_never_drops_below_four_yards() {
        assert_eq!(reach_for(2.0), 4.0);
        assert_eq!(reach_for(20.0), 12.0);
        assert_eq!(reach_fade(0.0, 12.0), 1.0);
        assert_eq!(reach_fade(12.0, 12.0), 0.0);
    }

    #[test]
    fn a_tall_upright_face_is_a_wall_but_a_stair_riser_is_not() {
        let tall = [Vec3::ZERO, Vec3::new(2.0, 0.0, 0.0), Vec3::new(0.0, 3.0, 0.0)];
        let riser = [Vec3::ZERO, Vec3::new(2.0, 0.0, 0.0), Vec3::new(0.0, 0.5, 0.0)];
        let slope = [Vec3::ZERO, Vec3::new(2.0, 1.0, 0.0), Vec3::new(0.0, 0.0, 2.0)];
        assert!(is_wall(tall));
        assert!(!is_wall(riser));
        assert!(!is_wall(slope));
    }

    #[test]
    fn a_half_filled_circle_samples_the_fill_disc_twice_as_wide() {
        assert_eq!(fill_uv(Shape::Circle, [0.75, 0.5], 0.5), [1.0, 0.5]);
        assert_eq!(fill_uv(Shape::Circle, [0.5, 0.5], 0.5), [0.5, 0.5]);
    }

    #[test]
    fn a_line_fills_out_from_its_origin() {
        assert_eq!(fill_uv(Shape::Line, [0.5, 1.0], 0.25), [0.5, 1.0]);
        assert_eq!(fill_uv(Shape::Line, [0.5, 0.75], 0.25), [0.5, 0.0]);
    }

    #[test]
    fn the_cone_opens_forward_ninety_degrees() {
        assert!(distance_inside(Shape::Cone, 10.0, 0.0, -5.0) > 0.0);
        assert!(distance_inside(Shape::Cone, 10.0, 4.0, -5.0) > 0.0);
        assert!(distance_inside(Shape::Cone, 10.0, 6.0, -5.0) < 0.0);
        assert!(distance_inside(Shape::Cone, 10.0, 0.0, 5.0) < 0.0);
    }

    #[test]
    fn a_ring_leaves_its_middle_open() {
        assert!(distance_inside(Shape::Ring, 30.0, 0.0, 0.0) < 0.0);
        assert!(distance_inside(Shape::Ring, 30.0, 8.0, 0.0) < 0.0);
        assert!(distance_inside(Shape::Ring, 30.0, 0.0, 20.0) > 0.0);
        assert!(distance_inside(Shape::Ring, 30.0, 31.0, 0.0) < 0.0);
    }

    #[test]
    fn a_ring_fills_as_a_growing_disc_that_never_shows_in_the_hole() {
        assert_eq!(ring_sweep_alpha(30.0, 5.0, 6.0), 0.0);
        assert_eq!(ring_sweep_alpha(30.0, 5.0, 30.0), 0.0);
        assert_eq!(ring_sweep_alpha(30.0, 20.0, 15.0), 0.0);
        assert!(ring_sweep_alpha(30.0, 12.0, 20.0) > 0.0);
        assert_eq!(ring_sweep_uv([0.5, 0.5], 0.0)[0], 0.0);
        assert!((ring_sweep_uv([1.0, 0.5], 1.0)[0] - 1.0 / RING_SWEEP_REACH).abs() < 1e-5);
    }

    #[test]
    fn a_wide_triangle_splits_until_every_edge_is_short() {
        let corner = |u: f32, v: f32| EffectVertex {
            pos: [u, 0.0, v],
            uv: [u, v],
            color: [1.0; 4],
        };
        let split = split_long_edges(vec![corner(0.0, 0.0), corner(1.0, 0.0), corner(0.0, 1.0)], 0.1);
        assert_eq!(split.len() % 3, 0);
        assert!(split.len() > 3);
        for tri in split.chunks_exact(3) {
            for (a, b) in [(0, 1), (1, 2), (2, 0)] {
                assert!((tri[a].uv[0] - tri[b].uv[0]).hypot(tri[a].uv[1] - tri[b].uv[1]) <= 0.1 + 1e-5);
            }
        }
    }

    #[test]
    fn the_frame_points_forward_along_the_facing() {
        use benilla_assets::coords::wow_to_bevy;
        let facing = 0.7_f32;
        let forward = wow_to_bevy([facing.cos(), facing.sin(), 0.0]);
        let (sin, cos) = facing.sin_cos();
        let z_in_frame = forward.z * cos + forward.x * sin;
        let x_in_frame = forward.x * cos - forward.z * sin;
        assert!((z_in_frame + 1.0).abs() < 1e-5);
        assert!(x_in_frame.abs() < 1e-5);
    }

    #[test]
    fn a_game_texture_loads_from_the_archive_path() {
        assert_eq!(
            mpq_path("World\\Goober\\RuneGroundBlue01.blp"),
            "mpq://world/goober/runegroundblue01.blp"
        );
    }
}
