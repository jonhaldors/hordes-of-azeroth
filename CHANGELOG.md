# Changelog

## 0.5.2

### Hotfix 1
- Auto-pick no longer ends the run on checkpoints with many extra level-ups.
- Single Darkmoon Favors refunds work again instead of needing Refund all.
- Rank-up cards no longer show a false "(at cap)" on Burning and other per-stack damage.
- Starter gear is white with slightly lower stats than the white gear from Normal runs, so every white drop is an upgrade instead of being salvaged.
- Epic trinkets show their effect in the tooltip again. The effect always worked.

### Gear
- Gear grows steadily with its tier instead of multiplying: each tier adds a quarter of its Tier 1 stats.
- Normal drops white gear. Heroic drops white and green, and bosses from floor 2 have a 15% chance to drop blue.
- Mythic gear and tier sets are blue.
- Epic versions of Mythic gear drop from floor 10: 10% per boss, +1% per floor, up to 25%. Epics always have a bonus stat.
- Legendaries drop from Mythic floor 20: 0.5% per boss, rising to 2%. Legendaries with tiers now have their effects.
- Bosses drop one piece instead of two.
- Shop greens, blues and epics now use real item looks for each slot.
- Durgan sells white gear (Normal) and green gear (Heroic). Varrok sells Tier 1-10 blues. Prices changed, will adjust if needed.
- Gold from kills and floors is halved, and Darkmoon Tickets drop about half as often, will adjust if needed.
- The Extraction Vault keeps its item if you die.
- The floor preview shows each boss's chance to drop blue, epic and legendary gear.
- Existing gear above Tier 20 becomes Tier 20. If you own legendaries, you're asked once whether to keep them or turn them into Scrap.

### Enchanter
- Power and Max Health enchants add 10-50% of the piece's own stat, from Minor to Godly.
- The Enchanter shows how much each enchant adds to the piece.
- Enchants no longer offer a stat the piece doesn't have.

### Mythic balance
- Enemy health no longer jumps at floors 11 and 16. Past floor 10 it grows by 12% per floor.
- Enemy health grows more slowly past level 10, so enemy hits no longer jump within a minute.

### Normal and Heroic
- Enemies leave you a way out more often instead of surrounding you. Mythic is unchanged.
- You move 10% faster by default, in Mythic too.

### Spells and level-ups
- Blade Flurry, Shadow Dance and Evasion are at max rank as soon as you learn them. Their evolutions can appear once your other spells total 20 ranks.
- Spell tooltips show "Max rank" when a spell can't rank up further.
- Banish only works on things you don't already own. Cards you own are dimmed while banishing.
- Ley Line blessings of the same stat give less each time: each pick is 85% of the last, down to 10%.
- Card proc chances show one decimal, so you can see each copy's gain at higher levels.

### Bosses
- Bosses and mini-bosses have voice lines, and battle music plays while a boss is up.
- Stampede and other charge warnings now show their full length, and charges only hit inside the drawn line.

### Quality of life
- The mailbox has an Open All button. It takes all items, then deletes the empty mail.
- Returning to the Inn at the portal asks you to confirm first.
- The Run Master's start floor is a dropdown list.
- The options window keeps the run paused.

### Controller
- Reroll, Banish and Skip on cards have their own buttons, which you can rebind in Controller settings.
- Card windows ignore button presses for a moment after opening, so a press meant for a chest or NPC can't pick a card.
- Closing the goblin vendor with B no longer leaves the game paused.
- SpaceMouse devices no longer start the game in controller mode.

### Languages
- Notices, server messages and addon text now show in your chosen language. Simplified Chinese thanks to xenoglossy-asyncio.

### Launcher
- Switch between accounts, or add, rename and delete them, from the account button next to the Discord button.
- Back up your save data and restore a backup from the ... menu.

### Fixes
- Fixed: Switching Display Mode between windowed and windowed fullscreen in game.
- Fixed: Level-up choices sometimes showed only 2 cards with an empty spot.
- Fixed: Seals and other spells at their cap showed blank level-up cards.
- Fixed: Glacial Fragments could crash the server when a large frozen pack died at once.
- Fixed: Glyph of Cleave's overkill damage got damage bonuses and crit a second time.
- Fixed: The path to the exit portal could lead up ledges and long detours.
- Fixed: Runs could start in unfinished parts of a zone.
- Fixed: Removing old backups could stop the launcher from updating.

