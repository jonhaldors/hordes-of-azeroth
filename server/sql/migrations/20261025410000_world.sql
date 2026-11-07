DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261025410000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261025410000');

INSERT INTO `bonk_bolt_look` (`spell_id`, `display_id`, `scale`, `impact_kit`, `cast_near`) VALUES
(21066, 18007, 1, 2350, 0),
(15245, 18007, 1, 0, 0),
(14297, 18007, 1, 0, 0),
(20741, 18007, 1, 0, 0),
(26546, 18007, 1, 0, 0),
(11988, 18003, 1, 0, 0),
(21687, 18602, 1, 0, 0),
(21071, 18601, 1, 0, 0),
(4164, 18601, 0.6, 0, 0),
(15791, 18006, 1, 0, 0)
ON DUPLICATE KEY UPDATE `display_id` = VALUES(`display_id`), `scale` = VALUES(`scale`), `impact_kit` = VALUES(`impact_kit`);

UPDATE `spell_template` SET `speed` = 24 WHERE `entry` = 21066;

UPDATE `bonk_mob_ability` SET `cast_kit` = 387, `impact_kit` = 282 WHERE `spell_id` = 5401 AND `shape` = 0 AND `target` = 0 AND `cast_kit` = 0 AND `impact_kit` = 0;
UPDATE `bonk_mob_ability` SET `cast_kit` = 321, `impact_kit` = 282 WHERE `spell_id` = 6254 AND `shape` = 0 AND `target` = 0 AND `cast_kit` = 0 AND `impact_kit` = 0;
UPDATE `bonk_mob_ability` SET `cast_kit` = 492, `impact_kit` = 348 WHERE `spell_id` = 6304 AND `shape` = 0 AND `target` = 0 AND `cast_kit` = 0 AND `impact_kit` = 0;
UPDATE `bonk_mob_ability` SET `cast_kit` = 321, `impact_kit` = 282 WHERE `spell_id` = 8292 AND `shape` = 0 AND `target` = 0 AND `cast_kit` = 0 AND `impact_kit` = 0;
UPDATE `bonk_mob_ability` SET `cast_kit` = 3054, `impact_kit` = 3055 WHERE `spell_id` = 10413 AND `shape` = 0 AND `target` = 0 AND `cast_kit` = 0 AND `impact_kit` = 0;
UPDATE `bonk_mob_ability` SET `cast_kit` = 321, `impact_kit` = 282 WHERE `spell_id` = 12058 AND `shape` = 0 AND `target` = 0 AND `cast_kit` = 0 AND `impact_kit` = 0;
UPDATE `bonk_mob_ability` SET `cast_kit` = 38, `impact_kit` = 728 WHERE `spell_id` = 13340 AND `shape` = 0 AND `target` = 0 AND `cast_kit` = 0 AND `impact_kit` = 0;
UPDATE `bonk_mob_ability` SET `cast_kit` = 38, `impact_kit` = 728 WHERE `spell_id` = 13341 AND `shape` = 0 AND `target` = 0 AND `cast_kit` = 0 AND `impact_kit` = 0;
UPDATE `bonk_mob_ability` SET `cast_kit` = 38, `impact_kit` = 2609 WHERE `spell_id` = 15241 AND `shape` = 0 AND `target` = 0 AND `cast_kit` = 0 AND `impact_kit` = 0;
UPDATE `bonk_mob_ability` SET `cast_kit` = 321, `impact_kit` = 282 WHERE `spell_id` = 15549 AND `shape` = 0 AND `target` = 0 AND `cast_kit` = 0 AND `impact_kit` = 0;
UPDATE `bonk_mob_ability` SET `cast_kit` = 218, `impact_kit` = 2709 WHERE `spell_id` = 15587 AND `shape` = 0 AND `target` = 0 AND `cast_kit` = 0 AND `impact_kit` = 0;
UPDATE `bonk_mob_ability` SET `cast_kit` = 316, `impact_kit` = 317 WHERE `spell_id` = 15605 AND `shape` = 0 AND `target` = 0 AND `cast_kit` = 0 AND `impact_kit` = 0;
UPDATE `bonk_mob_ability` SET `cast_kit` = 789, `impact_kit` = 76 WHERE `spell_id` = 16536 AND `shape` = 0 AND `target` = 0 AND `cast_kit` = 0 AND `impact_kit` = 0;
UPDATE `bonk_mob_ability` SET `cast_kit` = 118, `impact_kit` = 2350 WHERE `spell_id` = 16583 AND `shape` = 0 AND `target` = 0 AND `cast_kit` = 0 AND `impact_kit` = 0;
UPDATE `bonk_mob_ability` SET `cast_kit` = 119, `impact_kit` = 487 WHERE `spell_id` = 17149 AND `shape` = 0 AND `target` = 0 AND `cast_kit` = 0 AND `impact_kit` = 0;
UPDATE `bonk_mob_ability` SET `cast_kit` = 218, `impact_kit` = 2709 WHERE `spell_id` = 17194 AND `shape` = 0 AND `target` = 0 AND `cast_kit` = 0 AND `impact_kit` = 0;
UPDATE `bonk_mob_ability` SET `cast_kit` = 218, `impact_kit` = 2709 WHERE `spell_id` = 17287 AND `shape` = 0 AND `target` = 0 AND `cast_kit` = 0 AND `impact_kit` = 0;
UPDATE `bonk_mob_ability` SET `cast_kit` = 118, `impact_kit` = 2350 WHERE `spell_id` = 17289 AND `shape` = 0 AND `target` = 0 AND `cast_kit` = 0 AND `impact_kit` = 0;
UPDATE `bonk_mob_ability` SET `cast_kit` = 118, `impact_kit` = 2350 WHERE `spell_id` = 22575 AND `shape` = 0 AND `target` = 0 AND `cast_kit` = 0 AND `impact_kit` = 0;
UPDATE `bonk_mob_ability` SET `cast_kit` = 3169, `impact_kit` = 212 WHERE `spell_id` = 23979 AND `shape` = 0 AND `target` = 0 AND `cast_kit` = 0 AND `impact_kit` = 0;
UPDATE `bonk_mob_ability` SET `cast_kit` = 37 WHERE `shape` IN (3, 8) AND `cast_kit` = 0 AND `spell_id` IN (21687);
UPDATE `bonk_mob_ability` SET `cast_kit` = 61 WHERE `shape` IN (3, 8) AND `cast_kit` = 0 AND `spell_id` IN (11988, 16419);
UPDATE `bonk_mob_ability` SET `cast_kit` = 72 WHERE `shape` IN (3, 8) AND `cast_kit` = 0 AND `spell_id` IN (9459);
UPDATE `bonk_mob_ability` SET `cast_kit` = 118 WHERE `shape` IN (3, 8) AND `cast_kit` = 0 AND `spell_id` IN (8245, 19702, 19716, 21056, 24328, 28863);
UPDATE `bonk_mob_ability` SET `cast_kit` = 172 WHERE `shape` IN (3, 8) AND `cast_kit` = 0 AND `spell_id` IN (4164, 21071);
UPDATE `bonk_mob_ability` SET `cast_kit` = 202 WHERE `shape` IN (3, 8) AND `cast_kit` = 0 AND `spell_id` IN (10737);
UPDATE `bonk_mob_ability` SET `cast_kit` = 218 WHERE `shape` IN (3, 8) AND `cast_kit` = 0 AND `spell_id` IN (14297, 15245, 20741, 26546);
UPDATE `bonk_mob_ability` SET `cast_kit` = 239 WHERE `shape` IN (3, 8) AND `cast_kit` = 0 AND `spell_id` IN (7978);
UPDATE `bonk_mob_ability` SET `cast_kit` = 321 WHERE `shape` IN (3, 8) AND `cast_kit` = 0 AND `spell_id` IN (11085);
UPDATE `bonk_mob_ability` SET `cast_kit` = 539 WHERE `shape` IN (3, 8) AND `cast_kit` = 0 AND `spell_id` IN (12280);
UPDATE `bonk_mob_ability` SET `cast_kit` = 844 WHERE `shape` IN (3, 8) AND `cast_kit` = 0 AND `spell_id` IN (19695);
UPDATE `bonk_mob_ability` SET `cast_kit` = 1624 WHERE `shape` IN (3, 8) AND `cast_kit` = 0 AND `spell_id` IN (11638);
UPDATE `bonk_mob_ability` SET `cast_kit` = 4509 WHERE `shape` IN (3, 8) AND `cast_kit` = 0 AND `spell_id` IN (15791);
UPDATE `bonk_mob_ability` SET `cast_kit` = 4811 WHERE `shape` IN (3, 8) AND `cast_kit` = 0 AND `spell_id` IN (19798);
UPDATE `bonk_mob_ability` SET `cast_kit` = 5391 WHERE `shape` IN (3, 8) AND `cast_kit` = 0 AND `spell_id` IN (19717);

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
