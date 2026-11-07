DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261102220000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261102220000');

DELETE FROM `broadcast_text` WHERE `entry` = 900016;
INSERT INTO `broadcast_text` (`entry`, `male_text`, `female_text`) VALUES
(900016, 'You have cleared the final stage. The run is won. Step through to finish it, or stay and see how long you can last.',
         'You have cleared the final stage. The run is won. Step through to finish it, or stay and see how long you can last.');

DELETE FROM `npc_text` WHERE `ID` = 900016;
INSERT INTO `npc_text` (`ID`, `BroadcastTextID0`, `Probability0`) VALUES
(900016, 900016, 1);

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
