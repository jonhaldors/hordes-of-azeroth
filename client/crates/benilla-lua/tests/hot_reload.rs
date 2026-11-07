//! Hot reload: an addon's functions take new code in place, and everything that holds them
//! (a handler list, another addon's hook, a captured local helper) runs it, with state kept.

const NAME: &[u8] = b"@Interface\\AddOns\\MyAddon\\MyAddon.lua";

const V1: &str = r#"
MyAddon = { count = 0 }
local prefix = "v1"
local function helper(x) return x * 2 end
function MyAddon:OnEvent(event)
  self.count = self.count + 1
  return prefix .. ":" .. event .. ":" .. self.count
end
function MyAddon.Double(x) return helper(x) end
Handlers = {}
table.insert(Handlers, function(e) return MyAddon:OnEvent(e) end)
"#;

/// `OnEvent` and the local `helper` change; the top level is the same.
const V2: &str = r#"
MyAddon = { count = 0 }
local prefix = "v1"
local function helper(x) return x * 3 end
function MyAddon:OnEvent(event)
  self.count = self.count + 1
  return "NEW " .. prefix .. ":" .. event .. ":" .. self.count
end
function MyAddon.Double(x) return helper(x) end
Handlers = {}
table.insert(Handlers, function(e) return MyAddon:OnEvent(e) end)
"#;

/// `OnEvent` now captures a local the old closure has no slot for.
const V3: &str = r#"
MyAddon = { count = 0 }
local prefix = "v1"
local suffix = "!"
local function helper(x) return x * 3 end
function MyAddon:OnEvent(event)
  self.count = self.count + 1
  return prefix .. ":" .. event .. suffix
end
function MyAddon.Double(x) return helper(x) end
Handlers = {}
table.insert(Handlers, function(e) return MyAddon:OnEvent(e) end)
"#;

fn run(vm: &mut benilla_lua::Vm, src: &str) -> String {
    match vm.exec(src.as_bytes(), b"=probe") {
        Ok(v) => v.first().map_or(String::new(), |&v| vm.display(v)),
        Err(e) => format!("<raised> {}", vm.display(e)),
    }
}

#[test]
fn edited_functions_run_new_code_and_keep_their_state() {
    let mut vm = benilla_lua::new_state();
    vm.exec(V1.as_bytes(), NAME).unwrap();
    // Another addon keeps a direct reference, as SetScript or a hook does.
    run(&mut vm, "OtherAddonHook = MyAddon.OnEvent");
    assert_eq!(run(&mut vm, "return Handlers[1]('A')"), "v1:A:1");
    assert_eq!(
        run(&mut vm, "return OtherAddonHook(MyAddon, 'B')"),
        "v1:B:2"
    );
    assert_eq!(run(&mut vm, "return MyAddon.Double(5)"), "10");

    let report = vm.hot_reload(NAME, V2.as_bytes()).unwrap();
    println!("{report:#?}");
    assert!(report.reshaped.is_empty() && report.added.is_empty() && report.removed.is_empty());

    // The count carried on; the list's closure, the other addon's reference and the local
    // helper behind `Double` all run the new code.
    assert_eq!(run(&mut vm, "return Handlers[1]('C')"), "NEW v1:C:3");
    assert_eq!(
        run(&mut vm, "return OtherAddonHook(MyAddon, 'D')"),
        "NEW v1:D:4"
    );
    assert_eq!(run(&mut vm, "return MyAddon.Double(5)"), "15");
}

#[test]
fn a_function_whose_captures_changed_is_reported_and_left_running() {
    let mut vm = benilla_lua::new_state();
    vm.exec(V1.as_bytes(), NAME).unwrap();
    let report = vm.hot_reload(NAME, V3.as_bytes()).unwrap();
    assert_eq!(report.reshaped, vec!["MyAddon:OnEvent".to_string()]);
    // The old code still answers; the rest of the file swapped.
    assert_eq!(run(&mut vm, "return Handlers[1]('A')"), "v1:A:1");
    assert_eq!(run(&mut vm, "return MyAddon.Double(5)"), "15");
}

#[test]
fn a_syntax_error_changes_nothing() {
    let mut vm = benilla_lua::new_state();
    vm.exec(V1.as_bytes(), NAME).unwrap();
    let err = vm
        .hot_reload(NAME, b"function MyAddon:OnEvent( return end")
        .unwrap_err();
    assert!(err.to_string().contains("MyAddon.lua:1:"), "{err}");
    assert_eq!(run(&mut vm, "return Handlers[1]('A')"), "v1:A:1");
}

