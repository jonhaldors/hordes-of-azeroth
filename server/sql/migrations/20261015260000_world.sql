DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261015260000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261015260000');

DELETE FROM `bonk_mob_ability` WHERE (`entry`, `spell_id`) IN ((3238, 5401), (12076, 19641), (11667, 19630));

UPDATE `bonk_mob_ability` SET `spell_id` = 9053, `cooldown_ms` = 5000, `damage` = 1, `max_range` = 30,
    `comment` = 'Scorching Elemental: Fireball (was Scorch, which has no missile to dodge)'
WHERE `entry` = 6520 AND `spell_id` = 13878;
UPDATE `bonk_mob_ability` SET `spell_id` = 19452, `cooldown_ms` = 5000, `damage` = 1, `max_range` = 30,
    `comment` = 'Bloodpetal Trapper: Toxic Spit (was Entangling Roots, which has no missile to dodge)'
WHERE `entry` = 6512 AND `spell_id` = 11922;

UPDATE `bonk_weapon` SET `base_targets` = 3, `description` = 'Fires 3 arrows in a cone in front of you.' WHERE `id` = 37;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
