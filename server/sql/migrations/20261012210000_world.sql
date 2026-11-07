DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261012210000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261012210000');

DELETE FROM `bonk_upgrade` WHERE `id` IN (4, 7, 8);
UPDATE `bonk_upgrade` SET `cost_growth` = 1.4, `required_id` = 0, `required_rank` = 0;

UPDATE `bonk_upgrade` SET `value_per_rank` = 3, `max_rank` = 10, `cost` = 4500, `description` = '+3% damage.' WHERE `id` = 1;
UPDATE `bonk_upgrade` SET `value_per_rank` = 4, `max_rank` = 10, `cost` = 4500, `description` = '+4% maximum health.' WHERE `id` = 3;
UPDATE `bonk_upgrade` SET `value_per_rank` = 3, `max_rank` = 5, `cost` = 6500,
    `description` = '+3% Haste: spells fire and tick 3% more often.' WHERE `id` = 2;
UPDATE `bonk_upgrade` SET `value_per_rank` = 2, `max_rank` = 5, `cost` = 4500, `description` = '+2% movement speed.' WHERE `id` = 5;
UPDATE `bonk_upgrade` SET `value_per_rank` = 5, `max_rank` = 5, `cost` = 6500, `description` = '+5% gold.' WHERE `id` = 6;

UPDATE `bonk_upgrade` SET `tree_row` = 1, `tree_column` = 3 WHERE `id` = 15;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
