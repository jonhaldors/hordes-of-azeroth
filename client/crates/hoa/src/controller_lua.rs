use benilla_mlua::{Function, Lua, MultiValue, Result as LuaResult, Value};
use benilla_ui::script::UiScript;
use bevy::prelude::*;

use crate::pad::{PadEvent, PadKind, PadState, SharedController};

type SimulateArgs = (
    Value,
    Option<f64>,
    Option<f64>,
    Option<f64>,
    Option<f64>,
    Option<f64>,
    Option<f64>,
    Value,
);

pub fn register_controller_api(lua: &Lua, controller: &SharedController) -> LuaResult<()> {
    let globals = lua.globals();
    let c = controller.clone();
    globals.set(
        "HoAController_GetType",
        lua.create_function(move |_, ()| Ok(c.0.borrow().shown_kind().name()))?,
    )?;
    let c = controller.clone();
    globals.set(
        "HoAController_GetConnected",
        lua.create_function(move |_, ()| Ok(c.0.borrow().connected.name()))?,
    )?;
    let c = controller.clone();
    globals.set(
        "HoAController_GetSticks",
        lua.create_function(move |_, ()| {
            let pad = c.0.borrow().pad;
            Ok((
                f64::from(pad.lx),
                f64::from(pad.ly),
                f64::from(pad.rx),
                f64::from(pad.ry),
            ))
        })?,
    )?;
    let c = controller.clone();
    globals.set(
        "HoAController_SetCapture",
        lua.create_function(move |_, on: Option<bool>| {
            c.0.borrow_mut().capture = on.unwrap_or(false);
            Ok(())
        })?,
    )?;
    let c = controller.clone();
    globals.set(
        "HoAController_SetScrollMode",
        lua.create_function(move |_, on: Option<bool>| {
            c.0.borrow_mut().scroll_mode = on.unwrap_or(false);
            Ok(())
        })?,
    )?;
    let c = controller.clone();
    globals.set(
        "HoAController_CursorMode",
        lua.create_function(move |_, ()| Ok(c.0.borrow().cursor_mode))?,
    )?;
    globals.set("HoAController_Frame", lua.create_function(|_, ()| Ok(()))?)?;
    let c = controller.clone();
    globals.set(
        "HoAController_SetOption",
        lua.create_function(move |_, (name, value): (Option<String>, Value)| {
            let (number, flag) = match value {
                Value::Number(n) => (n as f32, n != 0.0),
                Value::Integer(n) => (n as f32, n != 0),
                Value::Boolean(b) => (if b { 1.0 } else { 0.0 }, b),
                _ => (0.0, false),
            };
            if let Some(name) = name {
                c.0.borrow_mut().options.set(&name, number, flag);
            }
            Ok(())
        })?,
    )?;
    globals.set("HoAController_Simulate", simulate(lua, controller.clone())?)?;
    Ok(())
}

fn simulate(lua: &Lua, controller: SharedController) -> LuaResult<Function> {
    lua.create_function(
        move |_, (lx, ly, rx, ry, lt, rt, buttons, style): SimulateArgs| {
            let mut c = controller.0.borrow_mut();
            if matches!(lx, Value::Nil) {
                c.simulated = None;
                return Ok(());
            }
            let number = |v: Option<f64>| v.unwrap_or(0.0) as f32;
            let lx = match lx {
                Value::Number(n) => n as f32,
                Value::Integer(n) => n as f32,
                _ => 0.0,
            };
            let state = PadState {
                lx: lx.clamp(-1.0, 1.0),
                ly: number(ly).clamp(-1.0, 1.0),
                rx: number(rx).clamp(-1.0, 1.0),
                ry: number(ry).clamp(-1.0, 1.0),
                lt: number(lt).clamp(0.0, 1.0),
                rt: number(rt).clamp(0.0, 1.0),
                buttons: buttons.unwrap_or(0.0) as u32,
            };
            let kind = match style {
                Value::Boolean(true) => PadKind::PlayStation,
                Value::String(name) => PadKind::of_style(&name.to_string_lossy()),
                _ => PadKind::Xbox,
            };
            c.simulated = Some((state, kind));
            Ok(())
        },
    )
}

fn call_global(script: &UiScript, name: &str, args: MultiValue) {
    let Ok(Some(function)) = script.lua().globals().get::<Option<Function>>(name) else {
        return;
    };
    if let Err(error) = function.call::<()>(args) {
        warn!("Hordes of Azeroth: {name} failed: {error}");
    }
}

pub fn deliver_pad_events(world: &mut World) {
    let Some(controller) = world.get_non_send_resource::<SharedController>().cloned() else {
        return;
    };
    let events = std::mem::take(&mut controller.0.borrow_mut().events);
    if events.is_empty() {
        return;
    }
    benilla_app::run_hosted(world, |script| {
        let Some(script) = script else {
            return;
        };
        for event in events {
            let lua = script.lua();
            match event {
                PadEvent::Button { name, down } => {
                    if let Ok(args) = lua.pack_multi((name, down)) {
                        script.with_binding_event(|| {
                            call_global(script, "HoAController_OnButton", args)
                        });
                    }
                }
                PadEvent::Device(kind) => {
                    if let Ok(args) = lua.pack_multi(kind) {
                        call_global(script, "HoAController_OnDevice", args);
                    }
                }
            }
        }
    });
}
