//! The client's own UI language packs.
//!
//! The packs are generated from `shared/i18n/ui` by `tools/i18n/gen_client_pack.py` and compiled
//! into the binary as `assets/i18n/<locale>.json`. The install's `Wow.ini` locale still selects
//! DBC columns and resources; `UiLanguage` is the account/launcher language that `GetLocale` and
//! the shipped XML read.

use std::collections::BTreeMap;
use std::sync::LazyLock;

use benilla_formats::Locale;
use benilla_ui::script::UiScript;
use bevy::prelude::*;
use include_dir::{include_dir, Dir};
use serde::Deserialize;

use benilla_assets::LockRecover;

use crate::cvars::{hoa_language, Cvars};

static PACKS_DIR: Dir<'_> = include_dir!("$CARGO_MANIFEST_DIR/assets/i18n");

const FALLBACK: &str = "enUS";
const SUPPORTED: [&str; 3] = ["enUS", "zhCN", "zhTW"];

#[derive(Debug, Deserialize)]
struct PackFile {
    version: u32,
    locale: String,
    #[serde(default)]
    messages: BTreeMap<String, String>,
    #[serde(default, rename = "fallbackMessages")]
    fallback_messages: BTreeMap<String, String>,
    #[serde(default)]
    globals: BTreeMap<String, String>,
    #[serde(default)]
    aliases: BTreeMap<String, String>,
}

#[derive(Debug, Clone)]
pub(crate) struct LanguagePack {
    pub(crate) locale: String,
    pub(crate) messages: BTreeMap<String, String>,
    pub(crate) fallback_messages: BTreeMap<String, String>,
    pub(crate) globals: BTreeMap<String, String>,
    pub(crate) aliases: BTreeMap<String, String>,
}

impl LanguagePack {
    fn empty(locale: &str) -> Self {
        Self {
            locale: locale.to_string(),
            messages: BTreeMap::new(),
            fallback_messages: BTreeMap::new(),
            globals: BTreeMap::new(),
            aliases: BTreeMap::new(),
        }
    }

    fn text(&self, key: &str) -> Option<&str> {
        self.messages
            .get(key)
            .or_else(|| self.fallback_messages.get(key))
            .map(String::as_str)
    }
}

struct Packs {
    packs: BTreeMap<String, LanguagePack>,
}

impl Packs {
    fn load() -> Self {
        let mut packs = BTreeMap::new();
        let mut files = Vec::new();

        if let Some(root) = crate::run_mode::dev_source_dir().map(|d| d.join("assets/i18n")) {
            if let Ok(entries) = std::fs::read_dir(&root) {
                for entry in entries.flatten() {
                    let path = entry.path();
                    if path.extension().and_then(|e| e.to_str()) == Some("json") {
                        if let Ok(bytes) = std::fs::read(&path) {
                            files.push(bytes);
                        }
                    }
                }
            }
        }
        if files.is_empty() {
            for file in PACKS_DIR.files() {
                if file.path().extension().and_then(|e| e.to_str()) == Some("json") {
                    if let Some(bytes) = file.contents_utf8() {
                        files.push(bytes.as_bytes().to_vec());
                    }
                }
            }
        }

        for bytes in files {
            match serde_json::from_slice::<PackFile>(&bytes) {
                Ok(file) if file.version == 1 => {
                    let locale = file.locale.clone();
                    if packs.contains_key(&locale) {
                        warn!("client_language: duplicate pack for {locale}");
                        continue;
                    }
                    packs.insert(
                        locale.clone(),
                        LanguagePack {
                            locale,
                            messages: file.messages,
                            fallback_messages: file.fallback_messages,
                            globals: file.globals,
                            aliases: file.aliases,
                        },
                    );
                }
                Ok(file) => warn!(
                    "client_language: unsupported pack version {} for {}",
                    file.version, file.locale
                ),
                Err(e) => warn!("client_language: cannot parse a language pack: {e}"),
            }
        }

        if !packs.contains_key(FALLBACK) {
            warn!("client_language: {FALLBACK} pack missing; UI text will read message ids");
        }
        Self { packs }
    }

