use benilla_mlua::{Lua, MultiValue, Result as LuaResult, Table};
use benilla_ui::script::{UiScript, VmKind};
use bevy::prelude::*;

use crate::controller_lua::register_controller_api;
use crate::coop_lua::register_coop_api;
use crate::interact::SharedInteract;
use crate::interact_lua::register_interact;
use crate::keys::{register_keys_api, SharedTyping};
use crate::nameplates::SharedPlates;
use crate::pad::SharedController;
use crate::snapshot::SharedSnapshot;
use crate::unit_lua::register_unit_api;
use crate::world_map::SharedMapAreas;

#[derive(Clone)]
pub struct LuaHosts {
    pub snapshot: SharedSnapshot,
    pub areas: SharedMapAreas,
    pub interact: SharedInteract,
    pub plates: SharedPlates,
    pub typing: SharedTyping,
    pub controller: SharedController,
    pub scripted_login: Option<(String, String)>,
}

impl LuaHosts {
    pub fn seed(&self, script: &UiScript) {
        let lua = script.lua();
        let seeded = match script.vm_kind() {
            VmKind::Glue => self.seed_glue(lua),
            VmKind::InGame => register_classic_api(lua, &self.snapshot, &self.areas)
                .and_then(|()| register_interact(lua, &self.interact))
                .and_then(|()| register_unit_api(lua, &self.snapshot, &self.plates))
                .and_then(|()| register_keys_api(lua, &self.typing)),
        }
        .and_then(|()| register_controller_api(lua, &self.controller))
        .and_then(|()| register_coop_api(lua));
        if let Err(error) = seeded {
            warn!("Hordes of Azeroth: Lua functions not installed: {error}");
        }
    }

    fn seed_glue(&self, lua: &Lua) -> LuaResult<()> {
        let Some((account, password)) = &self.scripted_login else {
            return Ok(());
        };
        let globals = lua.globals();
        globals.set("HOA_LOGIN_ACCOUNT", account.as_str())?;
        globals.set("HOA_LOGIN_PASSWORD", password.as_str())?;
        Ok(())
    }
}

pub fn scripted_login_from_env() -> Option<(String, String)> {
    let account = std::env::var("WOW_USER").ok().filter(|v| !v.is_empty())?;
    let password = std::env::var("WOW_PASS").ok().filter(|v| !v.is_empty())?;
    Some((account, password))
}

fn register_classic_api(
    lua: &Lua,
    snapshot: &SharedSnapshot,
    areas: &SharedMapAreas,
) -> LuaResult<()> {
    let globals = lua.globals();
    globals.set("UnitPosition", unit_position(lua, snapshot.clone())?)?;
    globals.set("GetPlayerFacing", player_facing(lua, snapshot.clone())?)?;
    globals.set("GetCameraFacing", camera_facing(lua, snapshot.clone())?)?;
    globals.set(
        "ClosestUnitPosition",
        closest_unit_position(lua, snapshot.clone())?,
    )?;
    let c_map = match globals.get::<Option<Table>>("C_Map")? {
        Some(table) => table,
        None => {
            let table = lua.create_table()?;
            globals.set("C_Map", table.clone())?;
            table
        }
    };
    c_map.set("GetMapAreaIDs", map_area_ids(lua, areas.clone())?)?;
    c_map.set(
        "GetMapPosFromWorldPos",
        map_pos_from_world_pos(lua, areas.clone())?,
    )?;
    Ok(())
}

fn is_player_token(token: &str) -> bool {
    token.eq_ignore_ascii_case("player")
}

fn unit_position(lua: &Lua, snapshot: SharedSnapshot) -> LuaResult<benilla_mlua::Function> {
    lua.create_function(move |lua, token: String| {
        let view = snapshot.0.borrow();
        match view.player.filter(|_| is_player_token(&token)) {
            Some(player) => lua.pack_multi((
                f64::from(player.position.west),
                f64::from(player.position.north),
                f64::from(player.position.up),
                f64::from(view.map_id),
            )),
            None => lua.pack_multi(benilla_mlua::Nil),
        }
    })
}

fn player_facing(lua: &Lua, snapshot: SharedSnapshot) -> LuaResult<benilla_mlua::Function> {
    lua.create_function(move |lua, ()| match snapshot.0.borrow().player {
        Some(player) => lua.pack_multi(f64::from(player.facing)),
        None => Ok(MultiValue::new()),
    })
}

fn camera_facing(lua: &Lua, snapshot: SharedSnapshot) -> LuaResult<benilla_mlua::Function> {
    lua.create_function(move |lua, ()| match snapshot.0.borrow().camera_facing {
        Some(facing) => lua.pack_multi(f64::from(facing)),
        None => Ok(MultiValue::new()),
    })
}

fn closest_unit_position(lua: &Lua, snapshot: SharedSnapshot) -> LuaResult<benilla_mlua::Function> {
    lua.create_function(move |lua, entry: f64| {
        match snapshot.0.borrow().closest_creature(entry as u32) {
            Some((position, distance)) => lua.pack_multi((
                f64::from(position.north),
                f64::from(position.west),
                f64::from(distance),
            )),
            None => Ok(MultiValue::new()),
        }
    })
}

fn map_area_ids(lua: &Lua, areas: SharedMapAreas) -> LuaResult<benilla_mlua::Function> {
    lua.create_function(move |lua, ()| {
        let table = lua.create_table()?;
        for (name, area_id) in areas.0.zone_ids() {
            table.set(name, f64::from(area_id))?;
        }
        Ok(table)
    })
}

fn map_pos_from_world_pos(lua: &Lua, areas: SharedMapAreas) -> LuaResult<benilla_mlua::Function> {
    lua.create_function(
        move |lua, (map_id, world, zone): (f64, Table, Option<f64>)| {
            let north: f64 = world.get("x")?;
            let west: f64 = world.get("y")?;
            let found = match zone {
                Some(zone) => areas
                    .0
                    .position_in_zone(zone as u32, north, west)
                    .map(|(across, down)| (zone as u32, across, down)),
                None => areas.0.position_on_map(map_id as u32, north, west),
            };
            let Some((area_id, across, down)) = found else {
                return lua.pack_multi(benilla_mlua::Nil);
            };
            let position = lua.create_table()?;
            position.set("x", across)?;
            position.set("y", down)?;
            lua.pack_multi((f64::from(area_id), position))
        },
    )
}
