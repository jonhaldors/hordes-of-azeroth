DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261027800003');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261027800003');

UPDATE `item_template` SET `armor` = 0, `holy_res` = 0, `fire_res` = 0, `nature_res` = 0, `frost_res` = 0, `shadow_res` = 0, `arcane_res` = 0,
    `stat_type1` = 0, `stat_value1` = 0, `stat_type2` = 0, `stat_value2` = 0, `stat_type3` = 0, `stat_value3` = 0, `stat_type4` = 0, `stat_value4` = 0,
    `stat_type5` = 0, `stat_value5` = 0, `stat_type6` = 0, `stat_value6` = 0, `stat_type7` = 0, `stat_value7` = 0, `stat_type8` = 0, `stat_value8` = 0,
    `stat_type9` = 0, `stat_value9` = 0, `stat_type10` = 0, `stat_value10` = 0,
    `spellid_1` = 0, `spelltrigger_1` = 0, `spellid_2` = 0, `spelltrigger_2` = 0, `spellid_3` = 0, `spelltrigger_3` = 0,
    `spellid_4` = 0, `spelltrigger_4` = 0, `spellid_5` = 0, `spelltrigger_5` = 0
WHERE `entry` BETWEEN 904500 AND 904899;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
