DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261025390000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261025390000');

UPDATE `bonk_mastery` SET `description` = 'You give up your forms and Shapeshift hurls Wrath in your own form for 35% less damage. Every other Druid spell deals and heals 15% more for each talent tree your Druid spells come from, up to 45%. Form bonuses and form traits no longer apply.' WHERE `id` = 110310;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