## 0.5.1

### Found gear
- Mythic bosses and mini-bosses drop gear at the floor's tier, sometimes higher. There is no tier cap.
- Some found items roll bonus stats.
- Upgrade extracted gear at the Mythic Quartermaster with Scrap.
- Reroll one bonus stat per item at the Mythic Quartermaster for gold. Each reroll on the same item costs more, up to 1,000g.
- The Quartermaster sells gear up to Tier 10.
- Existing gear has half its tier and can now be upgraded.
- Elites drop Scrap on Mythic difficulty.
- The Extraction Pillar shows a log of what has already been extracted on the current run.
- The Extraction Vault shows how much Scrap each item is worth.
- Mythic runs no longer give gold for unextracted gear, only Scrap.

### Trinkets
- All 8 Mythic trinkets have new effects.
- Trinkets are Unique-Equipped: you can wear only one of each, whatever its tier.
- Worn trinkets move to your bags on your first login after the update.

### Enchanter
- An Enchanter waits by the portal at the end of each floor.
- Spend Valor to enchant an item slot, not the item itself, from Minor to Godly. Each roll costs more.
- Enchants last for the run.

### Mythic checkpoints
- You can start Mythic runs from checkpoints every 5 floors, up to 15 below your best floor. Pick them at the Run Master.
- Checkpoint runs start at a matching level with extra level-ups to pick. (Will need to be adjusted)
- New Auto-pick button for those extra level-ups, letting you choose when everything is new, and auto-selecting already picked ones.

### Talents
- Talent presets: save up to three builds per class at the Talent Trainer. Can't be switched during a run.
- Inspect your talents during a run (N by default).

### Mythic balance
- Mythic bosses and mini-bosses have much more health.
- Enemies have more health from Mythic floors 11 and 16. (Old system, will be changed)
- Leveling past 60 is a bit slower.
- Rested no longer has a minimum value.
- Sayge's Might, Insight and Fortune favors no longer have a maximum rank.

### Cards and passives
- Fixed some Card and passive tooltips not showing your current total.
- Magnets also pick up Darkmoon Tickets and Valor Pouches.

### Glyphs
- Glyph of the Windseeker strikes up to 5 enemies for 60% of a normal enemy's health (was 8 enemies for 200%).
- Glyph of Shadowmourne strikes for 3 times a normal enemy's health (was 5 times).

### Combat feel (still WIP)
- New weapon hit sounds, weapon glows and kill effects.
- Your hits knock enemies back. Bigger enemies move less.
- Melee swing and cat claw sounds.
- Smoke Bomb, Caltrops, Cheap Shot, Frost Trap and treants now have sounds.

### Enemies and bosses
- Enemy pools and void zones deal more damage.
- Bosses and mini-bosses show on the minimap and world map.
- Fixed: Runs can start anywhere in the zone, instead of one area.

### Controller
- Rebind controller buttons.
- The controller now works in the Darkmoon vendor and Quartermaster windows.

### Languages
- Choose the game's language in the launcher, next to Play, or in Interface Options.
- The game can now show Chinese (Simplified) text. Translations are being worked on, thanks to xenoglossy-asyncio.

### Launcher
- Open your AddOns folder from the ··· menu next to Play.
- Key bindings from 0.4 carry over.
- After a crash, the launcher asks whether to send a crash report, then shows its reference for your bug report. Turn the question off in the ··· menu.

### Fixes
- Fixed: The Extraction Pillar was missing on floors ended early by a Summoning Stone.
- Fixed: Cooldown resets on kill sometimes failed after an instant cast.
- Fixed: Unextracted gear was kept after a server crash.
- Fixed: Run enemies in dungeons sometimes behaved like normal dungeon enemies.
- Fixed: The character screen forgot your last played character.
- Fixed: Escape stopped opening the game menu after unbinding it.
- Fixed: The interact key couldn't reach some objects properly.
- Fixed: The game crashed on PCs that only support OpenGL.
- Fixed: The launcher could update itself while the game was running.
- Fixed: The boss health bar showed wrong values on Mythic bosses.
- Fixed: Blink now teleports the way you face, even in midair.
- Fixed: Blade Flurry can rank up to its evolutions again.
- Fixed: The Druid's Shapeshift tooltip now shows the range of each form.

