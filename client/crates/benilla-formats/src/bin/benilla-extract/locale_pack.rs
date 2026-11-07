//! Write a stock language pack: the install's `GlobalStrings.lua` and every `DBFilesClient` table,
//! as the client's account-language overlay reads them (`benilla-config/locale/<language>/`).

use std::path::Path;

use anyhow::{Context, Result};
use benilla_formats::Chain;

const GLOBAL_STRINGS: &str = "Interface\\FrameXML\\GlobalStrings.lua";

/// Copy the chain's stock language data into `out`: `GlobalStrings.lua` at the root and each DBC
/// under `DBFilesClient/`, both resolved through the patch chain so a patch override wins.
pub fn locale_pack(chain: &Chain, language: &str, out: &Path, force: bool) -> Result<()> {
    let install = chain.locale().name();
    if !install.eq_ignore_ascii_case(language) {
        if !force {
            anyhow::bail!(
                "the install's Wow.ini names {install}, not {language}; \
                 pass --force to label the pack {language} anyway"
            );
        }
        eprintln!(
            "warning: the install's Wow.ini names {install}, writing a {language} pack anyway"
        );
    }
    let global = chain
        .read(GLOBAL_STRINGS)
        .with_context(|| format!("reading '{GLOBAL_STRINGS}' from the chain"))?;
    let dbc_dir = out.join("DBFilesClient");
    std::fs::create_dir_all(&dbc_dir).with_context(|| format!("creating {}", dbc_dir.display()))?;
    std::fs::write(out.join("GlobalStrings.lua"), &global)
        .with_context(|| format!("writing {}", out.join("GlobalStrings.lua").display()))?;

    let mut written = 0usize;
    let mut failed = Vec::new();
    let mut entries: Vec<_> = chain
        .list()
        .context("listing chain contents")?
        .into_iter()
        .filter(|entry| {
            let name = entry.name.to_ascii_lowercase();
            name.starts_with("dbfilesclient\\") && name.ends_with(".dbc")
        })
        .collect();
    entries.sort_by(|a, b| a.name.cmp(&b.name));
    for entry in &entries {
        let Some(base) = entry.name.rsplit(['\\', '/']).next() else {
            continue;
        };
        match chain.read(&entry.name) {
            Ok(bytes) => {
                std::fs::write(dbc_dir.join(base), bytes)
                    .with_context(|| format!("writing {}", dbc_dir.join(base).display()))?;
                written += 1;
            }
            Err(e) => failed.push(format!("{}: {e:#}", entry.name)),
        }
    }

    println!("GlobalStrings.lua: {} bytes", global.len());
    println!("DBFilesClient: {written} tables");
    for line in &failed {
        eprintln!("skipped {line}");
    }
    if failed.is_empty() {
        Ok(())
    } else {
        anyhow::bail!("{} tables could not be read", failed.len())
    }
}
