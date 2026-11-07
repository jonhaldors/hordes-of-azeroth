//! Tests for the read-back probe: it reads after the session start, in the corpus's VM.

use std::path::{Path, PathBuf};

use benilla_ui::script::ScriptValue;

use super::probe::{event_arg, probe, probe_ui, Step};

/// One throwaway AddOns root, cleaned up on drop even if a test panics.
struct Fixtures(PathBuf);

impl Fixtures {
    fn new(tag: &str) -> Self {
        let root = std::env::temp_dir().join(format!(
            "benilla-probe-{tag}-{}-{:?}",
            std::process::id(),
            std::thread::current().id()
        ));
        let _ = std::fs::remove_dir_all(&root);
        std::fs::create_dir_all(&root).unwrap();
        Self(root)
    }

    fn addon(&self, name: &str, body: &str) -> &Self {
        let dir = self.0.join(name);
        std::fs::create_dir_all(&dir).unwrap();
        std::fs::write(
            dir.join(format!("{name}.toc")),
            "## Interface: 11200\nbody.lua\n",
        )
        .unwrap();
        std::fs::write(dir.join("body.lua"), body).unwrap();
        self
    }

    fn root(&self) -> &Path {
        &self.0
    }
}

impl Drop for Fixtures {
    fn drop(&mut self) {
        let _ = std::fs::remove_dir_all(&self.0);
    }
}

/// A file-scope global and a `PLAYER_LOGIN` global are both readable, and a raise comes back as
/// `ERROR:` without stopping the next eval.
#[test]
fn the_probe_reads_the_vm_after_the_session_start() {
    let fx = Fixtures::new("after");
    fx.addon(
        "Talker",
        r#"
        TalkerFileScope = "loaded"
        local f = CreateFrame("Frame")
        f:RegisterEvent("PLAYER_LOGIN")
        f:SetScript("OnEvent", function() TalkerAtLogin = "logged in" end)
    "#,
    );

    let out = probe(
        fx.root(),
        "Talker",
        &[
            Step::Eval("return TalkerFileScope".to_string()),
            Step::Eval("return TalkerAtLogin".to_string()),
            Step::Eval("return nil + 1".to_string()),
            Step::Eval("return TalkerFileScope".to_string()),
        ],
    )
    .expect("the fixture has a manifest");

    assert!(out.load_errors.is_empty(), "{:?}", out.load_errors);
    assert!(out.session_errors.is_empty(), "{:?}", out.session_errors);
    let answers: Vec<&str> = out.answers.iter().map(|(_, a)| a.as_str()).collect();
    assert_eq!(answers[0], "= loaded", "the file scope ran");
    assert_eq!(
        answers[1], "= logged in",
        "the PLAYER_LOGIN handler ran BEFORE the read — a load-only probe would answer nil"
    );
    assert!(
        answers[2].starts_with("ERROR:"),
        "a raise is reported, not propagated: {}",
        answers[2]
    );
    assert_eq!(
        answers[3], "= loaded",
        "...and the eval after a raise still ran"
    );
}

/// The registry is the whole folder's: a sibling that is never loaded is still installed.
#[test]
fn the_probe_sees_the_whole_folder_installed() {
    let fx = Fixtures::new("registry");
    fx.addon("Asker", "AskerSaw = GetAddOnInfo(\"Sibling\")\n");
    fx.addon("Sibling", "SiblingRan = 1\n");

    let out = probe(
        fx.root(),
        "Asker",
        &[
            Step::Eval("return AskerSaw".to_string()),
            Step::Eval("return GetNumAddOns()".to_string()),
            Step::Eval("return SiblingRan".to_string()),
        ],
    )
    .expect("the fixture has a manifest");

    assert!(out.load_errors.is_empty(), "{:?}", out.load_errors);
    assert_eq!(
        out.answers[0].1, "= Sibling",
        "the sibling must be INSTALLED in the probed VM"
    );
    assert_eq!(
        out.answers[1].1, "= 2",
        "the registry is the folder's, not the selection's"
    );
    // Installed is not loaded: one addon per VM, as in the survey.
    assert_eq!(
        out.answers[2].1, "= nil",
        "an installed sibling must NOT have been run"
    );
}

/// A folder with no manifest is `None`, not an empty outcome.
#[test]
fn a_folder_without_a_manifest_is_refused() {
    let fx = Fixtures::new("nomanifest");
    std::fs::create_dir_all(fx.root().join("Backup")).unwrap();
    assert!(probe(fx.root(), "Backup", &[]).is_none());
    assert!(probe(fx.root(), "NotThereAtAll", &[]).is_none());
}

