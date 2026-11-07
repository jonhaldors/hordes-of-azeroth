DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261011194800');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261011194800');

CREATE TABLE IF NOT EXISTS `bonk_powerup` (
    `entry`    INT UNSIGNED NOT NULL COMMENT 'gameobject_template; only its looks are used',
    `spell_id` INT UNSIGNED NOT NULL COMMENT 'cast on the player who walks over it',
    `weight`   INT UNSIGNED NOT NULL DEFAULT 1,
    PRIMARY KEY (`entry`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='Vanilla Bonk power-ups';

ALTER TABLE `bonk_map`
    ADD COLUMN `powerup_interval_sec` INT UNSIGNED     NOT NULL DEFAULT 40 COMMENT 'a new power-up appears this often; 0 = none' AFTER `coins_per_kill`,
    ADD COLUMN `powerup_max`          TINYINT UNSIGNED NOT NULL DEFAULT 3  COMMENT 'most power-ups lying around at once' AFTER `powerup_interval_sec`;

DELETE FROM `gameobject_template` WHERE `entry` IN (900004, 900005);
INSERT INTO `gameobject_template` (`entry`, `patch`, `type`, `displayId`, `name`, `size`) VALUES
(900004, 0, 5, 5991, 'Restoration', 1.0),
(900005, 0, 5, 5995, 'Berserking',  1.0);

DELETE FROM `bonk_powerup`;
INSERT INTO `bonk_powerup` (`entry`, `spell_id`, `weight`) VALUES
(900004, 23493, 1),
(900005, 23505, 1);

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
