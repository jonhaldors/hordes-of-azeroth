DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261016480000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261016480000');

UPDATE `bonk_weapon` SET `description` = 'Blasts all nearby enemies with thunder, damaging them and slowing their movement.' WHERE `id` = 1;
UPDATE `bonk_weapon` SET `description` = 'Hurls an axe that stuns the nearest enemy.' WHERE `id` = 2;
UPDATE `bonk_weapon` SET `description` = 'Consecrates the ground under you, damaging enemies who stand in it.' WHERE `id` = 3;
UPDATE `bonk_weapon` SET `description` = 'Hurls a holy hammer at the nearest enemy.' WHERE `id` = 4;
UPDATE `bonk_weapon` SET `description` = 'Releases a burst of holy light that damages all nearby enemies and heals you.' WHERE `id` = 5;
UPDATE `bonk_weapon` SET `description` = 'Smites the nearest enemy with holy light.' WHERE `id` = 6;
UPDATE `bonk_weapon` SET `description` = 'Flings axes at the nearest enemy, stunning it.' WHERE `id` = 8;
UPDATE `bonk_weapon` SET `description` = 'Throws a knife at the nearest enemy. Requires a thrown weapon.' WHERE `id` = 9;
UPDATE `bonk_weapon` SET `description` = 'Strikes the nearest enemy with a bolt of lightning.' WHERE `id` = 10;
UPDATE `bonk_weapon` SET `description` = 'Hurls a bolt of lightning at the nearest enemy that jumps to additional nearby enemies.' WHERE `id` = 11;
UPDATE `bonk_weapon` SET `description` = 'Sends out a ring of fire that damages all nearby enemies.' WHERE `id` = 12;
UPDATE `bonk_weapon` SET `description` = 'Launches a bolt of frost at the nearest enemy, slowing it.' WHERE `id` = 13;
UPDATE `bonk_weapon` SET `description` = 'Hurls a fiery ball at the nearest enemy.' WHERE `id` = 14;
UPDATE `bonk_weapon` SET `description` = 'Causes an explosion of arcane magic that damages all nearby enemies.' WHERE `id` = 15;
UPDATE `bonk_weapon` SET `description` = 'Sends a shadowy bolt at the nearest enemy.' WHERE `id` = 17;
UPDATE `bonk_weapon` SET `description` = 'Burns all nearby enemies.' WHERE `id` = 19;
UPDATE `bonk_weapon` SET `description` = 'Hurls a bolt of nature energy at the nearest enemy.' WHERE `id` = 20;
UPDATE `bonk_weapon` SET `description` = 'Strikes the nearest enemy and cleaves the enemies beside it.' WHERE `id` = 30;
UPDATE `bonk_weapon` SET `description` = 'Wounds 3 nearby enemies, making them bleed.' WHERE `id` = 32;
UPDATE `bonk_weapon` SET `description` = 'Strikes the strongest enemy in reach for heavy damage, elites first.' WHERE `id` = 33;
UPDATE `bonk_weapon` SET `description` = 'Quickly strikes the nearest enemy and grazes the enemies beside it.' WHERE `id` = 34;
UPDATE `bonk_weapon` SET `description` = 'Strikes the nearest enemy with a vicious finishing blow.' WHERE `id` = 36;
UPDATE `bonk_weapon` SET `description` = 'Strikes the nearest enemy with holy power, also hitting the enemies beside it.' WHERE `id` = 39;
UPDATE `bonk_weapon` SET `description` = 'Blasts the nearest enemy with holy power.' WHERE `id` = 40;
UPDATE `bonk_weapon` SET `description` = 'Blasts the nearest enemy with shadow.' WHERE `id` = 42;
UPDATE `bonk_weapon` SET `description` = 'Strikes the nearest enemy with a storm-charged blow, also hitting the enemies beside it.' WHERE `id` = 44;
UPDATE `bonk_weapon` SET `description` = 'Roots random enemies in place and damages them.' WHERE `id` = 49;
UPDATE `bonk_weapon` SET `description` = 'Fires shadow bolts that deal triple damage to enemies below 20% health.' WHERE `id` = 103;
UPDATE `bonk_weapon` SET `description` = 'Hurls lightning that jumps between up to 10 nearby enemies.' WHERE `id` = 104;
UPDATE `bonk_weapon` SET `description` = 'Calls down stars on the nearest enemies, dealing heavy damage.' WHERE `id` = 105;
UPDATE `bonk_weapon` SET `description` = 'Casts Thunder Clap, then a moment later sends out a shockwave that stuns all nearby enemies.' WHERE `id` = 106;
UPDATE `bonk_weapon` SET `description` = 'Engulfs the nearest enemies in holy flame, leaving them burning.' WHERE `id` = 109;
UPDATE `bonk_weapon` SET `description` = 'Calls down holy light that jumps between up to 50 nearby enemies.' WHERE `id` = 110;
UPDATE `bonk_weapon` SET `description` = 'Strikes the nearest enemy and cleaves the enemies beside it. Normal enemies below 20% health that it hits are killed instantly.' WHERE `id` = 130;
UPDATE `bonk_weapon` SET `description` = 'You spin nonstop, striking all nearby enemies as you move.' WHERE `id` = 131;
UPDATE `bonk_weapon` SET `description` = 'Wounds 3 nearby enemies, making them bleed. You heal for 10% of the bleed damage.' WHERE `id` = 132;
UPDATE `bonk_weapon` SET `description` = 'Smashes the strongest enemy in reach. It takes 20% more damage from all sources for 5 sec.' WHERE `id` = 133;
UPDATE `bonk_weapon` SET `description` = 'Strikes the nearest enemy in a rapid flurry, also hitting the enemies beside it.' WHERE `id` = 134;
UPDATE `bonk_weapon` SET `description` = 'Strikes the nearest enemy with fatal blows.' WHERE `id` = 136;
UPDATE `bonk_weapon` SET `description` = 'Strikes the nearest enemy with holy power, cleaving many enemies at once.' WHERE `id` = 139;
UPDATE `bonk_weapon` SET `description` = 'Fires blasts of holy power at the nearest enemies.' WHERE `id` = 140;
UPDATE `bonk_weapon` SET `description` = 'Fires blasts of shadow at the nearest enemies.' WHERE `id` = 142;
UPDATE `bonk_weapon` SET `description` = 'Strikes the nearest enemy with lightning-fast blows, also hitting the enemies beside it.' WHERE `id` = 144;
UPDATE `bonk_weapon` SET `description` = 'Launches 3 arcane missiles at the nearest enemies.' WHERE `id` = 160;
UPDATE `bonk_weapon` SET `description` = 'Calls down a pillar of fire on the largest group of enemies, leaving the ground burning.' WHERE `id` = 161;
UPDATE `bonk_weapon` SET `description` = 'Blasts the enemies in a cone in front of you with frost, slowing them.' WHERE `id` = 162;
UPDATE `bonk_weapon` SET `description` = 'Scorches the nearest enemy with a quick, short-range fire bolt. Each hit makes the target take more Fire damage.' WHERE `id` = 163;
UPDATE `bonk_weapon` SET `description` = 'Fires a stream of arcane missiles at the nearest enemies.' WHERE `id` = 172;
UPDATE `bonk_weapon` SET `description` = 'Calls down a Blizzard on the largest group of enemies. 3 sec later, every enemy inside freezes solid.' WHERE `id` = 174;
UPDATE `bonk_weapon` SET `description` = 'Releases an arcane pulse around you, then a second, wider one.' WHERE `id` = 175;
UPDATE `bonk_weapon` SET `description` = 'Casts Flamestrike, and a moment later a meteor crashes onto the same spot.' WHERE `id` = 176;
UPDATE `bonk_weapon` SET `description` = 'Blasts a cone of frost that freezes the enemies in front of you. Frozen enemies take 50% more critical strike damage.' WHERE `id` = 177;
UPDATE `bonk_weapon` SET `description` = 'Fires quick fire bolts. 3 sec after a hit, the target explodes in flames.' WHERE `id` = 178;
UPDATE `bonk_weapon` SET `description` = 'Shouts at all nearby enemies, reducing their damage by 20% for 6 sec.' WHERE `id` = 181;
UPDATE `bonk_weapon` SET `description` = 'Every 12 sec, you shout and gain 20% Power for 6 sec.' WHERE `id` = 182;
UPDATE `bonk_weapon` SET `description` = '+5% chance to dodge. When you dodge, you strike back at all nearby enemies.' WHERE `id` = 183;
UPDATE `bonk_weapon` SET `description` = 'Shouts at all nearby enemies, reducing their damage by 25% for 6 sec, and heals you for 3% of your maximum health.' WHERE `id` = 191;
UPDATE `bonk_weapon` SET `description` = 'Casts Battle Shout. While it lasts, every hit you deal is a critical strike.' WHERE `id` = 192;
UPDATE `bonk_weapon` SET `description` = 'Works like Revenge. For 5 sec after you dodge, you strike back at every enemy that hits you.' WHERE `id` = 193;
UPDATE `bonk_weapon` SET `description` = 'Strikes the legs of the nearest enemy, slowing it. Every third strike, you also howl, slowing all nearby enemies.' WHERE `id` = 194;
UPDATE `bonk_weapon` SET `description` = 'Fires a powerful shot that pierces every enemy in a line, aimed at the Marked group or else the largest group.' WHERE `id` = 203;
UPDATE `bonk_weapon` SET `description` = 'A spirit wolf fights for you. Every 15 sec it howls, and your other pets deal double damage to all enemies in front for 6 sec.' WHERE `id` = 211;

