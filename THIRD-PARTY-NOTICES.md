# Third-party notices

Hordes of Azeroth is licensed under the GNU General Public License v3.0 (see `LICENSE`). It builds on, ships with or downloads the following projects, each under its own licence.

Hordes of Azeroth is not affiliated with or endorsed by Blizzard Entertainment. It contains no Blizzard files: the game client is our own build of benilla, which reads the player's own World of Warcraft 1.12.1 data, and the launcher builds everything else it needs from that data on the player's PC.

| Project | Used for | Licence | Source |
| --- | --- | --- | --- |
| benilla | The game client (our fork: `client`, built as `HordesOfAzeroth.exe`) | MIT OR Apache-2.0 | https://github.com/samwhosung/benilla |
| Rust crates in the client | Bevy, wgpu, mlua's Lua and the other libraries benilla builds on, compiled into `HordesOfAzeroth.exe`; every crate with its full licence text is listed in `CLIENT-LICENSES.md` next to the game | Each crate's own licence (MIT, Apache-2.0, MPL-2.0, zlib, BSD and similar) | https://crates.io |
| VMaNGOS | The game server (our fork: `server/core`) | GPL-2.0 | https://github.com/vmangos/core |
| VMaNGOS world database | The base of the shipped world database (`world-db`), with our changes applied | GPL-2.0 | https://github.com/vmangos/core/releases |
| MariaDB Server | The local database | GPL-2.0 | https://mariadb.org |
| ICU4C | App-local Unicode and time zone libraries for MariaDB on Wine without Windows ICU. The licence ships in the Windows launcher bundle and alongside the extracted DLLs. | Unicode-3.0 | https://github.com/unicode-org/icu |
| Barlow Bold | Health numbers font in the addon (`Interface/AddOns/HordesOfAzeroth/Fonts`, licence in `Barlow-OFL.txt` beside it) | SIL Open Font License 1.1 | https://github.com/jpt/barlow |
| Microsoft Visual C++ Redistributable | Runtime DLLs next to the server and map tools | Microsoft Software License Terms (redistributable files) | https://learn.microsoft.com/cpp/windows/latest-supported-vc-redist |

MariaDB is downloaded by the launcher from its own release page. The client and the VMaNGOS-based server are built from our forks' source: [hordes-of-azeroth-client](https://github.com/jonhaldors/hordes-of-azeroth-client) and [hordes-of-azeroth-server](https://github.com/jonhaldors/hordes-of-azeroth-server).

## benilla

benilla is dual-licensed under the MIT licence and the Apache License 2.0; the full Apache text is `LICENSE-APACHE` in the client source.

```
MIT License

Copyright (c) 2026 Sam

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```
