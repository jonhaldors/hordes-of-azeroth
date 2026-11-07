//! The read-back probe: load one addon as the survey does, drive the session start, then run
//! the caller's Lua, events, cursor moves, clicks and ticks against the VM left standing.
//! [`probe_ui`] does the same over the default interface with no addon.
//!
//! The registry and installed set are built from the whole folder, as the survey builds them:
//! against a registry of one, AceAddon and AceLibrary find no dependencies. It reads the state
//! after `PLAYER_ENTERING_WORLD` and the ticks, before the render and use probes touch the VM.
//! An eval can mutate the VM, so a probe is a debugger; the survey is the measurement.

use std::path::Path;

use benilla_ui::script::{ScriptValue, UiScript};
use benilla_ui::toc::Toc;

/// One addon, or the default interface alone, loaded and asked.
#[derive(Debug, Clone, Default)]
pub struct ProbeOutcome {
    pub name: String,
    /// Load-time failures, verbatim, as [`super::AddonReport::errors`] carries them.
    pub load_errors: Vec<String>,
    /// What its handlers raised while the session start was driven.
    pub session_errors: Vec<String>,
    /// `(step, answer)` per step in order; an answer is `= …`, `ERROR: <message>` or
    /// `SYNTAX: <message>`, and a raise does not stop the steps after it.
    pub answers: Vec<(String, String)>,
}

/// Wrap a chunk in `pcall` + `tostring` so a raise comes back as a value; only the first result
/// is returned, so the wrapper needs nothing beyond Lua 5.0.
fn wrapped(chunk: &str) -> String {
    format!(
        "local __ok, __v = pcall(function() {chunk} end)\n\
         if __ok then return \"= \" .. tostring(__v) else return \"ERROR: \" .. tostring(__v) end"
    )
}

/// One step of a probe run. Much addon state is hover-driven, so moves interleave with reads.
#[derive(Debug, Clone)]
pub enum Step {
    /// Lua to evaluate against the VM as it stands.
    Eval(String),
    /// Move the cursor to `(x, y)` in UI units (y-up from the bottom-left), firing the real
    /// `OnLeave`/`OnEnter` pair as [`UiScript::mouse_move`] does for the app; the answer is the
    /// frame under it and what the pair raised.
    Mouse(f32, f32),
    /// Advance one `OnUpdate` frame of `secs`; the answer is what the tick raised, or `no errors`.
    Tick(f32),
    /// Fire an engine event with its arguments, typed by [`event_arg`]; the answer is what the
    /// handlers raised.
    Event(String, Vec<String>),
    /// Move to `(x, y)`, then press and release `button` (`"LeftButton"`, …) there, as a player's
    /// click reaches [`UiScript::mouse_button`]; the answer is the frame hit and what it raised.
    Click(f32, f32, String),
}

/// One event argument from its text: a number is a number, `nil` is nil, anything else a string.
/// The 1.12 client passes counts and slots (`BAG_UPDATE`'s bag) as numbers.
pub fn event_arg(text: &str) -> ScriptValue {
    if text == "nil" {
        return ScriptValue::Nil;
    }
    // Finite only: Rust also parses `inf` and `NaN`, which are names, not numbers, here.
    match text.parse::<f64>() {
        Ok(n) if n.is_finite() => ScriptValue::Number(n),
        _ => ScriptValue::Str(text.to_string()),
    }
}

/// Load `name` out of `root` the way the survey does, drive the session start, then run each
/// [`Step`] against the VM that is left; `None` when the folder has no manifest.
pub fn probe(root: &Path, name: &str, steps: &[Step]) -> Option<ProbeOutcome> {
    let toc_path = super::manifest_path(root, name)?;
    // Decoded: a cp1252 manifest read as UTF-8 parses as an empty toc and a false clean pass.
    let toc = Toc::parse(&benilla_ui::source::decode(
        &std::fs::read(&toc_path).unwrap_or_default(),
    ));

    let (_, installed, registry) = super::corpus(root);

    let mut script = match fresh_vm() {
        Ok(s) => s,
        Err(e) => {
            return Some(ProbeOutcome {
                name: name.to_string(),
                load_errors: vec![format!("VM: {e}")],
                ..Default::default()
            })
        }
    };
    // No saved-variable roots, so a probe never touches a player's saved variables; the AddOns
    // root is passed as the survey passes it, so `LoadAddOn` resolves.
    script.register_addons(registry.clone(), Some(root.to_path_buf()), None, None);
    super::seat_a_session(&mut script);
    let _ = crate::ui_script::load_default_ui(&script);

    // Marked before its dependencies load (`0x51f313`), as the survey does.
    script.mark_addon_loaded(name);
    let _ = super::load_dependencies(&script, root, &registry, &toc);

    let load_errors = super::load_addon_files(&script, root, name, &toc).errors;
    let session_errors = super::drive_session_start(&mut script, name, &installed, root, &registry);

    let answers = run_steps(&mut script, steps);

    Some(ProbeOutcome {
        name: name.to_string(),
        load_errors,
        session_errors,
        answers,
    })
}

