DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261027300007');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261027300007');

INSERT INTO `broadcast_text` (`entry`, `male_text`, `female_text`) VALUES
(900015, 'Set pieces cut for another class? Hand them over and I''ll refit them for you, same slot and tier, for a tenth of their price.',
 'Set pieces cut for another class? Hand them over and I''ll refit them for you, same slot and tier, for a tenth of their price.');
INSERT INTO `npc_text` (`ID`, `BroadcastTextID0`, `Probability0`) VALUES (900015, 900015, 1);

UPDATE `creature_template` SET `script_name` = 'npc_bonk_tier_vendor', `npc_flags` = 5 WHERE `entry` = 900150;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
