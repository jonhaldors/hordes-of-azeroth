DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261012040000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261012040000');

ALTER TABLE `bonk_weapon`
    MODIFY COLUMN `target` TINYINT UNSIGNED NOT NULL DEFAULT 0 COMMENT '0 nearest enemies, 1 area around the player, 2 random enemies, 3 ground effect on the biggest pack',
    ADD COLUMN IF NOT EXISTS `duration_ms` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'how long the spell lasts; 0 = the spell''s own duration' AFTER `heal_pct`;

DELETE FROM `bonk_weapon` WHERE `id` BETWEEN 22 AND 26;
INSERT INTO `bonk_weapon` (`id`, `name`, `icon`, `description`, `spell_id`, `target`, `cooldown_ms`, `range`, `damage_fraction`,
    `class_mask`, `starter_class_mask`, `max_level`, `evolves_from`, `evolve_passive`, `heal_pct`, `duration_ms`) VALUES
(22, 'Blizzard',        'Spell_Frost_IceStorm',          'Ice rains on the biggest pack of enemies for 6 seconds and slows them.',  26607, 3, 5000, 28, 0.30,  128, 0, 8, 0, 0, 0, 6000),
(23, 'Rain of Fire',    'Spell_Shadow_RainOfFire',       'Fire rains on the biggest pack of enemies for 6 seconds.',                19717, 3, 5000, 28, 0.35,  256, 0, 8, 0, 0, 0, 6000),
(24, 'Starfall',        'Spell_Holy_ElunesGrace',        'Stars fall over a wide area on the biggest pack of enemies for 6 seconds.', 26540, 3, 5500, 28, 0.25, 1040, 0, 8, 0, 0, 0, 6000),
(25, 'Lightning Cloud', 'Spell_Nature_StormReach',       'A storm cloud strikes the biggest pack of enemies, then crackles for 6 seconds.', 26550, 3, 5500, 28, 0.35, 64, 0, 8, 0, 0, 0, 6000),
(26, 'Poison Cloud',    'Spell_Nature_NatureTouchDecay', 'Leaves a cloud of poison where you stand for 6 seconds.',                 25198, 1, 4500,  8, 0.30,   12, 0, 8, 0, 0, 0, 6000);

DELETE FROM `bonk_quest` WHERE `id` BETWEEN 30 AND 34;
INSERT INTO `bonk_quest` (`id`, `name`, `description`, `icon`, `type`, `target`, `amount`, `reward_type`, `reward_value`) VALUES
(30, 'Winter''s Grasp',  'Kill 150 enemies with Frostbolt.',      'Spell_Frost_IceStorm',          2, 13, 150, 2, 22),
(31, 'Burning Skies',    'Kill 150 enemies with Shadow Bolt.',    'Spell_Shadow_RainOfFire',       2, 17, 150, 2, 23),
(32, 'Stargazer',        'Reach level 10 in a single run.',       'Spell_Holy_ElunesGrace',        4,  0,  10, 2, 24),
(33, 'Eye of the Storm', 'Kill 150 enemies with Lightning Bolt.', 'Spell_Nature_StormReach',       2, 10, 150, 2, 25),
(34, 'Toxic Tactics',    'Kill 5 elites.',                        'Spell_Nature_NatureTouchDecay', 1,  1,   5, 2, 26);

END IF;
END??
DELIMITER ;
CALL add_migration();
