DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261024210000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261024210000');

UPDATE `bonk_weapon` SET `description` = 'Blasts all enemies within 8 yards of you with thunder after every 8 casts of your other spells that hit an enemy, instead of on a cooldown. Enemies hit attack 20% slower for 6 sec. Haste lowers the count, down to 4 casts.' WHERE `id` = 327;
UPDATE `bonk_weapon` SET `description` = 'When you are struck, strikes all enemies within 6 yards of you. Damage you take to your health is stored, up to 50% of your maximum health, and released by the next strike for up to 200% more damage. Damage absorbed by Shields is not stored. Can occur once every 2 sec.' WHERE `id` = 329;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