    fn get(&self, locale: &str) -> &LanguagePack {
        static EMPTY: LazyLock<LanguagePack> = LazyLock::new(|| LanguagePack::empty(FALLBACK));
        self.packs
            .get(locale)
            .or_else(|| self.packs.get(FALLBACK))
            .unwrap_or(&EMPTY)
    }
}

static PACKS: LazyLock<Packs> = LazyLock::new(Packs::load);

/// The account/launcher language the client's own UI and `GetLocale` use.
#[derive(Resource, Debug, Clone)]
pub(crate) struct UiLanguage {
    pub(crate) selected: String,
}

impl Default for UiLanguage {
    fn default() -> Self {
        Self {
            selected: FALLBACK.to_string(),
        }
    }
}

impl UiLanguage {
    /// The BCP-47 tag cosmic-text shapes with.
    pub(crate) fn shaping_locale(&self) -> &'static str {
        match self.selected.as_str() {
            "zhCN" => "zh-CN",
            "zhTW" => "zh-TW",
            _ => "en-US",
        }
    }

    /// The supported code, or enUS for an unknown one.
    pub(crate) fn normalize(code: &str) -> String {
        SUPPORTED
            .iter()
            .find(|supported| supported.eq_ignore_ascii_case(code.trim()))
            .map(|supported| (*supported).to_string())
            .unwrap_or_else(|| {
                warn!("client_language: unsupported language {code:?}; using {FALLBACK}");
                FALLBACK.to_string()
            })
    }
}

pub(crate) fn locale_for_code(code: &str) -> Locale {
    Locale::from_language_country(&code.as_bytes()[..2], &code.as_bytes()[2..])
}

/// Startup: seed the UI language from the launcher/last CVar, before the glue VM is built.
pub(crate) fn load_ui_language(mut language: ResMut<UiLanguage>, cvars: Option<Res<Cvars>>) {
    let code = cvars
        .as_deref()
        .map(hoa_language)
        .or_else(|| Some(crate::ui_script::client_locale().name().to_string()))
        .unwrap_or_else(|| FALLBACK.to_string());
    language.selected = UiLanguage::normalize(&code);
}

pub(crate) fn language_for(world: &World) -> String {
    if let Some(language) = world.get_resource::<UiLanguage>() {
        return language.selected.clone();
    }
    if let Some(cvars) = world.get_resource::<Cvars>() {
        return UiLanguage::normalize(&hoa_language(cvars));
    }
    crate::ui_script::client_locale().name().to_string()
}

/// Point the patch chain at `benilla-config/locale/<language>/` when a stock pack is installed:
/// its `GlobalStrings.lua` and `DBFilesClient` then replace the install's, and DBC columns read
/// the pack's language.
pub(crate) fn apply_language_assets(world: &mut World) {
    let code = language_for(world);
    let folder = crate::config_dir()
        .map(|dir| dir.join("locale").join(&code))
        .filter(|dir| dir.is_dir());
    if let Some(dir) = &folder {
        info!(
            "client_language: stock language data {code} at {}",
            dir.display()
        );
    }
    let locale = locale_for_code(&code);
    let Some(assets) = world.get_resource::<benilla_assets::WorldAssets>() else {
        return;
    };
    let overlay_locale = folder.as_ref().map(|_| locale);
    assets
        .chain
        .lock_recover()
        .set_language_overlay(overlay_locale, folder);
}

