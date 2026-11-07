DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261027810003');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261027810003');

UPDATE `bonk_mastery` SET `value_per_rank` = 4, `description` = REPLACE(`description`, '+2%', '+4%') WHERE `class` <> 0 AND `effect` = 0 AND `value_per_rank` = 2 AND `target` = 0;
UPDATE `bonk_mastery` SET `value_per_rank` = 4, `description` = REPLACE(`description`, '+2%', '+4%') WHERE `class` <> 0 AND `effect` = 0 AND `value_per_rank` = 2 AND `target` = 1;
UPDATE `bonk_mastery` SET `value_per_rank` = 4, `description` = REPLACE(`description`, '+2%', '+4%') WHERE `class` <> 0 AND `effect` = 0 AND `value_per_rank` = 2 AND `target` = 3;
UPDATE `bonk_mastery` SET `value_per_rank` = 5, `description` = REPLACE(`description`, '+3%', '+5%') WHERE `class` <> 0 AND `effect` = 0 AND `value_per_rank` = 3 AND `target` = 4;
UPDATE `bonk_mastery` SET `value_per_rank` = 0.2, `description` = REPLACE(`description`, '0.1%', '0.2%') WHERE `class` <> 0 AND `effect` = 0 AND ABS(`value_per_rank` - 0.1) < 0.001 AND `target` = 5;
UPDATE `bonk_mastery` SET `value_per_rank` = 6, `description` = REPLACE(`description`, '+4%', '+6%') WHERE `class` <> 0 AND `effect` = 0 AND `value_per_rank` = 4 AND `target` = 10;
UPDATE `bonk_mastery` SET `value_per_rank` = 5, `description` = REPLACE(`description`, '+3%', '+5%') WHERE `class` <> 0 AND `effect` = 0 AND `value_per_rank` = 3 AND `target` = 10;
UPDATE `bonk_mastery` SET `value_per_rank` = 4, `description` = REPLACE(`description`, '+2%', '+4%') WHERE `class` <> 0 AND `effect` = 0 AND `value_per_rank` = 2 AND `target` = 10;
UPDATE `bonk_mastery` SET `value_per_rank` = 5, `description` = REPLACE(`description`, '+3 ', '+5 ') WHERE `class` <> 0 AND `effect` = 0 AND `value_per_rank` = 3 AND `target` = 12;
UPDATE `bonk_mastery` SET `value_per_rank` = 2, `description` = REPLACE(`description`, '+1%', '+2%') WHERE `class` <> 0 AND `effect` = 0 AND `value_per_rank` = 1 AND `target` = 14;
UPDATE `bonk_mastery` SET `value_per_rank` = 3, `description` = REPLACE(`description`, '+2%', '+3%') WHERE `class` <> 0 AND `effect` = 0 AND `value_per_rank` = 2 AND `target` = 15;
UPDATE `bonk_mastery` SET `value_per_rank` = 2, `description` = REPLACE(`description`, '+1%', '+2%') WHERE `class` <> 0 AND `effect` = 0 AND `value_per_rank` = 1 AND `target` = 15;
UPDATE `bonk_mastery` SET `value_per_rank` = 10, `description` = REPLACE(`description`, 'deal 5%', 'deal 10%') WHERE `class` <> 0 AND `effect` = 0 AND `value_per_rank` = 5 AND `target` = 16;
UPDATE `bonk_mastery` SET `value_per_rank` = 5, `description` = REPLACE(`description`, 'of 3%', 'of 5%') WHERE `class` <> 0 AND `effect` = 0 AND `value_per_rank` = 3 AND `target` = 17;
UPDATE `bonk_mastery` SET `value_per_rank` = 4, `description` = REPLACE(`description`, 'of 2%', 'of 4%') WHERE `class` <> 0 AND `effect` = 0 AND `value_per_rank` = 2 AND `target` = 17;
UPDATE `bonk_mastery` SET `value_per_rank` = 10, `description` = REPLACE(`description`, 'deals 5%', 'deals 10%') WHERE `class` <> 0 AND `effect` = 0 AND `value_per_rank` = 5 AND `target` = 19;
UPDATE `bonk_mastery` SET `value_per_rank` = 5, `description` = REPLACE(`description`, 'deal 3%', 'deal 5%') WHERE `class` <> 0 AND `effect` = 12 AND `value_per_rank` = 3;
UPDATE `bonk_mastery` SET `value_per_rank` = 4, `description` = REPLACE(`description`, 'deal 2%', 'deal 4%') WHERE `class` <> 0 AND `effect` = 12 AND `value_per_rank` = 2;
UPDATE `bonk_mastery` SET `value_per_rank` = 10, `description` = REPLACE(`description`, 'deals 5%', 'deals 10%') WHERE `class` <> 0 AND `effect` = 13 AND `value_per_rank` = 5 AND `target` = 5;
UPDATE `bonk_mastery` SET `value_per_rank` = 12, `description` = REPLACE(`description`, '8%', '12%') WHERE `class` <> 0 AND `effect` = 13 AND `value_per_rank` = 8;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
