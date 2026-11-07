DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261102120011');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261102120011');

UPDATE `bonk_weapon` SET `description` = 'Drains the nearest enemy within 16 yards, dealing damage every sec and healing you for 1% of your maximum health per enemy drained, up to 2%. Drained enemies take 20% more damage from your Decay and Agony.' WHERE `id` = 906;
UPDATE `bonk_weapon` SET `description` = 'Drains the nearest enemy within 16 yards, dealing damage every sec and healing you, up to 2% of your maximum health a sec. Each enemy that dies while drained gives you a soul: 5% more damage for 10 sec, up to 10 souls. Drained enemies take 20% more damage from your Decay and Agony.' WHERE `id` = 923;
UPDATE `bonk_weapon` SET `description` = 'Drains the nearest enemy within 16 yards, dealing damage every sec and healing you, up to 2% of your maximum health a sec. Healing past full health makes your demons deal 30% more damage for 4 sec. Drained enemies take 20% more damage from your Decay and Agony.' WHERE `id` = 924;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