UPDATE `bonk_weapon` SET `description` = 'Ice shards pelt the largest group of enemies for 4 sec, slowing them.' WHERE `id` = 22;
UPDATE `bonk_weapon` SET `description` = 'Fire rains down on the largest group of enemies for 4 sec.' WHERE `id` = 23;
UPDATE `bonk_weapon` SET `description` = 'Stars rain down across a wide area on the largest group of enemies for 4 sec.' WHERE `id` = 24;
UPDATE `bonk_weapon` SET `description` = 'A storm cloud strikes the largest group of enemies, then keeps striking them with lightning for 4 sec.' WHERE `id` = 25;
UPDATE `bonk_weapon` SET `description` = 'Throws a cloud of poison onto the largest group of enemies. It lasts 8 sec and poisons every enemy inside twice per second.' WHERE `id` = 26;

UPDATE `bonk_weapon` SET `description` = 'Corrupts random enemies with Shadow damage over time. From rank 8, it spreads to nearby enemies when a corrupted enemy dies.' WHERE `id` = 18;
UPDATE `bonk_weapon` SET `description` = 'Burns random enemies with moonlight over time. From rank 8, it spreads to nearby enemies when an affected enemy dies.' WHERE `id` = 21;
UPDATE `bonk_weapon` SET `description` = 'Garrotes random nearby enemies, making them bleed. From rank 8, it spreads to nearby enemies when a bleeding enemy dies.' WHERE `id` = 35;
UPDATE `bonk_weapon` SET `description` = 'Afflicts random enemies with Shadow damage over time. From rank 8, it spreads to nearby enemies when an afflicted enemy dies.' WHERE `id` = 41;
UPDATE `bonk_weapon` SET `description` = 'Scorches random enemies and leaves them burning. From rank 8, the burn spreads to nearby enemies when a burning enemy dies.' WHERE `id` = 43;
UPDATE `bonk_weapon` SET `description` = 'Curses random enemies, damaging them over a long time. From rank 8, it spreads to nearby enemies when a cursed enemy dies.' WHERE `id` = 46;
UPDATE `bonk_weapon` SET `description` = 'Sends insects to bite random enemies over time. From rank 8, the swarm spreads to nearby enemies when an infested enemy dies.' WHERE `id` = 48;
UPDATE `bonk_weapon` SET `description` = 'Opens deep wounds on random enemies, making them bleed. The bleeding spreads to nearby enemies when a bleeding enemy dies.' WHERE `id` = 135;
UPDATE `bonk_weapon` SET `description` = 'Afflicts random enemies with Shadow damage over time. It spreads to nearby enemies when an afflicted enemy dies.' WHERE `id` = 141;
UPDATE `bonk_weapon` SET `description` = 'Scorches random enemies and leaves them burning. The burn spreads to nearby enemies when a burning enemy dies.' WHERE `id` = 143;
UPDATE `bonk_weapon` SET `description` = 'Corrupts random enemies, dealing Shadow damage over time. The Corruption spreads to nearby enemies when a corrupted enemy dies.' WHERE `id` = 146;
UPDATE `bonk_weapon` SET `description` = 'Curses random enemies with doom, damaging them over time. The curse spreads to nearby enemies when a cursed enemy dies.' WHERE `id` = 147;
UPDATE `bonk_weapon` SET `description` = 'Sends locusts at random enemies, damaging them over time. The swarm spreads to nearby enemies when an infested enemy dies.' WHERE `id` = 148;
UPDATE `bonk_weapon` SET `description` = 'Burns random enemies with moonlight, damaging them over time. It spreads to nearby enemies when an affected enemy dies.' WHERE `id` = 149;

