//! A script host frees its VM when dropped: its host closures capture handles into it, and a
//! handle holds its state weakly, so nothing keeps the VM alive past the host.

use std::cell::Cell;
use std::rc::Rc;

use benilla_ui::script::UiScript;

struct Sentinel(Rc<Cell<bool>>);

impl Drop for Sentinel {
    fn drop(&mut self) {
        self.0.set(true);
    }
}

fn watched(s: &UiScript) -> Rc<Cell<bool>> {
    let gone = Rc::new(Cell::new(false));
    s.lua().set_app_data(Sentinel(gone.clone()));
    gone
}

#[test]
fn a_dropped_script_host_frees_its_vm() {
    let s = UiScript::new().expect("a script host");
    let gone = watched(&s);
    s.lua()
        .load("table.insert({}, 1) table.setn({}, 0)")
        .exec()
        .unwrap();
    drop(s);
    assert!(gone.get(), "the VM and its app data went with the host");
}

#[test]
fn a_dropped_fork_frees_its_vm_and_leaves_the_template() {
    let template = UiScript::new().expect("a script host");
    let fork = template.fork();
    let gone = watched(&fork);
    fork.lua().load("table.insert({}, 1)").exec().unwrap();
    drop(fork);
    assert!(gone.get(), "the fork's VM went with it");
    template.lua().load("table.insert({}, 1)").exec().unwrap();
}
