DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261027730000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261027730000');

UPDATE `bonk_passive` SET `max_rank` = 0 WHERE `id` <> 19;
UPDATE `bonk_passive` SET `excludes` = 0;

DELETE FROM `bonk_glyph` WHERE `id` IN (1, 3, 4, 9, 10, 14, 26);
DELETE FROM `bonk_card` WHERE `id` IN (150, 152, 154, 155, 156);

UPDATE `bonk_glyph` SET `description` = 'Capture Ley Lines twice as fast. They offer 4 blessings to choose from instead of 3.' WHERE `id` = 6;
UPDATE `bonk_glyph` SET `value2` = 5,
    `description` = 'Fatal damage restores you to full health instead. Once per run, or once every 5 floors on Mythic.' WHERE `id` = 11;
UPDATE `bonk_glyph` SET `description` = 'Level-up spell ranks, chest cards and Glyph offers are 1 rarity higher.',
    `drawback` = 'Level-ups offer 2 choices.' WHERE `id` = 15;
UPDATE `bonk_glyph` SET `value1` = 120000, `description` = 'A chest appears near you every 2 minutes.' WHERE `id` = 20;
UPDATE `bonk_glyph` SET `value2` = 25, `description` = 'Your starter spell starts 2 ranks higher and deals 25% more damage.' WHERE `id` = 22;
UPDATE `bonk_glyph` SET `description` = 'Whenever mini-bosses appear, 1 more comes. Mini-bosses give double rewards.',
    `drawback` = 'Mini-bosses deal 25% more damage.' WHERE `id` = 23;
UPDATE `bonk_glyph` SET `value1` = 50, `description` = 'Below 50% health, +40% Haste and +20% movement speed.' WHERE `id` = 25;

INSERT INTO `bonk_glyph` (`id`, `name`, `icon`, `description`, `drawback`, `rarity`, `effect`, `value1`, `value2`, `value3`, `card_id`, `starter`) VALUES
(28, 'Glyph of Divination', 'Spell_Holy_MindVision', 'Level-ups offer 1 more choice.', '', 0, 25, 1, 0, 0, 0, 0),
(29, 'Glyph of Frost Nova', 'Spell_Frost_FrostNova', 'When an enemy hits you, freeze normal enemies within 10 yards for 2 sec. 15 sec cooldown.', '', 1, 26, 10, 15000, 0, 0, 0),
(30, 'Glyph of Vanish', 'Ability_Vanish', 'Dashing makes you immune for 1 sec after, and your next spell critically strikes.', '', 1, 27, 1000, 0, 0, 0, 0),
(31, 'Glyph of Corpse Explosion', 'Spell_Shadow_CorpseExplode', 'Enemies you kill have a 15% chance to explode for 40% of their health to enemies within 6 yards.', '', 2, 28, 15, 40, 6, 0, 0),
(32, 'Glyph of Execute', 'INV_Sword_48', 'Normal enemies below 15% health die instantly. Elites, mini-bosses and bosses below 30% health take 25% more damage.', '', 2, 29, 15, 30, 25, 0, 0),
(33, 'Glyph of Cleave', 'Ability_Warrior_Cleave', 'Damage beyond a killing blow strikes the nearest enemy within 10 yards.', '', 2, 30, 10, 0, 0, 0, 0),
(34, 'Glyph of Multi-Shot', 'Ability_UpgradeMoonGlaive', 'Your spells fire 1 additional bolt.', 'Your spells deal 15% less damage.', 2, 31, 1, 15, 0, 0, 0),
(35, 'Glyph of Echoes', 'Spell_Nature_Purge', 'Spell rank picks have a 25% chance to give 1 extra rank.', '', 2, 32, 25, 0, 0, 0, 0),
(36, 'Glyph of Ignite', 'Spell_Fire_Incinerate', 'Critical strikes apply 2 stacks of Burning.', '', 3, 33, 2, 0, 0, 0, 0),
(37, 'Glyph of Soul Siphon', 'Spell_Shadow_LifeDrain02', '+1% Power for every 500 kills.', '', 3, 34, 500, 1, 0, 0, 0),
(38, 'Glyph of Shadowmourne', 'Spell_Shadow_SoulGem', 'Every 50 kills, the souls you gathered strike all enemies within 20 yards for 5 times a normal enemy''s health.', '', 4, 35, 50, 5, 20, 0, 0);

UPDATE `bonk_quest` SET `reward_value` = 28 WHERE `id` = 400;
UPDATE `bonk_quest` SET `reward_value` = 32 WHERE `id` = 401;
UPDATE `bonk_quest` SET `reward_value` = 35 WHERE `id` = 405;

INSERT INTO `bonk_quest` (`id`, `name`, `description`, `icon`, `type`, `target`, `param`, `amount`, `reward_type`, `reward_value`, `class`, `category`) VALUES
(409, 'Escape Artist', 'Dash 500 times.', 'Ability_Vanish', 39, 0, 0, 500, 12, 30, 0, 5),
(410, 'Volley', 'Fire 100,000 bolts.', 'Ability_UpgradeMoonGlaive', 36, 0, 0, 100000, 12, 34, 0, 5),
(411, 'Soul Reaper', 'Kill 100,000 enemies.', 'Spell_Shadow_SoulGem', 0, 0, 0, 100000, 12, 38, 0, 3),
(412, 'Cold Descent', 'Reach Mythic floor 3.', 'Spell_Frost_FrostNova', 3, 2, 0, 3, 12, 29, 0, 3),
(413, 'Bone Pile', 'Reach Mythic floor 7.', 'Spell_Shadow_CorpseExplode', 3, 2, 0, 7, 12, 31, 0, 3),
(414, 'Through the Ranks', 'Reach Mythic floor 9.', 'Ability_Warrior_Cleave', 3, 2, 0, 9, 12, 33, 0, 3),
(415, 'Kindling', 'Reach Mythic floor 11.', 'Spell_Fire_Incinerate', 3, 2, 0, 11, 12, 36, 0, 3),
(416, 'Soul Bound', 'Reach Mythic floor 13.', 'Spell_Shadow_LifeDrain02', 3, 2, 0, 13, 12, 37, 0, 3);

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
