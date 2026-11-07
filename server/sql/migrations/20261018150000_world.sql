DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261018150000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261018150000');

DROP TEMPORARY TABLE IF EXISTS `bonk_aoe_spell`;
CREATE TEMPORARY TABLE `bonk_aoe_spell` (`id` INT UNSIGNED NOT NULL PRIMARY KEY);
INSERT INTO `bonk_aoe_spell` VALUES
(306), (323), (324), (308), (327), (328),
(402), (415), (416), (407), (425), (426), (408), (427), (428), (423),
(401), (413), (414), (404), (419), (420),
(137), (218), (219), (205), (220), (221);

UPDATE `bonk_weapon` `w` JOIN `bonk_aoe_spell` `a` ON `a`.`id` = `w`.`id` SET `w`.`flags` = `w`.`flags` | 0x4000000;

DELETE `u` FROM `bonk_weapon_upgrade` `u` JOIN `bonk_aoe_spell` `a` ON `a`.`id` = `u`.`weapon_id` WHERE `u`.`upgrade` IN (2, 16);
INSERT INTO `bonk_weapon_upgrade` (`weapon_id`, `upgrade`, `step`) SELECT `id`, 16, 1 FROM `bonk_aoe_spell`;

UPDATE `bonk_passive` SET `description` = '+{1} Count. Each Count makes your spells fire 1 additional bolt or shot, swing 1 additional time, place 1 additional trap, summon 1 additional pet or affect 1 additional target. AoE spells are not affected.' WHERE `id` = 19;

DROP TEMPORARY TABLE `bonk_aoe_spell`;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
