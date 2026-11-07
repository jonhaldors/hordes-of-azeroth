use std::cell::Cell;
use std::rc::Rc;

use benilla_mlua::{Lua, Result as LuaResult};
use benilla_ui::script::UiScript;
use bevy::prelude::*;

#[derive(Clone, Default)]
pub struct SharedTyping(pub Rc<Cell<bool>>);

pub fn register_keys_api(lua: &Lua, typing: &SharedTyping) -> LuaResult<()> {
    let typing = typing.clone();
    lua.globals().set(
        "HoAKeys_IsTyping",
        lua.create_function(move |_, ()| Ok(typing.0.get()))?,
    )
}

pub fn capture_typing(world: &mut World) {
    let Some(typing) = world.get_non_send_resource::<SharedTyping>().cloned() else {
        return;
    };
    let focused = world
        .get_non_send_resource::<UiScript>()
        .is_some_and(UiScript::has_keyboard_focus);
    typing.0.set(focused);
}