### Other changes
- Bug reports now include more crash information.
- Your dodge chance is now exactly your Dodge stat. The hidden dodge every class got from its class and Agility is gone, and Dodge on gear is 25% higher to make up for it.

## 0.5.0

### Hotfix 2
- Each Mythic item you don't extract now gives 2 Scrap. Items above the Quartermaster's tier give 4 to 8.
- The Extraction Vault shows 16 items per page, highest tier first.
- New passive cards show their description again. Total rows name their stat.
- Upgraded legendaries keep their effect text.
- Portals no longer spawn inside trees or other unreachable spots.
- Linux: installing into a folder with spaces in its path now works.

### Hotfix 1
- Haste and Area are no longer offered once a pick adds less than 1%.
- Extra card copies no longer reduce Count.
- Total rows show a decimal instead of a false "(at cap)".
- Talent tooltips show the value at your current rank and the next rank.
- Capped stats show their maximum again.
- Run data and bug reports now upload.
- Updating no longer fails when the game's database folder is open in another program.

### New client and Linux
- 0.5 runs on a new client (benilla), heavily modified for performance. Expect bugs.
- Linux and Steam Deck support (beta): native launcher, client and server.
- Controller support, with Steam Deck button prompts.

### Launcher
- New launcher for Windows and Linux.
- Optional: send run data and bug reports to help with class tuning and crash fixes.

### Mythic floors
- Mythic is now a climb of 20 floors, starting on floor 1 every run, with Endless past floor 20. Difficulty rises in three bands.
- All difficulties now use floors.
- Heroic and Mythic have tougher early enemies. Normal is unchanged.
- Gold and Darkmoon Tickets increase by 10% per Mythic floor. Milestone floors award double first-clear tickets.

### Run Master
- Redesigned window with a difficulty ladder, map list, loadout and floor slider.
- The floor preview shows enemy behavior, rewards and milestones for each floor.

### Mythic Quartermaster
- New vendor selling class tier sets, weapons, accessories and proc trinkets in Tiers 1-20. Each tier is 12% stronger than the last.
- Stock is two tiers below your best Mythic floor cleared.
- Set pieces from other classes can be refitted for your class for a small fee.
- Eight new trinkets, each with a 5% chance on cast to proc.
- More rings, necks and weapons are coming.

### Loot
- Extraction Pillar: appears after a floor's second mini-boss (every second floor up to 10, every floor after) and sends one item home.
- Scrap: items you don't extract become Scrap. 100 Scrap buys an item one tier above the shop, or upgrades a legendary.
- Legendaries now have tiers and drop only from floor bosses. Old legendaries upgrade to the shop's tier +1.
- Mini-bosses drop tier pieces more often on floors at or above the shop's tier. Blue items phase out over the first 10 Mythic floors.
- Gear worse than what you have equipped is salvaged for Valor automatically.
- Greens and blues go on Durgan's shelf at half price the first time you find them.
- Extraction item cards show the item's tier, an upgrade arrow, and whether you already own it.
- New loot beams, brighter by rarity. Darkmoon Tickets and Glyphs sit in glowing pools.

### Talents
- New talent trees for every class, with larger rows, a choice row and a capstone.
- Capstones no longer cost stats, and weak capstones have new effects.
- Talent tooltips explain terms such as Enrage, Bleed and Shield.
- Locked rows show how many points they still require.

### Darkmoon Cards and Glyphs
- Cards no longer have a copy limit. Each extra copy is slightly weaker. New card effects.
- New Darkmoon Deck table at the Inn for unlocking cards and Glyphs and buying ban slots.
- Up to 7 Glyph sockets on Mythic. Glyphs drop from mini-bosses and floor bosses, and Glyph damage shows on the damage meter.
- New Glyph of Raise Dead: slain elites rise as skeletons to fight for you.
- Gnomish Death Ray now grants +400% Power to the triggering cast instead of multiplying all damage by 5.
- Locked cards and Glyphs show their unlock progress.

### Pets and summons
- Pets and summons inherit 100% of your Power, Crit, Crit Damage, Haste, Duration and Movement Speed. They no longer trigger your on-hit or on-cast effects.
- Melee pets deal damage with their attacks. Spirit Wolves, Shadowfiends, Treants and the Felhunter cleave enemies in front of them.
- Hydra heads now attack different targets. Searing Totem hits 2 targets.
- Increased damage for Hydra, Searing Totem, Totem of Wrath, Imp and Felhunter.

