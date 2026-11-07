DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261022230000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261022230000');

UPDATE `bonk_weapon` SET `description` = 'For 4 seconds, your hits deal 30% more damage and every hit counts as a first hit for Ambush, once a second on each enemy.' WHERE `id` = 610;
UPDATE `bonk_weapon` SET `description` = 'For 4 seconds, your hits deal 30% more damage and every hit counts as a first hit for Ambush, once a second on each enemy. The dance begins with a vanish: normal enemies within 10 yards lose you and stand dazed for 2 seconds.' WHERE `id` = 632;
UPDATE `bonk_weapon` SET `description` = 'For 4 seconds, your hits deal 30% more damage and every hit counts as a first hit for Ambush, once a second on each enemy. The dance begins by striking the 5 strongest enemies within 20 yards with a shadow strike.' WHERE `id` = 633;
UPDATE `bonk_weapon` SET `description` = 'For 8 seconds, your single-target hits also strike 4 additional enemies within 8 yards for 50% of their damage as Shadow damage. Every extra hit counts as a first hit for Ambush, once a second on each enemy.' WHERE `id` = 615;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
