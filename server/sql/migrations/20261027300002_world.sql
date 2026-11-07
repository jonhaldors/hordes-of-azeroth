DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261027300002');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261027300002');

UPDATE `bonk_item_stat` SET `armor` = ROUND(`armor` * 0.2, 1) WHERE `armor` > 0;

UPDATE `bonk_item_set_bonus` SET `armor` = 2.5, `description` = '+2.5 Armor. Regain 1% of your health every second.' WHERE `set_id` = 1 AND `pieces` = 4;
UPDATE `bonk_item_set_bonus` SET `armor` = 3.75, `description` = '+3.8 Armor. Regain 1.5% of your health every second.' WHERE `set_id` = 3 AND `pieces` = 4;
UPDATE `bonk_item_set_bonus` SET `armor` = 5.625, `description` = '+5.6 Armor. Regain 2.25% of your health every second.' WHERE `set_id` = 5 AND `pieces` = 4;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