UPDATE `bonk_glyph` SET `description` = 'When an elite, mini-boss or boss dies within 30 yards of you, you heal for 30% of your maximum health.' WHERE `id` = 5;
UPDATE `bonk_glyph` SET `description` = 'You capture Ley Lines twice as fast, and they offer 4 blessings to choose from.' WHERE `id` = 6;
UPDATE `bonk_glyph` SET `description` = 'Your spells have a 30% chance to cast twice.' WHERE `id` = 7;
UPDATE `bonk_glyph` SET `description` = 'Every 50 kills, gain 40% Haste for 8 sec.' WHERE `id` = 8;
UPDATE `bonk_glyph` SET `drawback` = 'Chests have a 10% chance to explode when opened, dealing 10% of your maximum health to you.' WHERE `id` = 9;
UPDATE `bonk_glyph` SET `description` = 'Every 50 kills, you deal triple damage for 2 sec.' WHERE `id` = 12;
UPDATE `bonk_glyph` SET `drawback` = 'Turkey legs and Restoration power-ups no longer appear.' WHERE `id` = 14;
UPDATE `bonk_glyph` SET `description` = 'Spell ranks offered at level-ups are 1 rarity higher.' WHERE `id` = 15;
UPDATE `bonk_glyph` SET `description` = 'Every 3 sec, lightning strikes up to 8 enemies near you. Every strike is a critical strike.' WHERE `id` = 16;
UPDATE `bonk_glyph` SET `description` = 'Every 6 sec, a meteor crashes into the largest group of enemies near you.' WHERE `id` = 17;

