use std::cell::RefCell;
use std::collections::HashMap;
use std::rc::Rc;
use std::sync::LazyLock;

use benilla_app::PadSteer;
use bevy::input::gamepad::{Gamepad, GamepadAxis, GamepadButton};
use bevy::prelude::*;

pub const BUTTON_NAMES: [&str; 17] = [
    "a", "b", "x", "y", "lb", "rb", "lt", "rt", "view", "menu", "l3", "r3", "up", "down", "left",
    "right", "home",
];

pub const BUTTON_A: u32 = 1 << 0;
pub const BUTTON_X: u32 = 1 << 2;
pub const BUTTON_LT: u32 = 1 << 6;
pub const BUTTON_RT: u32 = 1 << 7;
pub const BUTTON_R3: u32 = 1 << 11;
pub const BUTTON_UP: u32 = 1 << 12;
pub const BUTTON_DOWN: u32 = 1 << 13;
pub const DPAD_BUTTONS: u32 = 0xF << 12;

const BUTTON_MAP: [(GamepadButton, u32); 15] = [
    (GamepadButton::South, 1 << 0),
    (GamepadButton::East, 1 << 1),
    (GamepadButton::West, 1 << 2),
    (GamepadButton::North, 1 << 3),
    (GamepadButton::LeftTrigger, 1 << 4),
    (GamepadButton::RightTrigger, 1 << 5),
    (GamepadButton::Select, 1 << 8),
    (GamepadButton::Start, 1 << 9),
    (GamepadButton::LeftThumb, 1 << 10),
    (GamepadButton::RightThumb, 1 << 11),
    (GamepadButton::DPadUp, 1 << 12),
    (GamepadButton::DPadDown, 1 << 13),
    (GamepadButton::DPadLeft, 1 << 14),
    (GamepadButton::DPadRight, 1 << 15),
    (GamepadButton::Mode, 1 << 16),
];

const SONY_VENDOR: u16 = 0x054C;
const VALVE_VENDOR: u16 = 0x28DE;
const STEAM_DECK_PRODUCT: u16 = 0x1205;
const THREEDCONNEXION_VENDOR: u16 = 0x256F;
const LOGITECH_VENDOR: u16 = 0x046D;
const LOGITECH_SPACE_MICE: std::ops::RangeInclusive<u16> = 0xC600..=0xC6FF;
static ON_STEAM_DECK: LazyLock<bool> = LazyLock::new(|| std::env::var("SteamDeck").is_ok_and(|v| v == "1"));
pub const TRIGGER_PRESSED: f32 = 0.45;
const ACTIVITY: f32 = 0.35;
pub const MOVE_DEADZONE: f32 = 0.24;
pub const LOOK_DEADZONE: f32 = 0.20;

#[derive(Clone, Copy, Debug, Default, PartialEq)]
pub struct PadState {
    pub lx: f32,
    pub ly: f32,
    pub rx: f32,
    pub ry: f32,
    pub lt: f32,
    pub rt: f32,
    pub buttons: u32,
}

impl PadState {
    pub fn is_active(&self) -> bool {
        self.buttons != 0
            || [self.lx, self.ly, self.rx, self.ry]
                .iter()
                .any(|v| v.abs() > ACTIVITY)
            || self.lt > TRIGGER_PRESSED
            || self.rt > TRIGGER_PRESSED
    }

    pub fn moved_from(&self, rest: &PadState) -> bool {
        self.buttons & !rest.buttons != 0
            || [
                self.lx - rest.lx,
                self.ly - rest.ly,
                self.rx - rest.rx,
                self.ry - rest.ry,
                self.lt - rest.lt,
                self.rt - rest.rt,
            ]
            .iter()
            .any(|v| v.abs() > ACTIVITY)
    }

    pub fn with_trigger_buttons(mut self) -> Self {
        if self.lt >= TRIGGER_PRESSED {
            self.buttons |= BUTTON_LT;
        }
        if self.rt >= TRIGGER_PRESSED {
            self.buttons |= BUTTON_RT;
        }
        self
    }
}

#[derive(Clone, Copy, Debug, Default, PartialEq, Eq)]
pub enum PadKind {
    #[default]
    None,
    Xbox,
    PlayStation,
    SteamDeck,
}