### Codex and tutorial
- New Rules tab in the Codex. Highlighted terms show an explanation on hover.
- New tutorial steps for the Darkmoon Deck and the Quartermaster. Tutorial arrows now follow the camera.
- Town NPCs appear once unlocked.
- New account-wide titles, each with a small stat bonus. New class quests for Mythic floors.

### Interface
- New spell tooltip layout with rank, radius, range, cooldown and upgrades.
- Enrage, Divine Shield, Renew and other buffs now have their own tooltips.
- The damage meter shows Glyphs. Right-click a row to hide it; the eye button shows all rows again.
- Character stats show the Armor cap and Shield restore.

### Balance
- Determination: each death grants a little Power and toughness until you clear Normal.
- Tuning pass for every class.
- Area and Haste have diminishing returns.
- Armor reduces damage taken by up to 60%, with diminishing returns.
- Hit has been removed, along with elite dodge.
- Account Training ranks are stronger.
- Proc damage no longer scales with difficulty.
- Damage over time ticks no longer count as hits.
- Elemental Mastery and Blast Wave damage reduced.

### Fixes
- Clearing a harder difficulty now also completes class quests for easier ones.
- Earth Shock now consumes Static.
- Trinkets no longer proc while your spells have no target.
- Glyph of Divine Shield now recharges on every difficulty.
- Spirit Wolf bites now apply Static and Shadowfiend bites now apply Decay.
- Monster spells no longer slow you for now. Stuns still apply.
- Fixed a run freeze when a Ley Line offer appeared as another choice closed. Stuck pauses now recover on their own.
- Damage over time and pets no longer damage enemies while a level-up choice is open.
- Custom key bindings are no longer reset at login.
- Windfury Weapon kills now count toward Windwalker's quest.
- Enemies no longer regenerate health out of combat.
- Clearing a floor now removes leftover shrine pins and events from the map.
- Ascension is no longer offered once no spell can evolve.

## 0.4.0

### Druid
- Druid is now available. Still WIP like every class.
- New starter spell Shapeshift with four form attacks (Moonkin, Cat, Bear, Tree of Life) and a bonus for fighting in the right form. Press 'R' to change form; you can rebind it in Tarn Oakhoof's Keys list next to Hearthstone and Dash.
- Hotbar spells glow green in their matching form and red when Bear form weakens them.

### Spell tooltips
- Shorter spell tooltips for every class, with live damage numbers in the first sentence.
- Updated tooltips across the board.

### Account bank
- New account-wide bank shared by every non-Ironman character on the account.

### Hotbar
- Moved everything closer and re-positioned some elements to make it look more like a proper UI.

### Difficulty and pacing
- The calm opening of a run is shorter on Heroic and gone on Mythic.
- Stage 2 and later start close to the previous stage's pressure instead of from scratch, with calmer stretches kept.

### Enemies
- Enemy casters glow during their wind-up, play cast animations, and their impacts land inside their circles.
- Some enemies left far behind no longer race across the map, they now teleport properly.

### Death recap additions
- Hover the health graph to see your health at that moment. Hits and heals show their amounts when the cursor snaps to them.

### Warrior
- Fixed builds that could stand still forever: shields from all sources share one Shield capped at 50%, Campfire healing is capped at 3%, regeneration no longer feeds Lifegiving Gem, on-hit cards count once per cast, and Vengeance stores only health damage.

### Warlock
- Fixed: Burning stacks now gain your damage bonuses (Power, spec, talents, cards) like every other damage over time.

### Launcher
- If the game crashes while reading a damaged MPQ archive, the launcher names that archive after the game closes and tells you how to fix it.

### Other changes
- XP orbs follow you through a dash and get picked up when you dash over them.
- No more reputation gains or reputation chat lines. Eastern Plaguelands towers and Silithus world PvP are off, so no capture bar covers the run timer.
- If the server stops after you connect, the login screen says so and points to Report a bug instead of showing the stock "Failed to connect" text.
- Rebuilt: character list on the right, class info on the left, and you create characters on the same screen.

## 0.3.1

