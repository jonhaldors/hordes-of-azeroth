<p align="center">
  <img src=".github/images/banner.jpg" alt="Hordes of Azeroth" width="100%">
</p>

<h1 align="center">Hordes of Azeroth</h1>

<p align="center">
  <b>A survivors-style game mode for World of Warcraft 1.12.1.</b><br>
  An endless horde, spells that fire on their own and a choice at every level up.<br>
  Played alone (for now), on a server that runs on your own PC.
</p>

<p align="center">
  <a href="https://github.com/jonhaldors/hordes-of-azeroth/releases/latest/download/HoALauncher.exe"><img src="https://img.shields.io/badge/Download-Windows-0078D4?style=for-the-badge&logo=data:image/svg%2bxml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgMCAyNCAyNCI+PHBhdGggZmlsbD0id2hpdGUiIGQ9Ik0wIDBoMTEuNHYxMS40SDB6TTEyLjYgMEgyNHYxMS40SDEyLjZ6TTAgMTIuNmgxMS40VjI0SDB6TTEyLjYgMTIuNkgyNFYyNEgxMi42eiIvPjwvc3ZnPg==" alt="Download for Windows"></a>
  <a href="https://github.com/jonhaldors/hordes-of-azeroth/releases/latest/download/HoALauncher-linux.tar.gz"><img src="https://img.shields.io/badge/Download-Linux_%2F_Steam_Deck-FCC624?style=for-the-badge&logo=linux&logoColor=black" alt="Download for Linux and Steam Deck"></a>
  <a href="https://github.com/jonhaldors/hordes-of-azeroth/releases/latest"><img src="https://img.shields.io/github/v/release/jonhaldors/hordes-of-azeroth?label=latest&color=3a8a4a&style=for-the-badge" alt="Latest version"></a>
  <a href="https://discord.gg/zpYfsqh6Dn"><img src="https://img.shields.io/badge/Discord-Join_us-5865F2?style=for-the-badge&logo=discord&logoColor=white" alt="Join the Discord"></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/licence-GPL--3.0-4a3a36?style=for-the-badge" alt="Licence: GPL-3.0"></a>
</p>

<p align="center">
  <a href="#getting-started">Getting started</a> ·
  <a href="#features">Features</a> ·
  <a href="#questions">Questions</a> ·
  <a href="https://discord.gg/zpYfsqh6Dn">Discord</a> ·
  <a href="#for-developers">For developers</a> ·
  <a href="https://github.com/jonhaldors/hordes-of-azeroth/issues">Report a bug</a>
</p>

<br>

<p align="center"><i>Gameplay from version 0.1. The game has changed a lot since.</i></p>

https://github.com/user-attachments/assets/3a82f020-7192-48dc-b6be-f6316bda0225

<br>

## Getting started

### What you need

- Your own copy of **World of Warcraft 1.12.1, build 5875, English (enUS)**. Hordes of Azeroth doesn't include the game.
- A copy of that client used only for Hordes of Azeroth. The launcher adds its own files to the folder, so don't use your folder for other servers.
- Windows 10 or 11 (64-bit), or Linux and Steam Deck (beta). About 3 GB of free space next to the game, and up-to-date graphics drivers.

### Install

