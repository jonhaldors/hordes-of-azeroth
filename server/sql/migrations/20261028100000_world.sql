DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261028100000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261028100000');

UPDATE `bonk_weapon` SET `base_targets` = 6, `damage_fraction` = 0.8, `description` = 'Fires 6 arrows in a cone in front of you, dealing damage.' WHERE `id` = 37;
UPDATE `bonk_weapon` SET `radius` = 10, `duration_ms` = 4000, `description` = 'Rains arrows on the largest group of enemies for 4 sec, dealing damage, 5% more for each different debuff on the target.' WHERE `id` = 137;
DELETE FROM `bonk_pet_ability` WHERE `family` = 1 AND `kind` = 4;
INSERT INTO `bonk_pet_ability` (`family`, `spell_id`, `kind`, `cooldown_ms`, `damage`, `stacks`, `value`, `kit`, `comment`) VALUES
(1, 779, 4, 3000, 2, 1, 8, 0, 'Cat: Swipe, every enemy in an arc in front of it within 8 yd, 2 bites worth, 1 Bleed');
UPDATE `bonk_weapon` SET `description` = 'Summons your cat to fight for you. Its Claw applies Bleed, and its Swipe hits every enemy in front of it.' WHERE `id` = 201;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
