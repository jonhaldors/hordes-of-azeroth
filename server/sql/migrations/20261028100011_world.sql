DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261028100011');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261028100011');

DELETE FROM `bonk_pet_ability` WHERE `family` = 15 AND `kind` = 4;
INSERT INTO `bonk_pet_ability` (`family`, `spell_id`, `kind`, `cooldown_ms`, `damage`, `stacks`, `value`, `kit`, `comment`) VALUES
(15, 17253, 4, 2500, 2, 0, 6, 0, 'Felhunter: Shadow Cleave, every enemy in an arc in front of it within 6 yd, 2 bites worth');
UPDATE `bonk_weapon` SET `description` = 'Summons a Felhunter whose Shadow Bite deals 10% more damage per affliction on the target and interrupts spells, and whose Shadow Cleave hits every enemy in front of it. Every 10 sec it removes a harmful effect from you.' WHERE `id` = 903;
UPDATE `bonk_weapon` SET `description` = 'Summons a Felhunter whose Shadow Bite deals 10% more damage per affliction on the target and interrupts every caster within 8 yards of it, and whose Shadow Cleave hits every enemy in front of it.' WHERE `id` = 917;
UPDATE `bonk_weapon` SET `description` = 'Summons a Felhunter whose Shadow Bite deals 10% more damage per affliction on the target and turns off an elite''s affixes for 6 sec, at most once every 10 sec, and whose Shadow Cleave hits every enemy in front of it.' WHERE `id` = 918;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
