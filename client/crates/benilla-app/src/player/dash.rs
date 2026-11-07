use benilla_protocol::MoveSpeeds;
use bevy::prelude::*;

use super::input::MoveAxes;

const DASH_SPEED_MIN: f32 = 20.0;
pub(crate) const AIR_DASH_SECS: f32 = 0.2;
const STANDING_DASH_GIVE_UP_SECS: f32 = 0.6;
const DASH_FOV_KICK: f32 = 0.08;
const DASH_FOV_RISE_SECS: f32 = 0.06;
const DASH_FOV_FALL_SECS: f32 = 0.35;

#[derive(Default, Clone, Copy, PartialEq, Debug)]
pub(crate) struct DashState {
    last_run_speed: f32,
    standing_dash_left: f32,
    air_dash_left: f32,
    fov_kick_elapsed: Option<f32>,
    pub(super) held: bool,
}

pub(super) fn freeze_world_while_held(
    player: Res<super::Player>,
    mut world_clock: ResMut<Time<Virtual>>,
) {
    let freeze = player.active && player.dash.held;
    if freeze && !world_clock.is_paused() {
        world_clock.pause();
    } else if !freeze && world_clock.is_paused() {
        world_clock.unpause();
    }
}

#[derive(Clone, Copy, PartialEq, Debug)]
pub(super) enum RunSpeedEdge {
    Steady,
    DashStarted,
    DashEnded { run: f32 },
}

pub(super) fn held_still(speeds: Option<MoveSpeeds>) -> bool {
    speeds.is_some_and(|s| s.walk == 0.0 && s.run == 0.0)
}

pub(crate) fn capped_horizontal(velocity: Vec3, cap: f32) -> Vec3 {
    let speed = velocity.length();
    if cap > 0.0 && speed > cap {
        velocity * (cap / speed)
    } else {
        velocity
    }
}

fn fov_kick_scale(elapsed: f32) -> f32 {
    if elapsed < DASH_FOV_RISE_SECS {
        return 1.0 + DASH_FOV_KICK * elapsed / DASH_FOV_RISE_SECS;
    }
    let falling = ((elapsed - DASH_FOV_RISE_SECS) / DASH_FOV_FALL_SECS).min(1.0);
    1.0 + DASH_FOV_KICK * (1.0 - falling) * (1.0 - falling)
}

pub(crate) fn is_dash_speed(run: f32) -> bool {
    run >= DASH_SPEED_MIN
}

impl DashState {
    pub(super) fn watch_run_speed(&mut self, run: f32) -> RunSpeedEdge {
        let before = std::mem::replace(&mut self.last_run_speed, run);
        if before > 0.0 && !is_dash_speed(before) && is_dash_speed(run) {
            return RunSpeedEdge::DashStarted;
        }
        if is_dash_speed(before) && run > 0.0 && !is_dash_speed(run) {
            self.standing_dash_left = 0.0;
            return RunSpeedEdge::DashEnded { run };
        }
        RunSpeedEdge::Steady
    }

    pub(super) fn start_fov_kick(&mut self) {
        self.fov_kick_elapsed = Some(0.0);
    }

    pub(super) fn tick_fov_kick(&mut self, dt: f32) -> f32 {
        let Some(elapsed) = self.fov_kick_elapsed else {
            return 1.0;
        };
        let scale = fov_kick_scale(elapsed);
        let next = elapsed + dt;
        self.fov_kick_elapsed = (next < DASH_FOV_RISE_SECS + DASH_FOV_FALL_SECS).then_some(next);
        scale
    }

    pub(super) fn start_standing_dash(&mut self) {
        self.standing_dash_left = STANDING_DASH_GIVE_UP_SECS;
    }

    pub(super) fn steer(&mut self, mut axes: MoveAxes, dt: f32, held: bool) -> MoveAxes {
        if self.standing_dash_left <= 0.0 {
            return axes;
        }
        if !held {
            self.standing_dash_left -= dt;
        }
        if axes.fwd == 0 && axes.side == 0 {
            axes.fwd = 1;
            axes.translating = true;
        }
        axes
    }

    pub(super) fn arm_air_dash(&mut self, xy_speed: f32, lift: f32) {
        if lift == 0.0 && is_dash_speed(xy_speed) {
            self.air_dash_left = AIR_DASH_SECS;
        }
    }