UPDATE `bonk_card` SET `description` = 'When you drop below 35% health, heal for 30% of your maximum health. 60 sec cooldown, 15% shorter for each additional copy.' WHERE `id` = 1;
UPDATE `bonk_card` SET `description` = 'Your critical strikes have a 25% chance to heal you for 1% of your maximum health (at most 2% per second).' WHERE `id` = 8;
UPDATE `bonk_card` SET `description` = 'Gain a Shield equal to 8% of your maximum health. When your Shield breaks, a fire nova scorches enemies within 8 yards.' WHERE `id` = 11;
UPDATE `bonk_card` SET `description` = 'Enemies that hit you take 50% of the damage they deal.' WHERE `id` = 12;
UPDATE `bonk_card` SET `description` = 'After you are hit, you are immune to damage for 0.5 sec. 8 sec cooldown, 15% shorter for each additional copy.' WHERE `id` = 13;
UPDATE `bonk_card` SET `description` = 'When you drop below 50% health, run 50% faster for 4 sec. 20 sec cooldown.' WHERE `id` = 14;
UPDATE `bonk_card` SET `description` = 'When you would die, you come back with 40% health instead. Works once for each copy.' WHERE `id` = 15;
UPDATE `bonk_card` SET `description` = 'Your spells have a 3% chance to cast twice.' WHERE `id` = 17;
UPDATE `bonk_card` SET `description` = 'Every 60 sec, gain 25% Power for 15 sec.' WHERE `id` = 21;
UPDATE `bonk_card` SET `description` = 'Every 120 sec, every experience orb on the ground flies to you. You can hold only 1.' WHERE `id` = 28;
UPDATE `bonk_card` SET `description` = 'Your hits have a 5% chance to unleash shadow, dealing 200% of the hit to enemies within 8 yards of the target and healing you for 10% of the damage dealt.' WHERE `id` = 102;
UPDATE `bonk_card` SET `description` = 'Your spells have a 10% chance to cast twice.' WHERE `id` = 104;
UPDATE `bonk_card` SET `description` = '+1 Count and +15% Area. Your spells fire 1 additional bolt, land 1 additional ground effect, cast again or affect 1 additional target, depending on the spell. Your area spells and melee attacks also reach farther.' WHERE `id` = 105;
UPDATE `bonk_card` SET `description` = 'Your critical strikes have a 50% chance to heal you for 1% of your maximum health (at most 3% per second).' WHERE `id` = 106;
UPDATE `bonk_card` SET `description` = 'Your spells have a 6% chance to cast twice.' WHERE `id` = 107;
UPDATE `bonk_card` SET `description` = '+60% pickup range, and power-ups stay on the ground twice as long.' WHERE `id` = 151;
UPDATE `bonk_card` SET `description` = 'Your spells have a 30% chance to cast twice.' WHERE `id` = 153;

UPDATE `item_template` SET `description` = 'Your hits have a 5% chance to unleash shadow, dealing 200% of the hit to enemies within 8 yards of the target and healing you for 10% of the damage dealt.' WHERE `entry` = 901421;
UPDATE `item_template` SET `description` = 'Your spells have a 10% chance to cast twice.' WHERE `entry` = 901423;
UPDATE `item_template` SET `description` = '+1 Count and +15% Area. Your spells fire 1 additional bolt, land 1 additional ground effect, cast again or affect 1 additional target, depending on the spell. Your area spells and melee attacks also reach farther.' WHERE `entry` = 901424;
UPDATE `item_template` SET `description` = 'Your critical strikes have a 50% chance to heal you for 1% of your maximum health (at most 3% per second).' WHERE `entry` = 901425;
UPDATE `item_template` SET `description` = 'Your spells have a 6% chance to cast twice.' WHERE `entry` = 901426;

UPDATE `item_template` SET `description` = 'Found during a run. Put it in the Extraction Vault to keep it.' WHERE `entry` BETWEEN 900300 AND 900437 AND `description` = 'Run gear: put it in the Extraction Vault to keep it.';
UPDATE `item_template` SET `description` = 'Opens a ring at your feet. Stand in it for 10 sec to go home with your loot. Disappears when the run ends.' WHERE `entry` = 900230;

UPDATE `bonk_passive` SET `description` = '+8% Haste. You attack and dots tick 8% more often.' WHERE `id` = 2;
UPDATE `bonk_passive` SET `description` = '+10% Area. Your area spells cover more ground and your melee attacks reach farther.' WHERE `id` = 11;
UPDATE `bonk_passive` SET `description` = '+10 Armor. Enemies deal less damage to you.' WHERE `id` = 13;
UPDATE `bonk_passive` SET `description` = 'Gain a Shield equal to 10% of your maximum health.' WHERE `id` = 17;
UPDATE `bonk_passive` SET `description` = '+5 Luck. Chests and level-ups offer rarer choices.' WHERE `id` = 18;
UPDATE `bonk_passive` SET `description` = '+1 Count. Your spells fire 1 additional bolt, land 1 additional ground effect, cast again or affect 1 additional target.' WHERE `id` = 19;
UPDATE `bonk_passive` SET `description` = 'Your hits have a 10% chance to heal you for 1% of your maximum health (at most 3% per second).' WHERE `id` = 20;

UPDATE `bonk_item_set_bonus` SET `description` = '+12.5 Armor. Regain 1% of your health every second.' WHERE `set_id` = 1 AND `pieces` = 4;
UPDATE `bonk_item_set_bonus` SET `description` = '+15% Power, and your hits have a 3% chance to heal you for 1% of your maximum health.' WHERE `set_id` = 2 AND `pieces` = 4;
UPDATE `bonk_item_set_bonus` SET `description` = '+18.75 Armor. Regain 1.5% of your health every second.' WHERE `set_id` = 3 AND `pieces` = 4;
UPDATE `bonk_item_set_bonus` SET `description` = '+22.5% Power, and your hits have a 4.5% chance to heal you for 1% of your maximum health.' WHERE `set_id` = 4 AND `pieces` = 4;
UPDATE `bonk_item_set_bonus` SET `description` = '+28.1 Armor. Regain 2.25% of your health every second.' WHERE `set_id` = 5 AND `pieces` = 4;
UPDATE `bonk_item_set_bonus` SET `description` = '+33.75% Power, and your hits have a 6.75% chance to heal you for 1% of your maximum health.' WHERE `set_id` = 6 AND `pieces` = 4;