/// Put the selected pack into one VM: the text tables, the generated globals, and
/// `HOA_UI_TEXT(idOrEnglish, ...)`.
pub(crate) fn install_for_script(script: &UiScript) {
    let index = script.ui_locale().unwrap_or_else(|| script.locale());
    let code = Locale::from_index(index)
        .map(Locale::name)
        .unwrap_or(FALLBACK);
    let pack = PACKS.get(code);
    if pack.locale == FALLBACK && code != FALLBACK {
        warn!("client_language: no {code} pack; falling back to {FALLBACK}");
    }

    let already = script
        .lua()
        .globals()
        .get::<String>("HOA_UI_LOCALE")
        .ok()
        .as_deref()
        == Some(pack.locale.as_str());
    if already {
        refresh_globals(script);
        return;
    }

    let lua = script.lua();
    let text_table = match lua.create_table() {
        Ok(table) => table,
        Err(e) => {
            warn!("client_language: cannot create text table: {e}");
            return;
        }
    };
    for (id, text) in &pack.messages {
        if let Err(e) = text_table.set(id.as_str(), text.as_str()) {
            warn!("client_language: cannot set message {id}: {e}");
        }
    }
    let fallback_table = match lua.create_table() {
        Ok(table) => table,
        Err(e) => {
            warn!("client_language: cannot create fallback table: {e}");
            return;
        }
    };
    for (id, text) in &pack.fallback_messages {
        if let Err(e) = fallback_table.set(id.as_str(), text.as_str()) {
            warn!("client_language: cannot set fallback {id}: {e}");
        }
    }
    let alias_table = match lua.create_table() {
        Ok(table) => table,
        Err(e) => {
            warn!("client_language: cannot create alias table: {e}");
            return;
        }
    };
    for (english, id) in &pack.aliases {
        if let Err(e) = alias_table.set(english.as_str(), id.as_str()) {
            warn!("client_language: cannot set alias {english:?}: {e}");
        }
    }

    let text_lookup = text_table.clone();
    let fallback_lookup = fallback_table.clone();
    let alias_lookup = alias_table.clone();
    let translate = match lua.create_function(
        move |lua, (key, values): (String, benilla_ui::mlua::Variadic<benilla_ui::mlua::Value>)| {
            let id = alias_lookup
                .get::<Option<String>>(key.as_str())?
                .unwrap_or(key);
            let mut text = text_lookup
                .get::<Option<String>>(id.as_str())?
                .or(fallback_lookup.get::<Option<String>>(id.as_str())?)
                .unwrap_or(id);
            for (index, value) in values.into_iter().enumerate() {
                let value = lua
                    .coerce_string(value)?
                    .map(|value| value.to_string_lossy())
                    .unwrap_or_default();
                text = text.replace(&format!("{{{}}}", index + 1), &value);
            }
            Ok(text)
        },
    ) {
        Ok(function) => function,
        Err(e) => {
            warn!("client_language: cannot create HOA_UI_TEXT: {e}");
            return;
        }
    };

    let globals = lua.globals();
    if let Err(e) = globals.set("HOA_UI_TEXT_TABLE", text_table) {
        warn!("client_language: cannot set HOA_UI_TEXT_TABLE: {e}");
    }
    if let Err(e) = globals.set("HOA_UI_FALLBACK_TABLE", fallback_table) {
        warn!("client_language: cannot set HOA_UI_FALLBACK_TABLE: {e}");
    }
    if let Err(e) = globals.set("HOA_UI_ALIASES", alias_table) {
        warn!("client_language: cannot set HOA_UI_ALIASES: {e}");
    }
    if let Err(e) = globals.set("HOA_UI_TEXT", translate) {
        warn!("client_language: cannot set HOA_UI_TEXT: {e}");
    }
    if let Err(e) = globals.set("HOA_UI_LOCALE", pack.locale.as_str()) {
        warn!("client_language: cannot set HOA_UI_LOCALE: {e}");
    }
    refresh_globals(script);
}

/// Re-apply the pack's global values, including stock names such as `BINDING_NAME_*` that the
/// core's `GlobalStrings.lua` writes after `new_vm` has seated the pack.
pub(crate) fn refresh_globals(script: &UiScript) {
    let index = script.ui_locale().unwrap_or_else(|| script.locale());
    let code = Locale::from_index(index)
        .map(Locale::name)
        .unwrap_or(FALLBACK);
    let pack = PACKS.get(code);
    let globals = script.lua().globals();
    for (name, id) in &pack.globals {
        let text = pack.text(id).unwrap_or(id);
        if let Err(e) = globals.set(name.as_str(), text) {
            warn!("client_language: cannot set {name}: {e}");
        }
    }
}

