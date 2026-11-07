DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261025100000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261025100000');

UPDATE `bonk_pet_family` SET `applies` = 15, `apply_stacks` = 1 WHERE `id` = 16;
DELETE FROM `bonk_pet_ability` WHERE `family` = 16;
INSERT INTO `bonk_pet_ability` (`family`, `spell_id`, `kind`, `cooldown_ms`, `damage`, `stacks`, `value`, `kit`, `comment`) VALUES
(16, 11976, 0, 6000, 2, 1, 0, 0, 'Treant: Entangling Strike, 2 bites worth, 1 Moonfire; roots the prey and normal enemies within 5 yd for 2 sec');
UPDATE `bonk_weapon` SET `description` = 'Summons 2 Treants that fight at your side. Their swings apply Moonfire, and every 6 sec a Treant''s strike roots its target and normal enemies within 5 yards for 2 sec.' WHERE `id` = 1009;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