/// An event step reaches a registered handler with its arguments typed, and a click step reaches
/// a button's `OnClick` through the hit-test.
#[test]
fn the_probe_fires_events_and_clicks() {
    let fx = Fixtures::new("actuate");
    fx.addon(
        "Actor",
        r#"
        local f = CreateFrame("Frame")
        f:RegisterEvent("BAG_UPDATE")
        f:SetScript("OnEvent", function() ActorGot = type(arg1) .. ":" .. tostring(arg1) .. "," .. tostring(arg2) end)
        local b = CreateFrame("Button", "ActorButton", UIParent)
        b:SetFrameStrata("TOOLTIP")
        b:SetWidth(40)
        b:SetHeight(40)
        b:SetPoint("CENTER", UIParent, "CENTER")
        b:EnableMouse(true)
        b:SetScript("OnClick", function() ActorClicked = arg1 end)
        local h = CreateFrame("Button", "ActorHot", UIParent)
        h:SetFrameStrata("TOOLTIP")
        h:SetWidth(40)
        h:SetHeight(40)
        h:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", 100, 300)
        h:EnableMouse(true)
        h:SetScript("OnEnter", function() error("hot to touch") end)
    "#,
    );

    let out = probe(
        fx.root(),
        "Actor",
        &[
            Step::Event("bag_update".into(), vec!["3".into(), "player".into()]),
            Step::Event("ACTOR_PING".into(), Vec::new()),
            Step::Eval("return ActorGot".into()),
            Step::Click(512.0, 384.0, "LeftButton".into()),
            Step::Eval("return ActorClicked".into()),
            Step::Click(120.0, 320.0, "LeftButton".into()),
            Step::Mouse(10.0, 700.0),
            Step::Mouse(120.0, 320.0),
        ],
    )
    .expect("the fixture has a manifest");

    assert!(out.load_errors.is_empty(), "{:?}", out.load_errors);
    let answers: Vec<&str> = out.answers.iter().map(|(_, a)| a.as_str()).collect();
    assert_eq!(answers[0], "= no errors", "the name is matched case folded");
    assert!(
        answers[1].starts_with("ERROR: 1.12 has no event ACTOR_PING"),
        "a name no frame can register is refused, not answered `no errors`: {}",
        answers[1]
    );
    assert_eq!(
        answers[2], "= number:3,player",
        "the arguments arrive typed"
    );
    assert_eq!(answers[3], "= clicked ActorButton, no errors");
    assert_eq!(answers[4], "= LeftButton", "OnClick ran with the button");
    for (i, step) in [(5, "click"), (7, "mouse")] {
        assert!(
            answers[i].starts_with("= ")
                && answers[i].contains("ActorHot, RAISED:")
                && answers[i].contains("hot to touch"),
            "a {step} answers what the hover's OnEnter raised: {}",
            answers[i]
        );
    }
}

/// The default interface loads the stock frames, clean.
#[test]
fn the_default_interface_probe_loads_the_stock_frames() {
    benilla_formats::wow_data_or_skip!();
    let out = probe_ui(&[Step::Eval("return MainMenuBar:IsVisible()".into())]);
    assert_eq!(out.answers[0].1, "= 1", "{:#?}", out.load_errors);
    assert!(out.load_errors.is_empty(), "{:#?}", out.load_errors);
    assert!(out.session_errors.is_empty(), "{:#?}", out.session_errors);
}

/// The default interface is probed with no addon folder at all.
#[test]
fn the_default_interface_is_probed_without_an_addon() {
    let out = probe_ui(&[Step::Eval("return UnitName('player')".into())]);
    assert_eq!(out.answers[0].1, "= Harness", "the session is seated");
}

/// Numbers are numbers, `nil` is nil, and a name that Rust would parse as a float stays a string.
#[test]
fn event_arguments_are_typed_from_their_text() {
    assert!(matches!(event_arg("3"), ScriptValue::Number(n) if n == 3.0));
    assert!(matches!(event_arg("-1.5"), ScriptValue::Number(n) if n == -1.5));
    assert!(matches!(event_arg("nil"), ScriptValue::Nil));
    for name in ["player", "inf", "NaN", ""] {
        assert!(
            matches!(event_arg(name), ScriptValue::Str(ref s) if s == name),
            "{name:?} must stay a string"
        );
    }
}
