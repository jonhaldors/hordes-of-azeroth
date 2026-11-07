//! A native holds `&mut Vm`, so safe code could put another VM or heap in place of the running
//! one, freeing the code and stack the running frames point into. The interpreter stops with a
//! panic there; it never runs on.

use benilla_lua::Vm;

fn replace_heap(vm: &mut Vm, _nargs: usize) -> benilla_lua::api::R<usize> {
    vm.heap = Default::default();
    Ok(0)
}

fn replace_vm(vm: &mut Vm, _nargs: usize) -> benilla_lua::api::R<usize> {
    *vm = benilla_lua::new_state();
    Ok(0)
}

fn run_with(native: benilla_lua::heap::NativeFn) -> String {
    let mut vm = benilla_lua::new_state();
    let f = vm.new_native("replace", native);
    vm.set_global("replace", f);
    let r = std::panic::catch_unwind(std::panic::AssertUnwindSafe(|| {
        // In a protected call, inside a Lua function, with a loop after: every way on would
        // read the freed frames.
        vm.exec(
            b"local function g() replace() local s = 0 for i = 1, 10 do s = s + i end return s end \
              return pcall(g)",
            b"=t",
        )
    }));
    match r {
        Ok(_) => "ran on".to_owned(),
        Err(p) => p
            .downcast_ref::<&str>()
            .map(|s| s.to_string())
            .or_else(|| p.downcast_ref::<String>().cloned())
            .unwrap_or_default(),
    }
}

#[test]
fn a_native_that_replaces_the_heap_stops_the_vm() {
    assert_eq!(
        run_with(replace_heap),
        "a native replaced the running Lua VM or its heap"
    );
}

#[test]
fn a_native_that_replaces_the_vm_stops_it() {
    assert_eq!(
        run_with(replace_vm),
        "a native replaced the running Lua VM or its heap"
    );
}

/// A hook, and host code a collection inside Lua runs (a freed host closure's captures, dropped
/// through the host's `reentry`), hold the same `&mut Vm`; one that replaces it stops the VM too.
#[test]
fn a_hook_or_a_collection_that_replaces_the_vm_stops_it() {
    use std::rc::Rc;
    let stopped = |vm: &mut Vm, src: &[u8]| {
        let r = std::panic::catch_unwind(std::panic::AssertUnwindSafe(|| vm.exec(src, b"=t")));
        r.err()
            .and_then(|p| p.downcast_ref::<&str>().map(|s| s.to_string()))
            .unwrap_or_default()
    };
    let mut vm = benilla_lua::new_state();
    vm.set_hook(
        10,
        Rc::new(|vm: &mut Vm| {
            vm.heap = Default::default();
            Ok(())
        }),
    );
    assert_eq!(
        stopped(
            &mut vm,
            b"local s = 0 for i = 1, 100 do s = s + i end return s"
        ),
        "a native replaced the running Lua VM or its heap"
    );

    let mut vm = benilla_lua::new_state();
    vm.reentry = Some(Rc::new(|vm: &mut Vm, f: &mut dyn FnMut()| {
        *vm = benilla_lua::new_state();
        f()
    }));
    let host: benilla_lua::heap::HostFn = Rc::new(|_: &mut Vm, _| Ok(0));
    let f = vm.new_host("f", host);
    vm.set_global("F", f);
    assert_eq!(
        stopped(
            &mut vm,
            b"F = nil for i = 1, 200000 do local t = {i} end return 1"
        ),
        "a native replaced the running Lua VM or its heap"
    );
}
