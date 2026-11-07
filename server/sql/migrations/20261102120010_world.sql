DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261102120010');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261102120010');

DELETE FROM `bonk_passive` WHERE `id` IN (22, 23);
INSERT INTO `bonk_passive` (`id`, `name`, `icon`, `description`, `effect`, `value_per_rank`, `max_rank`, `excludes`, `rare`) VALUES
(22, 'Pyromaniac', 'Spell_Fire_FlameShock', '+{10}% Burning damage.', 20, 10, 0, 0, 0),
(23, 'Serrated Blades', 'Ability_Rogue_Rupture', '+{10}% Bleed damage.', 21, 10, 0, 0, 0);

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
