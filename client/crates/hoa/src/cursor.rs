use bevy::input::mouse::{AccumulatedMouseMotion, MouseButtonInput, MouseWheel};
use bevy::input::ButtonState;
use bevy::prelude::*;
use bevy::window::{CursorOptions, PrimaryWindow};

use crate::pad::{PadKind, SharedController};

const MOUSE_TRAVEL_PIXELS: f32 = 30.0;
const MOUSE_TRAVEL_WINDOW_SECS: f64 = 0.4;
const MOUSE_GRACE_SECS: f64 = 1.5;
const INJECTED_CLICK_SECS: f64 = 0.1;

#[derive(Default)]
pub struct MouseTravel {
    pixels: f32,
    at: f64,
}

impl MouseTravel {
    pub fn add(&mut self, pixels: f32, now: f64) -> bool {
        if now - self.at > MOUSE_TRAVEL_WINDOW_SECS {
            self.pixels = 0.0;
        }
        self.at = now;
        self.pixels += pixels;
        self.pixels > MOUSE_TRAVEL_PIXELS
    }

    fn forget(&mut self) {
        self.pixels = 0.0;
    }
}

pub fn drive_pad_cursor(
    time: Res<Time<Real>>,
    shared: NonSend<SharedController>,
    mut windows: Query<(Entity, &mut Window), With<PrimaryWindow>>,
    mut clicks: MessageWriter<MouseButtonInput>,
    mut injected_until: Local<f64>,
) {
    let Ok((window_entity, mut window)) = windows.single_mut() else {
        return;
    };
    let mut controller = shared.0.borrow_mut();
    let travel = controller.cursor_travel(time.delta_secs(), window.height());
    if travel != Vec2::ZERO && window.focused {
        let size = Vec2::new(window.width(), window.height());
        let from = window.cursor_position().unwrap_or(size * 0.5);
        let to = (from + travel).clamp(Vec2::ZERO, size - Vec2::ONE);
        window.set_cursor_position(Some(to));
    }
    let now = time.elapsed_secs_f64();
    for click in controller.clicks.drain(..) {
        clicks.write(MouseButtonInput {
            button: if click.right {
                MouseButton::Right
            } else {
                MouseButton::Left
            },
            state: if click.down {
                ButtonState::Pressed
            } else {
                ButtonState::Released
            },
            window: window_entity,
        });
        *injected_until = now + INJECTED_CLICK_SECS;
    }
    controller.injected_click_until = *injected_until;
}

pub fn hide_cursor_for_pad(
    shared: NonSend<SharedController>,
    mut cursor: Query<&mut CursorOptions, With<PrimaryWindow>>,
    mut ours: Local<bool>,
) {
    let controller = shared.0.borrow();
    let hidden =
        controller.in_use && controller.connected != PadKind::None && !controller.cursor_mode;
    let Ok(mut options) = cursor.single_mut() else {
        return;
    };
    if hidden && options.visible {
        *ours = true;
        options.visible = false;
    } else if !hidden && *ours {
        *ours = false;
        if !options.visible {
            options.visible = true;
        }
    }
}

pub fn notice_keyboard_and_mouse(
    time: Res<Time<Real>>,
    keys: Res<ButtonInput<KeyCode>>,
    buttons: Res<ButtonInput<MouseButton>>,
    motion: Res<AccumulatedMouseMotion>,
    mut wheel: MessageReader<MouseWheel>,
    shared: NonSend<SharedController>,
    mut travel: Local<MouseTravel>,
) {
    let scrolled = wheel.read().count() > 0;
    let mut controller = shared.0.borrow_mut();
    if !controller.in_use {
        travel.forget();
        return;
    }
    let now = time.elapsed_secs_f64();
    let clicked =
        buttons.get_just_pressed().next().is_some() && now > controller.injected_click_until;
    let typed = keys.get_just_pressed().next().is_some();
    let moved = if now - controller.active_at < MOUSE_GRACE_SECS {
        travel.forget();
        false
    } else {
        let pixels = motion.delta.abs().element_sum();
        pixels > 0.0 && travel.add(pixels, now)
    };
    if typed || clicked || scrolled || moved {
        controller.use_keyboard_and_mouse();
        travel.forget();
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn mouse_travel_needs_thirty_pixels_inside_the_window() {
        let mut travel = MouseTravel::default();
        assert!(!travel.add(20.0, 1.0));
        assert!(travel.add(15.0, 1.2));
        travel.forget();
        assert!(!travel.add(20.0, 2.0));
        assert!(!travel.add(20.0, 2.5));
    }
}
