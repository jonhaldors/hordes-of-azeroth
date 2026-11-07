use bevy::prelude::*;

use super::camera::{CameraControl, FlyCam, CAM_PITCH_LIMIT};
use super::camera_zoom::CAM_DIST_MIN;
use super::input::MoveAxes;

#[derive(Resource, Default, Clone, Copy, Debug, PartialEq)]
pub struct PadSteer {
    pub moving: Vec2,
    pub look: Vec2,
    pub zoom: f32,
    pub yaw_rate: f32,
    pub pitch_rate: f32,
    pub jump: bool,
    pub recenter: bool,
}

#[derive(Default, Clone, Copy, Debug, PartialEq)]
pub(crate) struct PadHold {
    holding: bool,
    held_world_yaw: f32,
}

impl PadHold {
    pub(super) fn holding(&self) -> bool {
        self.holding
    }
}

pub(super) fn steer_axes(mut axes: MoveAxes, steer: &PadSteer, may_translate: bool) -> MoveAxes {
    let keys_idle = axes.fwd == 0 && axes.side == 0;
    if steer.moving != Vec2::ZERO && may_translate && keys_idle {
        axes.fwd = 1;
        axes.translating = true;
    }
    axes
}

pub(super) fn stick_facing(held_world_yaw: f32, stick: Vec2) -> f32 {
    held_world_yaw - stick.x.atan2(stick.y)
}

pub(super) fn steer_facing(
    hold: &mut PadHold,
    face_yaw: &mut f32,
    cam: &FlyCam,
    steer: &PadSteer,
    may_steer: bool,
) {
    if steer.moving == Vec2::ZERO || !may_steer {
        hold.holding = false;
        return;
    }
    if !hold.holding {
        hold.holding = true;
        hold.held_world_yaw = cam.yaw;
    }
    *face_yaw = stick_facing(hold.held_world_yaw, steer.moving);
}

pub(super) fn steer_view(
    hold: &mut PadHold,
    face_yaw: f32,
    rig: &mut CameraControl,
    cam: &mut FlyCam,
    steer: &PadSteer,
    dt: f32,
    zoom_speed: f32,
    zoom_max: f32,
) {
    if steer.recenter {
        if hold.holding {
            hold.held_world_yaw = face_yaw;
        } else {
            cam.yaw = face_yaw;
        }
    }
    let turn = -steer.look.x * steer.look.x.abs() * steer.yaw_rate * dt;
    if hold.holding {
        hold.held_world_yaw += turn;
        cam.yaw = hold.held_world_yaw;
    } else {
        cam.yaw += turn;
    }
    if steer.look.y != 0.0 {
        let pitch = steer.look.y * steer.look.y.abs() * steer.pitch_rate * dt;
        cam.pitch = (cam.pitch + pitch).clamp(-CAM_PITCH_LIMIT, CAM_PITCH_LIMIT);
    }
    if steer.zoom != 0.0 {
        let target = (rig.target_distance - steer.zoom * zoom_speed * dt)
            .max(CAM_DIST_MIN)
            .min(zoom_max);
        rig.distance = (rig.distance + (target - rig.target_distance))
            .max(CAM_DIST_MIN)
            .min(zoom_max);
        rig.target_distance = target;
    }
    rig.pad_holds_yaw = hold.holding;
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::f32::consts::FRAC_PI_2;

    fn idle() -> MoveAxes {
        MoveAxes {
            fwd: 0,
            side: 0,
            mouselook: false,
            turning: false,
            translating: false,
            strafe_left: false,
            strafe_right: false,
            turn_left: false,
            turn_right: false,
        }
    }

    #[test]
    fn the_stick_presses_forward_only_while_the_keys_are_idle() {
        let steer = PadSteer {
            moving: Vec2::new(0.0, 1.0),
            ..Default::default()
        };
        assert_eq!(steer_axes(idle(), &steer, true).fwd, 1);
        assert_eq!(steer_axes(idle(), &steer, false).fwd, 0);
        let backing = MoveAxes { fwd: -1, ..idle() };
        assert_eq!(steer_axes(backing, &steer, true).fwd, -1);
    }

    #[test]
    fn stick_right_faces_a_quarter_turn_clockwise_of_the_camera() {
        assert!((stick_facing(1.0, Vec2::new(0.0, 1.0)) - 1.0).abs() < 1e-6);
        assert!((stick_facing(1.0, Vec2::new(1.0, 0.0)) - (1.0 - FRAC_PI_2)).abs() < 1e-6);
        assert!((stick_facing(0.0, Vec2::new(-1.0, 0.0)) - FRAC_PI_2).abs() < 1e-6);
    }

    #[test]
    fn steering_locks_the_camera_yaw_it_started_from() {
        let mut hold = PadHold::default();
        let mut face = 0.0;
        let mut cam = FlyCam {
            yaw: 2.0,
            pitch: 0.0,
            speed: 0.0,
        };
        let steer = PadSteer {
            moving: Vec2::new(1.0, 0.0),
            ..Default::default()
        };
        steer_facing(&mut hold, &mut face, &cam, &steer, true);
        assert!((face - (2.0 - FRAC_PI_2)).abs() < 1e-6);
        cam.yaw = 5.0;
        steer_facing(&mut hold, &mut face, &cam, &steer, true);
        assert!((face - (2.0 - FRAC_PI_2)).abs() < 1e-6);
        steer_facing(&mut hold, &mut face, &cam, &PadSteer::default(), true);
        assert!(!hold.holding());
    }
}
