use benilla_mlua::{Function, Lua, MultiValue, Result as LuaResult, Table, Value};

use crate::nameplates::SharedPlates;
use crate::snapshot::{guid_text, AuraEntry, SharedSnapshot, Snapshot};

const POSITIONAL_AURA_VALUES: usize = 15;
const AURA_STACKS_AT: usize = 2;
const AURA_SPELL_ID_AT: usize = 9;

#[derive(Clone, Copy, Debug, PartialEq)]
pub enum AuraFilter {
    Helpful,
    Harmful,
    Any,
}

impl AuraFilter {
    pub fn parse(text: Option<&str>) -> Self {
        let text = text.unwrap_or("").to_ascii_uppercase();
        match (text.contains("HELPFUL"), text.contains("HARMFUL")) {
            (true, false) => AuraFilter::Helpful,
            (false, true) => AuraFilter::Harmful,
            _ => AuraFilter::Any,
        }
    }

    fn admits(self, aura: &AuraEntry) -> bool {
        match self {
            AuraFilter::Helpful => !aura.harmful,
            AuraFilter::Harmful => aura.harmful,
            AuraFilter::Any => true,
        }
    }
}

pub fn aura_slot_id(aura: &AuraEntry) -> u32 {
    u32::from(aura.slot) + 1
}

pub fn matching_slots(auras: &[AuraEntry], filter: AuraFilter) -> Vec<u32> {
    auras
        .iter()
        .filter(|aura| filter.admits(aura))
        .map(aura_slot_id)
        .collect()
}

pub fn parse_guid_text(text: &str) -> Option<u64> {
    let digits = text
        .strip_prefix("0x")
        .or_else(|| text.strip_prefix("0X"))?;
    u64::from_str_radix(digits, 16).ok()
}

fn token_guid(snapshot: &Snapshot, plates: &SharedPlates, token: &str) -> Option<u64> {
    let guid = if token.eq_ignore_ascii_case("player") {
        snapshot.player_guid
    } else if token.eq_ignore_ascii_case("target") {
        snapshot.target_guid
    } else {
        plates.0.borrow().guid_of(token)?
    };
    (guid != 0).then_some(guid)
}

pub fn register_unit_api(
    lua: &Lua,
    snapshot: &SharedSnapshot,
    plates: &SharedPlates,
) -> LuaResult<()> {
    let globals = lua.globals();
    globals.set(
        "UnitGUID",
        unit_guid(lua, snapshot.clone(), plates.clone())?,
    )?;
    globals.set(
        "UnitTokenFromGUID",
        unit_token_from_guid(lua, snapshot.clone(), plates.clone())?,
    )?;
    let name_plates = table_named(lua, "C_NamePlate")?;
    name_plates.set(
        "GetNamePlateForUnit",
        plate_for_unit(lua, snapshot.clone(), plates.clone())?,
    )?;
    name_plates.set("GetNamePlates", all_plates(lua, plates.clone())?)?;
    let auras = table_named(lua, "C_UnitAuras")?;
    auras.set(
        "GetAuraSlots",
        aura_slots(lua, snapshot.clone(), plates.clone())?,
    )?;
    auras.set(
        "UnitAuraBySlot",
        aura_by_slot(lua, snapshot.clone(), plates.clone())?,
    )?;
    Ok(())
}

fn table_named(lua: &Lua, name: &str) -> LuaResult<Table> {
    let globals = lua.globals();
    if let Some(table) = globals.get::<Option<Table>>(name)? {
        return Ok(table);
    }
    let table = lua.create_table()?;
    globals.set(name, table.clone())?;
    Ok(table)
}

fn unit_guid(lua: &Lua, snapshot: SharedSnapshot, plates: SharedPlates) -> LuaResult<Function> {
    lua.create_function(move |_, token: Option<String>| {
        let guid = token.and_then(|t| token_guid(&snapshot.0.borrow(), &plates, &t));
        Ok(guid.map(guid_text))
    })
}

fn unit_token_from_guid(
    lua: &Lua,
    snapshot: SharedSnapshot,
    plates: SharedPlates,
) -> LuaResult<Function> {
    lua.create_function(move |_, text: Option<String>| {
        let Some(guid) = text.as_deref().and_then(parse_guid_text) else {
            return Ok(None);
        };
        let view = snapshot.0.borrow();
        if guid == view.player_guid {
            return Ok(Some("player".to_string()));
        }
        if let Some(token) = plates.0.borrow().token_of(guid) {
            return Ok(Some(token));
        }
        Ok((guid == view.target_guid).then(|| "target".to_string()))
    })
}