### Enemies
- Enemies now move as a crowd: they no longer stack inside each other, and blocked enemies walk around the pack to an open side.
- Enemies emerge hidden and appear with a teleport flash. Spawns are more spread out and start farther away.

### Bosses
- Heroic and Mythic bosses fight harder: faster moves, marks that follow you, bombardment at range, wounds that cut healing, recovery when kited, healing wards, eruption lanes and Blink.
- Boss affix circles no longer stack on top of their wind-ups, and circles no longer spawn oversized.

### Movement speed
- Movement speed is capped at 50%. Temporary boosts such as Swiftness Potion, Body and Soul and Last Stand can go above it.
- Level-up passives, Darkmoon Cards and Ley Line buffs that would only add capped speed are no longer offered.
- The stats panel shows the 50% cap.

### Hearthstone
- The hearth timer keeps going when leaving the circle.
- A blue 5 yard ring fills up over the hearth time. If you are outside the ring when it fills, you are left behind as the ring and vault teleport away.

### Damage meter and death recap
- Redesigned damage meter.
- Healing and absorbs are credited to the spell, passive, card, glyph, talent, Moonwell or Healing Orb that made them, and show on the results screen.
- New death recap on the defeat screen: your health over the last 10 seconds with hit ticks, who killed you and the top damage sources.

### Hotbar
- New "Cooldown Numbers" option in Interface settings turns the countdown numbers on or off. It shows on spells with a cooldown of 2 seconds or more.

### Paladin
- Crusader Strike damage lands 300 ms after the swing, matching the animation.
- Seal spells no longer show a cooldown pie or "Casts every" line.

### Warlock
- Conflagrate's tooltip now says each struck enemy spreads fire to enemies within 5 yards for half damage and applies 1 stack of Burning.

### Launcher
- Shows a notice when Windows Smart App Control blocks the game.
- Ships the 32-bit Visual C++ runtime, so the performance DLL loads on PCs that didn't have it (fixes "VanillaFixes DLL error (0)").
- Hardened startup for the client fix DLL.

### Other changes
- Area rain spells hold still during pauses.
- Drain Life and other channel beams start at the caster's chest instead of in the air on flying and tall models.
- Pet tooltips show attack speed.
- The interact prompt draws over the hero health bar and sits above NPC nameplates.
- The magnet drop map pin uses a new icon.
- Extracted items show in the mailbox right away, without a relog.

## 0.3.0

### Warlock
- Warlock is now available. Still WIP like every class.
- 11 spells and 22 evolutions, talents and class quests.

### Bosses
- Attacks no longer fizzle after a pause: a wind-up that was on screen when a level-up, chest or vendor paused the game still lands afterwards.
- Warnings vanish as soon as their attack is broken off or the enemy dies, so none are left behind.
- Leaping bosses finish the leap instead of snapping the last yards.
- Stomps are 3 yards wider and hit harder. Breaths reach 16 yards on Normal, cones and tail sweeps are 3 yards longer, and all of them grow 20% per difficulty step.
- Melee specials such as Cleave, Mortal Strike, Knock Away and Uppercut now show a cone warning.
- War Stomp and Thunderclap circles match their real reach and only hit inside them. Caster bolt circles are slightly smaller.
- Running into or out of a bolt or eruption circle at the last moment now counts correctly, and big circle hits show a matching big impact.
- Lingering pools show a molten ring on the ground instead of a red aiming circle.

### Game window
- Fixed the stretched picture on ultrawide screens such as 3440x1440. The game now keeps your screen's resolution instead of dropping to 1600x1200 when Windows doesn't list that resolution for the game.
- The widescreen and ultrawide view now shows as much of the world from top to bottom as on 16:9 screens, instead of looking zoomed in on 21:9 and 32:9 screens.

### Launcher
- If the game crashes in Vulkan, the launcher switches the game to DirectX 9 and tells you once. PCs without Vulkan run on DirectX 9 from the start. A new "Vulkan graphics" checkbox in the "..." menu turns it back on or off.
- Database errors now show the real error, and the launcher keeps a log file that goes into the log bundle.

### Legendaries
- Legendaries are 15% stronger than Mythic run epics for their slot, and every legendary weapon has two extra stats that fit its theme.
- Legendary drop chance starts at 10% on the Mythic stage 2 boss and grows 5% each later stage, up to 40%.