#[test]
fn a_reload_then_a_snapshot_restore_goes_back_to_the_old_code() {
    let mut vm = benilla_lua::new_state();
    vm.exec(V1.as_bytes(), NAME).unwrap();
    let before = vm.clone();
    vm.hot_reload(NAME, V2.as_bytes()).unwrap();
    assert_eq!(run(&mut vm, "return MyAddon.Double(1)"), "3");
    vm = before;
    assert_eq!(run(&mut vm, "return MyAddon.Double(1)"), "2");
}

#[test]
fn an_edit_above_a_function_moves_its_lines_and_keeps_its_key() {
    let mut vm = benilla_lua::new_state();
    vm.exec(V1.as_bytes(), NAME).unwrap();
    let moved = format!("-- a header\n-- grown by three lines\n\n{V2}");
    let report = vm.hot_reload(NAME, moved.as_bytes()).unwrap();
    assert!(
        report.reshaped.is_empty() && report.added.is_empty() && report.removed.is_empty(),
        "{report:#?}"
    );
    assert_eq!(report.swapped.len(), 4, "{report:#?}");
    assert_eq!(run(&mut vm, "return Handlers[1]('A')"), "NEW v1:A:1");
    assert_eq!(run(&mut vm, "return MyAddon.Double(5)"), "15");
    // The swapped code reports its new lines.
    let line = moved
        .lines()
        .position(|l| l.contains("self.count = self.count + 1"))
        .unwrap()
        + 1;
    let err = run(&mut vm, "return MyAddon.OnEvent(nil, 'B')");
    assert!(err.contains(&format!("MyAddon.lua:{line}:")), "{err}");
}

/// A frame still running replaced code keeps that code's constants and upvalues alive through a
/// collection: only the retired copy holds them once the closure runs the new code.
#[test]
fn a_running_frame_keeps_its_replaced_code_alive_through_a_collection() {
    use std::rc::Rc;
    let mut vm = benilla_lua::new_state();
    let reload: benilla_lua::heap::HostFn = Rc::new(|vm: &mut benilla_lua::Vm, _| {
        vm.hot_reload(b"=mod", b"local u = {} function F() return 1 end")
            .unwrap();
        vm.full_gc();
        // Fill any freed slot with other objects.
        for i in 0..64 {
            let s = format!("filler {i}");
            let v = vm.str(s.as_bytes());
            let t = vm.heap.new_table(0, 0);
            vm.heap
                .table_mut(t)
                .set(v, benilla_lua::Value::Num(i as f64))
                .unwrap();
        }
        Ok(0)
    });
    let f = vm.new_host("reload", reload);
    vm.set_global("reload", f);
    vm.exec(
        b"local u = { tag = 'kept' }
          function F() reload() return 'old constant', u.tag end",
        b"=mod",
    )
    .unwrap();
    assert_eq!(
        run(&mut vm, "local a, b = F() return a .. '/' .. b"),
        "old constant/kept"
    );
    // The next call runs the new code.
    assert_eq!(run(&mut vm, "return F()"), "1");
}

/// `probe` after running `v1`, after reloading `v2` over it, and on a fresh state running `v2`,
/// with the reload's report.
fn three(
    v1: &str,
    keep: &str,
    v2: &str,
    probe: &str,
) -> (String, String, String, benilla_lua::reload::Report) {
    let mut vm = benilla_lua::new_state();
    vm.exec(v1.as_bytes(), NAME).unwrap();
    run(&mut vm, keep);
    let before = run(&mut vm, probe);
    let report = vm.hot_reload(NAME, v2.as_bytes()).unwrap();
    let after = run(&mut vm, probe);
    let mut fresh_vm = benilla_lua::new_state();
    fresh_vm.exec(v2.as_bytes(), NAME).unwrap();
    run(&mut fresh_vm, keep);
    let fresh = run(&mut fresh_vm, probe);
    (before, after, fresh, report)
}

#[test]
fn a_function_added_above_an_assigned_one_leaves_its_key_alone() {
    let (before, after, fresh, _) = three(
        "A = function() return 'a' end",
        "KeepA = A",
        "C = function() return 'c' end A = function() return 'a2' end",
        "return KeepA()",
    );
    assert_eq!(
        (before.as_str(), after.as_str(), fresh.as_str()),
        ("a", "a2", "a2")
    );
}

