DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261020980000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261020980000');

UPDATE `spell_template` SET `casterAuraState` = 0, `equippedItemClass` = -1, `equippedItemSubClassMask` = 0,
    `equippedItemInventoryTypeMask` = 0, `recoveryTime` = 0, `categoryRecoveryTime` = 0, `startRecoveryTime` = 0
WHERE `entry` IN (6572, 23922);

UPDATE `bonk_weapon` SET `spell_id` = 6572 WHERE `id` IN (309, 329, 330);
UPDATE `bonk_weapon` SET `spell_id` = 23922 WHERE `id` IN (310, 332);

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