### Mage
- Slow Time leaves a single time bubble for 10 sec, shown as a purple ring the size of its reach. The next blast after it fades leaves a new one.
- Only Blink and its evolutions turn your dash into Blink. Blink no longer shows a cooldown on the hotbar.
- Frostbolt deals 40% more damage, Arcane Missiles, Blizzard and Frost Nova 33% more, Arcane Explosion 29% more. Their evolutions get the same boost.

### Rogue
- During Shadow Dance, Vanish, Symbols of Death and Shadow Blades, each enemy can be Ambushed at most once a second. Count and fast hits no longer multiply Ambush strikes.

### Paladin
- Crusader Strike's splash hits each enemy at most once per strike, so overlapping splashes no longer stack.

### Warrior
- Bloodlust cuts at most 1 sec off its cooldown per strike, down to 3 sec (was down to 1 sec).
- Aftershock erupts for 30% of the damage with 1 Bleed stack (was 50% and 2).

### Other changes
- Pets land their special attacks while you run, such as the Felhunter's Shadow Bite and the cat's Claw and Bite.
- Gear you brought goes back on when you log out or disconnect during a run, instead of ending up in your bags.
- Level-up, gear and chest choices close when a run ends.
- Damage you take no longer shows twice sometimes on your character.

## 0.2.3

### Innkeeper
- A new NPC has moved in: Tarn Oakhoof, the new Innkeeper at the Inn.
- Tarn allows you to change some game settings, it also updates the settings in the Interface menu, and also works the other way around.
- New players meet Tarn before their first run. If you've already played, the tutorial shows you the way to him once.

### Interact key
- Press F to talk to people and open chests near you, no right-click needed. The key shows above whatever you can use.
- Tarn allows you to choose what the key interacts with: people, chests, shrines, portals and/or the mailbox.
- New option: Automatically open chests when you walk up to them. It's off by default and only opens Treasure and Elite Chests.
- F is the default interact key. You can change it by speaking to Tarn or inside the Key Bindings menu.

### Launcher
- The launcher now checks the game before every start and puts back missing or broken files, such as the login screen or the addon, before the game opens.
- An update or install that was stopped while loading the world now loads it again, instead of leaving a game that can't start.
- New Repair the game option in the "..." menu next to Play. It checks every file, downloads the ones that are missing or damaged and reloads the world. Your characters and unlocks are backed up first.
- The first time you play after this update, the launcher may reload the world once. It takes about a minute.

## 0.2.2

### Debuffs on health bars
- Enemy nameplates now show your debuffs under the health bar (Burning, Bleed, Poison, Decay, Chill, Static and the rest) with their stack counts, instead of elite affixes.
- The mini-boss and boss bar shows your debuffs too. Each icon darkens clockwise as its time runs out.
- Elite affixes are explained in a new Affixes tab at the Spellbook Keeper.
- Damage over time effects no longer fall off right after a level-up choice.

### Combat
- Bosses no longer hit you from far away. Enemy melee reach is capped (Magmadar reached almost 15 yards).
- Mini-bosses are tougher: 35 times a normal enemy's health, up from 14.
- An elite that is a bounty target no longer also drops its own chest.
- Level-ups add the max health you gain on top of the 5% heal.
- XP orbs fly to your hero's chest, and follow you through the air.
- The kodo caravan stops while the run is paused.

### Paladin
- Hammer of Justice only knocks down enemies it stuns. Bosses, mini-bosses and stun-immune enemies no longer plays the stun animation when they're not stunned.
- Avenger's Shield no longer looks like it knocks enemies down.
- Judgement plays your cast animation and an impact on each target.

### Sound
- XP pickups play a sound for each orb. It can be turned off in Sound Options (Experience Pickup Sounds).
- Valor Pouch pickups play the coin sound.

### Game window
- New proper Borderless window mode, on by default: the game fills your screen without a title bar or borders, like modern games. Alt+Tab switches instantly, and the picture stays sharp with Windows display scaling.
- Fixed a stretched picture on ultrawide and other screens when the game resolution didn't match the screen's shape. The launcher now sets your screen's resolution when the two don't match.
- Window mode now opens as a normal window that fits above the taskbar.

