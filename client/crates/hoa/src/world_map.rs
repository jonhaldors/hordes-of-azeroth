use std::rc::Rc;

use benilla_formats::{load_world_map_area_catalog, wow_data, Chain, WorldMapArea};
use bevy::log::warn;

#[derive(Clone, Debug, PartialEq)]
pub struct MapArea {
    pub map_id: u32,
    pub area_id: u32,
    pub name: String,
    pub left: f64,
    pub right: f64,
    pub top: f64,
    pub bottom: f64,
}

impl MapArea {
    fn from_row(row: &WorldMapArea) -> Self {
        Self {
            map_id: row.map_id,
            area_id: row.area_id,
            name: row.name.clone(),
            left: f64::from(row.loc_left),
            right: f64::from(row.loc_right),
            top: f64::from(row.loc_top),
            bottom: f64::from(row.loc_bottom),
        }
    }

    pub fn fraction_of(&self, north: f64, west: f64) -> Option<(f64, f64)> {
        let span_west = self.left - self.right;
        let span_north = self.top - self.bottom;
        if span_west <= 0.0 || span_north <= 0.0 {
            return None;
        }
        let across = (self.left - west) / span_west;
        let down = (self.top - north) / span_north;
        let on_map = (0.0..=1.0).contains(&across) && (0.0..=1.0).contains(&down);
        on_map.then_some((across, down))
    }
}

#[derive(Default, Debug)]
pub struct MapAreas(pub Vec<MapArea>);

impl MapAreas {
    pub fn zone_ids(&self) -> impl Iterator<Item = (&str, u32)> {
        self.0
            .iter()
            .filter(|area| area.area_id != 0 && !area.name.is_empty())
            .map(|area| (area.name.as_str(), area.area_id))
    }

    fn zone(&self, area_id: u32) -> Option<&MapArea> {
        self.0.iter().find(|area| area.area_id == area_id)
    }

    pub fn position_in_zone(&self, area_id: u32, north: f64, west: f64) -> Option<(f64, f64)> {
        self.zone(area_id)?.fraction_of(north, west)
    }

    pub fn position_on_map(&self, map_id: u32, north: f64, west: f64) -> Option<(u32, f64, f64)> {
        self.0
            .iter()
            .filter(|area| area.map_id == map_id && area.area_id != 0)
            .find_map(|area| {
                let (across, down) = area.fraction_of(north, west)?;
                Some((area.area_id, across, down))
            })
    }
}

#[derive(Clone, Default)]
pub struct SharedMapAreas(pub Rc<MapAreas>);

impl SharedMapAreas {
    pub fn from_install() -> Self {
        match load_from_install() {
            Ok(areas) => Self(Rc::new(areas)),
            Err(error) => {
                warn!("Hordes of Azeroth: world map areas not loaded: {error:#}");
                Self::default()
            }
        }
    }
}

fn load_from_install() -> anyhow::Result<MapAreas> {
    let data = wow_data().ok_or_else(|| anyhow::anyhow!("no WoW Data folder found"))?;
    let mut chain = Chain::open(&data)?;
    let catalog = load_world_map_area_catalog(&mut chain)?;
    Ok(MapAreas(
        catalog
            .iter()
            .map(|(_, row)| MapArea::from_row(row))
            .collect(),
    ))
}

#[cfg(test)]
mod tests {
    use super::*;

    fn elwynn() -> MapArea {
        MapArea {
            map_id: 0,
            area_id: 12,
            name: "Elwynn".into(),
            left: 1535.4166,
            right: -1935.4166,
            top: -7939.583,
            bottom: -10254.166,
        }
    }

    #[test]
    fn zone_fraction_runs_east_and_south_from_the_top_left() {
        let zone = elwynn();
        let (across, down) = zone.fraction_of(zone.top, zone.left).unwrap();
        assert_eq!((across, down), (0.0, 0.0));
        let (across, down) = zone.fraction_of(zone.bottom, zone.right).unwrap();
        assert!((across - 1.0).abs() < 1e-9 && (down - 1.0).abs() < 1e-9);
    }

    #[test]
    fn a_point_off_the_zone_has_no_position() {
        assert_eq!(elwynn().fraction_of(0.0, 0.0), None);
    }

    #[test]
    fn map_lookup_finds_the_zone_holding_the_point() {
        let areas = MapAreas(vec![elwynn()]);
        let (area, _, _) = areas.position_on_map(0, -9000.0, 0.0).unwrap();
        assert_eq!(area, 12);
        assert_eq!(areas.position_on_map(1, -9000.0, 0.0), None);
        assert_eq!(areas.zone_ids().collect::<Vec<_>>(), vec![("Elwynn", 12)]);
    }
}
