DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261028100013');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261028100013');

DELETE FROM `bonk_pet_ability` WHERE `family` IN (6, 10, 11, 16) AND `kind` = 4;
INSERT INTO `bonk_pet_ability` (`family`, `spell_id`, `kind`, `cooldown_ms`, `damage`, `stacks`, `value`, `kit`, `comment`) VALUES
(6, 17253, 4, 3000, 2, 1, 6, 0, 'Spirit Wolf: Cleave, every enemy in an arc in front within 6 yd, 2 bites worth, 1 Static'),
(10, 17253, 4, 3000, 2, 1, 6, 0, 'Elemental Spirit: Cleave, every enemy in an arc in front within 6 yd, 2 bites worth'),
(11, 17253, 4, 3000, 2, 1, 6, 0, 'Shadowfiend: Shadow Cleave, every enemy in an arc in front within 6 yd, 2 bites worth, 1 Decay'),
(16, 17253, 4, 3000, 2, 1, 6, 0, 'Treant: Sweep, every enemy in an arc in front within 6 yd, 2 bites worth, 1 Moonfire');

UPDATE `bonk_pet_ability` SET `damage` = 4.5 WHERE `family` = 12 AND `kind` = 0;
UPDATE `bonk_weapon` SET `damage_fraction` = 2.0 WHERE `id` IN (410, 431, 432);
UPDATE `bonk_weapon` SET `damage_fraction` = 2.5 WHERE `id` IN (708, 729);
UPDATE `bonk_weapon` SET `damage_fraction` = 1.6 WHERE `id` IN (900, 911, 912);

UPDATE `bonk_weapon` SET `damage_fraction` = 1.3 WHERE `id` = 1031;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
