DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261018120000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261018120000');

DELETE `v` FROM `npc_vendor` `v`
    JOIN `item_template` `i` ON `i`.`entry` = `v`.`item`
    JOIN `bonk_item_stat` `s` ON `s`.`entry` = `v`.`item`
    WHERE `v`.`entry` = 900004 AND `s`.`unlock_tier` <> 0 AND `i`.`quality` < 4;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