### Other changes
- Upgrade offers name the reward type (Darkmoon Card, upgrade, reward or blessing), and cards grow to fit long text.
- Shorter Darkmoon Card descriptions.
- Hero creation now says races are cosmetic only, with no racial bonuses.

## 0.2.1

### Gear
- Gear can now be looted as well. Carry the piece in your bags to either wear it later or extract it. Found gear is still only saved if it's in the Extraction Vault.
- You can change gear from your bags during a run. Putting on a shield or off-hand while holding a two-hander moves the two-hander to your bags.

### Hearthstone
- A Hearthstone button sits next to the hotbar while you carry one, used on T by default (Key Bindings, Use Hearthstone). Your first one found comes with a short explanation.
- The Hearthstone's Extraction Vault holds 1 item, even with Pack Mule.

### Controller
- Moving, jumping and buttons work as soon as you enter the world, without touching the mouse or keyboard first.
- The camera on new installs no longer swings behind your hero on its own, which made movement feel reversed and the camera sluggish.

### Other changes
- Your health now shows as numbers on your health bar. On by default, turn it off in Interface Options (Health Numbers).
- Fixed a rare login error ("The information you have entered is not valid") when starting the game.

## 0.2.0

### Paladin
- Paladin is now available. Still WIP like every class.
- 13 spells, 26 evolutions, three talent trees (Holy, Protection, Retribution) each with its own capstone, and 10 Paladin quests that award talent points.

### Other changes
- You can now customize your character when you create it: skin color, face, hairstyle, hair color and facial hair.
- Quest unlocks no longer need a Spellbook purchase.
- Addons other than Hordes of Azeroth are turned off when the launcher starts the game.
- Enemy warnings and bolts vanish when the enemy casting them dies.
- Spell cooldowns on the hotbar pause while a menu, shop or reward choice is open.
- The tutorial explains Gold, Darkmoon Tickets and Valor.
- Launcher fixes for screen resolution and database setup.
- No more going Away and sitting down when idle, no honor restart countdown and no tutorial popups from the base game.
- Ironman mode: tick the box when you create a character, and that character keeps its own gold and unlocks, apart from your other characters.

### Balance

#### Warrior
- Blood Aura, Aegis and Spiked Shield reach ~~6~~ → **8** yards.
- Bloodthirst no longer loses most of its damage due to a scaling bug early in a run.

#### Priest
- Halo also hits enemies right next to you, pulses every ~~5~~ → **4** sec and heals up to ~~5%~~ → **2%** of your health.
- Smite hits ~~1~~ → **2** enemies. Chastise every ~~20~~ → **12** sec.
- Penance +30% damage, Mind Blast +20%.

#### Rogue
- Sinister Strike and Ambush +25% damage. Killing Spree every ~~12~~ → **8** sec.
- Killing Spree shows a slash on every enemy it hits.
- Shuriken Toss throws ~~2~~ → **3** shurikens, +25% damage.

#### Shaman
- Lightning Bolt bounces to a second enemy, +60% damage.
- Chain Lightning and Forked Lightning jump to ~~3~~ → **4** enemies. Chain Lightning every ~~2.5~~ → **3** sec, +70% damage.
- Flame Shock and Earth Shock +50% damage. Windfury Weapon, Stormstrike and Magma Totem +33%.

## 0.1.1

- Monster paths now come as a download instead of being built on your processor. Installs and updates fetch them in a few minutes (about 330 MB), with no more long wait at 100% CPU. If your launcher already finished building them, there's nothing extra to download.
- If the download doesn't work, the launcher builds them on your PC like before. It first asks whether to use all of your processor cores or half, so your PC stays usable, and you can change that later from the ••• menu next to Play.
- Building monster paths now runs at a lower priority, so the rest of your PC stays responsive.

## 0.1.0

The first public version. It's early, so here's what to expect.

- Balance hasn't had much work yet. Some classes, spells and builds are bound to be too strong or too weak, and some zones are harder than they should be. Tell us what feels off.
- Six classes are playable. Druid, Paladin and Warlock come in later updates.
- Expect bugs. If something breaks, use Report a bug in the launcher: it saves a zip of your logs on your desktop to attach, or post it in the Discord.
- The first install takes a while, because the launcher builds the monster paths from your own game files. The harder zones keep building in the background while you play.
- Updates come through the launcher. Your characters are backed up before every update and your unlocks stay.
