//! Which addon a chunk belongs to, from its chunk name.

/// The addon a chunk name belongs to: the folder of an `@Interface\AddOns\<Folder>\…` file,
/// `FrameXML` for the stock interface, `benilla` for benilla's own layer. A chunk Lua compiled
/// from a string (`loadstring`, `RunScript`) belongs to the chunk that compiled it, its parent.
/// One the host compiled names no file and has no parent: an XML handler's (`<frame>:<script>`)
/// goes to the addon whose file was compiled just before it, since the loader compiles an addon's
/// handlers while that addon loads, so an addon whose handlers come before any of its `.lua` files
/// is charged to the one before it; a binding's body goes to the addon loaded last, an
/// approximation the per-addon time carries.
/// Indexed by source id: `heap.sources` has `slots` slots, and `in_order` lists the live ones in
/// compile order (`Heap::sources_in_order`), which slot order is not once a slot is reused, each
/// with its parent, which comes before it.
pub(super) fn owner_names<'a>(
    slots: usize,
    in_order: impl IntoIterator<Item = (u32, &'a [u8], Option<u32>)>,
) -> Vec<String> {
    let mut out = vec![String::new(); slots];
    let mut current = String::from("FrameXML");
    for (id, s, parent) in in_order {
        let name = String::from_utf8_lossy(s);
        let lower = name.to_ascii_lowercase();
        let owner = if let Some(rest) = lower.strip_prefix("@interface\\addons\\") {
            let folder_len = rest.find('\\').unwrap_or(rest.len());
            // The folder in the chunk name's own spelling.
            let start = "@interface\\addons\\".len();
            let folder = name[start..start + folder_len].to_string();
            current = folder.clone();
            folder
        } else if lower.starts_with("@interface\\framexml") || lower.starts_with("@interface\\glue")
        {
            current = "FrameXML".into();
            current.clone()
        } else if name.starts_with('@') || name.starts_with('=') {
            "benilla".into()
        } else if let Some(p) = parent.filter(|&p| !out[p as usize].is_empty()) {
            out[p as usize].clone()
        } else {
            current.clone()
        };
        out[id as usize] = owner;
    }
    out
}

/// [`owner_names`] for a heap.
pub(super) fn owners_of(heap: &benilla_ui::mlua::benilla_lua::heap::Heap) -> Vec<String> {
    let in_order = heap.sources_in_order();
    owner_names(
        heap.sources.len(),
        in_order
            .iter()
            .map(|(id, name)| (*id, &name[..], heap.source_parent(*id))),
    )
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn handlers_follow_the_file_before_them_and_strings_their_compiler() {
        // Slot order differs from compile order, as once a slot is reused.
        let order: [(u32, &str, Option<u32>); 7] = [
            (0, "=[host]", None),
            (3, "@Interface\\FrameXML\\UIParent.lua", None),
            (1, "UIParent:OnUpdate", None),
            (5, "@Interface\\AddOns\\Bagnon\\Bagnon.lua", None),
            (2, "BagnonFrame:OnUpdate", None),
            (4, "@Interface\\AddOns\\!OmniCC\\OmniCC.lua", None),
            // A `loadstring` Bagnon's code ran after OmniCC loaded.
            (6, "return 1", Some(5)),
        ];
        let by_id = owner_names(7, order.iter().map(|&(i, n, p)| (i, n.as_bytes(), p)));
        let names: Vec<&str> = order
            .iter()
            .map(|&(i, _, _)| by_id[i as usize].as_str())
            .collect();
        assert_eq!(
            names,
            ["benilla", "FrameXML", "FrameXML", "Bagnon", "Bagnon", "!OmniCC", "Bagnon"]
        );
    }
}
