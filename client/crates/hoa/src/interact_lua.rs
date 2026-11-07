use std::collections::HashSet;

use benilla_mlua::{Function, Lua, Result as LuaResult};

use crate::interact::SharedInteract;

pub fn register_interact(lua: &Lua, interact: &SharedInteract) -> LuaResult<()> {
    let globals = lua.globals();
    globals.set(
        "HoAController_GetInteract",
        get_interact(lua, interact.clone())?,
    )?;
    globals.set("HoAController_Interact", use_pick(lua, interact.clone())?)?;
    globals.set(
        "HoAController_GetPlayerHead",
        player_head(lua, interact.clone())?,
    )?;
    globals.set(
        "HoAController_SetObjectReach",
        set_object_reach(lua, interact.clone())?,
    )?;
    globals.set(
        "HoAController_SetInteractSkip",
        set_interact_skip(lua, interact.clone())?,
    )?;
    globals.set(
        "HoAController_SetAutoUse",
        set_auto_use(lua, interact.clone())?,
    )?;
    globals.set("HoAController_AutoUse", auto_use(lua, interact.clone())?)?;
    Ok(())
}

fn get_interact(lua: &Lua, interact: SharedInteract) -> LuaResult<Function> {
    lua.create_function(move |lua, ()| {
        let state = interact.0.borrow();
        let Some((pick, screen)) = state.pick.and_then(|pick| Some((pick, pick.screen?))) else {
            return lua.pack_multi(benilla_mlua::Nil);
        };
        let candidate = pick.candidate;
        let kind = if candidate.unit { "unit" } else { "object" };
        lua.pack_multi((
            kind,
            f64::from(candidate.entry),
            f64::from(candidate.detail),
            f64::from(screen.x),
            f64::from(screen.y),
            f64::from(candidate.distance),
        ))
    })
}

fn use_pick(lua: &Lua, interact: SharedInteract) -> LuaResult<Function> {
    lua.create_function(move |_, ()| Ok(interact.0.borrow_mut().interact()))
}

fn player_head(lua: &Lua, interact: SharedInteract) -> LuaResult<Function> {
    lua.create_function(move |lua, ()| match interact.0.borrow().player_head {
        Some(head) => lua.pack_multi((f64::from(head.x), f64::from(head.y))),
        None => lua.pack_multi(benilla_mlua::Nil),
    })
}

fn set_object_reach(lua: &Lua, interact: SharedInteract) -> LuaResult<Function> {
    lua.create_function(move |_, (entry, yards): (f64, f64)| {
        let mut state = interact.0.borrow_mut();
        if yards > 0.0 {
            state.object_reach.insert(entry as u32, yards as f32);
        } else {
            state.object_reach.remove(&(entry as u32));
        }
        Ok(())
    })
}

fn set_member(members: &mut HashSet<u32>, id: u32, member: bool) {
    if member {
        members.insert(id);
    } else {
        members.remove(&id);
    }
}

fn set_interact_skip(lua: &Lua, interact: SharedInteract) -> LuaResult<Function> {
    lua.create_function(
        move |_, (kind, id, skip): (Option<String>, Option<f64>, Option<bool>)| {
            let mut state = interact.0.borrow_mut();
            let id = id.unwrap_or(0.0) as u32;
            let skip = skip.unwrap_or(false);
            match kind.as_deref() {
                Some("unit") => state.skip_units = skip,
                Some("object") => set_member(&mut state.skip_entries, id, skip),
                Some("type") => set_member(&mut state.skip_types, id, skip),
                _ => {}
            }
            Ok(())
        },
    )
}

fn set_auto_use(lua: &Lua, interact: SharedInteract) -> LuaResult<Function> {
    lua.create_function(move |_, (entry, on): (f64, Option<bool>)| {
        let mut state = interact.0.borrow_mut();
        set_member(
            &mut state.auto_use_entries,
            entry as u32,
            on.unwrap_or(false),
        );
        Ok(())
    })
}

fn auto_use(lua: &Lua, interact: SharedInteract) -> LuaResult<Function> {
    lua.create_function(move |_, ()| Ok(interact.0.borrow_mut().auto_use()))
}