impl PadKind {
    pub fn name(self) -> Option<&'static str> {
        match self {
            PadKind::None => None,
            PadKind::Xbox => Some("xbox"),
            PadKind::PlayStation => Some("ps"),
            PadKind::SteamDeck => Some("deck"),
        }
    }

    pub fn of_style(style: &str) -> Self {
        match style {
            "ps" => PadKind::PlayStation,
            "deck" => PadKind::SteamDeck,
            _ => PadKind::Xbox,
        }
    }

    fn of_device(vendor: Option<u16>, product: Option<u16>, on_steam_deck: bool) -> Self {
        match vendor {
            Some(SONY_VENDOR) => PadKind::PlayStation,
            Some(VALVE_VENDOR) if product == Some(STEAM_DECK_PRODUCT) || on_steam_deck => PadKind::SteamDeck,
            _ => PadKind::Xbox,
        }
    }
}

#[derive(Clone, Copy, Debug, PartialEq)]
pub struct PadOptions {
    pub yaw_speed: f32,
    pub pitch_speed: f32,
    pub cursor_speed: f32,
    pub move_deadzone: f32,
    pub look_deadzone: f32,
    pub invert_pitch: bool,
}

impl Default for PadOptions {
    fn default() -> Self {
        Self {
            yaw_speed: 1.0,
            pitch_speed: 1.0,
            cursor_speed: 1.0,
            move_deadzone: MOVE_DEADZONE,
            look_deadzone: LOOK_DEADZONE,
            invert_pitch: false,
        }
    }
}

impl PadOptions {
    pub fn set(&mut self, name: &str, value: f32, flag: bool) {
        match name {
            "yawSpeed" => self.yaw_speed = value.clamp(0.25, 3.0),
            "pitchSpeed" => self.pitch_speed = value.clamp(0.25, 3.0),
            "cursorSpeed" => self.cursor_speed = value.clamp(0.25, 3.0),
            "deadzone" => {
                self.move_deadzone = value.clamp(0.05, 0.6);
                self.look_deadzone = self.move_deadzone * LOOK_DEADZONE / MOVE_DEADZONE;
            }
            "invertPitch" => self.invert_pitch = flag,
            _ => {}
        }
    }
}