1. Download **[HoALauncher.exe](https://github.com/jonhaldors/hordes-of-azeroth/releases/latest/download/HoALauncher.exe)** for Windows, or **[HoALauncher-linux.tar.gz](https://github.com/jonhaldors/hordes-of-azeroth/releases/latest/download/HoALauncher-linux.tar.gz)** for Linux and Steam Deck.
2. Put it in your World of Warcraft folder, next to `WoW.exe`. On Linux, unpack it there.
3. Start it and press **Install**. The first install takes a few minutes.
4. Press **Play**.

From then on, always start the game with the launcher. It starts the server, then the game, and stops the server when you close the game. On Steam Deck, add `HoALauncher` to Steam as a non-Steam game.

<p align="center">
  <img src=".github/images/launcher.jpg" width="720" alt="The launcher during the first install">
</p>

### Updates

Updates come through the launcher. When a new version is out, **Play** turns into **Update**, and the patch notes show what changed. Your characters are backed up first, and everything you've unlocked stays. You don't have to download the launcher again.

> [!NOTE]
> Windows may show "Windows protected your PC" the first time, because the launcher is new and not signed yet. Click **More info**, then **Run anyway**. The full source is in this repository if you'd rather check it or build it yourself.

<br>

---

## Features

- **Runs across Azeroth's zones** on Normal, Heroic and Mythic, with more zones on the way.
- **Mythic floors**: climb 20 floors that get harder each time, then Endless for as long as you last.
- **Challenge mode** inside raids, or **Invasions** that bring their enemies into the open world.
- **All nine classes**, each with their own spells and evolutions.
- **Bosses you can outplay**: see their attacks coming and dodge them.
- **Dash** out of danger: making you untouchable for a moment. Rebind it in Key Bindings, and upgrade its range and cooldown at the Inn.
- **Find gear, Darkmoon Cards and Glyphs**. Tier sets and legendaries are lost on death unless you extract them.
- **The Mythic Quartermaster** sells class tier sets that keep pace with your best floor.
- **An Inn** with account-wide gold, upgrades, fortunes and class talent trees.
- **Controller support** for Xbox, PlayStation and Steam Deck, switching to and from mouse and keyboard automatically.
- **And a lot more to come.**

<br>

---

## Questions

<details>
<summary><b>What are the monster paths the launcher sets up?</b></summary>
<br>
In World of Warcraft, the server decides where monsters walk, not the game on your PC. Your client only has the shape of the world, so the launcher turns that into walking maps (navigation meshes) for every zone the game uses. That's the slow part.
<br><br>
The game mode uses those maps for two things. The mobs chase you around trees, up ramps and through doorways instead of walking through walls. And every monster spawns on a spot it can actually reach you from: never inside a rock or a tree, on a rooftop, or across a river or cliff.
<br><br>
The launcher downloads them ready-made with the game. If the download doesn’t work, it builds them from your own game files instead. That keeps your processor busy for a while, and it asks first whether to use all of your cores or half. The Inn and the Normal zones come first, so you can play while the rest finishes in the background.
</details>

<details>
<summary><b>Does it change my World of Warcraft?</b></summary>
<br>
<code>WoW.exe</code> stays as it is. Hordes of Azeroth runs on its own game client, which reads the models, maps and sounds from your 1.12.1 game files. The launcher adds its own files next to them: the client, the server, an addon and a spell effects patch. That's why it wants a copy of the game of its own.
</details>

<details>
<summary><b>Can I play with friends?</b></summary>
<br>
Not yet. Each player runs their own server on their own PC. Once the game is installed, you can play without internet; the launcher just can't check for updates until you're back online.
</details>

<details>
<summary><b>The game is too easy/hard</b></summary>
<br>
The game is currently in early development, balancing will happen over time. Some classes will be stronger or weaker than others, but updates happen regularly. If you'd like to see something changed, make a suggestion on <a href="https://discord.gg/zpYfsqh6Dn">Discord</a>.
</details>

<details>
<summary><b>Where are my characters, and what if an update goes wrong?</b></summary>
<br>
They're in the local database inside the game folder. Before every update the launcher saves a backup in <code>HordesOfAzeroth\backups</code> and keeps the three newest.
</details>

<details>
<summary><b>My antivirus flags the launcher.</b></summary>
<br>
New, unsigned programs that download files and start other programs sometimes get flagged by mistake. Every release lists the launcher's SHA-256 checksum, so you can check that yours is the real one (in PowerShell: <code>Get-FileHash HoALauncher.exe</code>). If it happens, please <a href="https://github.com/jonhaldors/hordes-of-azeroth/issues">open an issue</a>.
</details>

<details>
<summary><b>Windows Firewall asks whether to allow access.</b></summary>
<br>
Hordes of Azeroth runs its own small game server on your PC (a database, a login server and a world server), and the game connects to it. That connection never leaves your PC: the server only accepts connections from your own computer, so nobody on your network or the internet can reach it, and nothing about you is shared through it. You can choose either answer, and the game works the same.
<br><br>
The launcher goes online to check GitHub for updates and download them, the same as opening a web page.
</details>

<details>
<summary><b>What does the launcher send?</b></summary>
<br>
Only what you agree to. The launcher asks once whether to send your finished runs (class, spells, gear, damage, how far you got, and your game version and operating system) to help balance the classes. You can turn it off in the launcher's menu at any time. When you report a bug, it can also upload your logs and give you a reference to post with your report.
</details>

<details>
<summary><b>How do I uninstall it?</b></summary>
<br>
Close the launcher (also from the tray) and delete the game folder. Hordes of Azeroth keeps nothing anywhere else except a small font cache in <code>%LOCALAPPDATA%\HordesOfAzeroth</code>.
</details>

<details>
<summary><b>Can I play with a controller?</b></summary>
<br>
Yes. Plug in an Xbox or PlayStation controller and play. Button prompts switch to your controller or your keyboard keys, depending on which one you last used. Settings are under Key Bindings.
</details>

<details>
<summary><b>Can I use my own addons?</b></summary>
<br>
Yes. Addons go in <code>benilla-config\AddOns</code> inside the game folder, not in <code>Interface\AddOns</code>. In the launcher, click the <b>···</b> button next to Play, then <b>Open AddOns folder</b>. Put each addon there in its own folder. The client is new, so not every 1.12 addon works yet, and addons that change the unit frames or action bars may clash with the game's own interface.
</details>

<details>
<summary><b>Can I use HD model or texture packs?</b></summary>
<br>
Packs that come as <code>patch-?.MPQ</code> files go in the game's <code>Data</code> folder, the same as for 1.12.1. Name them <code>patch-4.MPQ</code> to <code>patch-9.MPQ</code> or <code>patch-A.MPQ</code> to <code>patch-Y.MPQ</code>. <code>patch-z.MPQ</code> is the game's own. The launcher rebuilds the game's spell effects on top of your packs the next time you press Play. They are untested, and packs made for modified clients may not show.
</details>

<details>
<summary><b>Does it run on Mac or Linux?</b></summary>
<br>
Linux and Steam Deck are supported in beta, see <a href="#install">Install</a>. Mac isn't supported.
</details>

<br>

---

## Community, bugs and ideas

Come hang out on the **[Discord](https://discord.gg/zpYfsqh6Dn)**: get help with installing, report bugs, share your best runs, and tell us what you’d like to see added.

Found a bug? Post it in the Discord's `#bug-reports`, or open an issue on the [issue tracker](https://github.com/jonhaldors/hordes-of-azeroth/issues). The launcher's **Report a bug** link saves a zip of your logs on the desktop and opens the tracker; attach the zip to your report or post. The ⋯ menu has **Save logs to the desktop** on its own, for Discord.

<br>

---

## For developers

Hordes of Azeroth is open source. Everything you need to build it, run your own development copy and make changes is in the developer guide.

<p>
  <a href="BUILDING.md"><img src="https://img.shields.io/badge/Developer_guide-BUILDING.md-b3261e?style=for-the-badge" alt="Developer guide"></a>
  <a href="https://github.com/jonhaldors/hordes-of-azeroth-server"><img src="https://img.shields.io/badge/Server_code-hordes--of--azeroth--server-4a3a36?style=for-the-badge" alt="Server code"></a>
  <a href="CHANGELOG.md"><img src="https://img.shields.io/badge/Changelog-CHANGELOG.md-4a3a36?style=for-the-badge" alt="Changelog"></a>
</p>

<br>

---

## About

Hordes of Azeroth is an unofficial fan project. Blizzard Entertainment didn't make it, doesn't endorse it, and has no part in it.

Nothing in this repository or in the releases comes from the game: no models, textures, sounds, maps, interface files or game data. The game runs on a modified version of [benilla](https://github.com/samwhosung/benilla), which reads the models, maps and sounds from a 1.12.1 client you own. The launcher builds the rest from those files on your PC: the server's map data and the spell effects patch. The one thing added is the monster paths: custom navigation meshes, which say only where monsters can walk, with no models, textures or terrain in them. Everything under `Interface/` in this repository is written for this project.

World of Warcraft and Blizzard Entertainment are trademarks or registered trademarks of Blizzard Entertainment, Inc.

Our code is licensed under the [GNU General Public License v3.0](LICENSE). The game client is a modified version of [benilla](https://github.com/samwhosung/benilla), under MIT or Apache-2.0. The server is a fork of [VMaNGOS](https://github.com/vmangos/core), published as [hordes-of-azeroth-server](https://github.com/jonhaldors/hordes-of-azeroth-server) under GPL-2.0. The other projects we build on or download, and their licences, are listed in [THIRD-PARTY-NOTICES.md](THIRD-PARTY-NOTICES.md).