UPDATE `bonk_upgrade` SET `description` = '+3 Luck. Chests and level-ups offer rarer choices.' WHERE `id` = 15;
UPDATE `bonk_upgrade` SET `description` = '+0.8 yards of dash distance.' WHERE `id` = 16;
UPDATE `bonk_upgrade` SET `description` = '-4% Valor cost for chests and the wandering vendor''s wares.' WHERE `id` = 19;
UPDATE `bonk_upgrade` SET `description` = 'Chests offer 1 additional Darkmoon Card to choose from.' WHERE `id` = 21;
UPDATE `bonk_upgrade` SET `description` = 'Level-ups offer 1 additional choice.' WHERE `id` = 22;
UPDATE `bonk_upgrade` SET `description` = '+2 sec to catch a treasure goblin, kill a bounty or finish other timed events. Fleeing targets also wait longer to run.' WHERE `id` = 23;
UPDATE `bonk_upgrade` SET `description` = '+8% Ley Line capture speed and +8% Moonwell duration.' WHERE `id` = 24;
UPDATE `bonk_upgrade` SET `description` = '+20% chance to find a Hearthstone. Each rank also cuts 1 sec from the time you must stand in its ring.' WHERE `id` = 25;
UPDATE `bonk_upgrade` SET `description` = '+1 starting level in runs. Each extra level brings its level-up choice.' WHERE `id` = 26;
UPDATE `bonk_upgrade` SET `description` = 'Runs start with a random common Darkmoon Card (uncommon at rank 2).' WHERE `id` = 27;
UPDATE `bonk_upgrade` SET `description` = 'Adds a second slot to the Extraction Vault, so you can bring 1 additional piece of run gear home.' WHERE `id` = 28;
UPDATE `bonk_upgrade` SET `description` = '+1 Darkmoon Card or Glyph you can switch off in the Spellbook. Runs never offer what you switch off.' WHERE `id` = 29;
UPDATE `bonk_upgrade` SET `description` = 'Choose a Glyph at the start of every run, on top of the ones mini-bosses and bosses give.' WHERE `id` = 30;

UPDATE `bonk_talent` SET `description` = 'Reroll the choices you are offered, once per run.' WHERE `id` = 5;
UPDATE `bonk_talent` SET `description` = 'Banish one of the choices you are offered, once per run. It won''t be offered again that run.' WHERE `id` = 6;
UPDATE `bonk_talent` SET `description` = 'Once per run, when you would die, you come back with 50% health.' WHERE `id` = 7;
UPDATE `bonk_talent` SET `description` = 'Skip a choice you are offered, once per run, and take a quarter of a chest''s price in Valor instead.' WHERE `id` = 9;
UPDATE `bonk_talent` SET `description` = '+1 passive slot in runs. You start with 3.' WHERE `id` = 10;
UPDATE `bonk_talent` SET `description` = '+1 spell slot in runs. You start with 3.' WHERE `id` = 11;

UPDATE `bonk_mastery` SET `description` = 'Rend affects 1 additional target.' WHERE `id` = 10108;
UPDATE `bonk_mastery` SET `description` = 'Mortal Strike affects 1 additional target.' WHERE `id` = 10208;
UPDATE `bonk_mastery` SET `description` = 'Holy Shock affects 1 additional target.' WHERE `id` = 20108;
UPDATE `bonk_mastery` SET `description` = 'Crusader Strike affects 1 additional target.' WHERE `id` = 20308;
UPDATE `bonk_mastery` SET `description` = 'Call Pet summons 1 additional beast.' WHERE `id` = 30108;
UPDATE `bonk_mastery` SET `description` = 'Arcane Shot affects 1 additional target.' WHERE `id` = 30208;
UPDATE `bonk_mastery` SET `description` = 'Serpent Sting affects 1 additional target.' WHERE `id` = 30308;
UPDATE `bonk_mastery` SET `description` = 'Garrote affects 1 additional target.' WHERE `id` = 40108;
UPDATE `bonk_mastery` SET `description` = 'Throwing Knives affects 1 additional target.' WHERE `id` = 40208;
UPDATE `bonk_mastery` SET `description` = 'Sinister Strike affects 1 additional target.' WHERE `id` = 40308;
UPDATE `bonk_mastery` SET `description` = 'Smite affects 1 additional target.' WHERE `id` = 50208;
UPDATE `bonk_mastery` SET `description` = 'Shadow Word: Pain affects 1 additional target.' WHERE `id` = 50308;
UPDATE `bonk_mastery` SET `description` = 'Lightning Bolt affects 1 additional target.' WHERE `id` = 70108;
UPDATE `bonk_mastery` SET `description` = 'Fireball affects 1 additional target.' WHERE `id` = 80208;
UPDATE `bonk_mastery` SET `description` = 'Frostbolt affects 1 additional target.' WHERE `id` = 80308;
UPDATE `bonk_mastery` SET `description` = 'Corruption affects 1 additional target.' WHERE `id` = 90108;
UPDATE `bonk_mastery` SET `description` = 'Shadow Bolt affects 1 additional target.' WHERE `id` = 90308;
UPDATE `bonk_mastery` SET `description` = 'Wrath affects 1 additional target.' WHERE `id` = 110108;
UPDATE `bonk_mastery` SET `description` = 'Insect Swarm affects 1 additional target.' WHERE `id` = 110308;

UPDATE `bonk_mastery` SET `description` = 'Your spells have a 10% chance to reset their cooldown when cast.' WHERE `id` IN (10209, 30109, 40209, 50109, 70109, 80109, 110109);