#[derive(Clone, Copy, Debug, PartialEq)]
pub enum PadEvent {
    Button { name: &'static str, down: bool },
    Device(Option<&'static str>),
}

#[derive(Default)]
pub struct Controller {
    pub connected: PadKind,
    pub in_use: bool,
    pub capture: bool,
    pub scroll_mode: bool,
    pub cursor_mode: bool,
    pub options: PadOptions,
    pub simulated: Option<(PadState, PadKind)>,
    pub pad: PadState,
    pub active_at: f64,
    previous_buttons: u32,
    reported: PadKind,
    pub events: Vec<PadEvent>,
    pub clicks: Vec<CursorClick>,
    pub injected_click_until: f64,
    left_held: bool,
    right_held: bool,
}

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub struct CursorClick {
    pub right: bool,
    pub down: bool,
}

const CURSOR_SCREENS_PER_SECOND: f32 = 1.1;

impl Controller {
    pub fn shown_kind(&self) -> PadKind {
        if self.in_use {
            self.connected
        } else {
            PadKind::None
        }
    }

    pub fn take_input(&mut self, read: Option<(PadState, PadKind)>, now: f64) -> u32 {
        let (raw, kind) = self.simulated.or(read).unwrap_or_default();
        self.connected = kind;
        let pad = raw.with_trigger_buttons();
        self.pad = raw;
        if pad.is_active() && kind != PadKind::None {
            self.active_at = now;
            self.in_use = true;
        }
        let changed = pad.buttons ^ self.previous_buttons;
        self.previous_buttons = pad.buttons;
        if self.shown_kind() != self.reported {
            self.reported = self.shown_kind();
            self.events.push(PadEvent::Device(self.reported.name()));
        }
        if !self.capture || changed & pad.buttons & DPAD_BUTTONS != 0 {
            self.leave_cursor_mode();
        }
        for (index, name) in BUTTON_NAMES.iter().enumerate() {
            let bit = 1 << index;
            if changed & bit == 0 {
                continue;
            }
            let down = pad.buttons & bit != 0;
            if self.cursor_click(bit, down) {
                continue;
            }
            if bit == BUTTON_R3 && down && self.capture {
                self.cursor_mode = !self.cursor_mode;
                if !self.cursor_mode {
                    self.leave_cursor_mode();
                }
            }
            self.events.push(PadEvent::Button { name, down });
        }
        changed
    }

    fn cursor_click(&mut self, bit: u32, down: bool) -> bool {
        if !self.cursor_mode || (bit != BUTTON_A && bit != BUTTON_X) {
            return false;
        }
        let right = bit == BUTTON_X;
        let held = if right {
            &mut self.right_held
        } else {
            &mut self.left_held
        };
        if down != *held {
            *held = down;
            self.clicks.push(CursorClick { right, down });
        }
        true
    }

    fn leave_cursor_mode(&mut self) {
        for (right, held) in [(false, self.left_held), (true, self.right_held)] {
            if held {
                self.clicks.push(CursorClick { right, down: false });
            }
        }
        self.left_held = false;
        self.right_held = false;
        self.cursor_mode = false;
    }

    pub fn cursor_travel(&mut self, dt: f32, screen_height: f32) -> Vec2 {
        if !self.capture || (self.scroll_mode && !self.cursor_mode) {
            return Vec2::ZERO;
        }
        let stick = radial_deadzone(self.pad.rx, self.pad.ry, self.options.look_deadzone);
        if stick == Vec2::ZERO {
            return Vec2::ZERO;
        }
        self.cursor_mode = true;
        let speed = CURSOR_SCREENS_PER_SECOND
            * self.options.cursor_speed
            * screen_height
            * dt
            * stick.length();
        Vec2::new(stick.x * speed, -stick.y * speed)
    }

    pub fn use_keyboard_and_mouse(&mut self) {
        self.in_use = false;
        self.leave_cursor_mode();
    }
}

#[derive(Clone, Default)]
pub struct SharedController(pub Rc<RefCell<Controller>>);

pub fn read_gamepad(pad: &Gamepad) -> (PadState, PadKind) {
    let axis = |a: GamepadAxis| pad.get(a).unwrap_or(0.0);
    let button = |b: GamepadButton| pad.get(b).unwrap_or(0.0);
    let buttons = BUTTON_MAP
        .iter()
        .filter(|(b, _)| pad.pressed(*b))
        .fold(0, |acc, (_, bit)| acc | bit);
    let state = PadState {
        lx: axis(GamepadAxis::LeftStickX),
        ly: axis(GamepadAxis::LeftStickY),
        rx: axis(GamepadAxis::RightStickX),
        ry: axis(GamepadAxis::RightStickY),
        lt: button(GamepadButton::LeftTrigger2),
        rt: button(GamepadButton::RightTrigger2),
        buttons,
    };
    (state, PadKind::of_device(pad.vendor_id(), pad.product_id(), *ON_STEAM_DECK))
}

pub fn radial_deadzone(x: f32, y: f32, deadzone: f32) -> Vec2 {
    let v = Vec2::new(x, y);
    let length = v.length();
    if length <= deadzone {
        return Vec2::ZERO;
    }
    let scaled = ((length - deadzone) / (1.0 - deadzone)).min(1.0);
    v / length * scaled
}

const YAW_RADIANS_PER_SECOND: f32 = std::f32::consts::PI;
const PITCH_RADIANS_PER_SECOND: f32 = 1.6;

pub fn steer_from(controller: &Controller, changed: u32) -> PadSteer {
    if controller.connected == PadKind::None {
        return PadSteer::default();
    }
    let pad = controller.pad.with_trigger_buttons();
    let options = controller.options;
    let pressed = |bit: u32| pad.buttons & bit != 0 && changed & bit != 0;
    let moving = radial_deadzone(pad.lx, pad.ly, options.move_deadzone);
    let mut look = radial_deadzone(pad.rx, pad.ry, options.look_deadzone);
    let mut zoom = 0.0;
    if pad.lt >= TRIGGER_PRESSED {
        let dpad = f32::from(u8::from(pad.buttons & BUTTON_UP != 0))
            - f32::from(u8::from(pad.buttons & BUTTON_DOWN != 0));
        zoom = look.y + dpad;
        look.y = 0.0;
    }
    if options.invert_pitch {
        look.y = -look.y;
    }
    if controller.capture {
        look = Vec2::ZERO;
        zoom = 0.0;
    }
    PadSteer {
        moving,
        look,
        zoom,
        yaw_rate: YAW_RADIANS_PER_SECOND * options.yaw_speed,
        pitch_rate: PITCH_RADIANS_PER_SECOND * options.pitch_speed,
        jump: pressed(BUTTON_A) && !controller.capture,
        recenter: pressed(BUTTON_R3) && !controller.capture,
    }
}

pub fn log_new_pads(pads: Query<(&Gamepad, Option<&Name>), Added<Gamepad>>) {
    for (pad, name) in &pads {
        info!(
            "controller connected: {} (vendor {:04x}, product {:04x})",
            name.map_or("unnamed", |n| n.as_str()),
            pad.vendor_id().unwrap_or(0),
            pad.product_id().unwrap_or(0)
        );
    }
}

fn is_space_mouse(vendor: Option<u16>, product: Option<u16>) -> bool {
    match (vendor, product) {
        (Some(THREEDCONNEXION_VENDOR), _) => true,
        (Some(LOGITECH_VENDOR), Some(product)) => LOGITECH_SPACE_MICE.contains(&product),
        _ => false,
    }
}

#[derive(Clone, Copy, Default)]
pub struct PadRest {
    rest: PadState,
    woken: bool,
}

impl PadRest {
    fn first(read: PadState) -> Self {
        Self {
            rest: read,
            woken: false,
        }
    }

    fn wakes(&mut self, read: &PadState) -> bool {
        if !self.woken {
            self.woken = read.moved_from(&self.rest);
            self.rest.buttons &= read.buttons;
        }
        self.woken
    }
}

pub fn poll_pads(
    time: Res<Time<Real>>,
    pads: Query<(Entity, &Gamepad)>,
    shared: NonSend<SharedController>,
    mut steer: ResMut<PadSteer>,
    mut rests: Local<HashMap<Entity, PadRest>>,
) {
    rests.retain(|entity, _| pads.contains(*entity));
    let mut chosen: Option<(PadState, PadKind)> = None;
    for (entity, pad) in &pads {
        if is_space_mouse(pad.vendor_id(), pad.product_id()) {
            continue;
        }
        let read = read_gamepad(pad);
        let rest = rests.entry(entity).or_insert_with(|| PadRest::first(read.0));
        if !rest.wakes(&read.0) {
            continue;
        }
        let active = read.0.with_trigger_buttons().is_active();
        if chosen.is_none() || active {
            chosen = Some(read);
        }
        if active {
            break;
        }
    }
    let mut controller = shared.0.borrow_mut();
    let changed = controller.take_input(chosen, time.elapsed_secs_f64());
    *steer = steer_from(&controller, changed);
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn the_steam_deck_is_told_apart_from_other_valve_pads() {
        let deck = PadKind::of_device(Some(VALVE_VENDOR), Some(STEAM_DECK_PRODUCT), false);
        let virtual_pad_on_deck = PadKind::of_device(Some(VALVE_VENDOR), Some(0x11FF), true);
        let virtual_pad_on_desktop = PadKind::of_device(Some(VALVE_VENDOR), Some(0x11FF), false);
        assert_eq!(deck, PadKind::SteamDeck);
        assert_eq!(virtual_pad_on_deck, PadKind::SteamDeck);
        assert_eq!(virtual_pad_on_desktop, PadKind::Xbox);
        assert_eq!(PadKind::of_device(Some(SONY_VENDOR), None, true), PadKind::PlayStation);
        assert_eq!(PadKind::SteamDeck.name(), Some("deck"));
    }

    #[test]
    fn space_mice_are_not_pads() {
        assert!(is_space_mouse(Some(THREEDCONNEXION_VENDOR), Some(0xC652)));
        assert!(is_space_mouse(Some(LOGITECH_VENDOR), Some(0xC626)));
        assert!(!is_space_mouse(Some(LOGITECH_VENDOR), Some(0xC21D)));
        assert!(!is_space_mouse(Some(SONY_VENDOR), Some(0x09CC)));
        assert!(!is_space_mouse(None, None));
    }

    #[test]
    fn a_device_resting_off_centre_wakes_only_when_it_moves() {
        let resting = PadState {
            lt: -1.0,
            ry: 0.8,
            buttons: BUTTON_X,
            ..Default::default()
        };
        let mut rest = PadRest::first(resting);
        assert!(!rest.wakes(&resting));
        let released = PadState {
            buttons: 0,
            ..resting
        };
        assert!(!rest.wakes(&released));
        assert!(rest.wakes(&PadState {
            buttons: BUTTON_X,
            ..resting
        }));
    }

    #[test]
    fn a_real_pad_wakes_on_its_first_press() {
        let mut rest = PadRest::first(PadState::default());
        assert!(!rest.wakes(&PadState::default()));
        assert!(rest.wakes(&PadState {
            lx: 0.5,
            ..Default::default()
        }));
        assert!(rest.wakes(&PadState::default()));
    }

    #[test]
    fn edges_become_button_events_and_the_device_is_announced() {
        let mut controller = Controller::default();
        let pressed = PadState {
            buttons: BUTTON_A,
            ..Default::default()
        };
        controller.take_input(Some((pressed, PadKind::PlayStation)), 1.0);
        assert_eq!(
            controller.events,
            vec![
                PadEvent::Device(Some("ps")),
                PadEvent::Button {
                    name: "a",
                    down: true
                }
            ]
        );
        controller.events.clear();
        controller.take_input(Some((PadState::default(), PadKind::PlayStation)), 1.1);
        assert_eq!(
            controller.events,
            vec![PadEvent::Button {
                name: "a",
                down: false
            }]
        );
    }

    #[test]
    fn a_pulled_trigger_counts_as_its_button() {
        let mut controller = Controller::default();
        let pulled = PadState {
            rt: 0.6,
            ..Default::default()
        };
        controller.take_input(Some((pulled, PadKind::Xbox)), 0.0);
        assert!(controller.events.contains(&PadEvent::Button {
            name: "rt",
            down: true
        }));
    }

    #[test]
    fn keyboard_use_hides_the_pad_kind() {
        let mut controller = Controller::default();
        let moved = PadState {
            lx: 0.9,
            ..Default::default()
        };
        controller.take_input(Some((moved, PadKind::Xbox)), 0.0);
        assert_eq!(controller.shown_kind(), PadKind::Xbox);
        controller.use_keyboard_and_mouse();
        assert_eq!(controller.shown_kind(), PadKind::None);
        assert_eq!(controller.connected, PadKind::Xbox);
    }

    #[test]
    fn the_deadzone_rescales_from_its_edge() {
        assert_eq!(radial_deadzone(0.1, 0.1, 0.24), Vec2::ZERO);
        let full = radial_deadzone(1.0, 0.0, 0.24);
        assert!((full.x - 1.0).abs() < 1e-6);
        let half = radial_deadzone(0.62, 0.0, 0.24);
        assert!((half.x - 0.5).abs() < 1e-3);
    }
}

#[cfg(test)]
mod cursor_tests {
    use super::*;

    #[test]
    fn the_right_stick_drives_the_cursor_only_while_a_window_captures() {
        let mut controller = Controller {
            pad: PadState {
                rx: 1.0,
                ..Default::default()
            },
            ..Default::default()
        };
        assert_eq!(controller.cursor_travel(0.5, 1000.0), Vec2::ZERO);
        controller.capture = true;
        let travel = controller.cursor_travel(0.5, 1000.0);
        assert!((travel.x - 550.0).abs() < 1e-3 && travel.y == 0.0);
        assert!(controller.cursor_mode);
    }

    #[test]
    fn a_and_x_click_in_cursor_mode_and_leaving_releases_them() {
        let mut controller = Controller {
            capture: true,
            cursor_mode: true,
            ..Default::default()
        };
        let pressed = PadState {
            buttons: BUTTON_A,
            ..Default::default()
        };
        controller.take_input(Some((pressed, PadKind::Xbox)), 0.0);
        assert_eq!(
            controller.clicks,
            vec![CursorClick {
                right: false,
                down: true
            }]
        );
        assert!(!controller
            .events
            .iter()
            .any(|e| matches!(e, PadEvent::Button { name: "a", .. })));
        controller.clicks.clear();
        controller.capture = false;
        controller.take_input(Some((pressed, PadKind::Xbox)), 0.1);
        assert_eq!(
            controller.clicks,
            vec![CursorClick {
                right: false,
                down: false
            }]
        );
        assert!(!controller.cursor_mode);
    }
}
