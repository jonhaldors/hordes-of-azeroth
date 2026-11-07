DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261028100012');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261028100012');

DELETE FROM `bonk_pet_ability` WHERE `family` IN (6, 10, 11, 16) AND `kind` = 0 AND `cooldown_ms` = 1500;
INSERT INTO `bonk_pet_ability` (`family`, `spell_id`, `kind`, `cooldown_ms`, `damage`, `stacks`, `value`, `kit`, `comment`) VALUES
(6, 17253, 0, 1500, 4, 1, 0, 0, 'Spirit Wolf: Bite, 4 bites worth, 1 Static; melee swings land too rarely to carry the damage'),
(10, 17253, 0, 1500, 4, 1, 0, 0, 'Elemental Spirit: Bite, 4 bites worth, 1 stack of its element'),
(11, 17253, 0, 1500, 4, 1, 0, 0, 'Shadowfiend: Shadow Strike, 4 bites worth, 1 Decay'),
(16, 17253, 0, 1500, 4, 1, 0, 0, 'Treant: Strike, 4 bites worth, 1 Moonfire');

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