/// The server's account language, after login. A change updates the current VM immediately and
/// queues one `ReloadUI` for the frames that already read the old text.
pub fn set_hoa_account_language(world: &mut World, code: &str) -> bool {
    let code = UiLanguage::normalize(code);
    if language_for(world) == code {
        return false;
    }

    match world.get_resource_mut::<UiLanguage>() {
        Some(mut language) => language.selected = code.clone(),
        None => {
            world.insert_resource(UiLanguage {
                selected: code.clone(),
            });
        }
    }

    if let Some(mut script) = world.get_non_send_resource_mut::<UiScript>() {
        let locale = locale_for_code(&code);
        script.set_ui_locale(Some(locale.index()));
        install_for_script(&script);
    }

    if world
        .get_resource::<crate::ui_script::ReloadUiPending>()
        .is_some()
    {
        world.resource_mut::<crate::ui_script::ReloadUiPending>().0 = true;
    }
    apply_language_assets(world);
    true
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn supported_codes_normalize_and_unknown_codes_fall_back() {
        assert_eq!(UiLanguage::normalize("enUS"), "enUS");
        assert_eq!(UiLanguage::normalize("zhcn"), "zhCN");
        assert_eq!(UiLanguage::normalize("zhtw"), "zhTW");
        assert_eq!(UiLanguage::normalize("frFR"), "enUS");
        assert_eq!(UiLanguage::normalize(""), "enUS");
    }

    #[test]
    fn packs_have_both_languages_and_the_expected_global() {
        for locale in SUPPORTED {
            let pack = PACKS.get(locale);
            assert_eq!(pack.locale, locale);
            assert!(!pack.messages.is_empty(), "{locale}");
            assert!(
                pack.globals.contains_key("HOA_UI_OPTIONS_TITLE"),
                "{locale}"
            );
            assert_eq!(
                pack.text("hoa.ui.options.title"),
                Some(match locale {
                    "zhCN" => "选项",
                    "zhTW" => "選項",
                    _ => "Options",
                })
            );
        }
    }

    #[test]
    fn an_unknown_pack_falls_back_to_english() {
        let pack = PACKS.get("frFR");
        assert_eq!(pack.locale, FALLBACK);
        assert_eq!(pack.text("hoa.ui.options.title"), Some("Options"));
    }

    #[test]
    fn install_seats_globals_and_the_text_function() {
        for (locale, title) in [("enUS", "Options"), ("zhCN", "选项"), ("zhTW", "選項")] {
            let mut script = UiScript::new().expect("VM");
            script.set_ui_locale(Some(locale_for_code(locale).index()));
            install_for_script(&script);
            assert_eq!(
                script
                    .eval::<String>("return HOA_UI_OPTIONS_TITLE")
                    .unwrap(),
                title
            );
            assert_eq!(
                script
                    .eval::<String>("return HOA_UI_TEXT('hoa.ui.options.title')")
                    .unwrap(),
                title
            );
            assert_eq!(script.eval::<String>("return GetLocale()").unwrap(), locale);
        }
    }

    #[test]
    fn the_account_language_updates_the_resource_and_queues_one_reload() {
        let mut world = World::new();
        world.insert_resource(UiLanguage::default());
        world.insert_resource(crate::ui_script::ReloadUiPending(false));

        let script = UiScript::new().expect("VM");
        install_for_script(&script);
        world.insert_non_send_resource(script);

        assert!(set_hoa_account_language(&mut world, "zhCN"));
        assert_eq!(world.resource::<UiLanguage>().selected, "zhCN");
        assert!(world.resource::<crate::ui_script::ReloadUiPending>().0);
        assert_eq!(
            world
                .get_non_send_resource::<UiScript>()
                .unwrap()
                .eval::<String>("return GetLocale()")
                .unwrap(),
            "zhCN"
        );

        world.resource_mut::<crate::ui_script::ReloadUiPending>().0 = false;
        assert!(!set_hoa_account_language(&mut world, "zhCN"));
        assert!(!world.resource::<crate::ui_script::ReloadUiPending>().0);

        assert!(set_hoa_account_language(&mut world, "enUS"));
        assert_eq!(world.resource::<UiLanguage>().selected, "enUS");
    }

    #[test]
    fn an_unknown_account_language_falls_back_to_english() {
        let mut world = World::new();
        world.insert_resource(UiLanguage::default());
        assert!(!set_hoa_account_language(&mut world, "frFR"));
        assert_eq!(world.resource::<UiLanguage>().selected, "enUS");
    }
}