#[test]
fn swapped_fields_of_a_local_table_keep_their_keys() {
    let (before, after, fresh, report) = three(
        "local M = {} Mod = M function M.f() return 'f' end function M.g() return 'g' end",
        "F, G = Mod.f, Mod.g",
        "local M = {} Mod = M function M.g() return 'g' end function M.f() return 'f' end",
        "return F() .. ',' .. G()",
    );
    assert_eq!(
        (before.as_str(), after.as_str(), fresh.as_str()),
        ("f,g", "f,g", "f,g")
    );
    assert_eq!(report.swapped, ["M.f", "M.g"]);
}

#[test]
fn a_method_added_above_another_leaves_its_key_alone() {
    let (before, after, fresh, report) = three(
        "local M = {} Mod = M function M:f() return 'f' end",
        "F = Mod.f",
        "local M = {} Mod = M function M:new() return 'new' end function M:f() return 'f2' end",
        "return F(Mod)",
    );
    assert_eq!(
        (before.as_str(), after.as_str(), fresh.as_str()),
        ("f", "f2", "f2")
    );
    assert_eq!(report.swapped, ["M:f"]);
    assert_eq!(report.added, ["M:new"]);
}

#[test]
fn a_method_and_a_field_of_one_name_are_two_functions() {
    let v = "T = {} function T.m() return 'dot' end D = T.m function T:m() return 'colon' end";
    let (_, after, _, report) = three(v, "", v, "return D() .. ',' .. T.m(T)");
    assert_eq!(after, "dot,colon");
    assert_eq!(report.swapped, ["T.m", "T:m"]);
    assert!(report.reshaped.is_empty(), "{report:#?}");
}

#[test]
fn swapped_handler_assignments_keep_their_keys() {
    let (before, after, fresh, _) = three(
        "H = {} H.OnShow = function() return 'show' end H.OnHide = function() return 'hide' end",
        "S, D = H.OnShow, H.OnHide",
        "H = {} H.OnHide = function() return 'hide' end H.OnShow = function() return 'show' end",
        "return S() .. ',' .. D()",
    );
    assert_eq!(
        (before.as_str(), after.as_str(), fresh.as_str()),
        ("show,hide", "show,hide", "show,hide")
    );
}

#[test]
fn an_anonymous_function_added_above_a_nested_one_leaves_it_alone() {
    let (before, after, fresh, _) = three(
        "Mk = function() return function() return 'inner1' end end",
        "Inner = Mk()",
        "Pre = function() return 'PRE' end Mk = function() return function() return 'inner2' end end",
        "return Inner()",
    );
    assert_eq!(
        (before.as_str(), after.as_str(), fresh.as_str()),
        ("inner1", "inner2", "inner2")
    );
}

#[test]
fn table_fields_and_locals_are_named_after_their_target() {
    let (before, after, fresh, report) = three(
        "local f = function() return 'f' end T = { a = function() return 'a' end, b = function() return f() end }",
        "A, B = T.a, T.b",
        "T = { b = function() return 'b2' end, a = function() return 'a2' end }",
        "return A() .. ',' .. B()",
    );
    assert_eq!(
        (before.as_str(), after.as_str(), fresh.as_str()),
        ("a,f", "a2,b2", "a2,b2")
    );
    assert_eq!(report.swapped, ["T.a", "T.b"]);
}

#[test]
fn numbered_keys_whose_count_changed_stay_on_the_old_code() {
    let (before, after, _, report) = three(
        "L = {} table.insert(L, function() return 1 end) table.insert(L, function() return 2 end)",
        "",
        "L = {} table.insert(L, function() return 0 end) table.insert(L, function() return 1 end) \
         table.insert(L, function() return 2 end)",
        "return L[1]() .. ',' .. L[2]()",
    );
    assert_eq!((before.as_str(), after.as_str()), ("1,2", "1,2"));
    // Named after the call, `table.insert`, and numbered by position.
    assert_eq!(report.reshaped, ["insert", "insert#2"]);
    assert!(report.swapped.is_empty(), "{report:#?}");
}