UPDATE `bonk_mastery` SET `description` = 'Once a quest unlocks Serpent Sting, start every run with it.' WHERE `id` = 30306;
UPDATE `bonk_mastery` SET `description` = 'Once a quest unlocks Poison Cloud, start every run with it.' WHERE `id` = 40106;
UPDATE `bonk_mastery` SET `description` = 'Once a quest unlocks Starfall, start every run with it.' WHERE `id` = 50106;
UPDATE `bonk_mastery` SET `description` = 'Once a quest unlocks Chain Lightning, start every run with it.' WHERE `id` = 70106;
UPDATE `bonk_mastery` SET `description` = 'Once a quest unlocks Frost Nova, start every run with it.' WHERE `id` = 80306;
UPDATE `bonk_mastery` SET `description` = 'Once a quest unlocks Searing Pain, start every run with it.' WHERE `id` = 90306;
UPDATE `bonk_mastery` SET `description` = 'Once a quest unlocks Entangling Roots, start every run with it.' WHERE `id` = 110206;

UPDATE `bonk_mastery` SET `description` = 'Killing an enemy with a Holy spell heals you for 0.5% of your maximum health (at most 3% per second).' WHERE `id` IN (20109, 50209);
UPDATE `bonk_mastery` SET `description` = 'Killing an enemy with a Nature spell heals you for 0.5% of your maximum health (at most 3% per second).' WHERE `id` IN (30309, 70309, 110309);
UPDATE `bonk_mastery` SET `description` = 'Killing an enemy with a Shadow spell heals you for 0.5% of your maximum health (at most 3% per second).' WHERE `id` IN (50309, 90109);

UPDATE `bonk_mastery` SET `description` = '+0.5% chance for your hits to heal you for 1% of your maximum health.' WHERE `id` IN (20107, 70308);

UPDATE `bonk_mastery` SET `description` = 'Regain 0.1% of your health every second.' WHERE `id` IN (10203, 20102, 50102, 50207, 70302, 80107, 90107, 90202, 110302);
UPDATE `bonk_mastery` SET `description` = '+5% Area.' WHERE `id` IN (10308, 20208, 50108, 70208, 90208);
UPDATE `bonk_mastery` SET `description` = '+4% Area.' WHERE `id` IN (80105, 80307, 90303, 110103);
UPDATE `bonk_mastery` SET `description` = '+30% damage to enemies above 80% health.' WHERE `id` IN (20309, 30209, 40309, 70209);
UPDATE `bonk_mastery` SET `description` = '+30% Fire damage to enemies above 80% health.' WHERE `id` = 80209;
UPDATE `bonk_mastery` SET `description` = 'Your spells recharge 2% faster.' WHERE `id` IN (30102, 30207, 40304, 50104, 70303, 80102, 110205);
UPDATE `bonk_mastery` SET `description` = 'Your spells last 5% longer.' WHERE `id` IN (40107, 50307, 70307, 90103, 110307);
UPDATE `bonk_mastery` SET `description` = 'Reduces the cooldown of Throwing Knives by 6%.' WHERE `id` = 40204;
UPDATE `bonk_mastery` SET `description` = 'Reduces the cooldown of Entangling Roots by 6%.' WHERE `id` = 110304;
UPDATE `bonk_mastery` SET `description` = '+10% pickup range for experience orbs and turkey legs.' WHERE `id` = 30203;

UPDATE `bonk_mastery` SET `description` = '+2% Physical damage.' WHERE `id` IN (10202, 20302, 40202, 70202);
UPDATE `bonk_mastery` SET `description` = '+2% Holy damage.' WHERE `id` IN (20101, 50202);
UPDATE `bonk_mastery` SET `description` = '+2% Physical and Arcane damage.' WHERE `id` = 30202;
UPDATE `bonk_mastery` SET `description` = '+2% Nature damage.' WHERE `id` IN (30307, 70102);
UPDATE `bonk_mastery` SET `description` = '+2% Shadow damage.' WHERE `id` IN (50302, 90102);
UPDATE `bonk_mastery` SET `description` = '+2% Fire damage.' WHERE `id` IN (80202, 90302);
UPDATE `bonk_mastery` SET `description` = '+2% Frost damage.' WHERE `id` = 80302;
UPDATE `bonk_mastery` SET `description` = '+2% Nature and Arcane damage.' WHERE `id` = 110102;

