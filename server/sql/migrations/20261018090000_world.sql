DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261018090000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261018090000');

ALTER TABLE `bonk_pet_family` ADD COLUMN `description` VARCHAR(1024) NOT NULL DEFAULT '';
UPDATE `bonk_pet_family` SET `description` = 'Now a Water Elemental: it casts Frostbolts that apply Chill, and a small Frost Nova every 5 sec that applies 2 stacks of Chill to enemies within 6 yards.' WHERE `id` = 2;
UPDATE `bonk_pet_family` SET `description` = 'Now a Fire Elemental: it casts Fireballs that leave enemies burning, and burns enemies within 5 yards every 2 sec, applying 1 stack of Burning.' WHERE `id` = 3;
UPDATE `bonk_pet_family` SET `description` = 'Now an Arcane Elemental: it casts Arcane Bolts, and a small Arcane Explosion every 3 sec that hits enemies within 6 yards.' WHERE `id` = 4;

UPDATE `bonk_weapon` SET `description` = 'Summons an elemental to fight for you, following the school most of your spells belong to.' WHERE `id` = 410;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