#[test]
fn a_capture_of_another_declaration_of_a_name_is_a_reshape() {
    let (before, after, fresh, report) = three(
        "local x = 'outer' do local x = 'inner' function F() return x end end",
        "",
        "local x = 'outer' function F() return x end",
        "return F()",
    );
    assert_eq!(
        (before.as_str(), after.as_str(), fresh.as_str()),
        ("inner", "inner", "outer")
    );
    assert_eq!(report.reshaped, ["F"]);
}

#[test]
fn a_function_without_a_live_closure_is_not_added() {
    let v = "if false then H = function() end end function F() return 1 end";
    let (_, _, _, report) = three(v, "", v, "return F()");
    assert!(report.added.is_empty(), "{report:#?}");
    assert_eq!(report.swapped, ["F"]);
}

/// Handlers set through a call are told apart by the call: deleting `OnShow`'s and adding
/// `OnEvent`'s leaves `OnHide`'s closure on `OnHide`'s code, where positional keys would have
/// handed it the newcomer's.
#[test]
fn handlers_set_through_a_call_keep_their_own_code() {
    const H1: &str = r#"
F = {}
function F:SetScript(name, fn) self[name] = fn end
F:SetScript("OnShow", function() return "show" end)
F:SetScript("OnHide", function() return "hide" end)
"#;
    const H2: &str = r#"
F = {}
function F:SetScript(name, fn) self[name] = fn end
F:SetScript("OnHide", function() return "hide v2" end)
F:SetScript("OnEvent", function() return "event" end)
"#;
    let mut vm = benilla_lua::new_state();
    vm.exec(H1.as_bytes(), NAME).unwrap();
    let r = vm.hot_reload(NAME, H2.as_bytes()).unwrap();
    assert_eq!(run(&mut vm, "return F.OnHide()"), "hide v2");
    assert_eq!(
        run(&mut vm, "return F.OnShow()"),
        "show",
        "a removed handler keeps its code"
    );
    assert_eq!(r.swapped, ["F:SetScript", "SetScript:OnHide"]);
    assert_eq!(r.removed, ["SetScript:OnShow"]);
    assert_eq!(r.added, ["SetScript:OnEvent"]);
}

/// An edit of the top level, which ran once, is told apart from an edit inside a function body:
/// the new value of `SPACING` is not the one the swapped function reads.
#[test]
fn a_changed_top_level_is_told_apart() {
    use benilla_lua::reload::top_level_changed;
    let old = b"local SPACING = 4 Note('kept') function Gap() return SPACING end";
    let body = b"local SPACING = 4 Note('kept') function Gap() return SPACING + 0 end";
    let top = b"local SPACING = 6 Note('kept') function Gap() return SPACING + 0 end";
    assert!(
        !top_level_changed(old, body),
        "a body edit leaves the top level"
    );
    assert!(top_level_changed(old, top));
    assert!(
        !top_level_changed(old, b"nil +"),
        "a source that does not compile"
    );

    let mut vm = benilla_lua::new_state();
    vm.exec(b"function Note() end", b"=setup").unwrap();
    vm.exec(old, NAME).unwrap();
    vm.hot_reload(NAME, top).unwrap();
    assert_eq!(
        run(&mut vm, "return Gap()"),
        "4",
        "the top level did not run again"
    );
}

/// An XML handler is a chunk run as a function. Its body edited, the handlers built from it
/// (each frame's own chunk, `F1:OnClick`) run the new body; another handler with the same body
/// under a tag the edit did not name, and a handler with another body, keep theirs.
#[test]
fn handler_bodies_are_swapped_into_the_frames_that_run_them() {
    let mut vm = benilla_lua::new_state();
    for (name, body) in [
        ("F1:OnClick", "return 'a'"),
        ("F2:OnClick", "return 'a'"),
        ("F3:OnShow", "return 'a'"),
        ("F4:OnClick", "return 'other'"),
    ] {
        let f = vm.load(body.as_bytes(), name.as_bytes()).unwrap();
        vm.set_global(&name.replace(':', "_"), f);
    }
    let n = vm
        .hot_reload_mains(b"return 'a'", b"return 'b'", |p| {
            p.source.ends_with(b":OnClick")
        })
        .unwrap();
    assert_eq!(n, 2);
    assert_eq!(
        run(
            &mut vm,
            "return F1_OnClick() .. F2_OnClick() .. F3_OnShow() .. F4_OnClick()"
        ),
        "bbaother"
    );
}