UPDATE `bonk_quest` SET `description` = 'Win a run on Mythic.' WHERE `id` = 9;
UPDATE `bonk_quest` SET `description` = 'Win a run on Heroic.' WHERE `id` = 14;
UPDATE `bonk_quest` SET `description` = 'Win a run on Heroic.' WHERE `id` = 51;
UPDATE `bonk_quest` SET `description` = 'Win a run on Mythic.' WHERE `id` = 407;
UPDATE `bonk_quest` SET `description` = 'Win a run on Normal as a mage.' WHERE `id` = 101;
UPDATE `bonk_quest` SET `description` = 'Win a run on Heroic as a mage.' WHERE `id` = 109;
UPDATE `bonk_quest` SET `description` = 'Win a run on Normal as a warlock.' WHERE `id` = 111;
UPDATE `bonk_quest` SET `description` = 'Win a run on Heroic as a warlock.' WHERE `id` = 119;
UPDATE `bonk_quest` SET `description` = 'Win a run on Normal as a warrior.' WHERE `id` = 121;
UPDATE `bonk_quest` SET `description` = 'Win a run on Heroic as a warrior.' WHERE `id` = 129;
UPDATE `bonk_quest` SET `description` = 'Win a run on Normal as a paladin.' WHERE `id` = 131;
UPDATE `bonk_quest` SET `description` = 'Win a run on Heroic as a paladin.' WHERE `id` = 139;
UPDATE `bonk_quest` SET `description` = 'Win a run on Normal as a hunter.' WHERE `id` = 141;
UPDATE `bonk_quest` SET `description` = 'Win a run on Heroic as a hunter.' WHERE `id` = 149;
UPDATE `bonk_quest` SET `description` = 'Win a run on Normal as a rogue.' WHERE `id` = 151;
UPDATE `bonk_quest` SET `description` = 'Win a run on Heroic as a rogue.' WHERE `id` = 159;
UPDATE `bonk_quest` SET `description` = 'Win a run on Normal as a priest.' WHERE `id` = 161;
UPDATE `bonk_quest` SET `description` = 'Win a run on Heroic as a priest.' WHERE `id` = 169;
UPDATE `bonk_quest` SET `description` = 'Win a run on Normal as a shaman.' WHERE `id` = 171;
UPDATE `bonk_quest` SET `description` = 'Win a run on Heroic as a shaman.' WHERE `id` = 179;
UPDATE `bonk_quest` SET `description` = 'Win a run on Normal as a druid.' WHERE `id` = 181;
UPDATE `bonk_quest` SET `description` = 'Win a run on Heroic as a druid.' WHERE `id` = 189;
UPDATE `bonk_quest` SET `description` = 'Heal 30,000 health across all your runs.' WHERE `id` = 201;
UPDATE `bonk_quest` SET `description` = 'Clear stage 1 with a warrior, a hunter and a mage.' WHERE `id` = 203;
UPDATE `bonk_quest` SET `description` = 'Reach Mastery level 10 with a warrior.' WHERE `id` = 204;
UPDATE `bonk_quest` SET `description` = 'Reach Mastery level 10 with a hunter.' WHERE `id` = 205;
UPDATE `bonk_quest` SET `description` = 'Reach Mastery level 10 with a mage.' WHERE `id` = 206;
UPDATE `bonk_quest` SET `description` = 'Kill a stage boss before the clock reaches 5:00; a Summoning Stone can call it early.' WHERE `id` = 207;
UPDATE `bonk_quest` SET `description` = 'Kill 40,000 enemies as a warrior.' WHERE `id` = 212;
UPDATE `bonk_quest` SET `description` = 'Kill 40,000 enemies as a paladin.' WHERE `id` = 213;
UPDATE `bonk_quest` SET `description` = 'Kill 40,000 enemies as a hunter.' WHERE `id` = 214;
UPDATE `bonk_quest` SET `description` = 'Kill 40,000 enemies as a rogue.' WHERE `id` = 215;
UPDATE `bonk_quest` SET `description` = 'Kill 40,000 enemies as a priest.' WHERE `id` = 216;
UPDATE `bonk_quest` SET `description` = 'Kill 40,000 enemies as a shaman.' WHERE `id` = 217;
UPDATE `bonk_quest` SET `description` = 'Kill 40,000 enemies as a mage.' WHERE `id` = 218;
UPDATE `bonk_quest` SET `description` = 'Kill 40,000 enemies as a warlock.' WHERE `id` = 219;
UPDATE `bonk_quest` SET `description` = 'Kill 40,000 enemies as a druid.' WHERE `id` = 220;
UPDATE `bonk_quest` SET `description` = 'Kill 10,000 enemies with Fire spells.' WHERE `id` = 221;
UPDATE `bonk_quest` SET `description` = 'Kill 10,000 enemies with Frost spells.' WHERE `id` = 222;
UPDATE `bonk_quest` SET `description` = 'Kill 10,000 enemies with Nature spells.' WHERE `id` = 223;
UPDATE `bonk_quest` SET `description` = 'Kill 10,000 enemies with Shadow spells.' WHERE `id` = 224;
UPDATE `bonk_quest` SET `description` = 'Kill 10,000 enemies with Arcane spells.' WHERE `id` = 225;
UPDATE `bonk_quest` SET `description` = 'Kill 10,000 enemies with Holy spells.' WHERE `id` = 226;
UPDATE `bonk_quest` SET `description` = 'Kill 10,000 enemies with physical attacks.' WHERE `id` = 227;
UPDATE `bonk_quest` SET `description` = 'Kill 1,500 enemies while standing still.' WHERE `id` = 228;
UPDATE `bonk_quest` SET `description` = 'Kill a stage boss without taking a hit after it arrives.' WHERE `id` = 235;
UPDATE `bonk_quest` SET `description` = 'Go 3 minutes without being hit during a run.' WHERE `id` = 237;
UPDATE `bonk_quest` SET `description` = 'Heal 15,000 health with on-hit healing, such as Vampiric Embrace.' WHERE `id` = 241;
UPDATE `bonk_quest` SET `description` = 'Prevent 15,000 damage with Armor.' WHERE `id` = 243;
UPDATE `bonk_quest` SET `description` = 'Buy 20 items from the wandering vendor.' WHERE `id` = 245;
UPDATE `bonk_quest` SET `description` = 'Clear a stage with 2 Dark Fortunes active.' WHERE `id` = 253;
UPDATE `bonk_quest` SET `description` = 'Heal 25,000 health across all your runs.' WHERE `id` = 300;
UPDATE `bonk_quest` SET `description` = 'Kill 1,500 enemies while standing still.' WHERE `id` = 302;
UPDATE `bonk_quest` SET `description` = 'Heal 100,000 health across all your runs.' WHERE `id` = 304;
UPDATE `bonk_quest` SET `description` = 'Prevent 20,000 damage with Armor.' WHERE `id` = 305;
UPDATE `bonk_quest` SET `description` = 'Go 4 minutes without being hit during a run.' WHERE `id` = 306;
UPDATE `bonk_quest` SET `description` = 'Kill 15,000 enemies with Fire spells.' WHERE `id` = 308;
UPDATE `bonk_quest` SET `description` = 'Kill 10,000 enemies with Nature spells.' WHERE `id` = 310;
UPDATE `bonk_quest` SET `description` = 'Kill 10,000 enemies with physical attacks.' WHERE `id` = 315;
UPDATE `bonk_quest` SET `description` = 'Find Hogger hiding during a Westfall run and defeat him.' WHERE `id` = 500;
UPDATE `bonk_quest` SET `description` = 'Find Old Murk-Eye in his camp during a Westfall run and defeat him.' WHERE `id` = 501;

