//! A heap handle is a plain index anyone can build. One to no live object, stale or made up,
//! reads some object of the right type in a release build and panics in a debug one; it never
//! reads freed or out-of-bounds memory.

use benilla_lua::heap::Heap;
use benilla_lua::value::{FuncRef, StrRef, TableRef, UserRef};

/// `f`'s answer, or `None` where a debug build's check panicked.
fn read<T>(f: impl FnOnce() -> T) -> Option<T> {
    let r = std::panic::catch_unwind(std::panic::AssertUnwindSafe(f));
    assert!(
        r.is_ok() || cfg!(debug_assertions),
        "only a debug build's handle check panics"
    );
    r.ok()
}

#[test]
fn a_made_up_handle_reads_no_memory_outside_the_heap() {
    for i in [0, 1, 63, 64, 1 << 20, u32::MAX] {
        let heap = Heap::default();
        read(|| heap.table(TableRef(i)).meta.is_some());
        read(|| {
            matches!(
                heap.func(FuncRef(i)),
                benilla_lua::heap::FuncObj::Native { .. }
            )
        });
        read(|| heap.user(UserRef(i)).tag);
        read(|| heap.upval(i));
        read(|| {
            heap.str(StrRef {
                id: i & 0xff_ffff,
                hash: 0,
            })
            .len()
        });
    }
}

#[test]
fn a_stale_handle_reads_no_freed_memory() {
    let mut vm = benilla_lua::new_state();
    let t = vm.heap.new_table(0, 4);
    let k = vm.str(b"key");
    vm.heap.table_mut(t).set(k, k).unwrap();
    vm.full_gc();
    // Nothing held the table: its slot is free, then taken by others.
    let heap = vm.heap.clone();
    read(move || heap.table(t).meta.is_some());
    for _ in 0..100 {
        vm.heap.new_table(0, 0);
    }
    let heap = vm.heap.clone();
    read(move || heap.table(t).meta.is_some());
}
