//! The server-pushed custom aura catalog.
//!
//! Names, icons and descriptions arrive already localized in the account language, so this
//! module never inspects a locale. It only turns the rows into `SpellDisplay`s for the spell
//! catalog overlay.

use std::collections::HashMap;

use bevy::prelude::*;
use benilla_formats::{SpellCatalog, SpellDisplay};

/// One row of `aura_catalog_entry`.
#[derive(Clone, Debug)]
pub struct HoaAuraRow {
    pub id: u32,
    pub name: String,
    pub icon: String,
    pub description: String,
    pub stack_amount: u32,
    pub duration_index: u32,
}

/// Set when the overlay changed, so the aura feed repaints the frame after the swap.
#[derive(Resource, Default)]
pub(crate) struct HoaCatalogChanged(pub bool);

/// The last server-sent value text per aura, reapplied after the catalog is replaced.
#[derive(Resource, Default)]
pub(crate) struct HoaValueTexts(pub HashMap<u32, String>);

fn display(row: &HoaAuraRow, base: Option<&SpellDisplay>) -> SpellDisplay {
    let mut display = base.cloned().unwrap_or_default();
    display.id = row.id;
    if !row.name.is_empty() {
        display.name = row.name.clone();
    }
    if !row.icon.is_empty() {
        display.icon = Some(row.icon.clone());
    }
    if !row.description.is_empty() {
        display.description = Some(row.description.clone());
        display.aura_description = Some(row.description.clone());
    }
    display.stack_amount = row.stack_amount;
    display.duration_index = row.duration_index;
    display
}

fn overlay(rows: &[HoaAuraRow], catalog: &SpellCatalog) -> HashMap<u32, SpellDisplay> {
    rows.iter()
        .map(|row| (row.id, display(row, catalog.dbc(row.id))))
        .collect()
}

/// Replaces the custom spell overlay with the server's catalog. False when the spell catalog
/// does not exist yet (the world is still loading); the caller retries.
pub fn set_hoa_aura_catalog(world: &mut World, rows: &[HoaAuraRow]) -> bool {
    let value_texts = world
        .get_resource::<HoaValueTexts>()
        .map(|texts| texts.0.clone())
        .unwrap_or_default();
    let Some(mut spells) = world.get_resource_mut::<crate::ui_action::Spells>() else {
        return false;
    };
    let overlay = overlay(rows, &spells.catalog);
    spells.catalog.set_overlay(overlay);
    for (id, text) in value_texts {
        spells.catalog.set_overlay_description(id, text);
    }
    if let Some(mut changed) = world.get_resource_mut::<HoaCatalogChanged>() {
        changed.0 = true;
    }
    true
}

#[cfg(test)]
mod tests {
    use super::*;
    use benilla_formats::SpellCatalog;

    fn row(id: u32) -> HoaAuraRow {
        HoaAuraRow {
            id,
            name: format!("aura {id}"),
            icon: "Interface\\Icons\\Spell_Holy_DevotionAura".to_string(),
            description: "description".to_string(),
            stack_amount: 3,
            duration_index: 28,
        }
    }

    #[test]
    fn rows_become_catalog_displays() {
        let base = SpellCatalog::from_displays(HashMap::new());
        let rows = [row(60001)];
        let catalog = SpellCatalog::from_displays(HashMap::new()).with_overlay(overlay(&rows, &base));
        let display = catalog.get(60001).expect("custom spell");
        assert_eq!(display.name, "aura 60001");
        assert_eq!(display.stack_amount, 3);
        assert_eq!(display.duration_index, 28);
        assert_eq!(display.aura_description.as_deref(), Some("description"));
    }
}