    pub(super) fn flies_level(&self) -> bool {
        self.air_dash_left > 0.0
    }

    pub(super) fn tick_air_dash(&mut self, dt: f32, airborne: bool) -> bool {
        if !self.flies_level() {
            return false;
        }
        if !airborne {
            self.air_dash_left = 0.0;
            return false;
        }
        self.air_dash_left -= dt;
        !self.flies_level()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn still() -> MoveAxes {
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
    fn dash_fov_kick_rises_then_settles() {
        let mut dash = DashState::default();
        assert_eq!(dash.tick_fov_kick(0.03), 1.0);
        dash.start_fov_kick();
        assert_eq!(dash.tick_fov_kick(DASH_FOV_RISE_SECS), 1.0);
        let peak = dash.tick_fov_kick(0.1);
        assert!((peak - (1.0 + DASH_FOV_KICK)).abs() < 1e-5);
        let easing = dash.tick_fov_kick(1.0);
        assert!(easing > 1.0 && easing < peak);
        assert_eq!(dash.tick_fov_kick(0.03), 1.0);
    }

    #[test]
    fn zero_walk_and_run_hold_the_body_still() {
        let paused = MoveSpeeds {
            walk: 0.0,
            run: 0.0,
            ..Default::default()
        };
        let normal = MoveSpeeds {
            walk: 2.5,
            run: 7.0,
            ..Default::default()
        };
        assert!(held_still(Some(paused)));
        assert!(!held_still(Some(normal)));
        assert!(!held_still(None));
    }

    #[test]
    fn the_run_speed_edges_name_the_dash() {
        let mut dash = DashState::default();
        assert_eq!(dash.watch_run_speed(7.0), RunSpeedEdge::Steady);
        assert_eq!(dash.watch_run_speed(40.0), RunSpeedEdge::DashStarted);
        assert_eq!(dash.watch_run_speed(40.0), RunSpeedEdge::Steady);
        assert_eq!(
            dash.watch_run_speed(7.0),
            RunSpeedEdge::DashEnded { run: 7.0 }
        );
        assert_eq!(dash.watch_run_speed(0.0), RunSpeedEdge::Steady);
        assert_eq!(dash.watch_run_speed(40.0), RunSpeedEdge::Steady);
    }

    #[test]
    fn a_standing_dash_presses_forward_until_it_gives_up() {
        let mut dash = DashState::default();
        dash.start_standing_dash();
        let axes = dash.steer(still(), 0.3, false);
        assert_eq!((axes.fwd, axes.translating), (1, true));
        let held = dash.steer(still(), 5.0, true);
        assert_eq!(held.fwd, 1);
        dash.steer(still(), 0.31, false);
        assert_eq!(dash.steer(still(), 0.01, false).fwd, 0);
    }

    #[test]
    fn a_dash_speed_ending_releases_the_forward_press() {
        let mut dash = DashState::default();
        dash.watch_run_speed(7.0);
        dash.watch_run_speed(40.0);
        dash.start_standing_dash();
        dash.watch_run_speed(7.0);
        assert_eq!(dash.steer(still(), 0.01, false).fwd, 0);
    }

    #[test]
    fn an_air_dash_flies_level_then_reports_its_end_in_the_air() {
        let mut dash = DashState::default();
        dash.arm_air_dash(40.0, 3.0);
        assert!(!dash.flies_level());
        dash.arm_air_dash(40.0, 0.0);
        assert!(dash.flies_level());
        assert!(!dash.tick_air_dash(0.1, true));
        assert!(dash.tick_air_dash(0.11, true));
        assert!(!dash.flies_level());
    }

    #[test]
    fn landing_ends_an_air_dash_quietly() {
        let mut dash = DashState::default();
        dash.arm_air_dash(40.0, 0.0);
        assert!(!dash.tick_air_dash(0.05, false));
        assert!(!dash.flies_level());
    }

    #[test]
    fn the_horizontal_cap_keeps_the_heading() {
        let capped = capped_horizontal(Vec3::new(30.0, 0.0, 40.0), 7.0);
        assert!((capped.length() - 7.0).abs() < 1e-4);
        assert!((capped.x / capped.z - 0.75).abs() < 1e-4);
        assert_eq!(capped_horizontal(Vec3::X, 7.0), Vec3::X);
    }
}
