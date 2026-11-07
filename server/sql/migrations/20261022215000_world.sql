DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261022215000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261022215000');

UPDATE `bonk_pet_ability` SET `damage` = 5 WHERE `family` = 12 AND `spell_id` = 11763;
UPDATE `bonk_pet_ability` SET `damage` = 4 WHERE `family` = 15 AND `spell_id` = 17253;

UPDATE `bonk_weapon` SET `base_targets` = 5, `apply_stacks` = 8,
    `description` = 'Corrupts the 5 nearest enemies that are not corrupted yet, applying 8 stacks of Decay.' WHERE `id` = 904;
UPDATE `bonk_weapon` SET `base_targets` = 5, `apply_stacks` = 8, `cooldown_ms` = 3000,
    `description` = 'Curses the 5 uncursed enemies with the most health, applying 8 stacks of Agony. Agony deals more damage every sec it stays on the enemy.' WHERE `id` = 905;
UPDATE `bonk_weapon` SET `damage_fraction` = 1.0 WHERE `id` = 906;
UPDATE `bonk_weapon` SET `damage_fraction` = 2.0 WHERE `id` = 907;
UPDATE `bonk_weapon` SET `damage_fraction` = 1.6, `apply_stacks` = 6,
    `description` = 'Fel fire strikes the 2 nearest enemies and applies 6 stacks of Burning.' WHERE `id` = 908;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