/// The default interface alone, the core and benilla's layer with no addon, seated and entered
/// as [`probe`] does, then asked. Its load errors are the interface's own load failures.
pub fn probe_ui(steps: &[Step]) -> ProbeOutcome {
    let mut script = match fresh_vm() {
        Ok(s) => s,
        Err(e) => {
            return ProbeOutcome {
                name: "the default interface".to_string(),
                load_errors: vec![format!("VM: {e}")],
                ..Default::default()
            }
        }
    };
    super::seat_a_session(&mut script);
    let load_errors = crate::ui_script::load_default_ui(&script);

    let before = script.errors().len();
    super::enter_world(&mut script);
    let session_errors = script.errors().split_off(before);

    ProbeOutcome {
        name: "the default interface".to_string(),
        load_errors,
        session_errors,
        answers: run_steps(&mut script, steps),
    }
}

/// A VM as the survey sizes and bounds one.
fn fresh_vm() -> benilla_ui::mlua::Result<UiScript> {
    let mut script = UiScript::new()?;
    script.set_instruction_budget(super::ADDON_INSTRUCTION_BUDGET);
    // A fixed `rand` seed, so two probe runs of an addon that draws at load agree.
    script.lua().srand(1);
    script.set_screen_size(1024.0, 768.0);
    Ok(script)
}

/// Each step against the VM in order, as `(step, answer)`.
fn run_steps(script: &mut UiScript, steps: &[Step]) -> Vec<(String, String)> {
    steps
        .iter()
        .map(|step| match step {
            Step::Eval(chunk) => {
                let answer = script
                    .eval::<String>(&wrapped(chunk))
                    // Only a syntax error in the chunk reaches here; `pcall` caught any raise.
                    .unwrap_or_else(|e| format!("SYNTAX: {e}"));
                (chunk.clone(), answer)
            }
            Step::Tick(secs) => {
                let before = script.errors().len();
                script.tick(*secs);
                (format!("--tick {secs}"), raised_since(script, before, ""))
            }
            Step::Event(name, args) => {
                let line = std::iter::once(name.as_str())
                    .chain(args.iter().map(String::as_str))
                    .collect::<Vec<_>>()
                    .join(" ");
                // A name the event table lacks registers nothing (`0x702140`), so firing it would
                // answer `no errors` for a typo; the table's own spelling is what frames hold.
                let Some(event) = script.vm_kind().event_key(name) else {
                    return (
                        format!("--event {line}"),
                        format!("ERROR: 1.12 has no event {name}, so no frame can register it"),
                    );
                };
                let before = script.errors().len();
                script.fire_event(event, args.iter().map(|a| event_arg(a)).collect());
                (format!("--event {line}"), raised_since(script, before, ""))
            }
            Step::Mouse(x, y) => {
                let before = script.errors().len();
                let over = hover(script, *x, *y);
                (
                    format!("--mouse {x},{y}"),
                    raised_since(script, before, &format!("over {over}, ")),
                )
            }
            Step::Click(x, y, button) => {
                // Before the hover: its `OnLeave`/`OnEnter` are part of the click.
                let before = script.errors().len();
                let over = hover(script, *x, *y);
                script.mouse_button(*x, *y, button, true);
                script.mouse_button(*x, *y, button, false);
                (
                    format!("--click {x},{y},{button}"),
                    raised_since(script, before, &format!("clicked {over}, ")),
                )
            }
        })
        .collect()
}

/// Move the cursor to `(x, y)`, firing the real `OnLeave`/`OnEnter` pair, and name the frame
/// under it.
fn hover(script: &mut UiScript, x: f32, y: f32) -> String {
    // Resolve first: the hit-test reads resolved rects, which a new or moved frame lacks until then.
    script.resolve();
    script.mouse_move(x, y);
    script
        .hit_test_name(x, y)
        .unwrap_or_else(|| "<nothing>".into())
}

/// What the VM raised since error `before`, after `lead`: `= <lead>no errors` or
/// `= <lead>RAISED: …`.
fn raised_since(script: &UiScript, before: usize, lead: &str) -> String {
    let raised: Vec<String> = script.errors().into_iter().skip(before).collect();
    if raised.is_empty() {
        format!("= {lead}no errors")
    } else {
        format!("= {lead}RAISED: {}", raised.join(" | "))
    }
}