fn plate_for_unit(
    lua: &Lua,
    snapshot: SharedSnapshot,
    plates: SharedPlates,
) -> LuaResult<Function> {
    lua.create_function(move |_, token: Option<String>| {
        let guid = token.and_then(|t| token_guid(&snapshot.0.borrow(), &plates, &t));
        Ok(guid.and_then(|g| plates.0.borrow().frame_of(g)))
    })
}

fn all_plates(lua: &Lua, plates: SharedPlates) -> LuaResult<Function> {
    lua.create_function(move |lua, ()| {
        let list = lua.create_table()?;
        for (index, frame) in plates.0.borrow().frames().enumerate() {
            list.set(index + 1, frame.clone())?;
        }
        Ok(list)
    })
}

type AuraSlotsArgs = (
    Option<String>,
    Option<String>,
    Option<f64>,
    Option<f64>,
    Option<Table>,
);

fn aura_slots(lua: &Lua, snapshot: SharedSnapshot, plates: SharedPlates) -> LuaResult<Function> {
    lua.create_function(
        move |lua, (token, filter, max, _continuation, out): AuraSlotsArgs| {
            let view = snapshot.0.borrow();
            let auras = token
                .and_then(|t| token_guid(&view, &plates, &t))
                .and_then(|guid| view.auras.get(&guid));
            let mut slots = auras.map_or_else(Vec::new, |a| {
                matching_slots(a, AuraFilter::parse(filter.as_deref()))
            });
            if let Some(max) = max.filter(|m| *m > 0.0) {
                slots.truncate(max as usize);
            }
            let Some(out) = out else {
                let mut values = vec![Value::Nil];
                values.extend(slots.iter().map(|slot| Value::Number(f64::from(*slot))));
                return Ok(MultiValue::from_vec(values));
            };
            let previous = out.raw_len();
            for (index, slot) in slots.iter().enumerate() {
                out.raw_set(index + 1, f64::from(*slot))?;
            }
            for stale in slots.len() + 1..=previous {
                out.raw_set(stale, Value::Nil)?;
            }
            out.raw_set("n", slots.len() as f64)?;
            lua.pack_multi((Value::Nil, slots.len() as f64))
        },
    )
}

fn aura_by_slot(lua: &Lua, snapshot: SharedSnapshot, plates: SharedPlates) -> LuaResult<Function> {
    lua.create_function(move |_, (token, slot): (Option<String>, Option<f64>)| {
        let view = snapshot.0.borrow();
        let aura = token
            .and_then(|t| token_guid(&view, &plates, &t))
            .and_then(|guid| view.auras.get(&guid))
            .and_then(|auras| {
                let slot = slot? as u32;
                auras.iter().find(|aura| aura_slot_id(aura) == slot)
            });
        let Some(aura) = aura else {
            return Ok(MultiValue::from_vec(vec![Value::Nil]));
        };
        let mut values = vec![Value::Nil; POSITIONAL_AURA_VALUES];
        values[AURA_STACKS_AT] = Value::Number(f64::from(aura.stacks));
        values[AURA_SPELL_ID_AT] = Value::Number(f64::from(aura.spell_id));
        Ok(MultiValue::from_vec(values))
    })
}

#[cfg(test)]
mod tests {
    use super::*;

    fn aura(slot: u8, harmful: bool) -> AuraEntry {
        AuraEntry {
            slot,
            spell_id: 700 + u32::from(slot),
            stacks: 1,
            harmful,
        }
    }

    #[test]
    fn filters_split_buffs_from_debuffs() {
        let auras = [aura(0, false), aura(32, true), aura(33, true)];
        assert_eq!(
            matching_slots(&auras, AuraFilter::parse(Some("HARMFUL"))),
            vec![33, 34]
        );
        assert_eq!(
            matching_slots(&auras, AuraFilter::parse(Some("helpful"))),
            vec![1]
        );
        assert_eq!(matching_slots(&auras, AuraFilter::parse(None)).len(), 3);
    }

    #[test]
    fn guid_text_round_trips() {
        let guid = 0xF130_0000_4D00_0123;
        assert_eq!(guid_text(guid), "0xF13000004D000123");
        assert_eq!(parse_guid_text(&guid_text(guid)), Some(guid));
        assert_eq!(parse_guid_text("nameplate1"), None);
    }
}