UPDATE `bonk_tier` SET `description` = 'One stage in wide-open lands. Beat its boss to win the run.' WHERE `id` = 1;
UPDATE `bonk_tier` SET `description` = 'Three stages against the deadliest foes, then Endless mode for those who dare.' WHERE `id` = 2;
UPDATE `bonk_tier` SET `description` = 'Two stages in rougher lands, with tougher foes, better loot and more Darkmoon Tickets.' WHERE `id` = 3;

UPDATE `bonk_wave` SET `name` = 'Brute Wave' WHERE `start_sec` = 240;
UPDATE `bonk_wave` SET `name` = 'The Swarm' WHERE `start_sec` = 420;

UPDATE `bonk_shop_tree` SET `name` = 'Prosperity' WHERE `id` = 2;

UPDATE `broadcast_text` SET `male_text` = 'Back already, $n? Pick a difficulty and I''ll send you in. Each stage is harder than the last.$B$BWin or lose, you wake up right here.', `female_text` = 'Back already, $n? Pick a difficulty and I''ll send you in. Each stage is harder than the last.$B$BWin or lose, you wake up right here.' WHERE `entry` = 900001;
UPDATE `broadcast_text` SET `male_text` = 'Care to hear your fortune, $n? Each reading costs a Darkmoon Ticket or two. A bright Fortune makes the road kinder; a Dark Fortune makes it harder, but pays better. Tickets are rare out there, though elites and bosses carry more of them.', `female_text` = 'Care to hear your fortune, $n? Each reading costs a Darkmoon Ticket or two. A bright Fortune makes the road kinder; a Dark Fortune makes it harder, but pays better. Tickets are rare out there, though elites and bosses carry more of them.' WHERE `entry` = 900004;
UPDATE `broadcast_text` SET `male_text` = 'Every hero who makes it back has a story. Finish a task on my board and I''ll see that you''re rewarded. Some of what I hand out can''t be found anywhere else.', `female_text` = 'Every hero who makes it back has a story. Finish a task on my board and I''ll see that you''re rewarded. Some of what I hand out can''t be found anywhere else.' WHERE `entry` = 900005;
UPDATE `broadcast_text` SET `male_text` = 'Every spell a hero can learn out there is written in here: how it grows, what it becomes, and what you must do before it will answer you.', `female_text` = 'Every spell a hero can learn out there is written in here: how it grows, what it becomes, and what you must do before it will answer you.' WHERE `entry` = 900006;
UPDATE `broadcast_text` SET `male_text` = 'Every class walks its own road, $n. Bring me what your runs have taught you, and I will shape it into talents for this class, and this class alone.', `female_text` = 'Every class walks its own road, $n. Bring me what your runs have taught you, and I will shape it into talents for this class, and this class alone.' WHERE `entry` = 900008;
UPDATE `broadcast_text` SET `male_text` = 'The Extraction Vault is empty. Go home anyway? Everything you found will be sold for gold.', `female_text` = 'The Extraction Vault is empty. Go home anyway? Everything you found will be sold for gold.' WHERE `entry` = 900010;
UPDATE `broadcast_text` SET `male_text` = 'This is Bixi''s vault. Whatever you leave inside will be waiting in your mailbox when you get home; everything else you found is sold.', `female_text` = 'This is Bixi''s vault. Whatever you leave inside will be waiting in your mailbox when you get home; everything else you found is sold.' WHERE `entry` = 900011;

UPDATE `creature_template` SET `subname` = 'Upgrade Vendor' WHERE `entry` = 900002;
UPDATE `creature_template` SET `subname` = 'Gear Vendor' WHERE `entry` = 900004;
UPDATE `creature_template` SET `subname` = 'Quest Giver' WHERE `entry` = 900005;
UPDATE `creature_template` SET `subname` = 'Spellbook Keeper' WHERE `entry` = 900006;

UPDATE `gameobject_template` SET `name` = 'Loot Sack' WHERE `entry` = 900040;

UPDATE `spell_template` SET `auraDescription` = 'Explodes when it reaches you.' WHERE `entry` = 33400;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
