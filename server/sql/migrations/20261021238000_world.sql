DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261021238000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261021238000');

UPDATE `bonk_weapon` SET `behavior` = 22, `behavior_value` = 1,
    `description` = 'Hurls a bolt of lightning at the nearest enemy that bounces to 1 more enemy nearby, dealing Nature damage and applying 1 stack of Static to each.'
    WHERE `id` = 700;
UPDATE `spell_template` SET `effectChainTarget1` = 5 WHERE `entry` = 421;
UPDATE `bonk_weapon` SET `description` = REPLACE(`description`, 'jumps to 3 additional', 'jumps to 4 additional') WHERE `id` IN (701, 715);

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
