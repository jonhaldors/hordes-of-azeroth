DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261028100004');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261028100004');

UPDATE `bonk_mastery` SET `description` = 'Every 3rd cast of each spell critically strikes every enemy it hits, and those critical strikes deal 25% more damage.' WHERE `id` = 10110;
UPDATE `bonk_mastery` SET `description` = 'You are always Enraged. Enrage gives 50% more Haste, and talents that improve Enrage are 50% stronger. You take 15% more damage.' WHERE `id` = 10210;
UPDATE `bonk_mastery` SET `description` = 'Your single-target hits also strike 1 additional enemy within 8 yards for 60% damage, even without Blade Flurry.' WHERE `id` = 40210;
UPDATE `bonk_mastery` SET `description` = 'Chill freezes at 4 stacks instead of 10.' WHERE `id` = 80310;
UPDATE `bonk_mastery` SET `description` = 'When an enemy with your Decay or Agony dies, they jump to the nearest enemy without them, keeping half the stacks.' WHERE `id` = 90110;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
