//! A fork is independent: host closures it copied act on the fork, not on the original.

use benilla_mlua::{Lua, Table};

#[test]
fn a_copied_host_closure_acts_on_its_own_fork() {
    let lua = Lua::new();
    let store = lua.create_table().unwrap();
    store.set("n", 0).unwrap();
    let held = store.clone();
    let bump = lua
        .create_function(move |_, ()| {
            let n: i64 = held.get("n")?;
            held.set("n", n + 1)
        })
        .unwrap();
    lua.globals().set("bump", bump).unwrap();
    lua.globals().set("store", store).unwrap();
    lua.load("bump()").exec().unwrap();

    let fork = lua.fork();
    fork.load("bump() bump()").exec().unwrap();
    let n = |l: &Lua| {
        l.globals()
            .get::<Table>("store")
            .unwrap()
            .get::<i64>("n")
            .unwrap()
    };
    assert_eq!(n(&lua), 1, "the original is untouched");
    assert_eq!(n(&fork), 3, "the fork's own table counted");
    lua.load("bump()").exec().unwrap();
    assert_eq!((n(&lua), n(&fork)), (2, 3));
}

/// A handle made after the fork names nothing in the fork: reading it from a callback the fork
/// copied is another state's value, mlua's panic, which the fork's `pcall` catches.
#[test]
fn a_handle_made_after_the_fork_is_foreign_to_it() {
    use std::cell::RefCell;
    use std::rc::Rc;
    let lua = Lua::new();
    let slot: Rc<RefCell<Option<Table>>> = Default::default();
    let held = slot.clone();
    let read = lua
        .create_function(move |_, ()| {
            let t = held.borrow().clone().expect("set before the call");
            t.get::<i64>("v")
        })
        .unwrap();
    lua.globals().set("read", read).unwrap();
    let fork = lua.fork();
    let t = lua.create_table().unwrap();
    t.set("v", 7).unwrap();
    *slot.borrow_mut() = Some(t);
    assert_eq!(lua.load("return read()").eval::<i64>().unwrap(), 7);
    let r: String = fork
        .load("local ok, e = pcall(read) return tostring(ok) .. ' ' .. tostring(e)")
        .eval()
        .unwrap();
    assert_eq!(
        r,
        "false Lua instance passed Value created from a different main Lua state"
    );
}

/// A string handle is checked as a table handle is: made after the fork, it names nothing in the
/// fork, even where the fork has since rooted a string of its own under the same slot.
#[test]
fn a_string_made_after_the_fork_is_foreign_to_it() {
    use benilla_mlua::String as LuaString;
    use std::cell::RefCell;
    use std::rc::Rc;
    let lua = Lua::new();
    let slot: Rc<RefCell<Option<LuaString>>> = Default::default();
    let held = slot.clone();
    let read = lua
        .create_function(move |_, ()| {
            let s = held.borrow().clone().expect("set before the call");
            Ok(s.to_str()?.to_string())
        })
        .unwrap();
    lua.globals().set("read", read).unwrap();
    let fork = lua.fork();
    let _fork_own = fork.create_string("FORK0").unwrap();
    *slot.borrow_mut() = Some(lua.create_string("TEMPLATE").unwrap());
    assert_eq!(
        lua.load("return read()").eval::<String>().unwrap(),
        "TEMPLATE"
    );
    let r: String = fork
        .load("local ok, e = pcall(read) return tostring(ok) .. ' ' .. tostring(e)")
        .eval()
        .unwrap();
    assert_eq!(
        r,
        "false Lua instance passed Value created from a different main Lua state"
    );
}

/// A fork is made between calls: inside a callback the copy would hold frames no one returns
/// from, so it panics, and the panic resumes in Rust as a callback's panic does.
#[test]
fn a_fork_inside_a_callback_panics() {
    let lua = Lua::new();
    let f = lua
        .create_function(|lua, ()| {
            let _ = lua.fork();
            Ok(())
        })
        .unwrap();
    let r = std::panic::catch_unwind(std::panic::AssertUnwindSafe(|| f.call::<()>(())));
    let p = r.unwrap_err();
    assert_eq!(
        p.downcast_ref::<&str>().copied(),
        Some("a state is forked from outside its callbacks")
    );
    // Between calls it forks.
    let copy = lua.fork();
    assert_eq!(copy.load("return 1 + 1").eval::<i64>().unwrap(), 2);
}
