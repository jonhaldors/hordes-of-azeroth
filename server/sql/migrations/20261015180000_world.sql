DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261015180000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261015180000');

DELETE FROM `bonk_quest` WHERE `id` BETWEEN 212 AND 255;
INSERT INTO `bonk_quest` (`id`, `name`, `description`, `icon`, `type`, `target`, `param`, `amount`, `reward_type`, `reward_value`, `class`, `category`) VALUES
(212, 'Bloodied Blade', 'Slay 15,000 enemies as a Warrior.', 'Ability_Warrior_BattleShout', 0, 0, 0, 15000, 1, 5, 1,  0),
(213, 'Crusader',       'Slay 15,000 enemies as a Paladin.', 'Spell_Holy_SealOfMight',      0, 0, 0, 15000, 1, 5, 2,  0),
(214, 'Huntmaster',     'Slay 15,000 enemies as a Hunter.',  'INV_Weapon_Bow_02',           0, 0, 0, 15000, 1, 5, 3,  0),
(215, 'Cutthroat',      'Slay 15,000 enemies as a Rogue.',   'Ability_BackStab',            0, 0, 0, 15000, 1, 5, 4,  0),
(216, 'Zealot',         'Slay 15,000 enemies as a Priest.',  'Spell_Holy_HolySmite',        0, 0, 0, 15000, 1, 5, 5,  0),
(217, 'Earthbreaker',   'Slay 15,000 enemies as a Shaman.',  'Spell_Nature_BloodLust',      0, 0, 0, 15000, 1, 5, 7,  0),
(218, 'Battlemage',     'Slay 15,000 enemies as a Mage.',    'Spell_Fire_FireBolt02',       0, 0, 0, 15000, 1, 5, 8,  0),
(219, 'Doombringer',    'Slay 15,000 enemies as a Warlock.', 'Spell_Shadow_DeathCoil',      0, 0, 0, 15000, 1, 5, 9,  0),
(220, 'Feral Fury',     'Slay 15,000 enemies as a Druid.',   'Ability_Druid_Maul',          0, 0, 0, 15000, 1, 5, 11, 0),
(221, 'Pyromancer',     'Slay 4,000 enemies with Fire spells.',     'Spell_Fire_FlameBolt',     18, 3, 0, 4000, 1, 3, 0, 0),
(222, 'Frostbinder',    'Slay 4,000 enemies with Frost spells.',    'Spell_Frost_FrostBolt02',  18, 5, 0, 4000, 1, 3, 0, 0),
(223, 'Stormcaller',    'Slay 3,000 enemies with Nature spells.',   'Spell_Nature_Lightning',   18, 4, 0, 3000, 1, 3, 0, 0),
(224, 'Shadowmonger',   'Slay 3,000 enemies with Shadow spells.',   'Spell_Shadow_ShadowBolt',  18, 6, 0, 3000, 1, 3, 0, 0),
(225, 'Arcanist',       'Slay 3,000 enemies with Arcane spells.',   'Spell_Arcane_StarFire',    18, 7, 0, 3000, 1, 3, 0, 0),
(226, 'Lightbringer',   'Slay 3,000 enemies with Holy spells.',     'Spell_Holy_SearingLight',  18, 2, 0, 3000, 1, 3, 0, 0),
(227, 'Weaponmaster',   'Slay 4,000 enemies with physical attacks.', 'INV_Sword_27',            18, 1, 0, 4000, 1, 3, 0, 0),
(228, 'Stand Your Ground', 'Slay 500 enemies while standing still.', 'Ability_Warrior_DefensiveStance', 19, 0, 0, 500, 1, 2, 0, 3),
(229, 'Specialist',     'Raise any passive to rank 5 in one run.',  'INV_Misc_Book_11',        20, 0, 0, 5,    0, 2500, 0, 3),
(230, 'Adept',          'Raise a spell to rank 10 in one run.',     'INV_Misc_Book_07',        21, 0, 0, 10,   1, 1, 0, 3),
(231, 'Master of One',  'Raise a spell to rank 20 in one run.',     'INV_Misc_Book_06',        21, 0, 0, 20,   1, 3, 0, 3),
(232, 'Juggernaut',     'Reach 1,000 maximum health in a run.',     'Spell_Holy_WordFortitude', 22, 0, 0, 1000, 1, 2, 0, 3),
(233, 'Quick Draw',     'Kill a mini-boss within 25 seconds of its arrival.', 'INV_Misc_PocketWatch_01', 23, 3, 25, 1, 1, 2, 0, 3),
(234, 'Boss Buster',    'Kill a stage boss within 30 seconds of its arrival.', 'Ability_Warrior_Charge', 23, 2, 30, 1, 1, 5, 0, 3),
(235, 'Untouchable',    'Kill a stage boss without being hit since it arrived.', 'Spell_Holy_DivineIntervention', 24, 2, 0, 1, 1, 5, 0, 3),
(236, 'Close Call',     'Kill a stage boss with under 10% of your health left.', 'Spell_Holy_SealOfSacrifice', 25, 2, 10, 1, 1, 3, 0, 3),
(237, 'Ghost Walk',     'Go 2 minutes without being hit in a run.',  'Spell_Nature_Invisibilty', 26, 0, 0, 120, 1, 3, 0, 3),
(238, 'Overtime',       'Survive 1 minute of overtime.',  'Spell_Shadow_AnimateDead', 27, 0, 0, 60,  1, 2,  0, 3),
(239, 'Undying',        'Survive 2 minutes of overtime.', 'Spell_Shadow_RaiseDead',   27, 0, 0, 120, 1, 4,  0, 3),
(240, 'Deathless',      'Survive 6 minutes of overtime.', 'Spell_Holy_Resurrection',  27, 0, 0, 360, 1, 10, 0, 3),
(241, 'Bloodthirsty',   'Heal 5,000 health with Vampiric Embrace.', 'Spell_Shadow_LifeDrain02', 28, 0, 0, 5000, 1, 3, 0, 5),
(242, 'Slippery',       'Dodge 500 enemy attacks.',                 'Ability_Rogue_Feint',      29, 0, 0, 500,  1, 2, 0, 5),
(243, 'Ironclad',       'Let Armor stop 5,000 damage.',             'Spell_Holy_DevotionAura',  30, 0, 0, 5000, 1, 2, 0, 5),
(244, 'Treasure Hunter', 'Buy 25 chests.',                          'INV_Box_02',               31, 0, 0, 25, 1, 3, 0, 5),
(245, 'Valued Customer', 'Buy 10 things from the wandering vendor.', 'INV_Misc_Bag_10',         32, 0, 0, 10, 1, 2, 0, 5),
(246, 'Goblin Snatcher', 'Catch 5 treasure goblins.',               'INV_Misc_Coin_01',         33, 1, 0, 5,  1, 2, 0, 5),
(247, 'Bounty Hunter',   'Claim 5 bounties.',                       'INV_Misc_Bone_HumanSkull_01', 33, 2, 0, 5, 1, 2, 0, 5),
(248, 'Smitten',         'Defeat Mr. Smite 3 times.',              'INV_Hammer_09',             34, 646,   0, 3, 1, 2, 0, 0),
(249, 'Stitched Up',     'Defeat Stitches 3 times.',               'Spell_Shadow_AbominationExplosion', 34, 412, 0, 3, 1, 3, 0, 0),
(250, 'Razor Burn',      'Defeat Charlga Razorflank 3 times.',     'INV_Misc_Head_Quillboar_01', 34, 4421,  0, 3, 1, 3, 0, 0),
(251, 'Hound Master',    'Defeat Magmadar 3 times.',               'Spell_Fire_Fire',           34, 11982, 0, 3, 1, 4, 0, 0),
(252, 'King of the Crater', 'Defeat King Mosh 3 times.',           'Ability_Hunter_Pet_Raptor', 34, 6584, 0, 3, 1, 4, 0, 0),
(253, 'Glutton for Punishment', 'Clear a stage with 2 Dark Fortunes on.', 'Spell_Shadow_GatherShadows', 35, 0, 0, 2, 1, 4, 0, 3),
(254, 'Volley',          'Fire 5,000 bolts.',                      'INV_Ammo_Arrow_02',         36, 0, 0, 5000, 1, 2, 0, 5),
(255, 'Spirit Healer''s Regular', 'Die 10 times.',                 'Spell_Shadow_DeathScream',  37, 0, 0, 10, 0, 5000, 0, 5);

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
