DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261030150001');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261030150001');

CREATE TEMPORARY TABLE `bonk_shop_armor` (`entry` INT UNSIGNED PRIMARY KEY, `factor` FLOAT NOT NULL);
INSERT INTO `bonk_shop_armor` VALUES
    (900125, 0.6), (900126, 0.6), (900127, 0.6), (900121, 0.6), (900128, 0.6), (900122, 0.6), (900123, 0.6), (900124, 0.6),
    (902024, 0.85), (902025, 0.85), (902026, 0.85), (902020, 0.85), (902027, 0.85), (902021, 0.85), (902022, 0.85), (902023, 0.85);

UPDATE `bonk_item_stat` s JOIN `bonk_shop_armor` a ON a.`entry` = s.`entry` SET
    s.`power` = GREATEST(s.`power`, ROUND(6.0 * a.`factor`, 1)),
    s.`max_health` = GREATEST(s.`max_health`, ROUND(7.0 * a.`factor`, 1)),
    s.`armor` = GREATEST(s.`armor`, ROUND(3.5 * a.`factor`, 1)),
    s.`dodge` = GREATEST(s.`dodge`, ROUND(1.5 * a.`factor`, 1)),
    s.`crit` = GREATEST(s.`crit`, ROUND(2.0 * a.`factor`, 1)),
    s.`crit_damage` = GREATEST(s.`crit_damage`, ROUND(3.0 * a.`factor`, 1)),
    s.`shield` = GREATEST(s.`shield`, ROUND(3.5 * a.`factor`, 1));

UPDATE `bonk_item_stat` SET
    `power` = ROUND(`power` * 1.2, 1), `max_health` = ROUND(`max_health` * 1.2, 1), `armor` = ROUND(`armor` * 1.2, 1),
    `dodge` = ROUND(`dodge` * 1.2, 1), `crit` = ROUND(`crit` * 1.2, 1), `crit_damage` = ROUND(`crit_damage` * 1.2, 1),
    `shield` = ROUND(`shield` * 1.2, 1), `haste` = ROUND(`haste` * 1.2, 1), `area` = ROUND(`area` * 1.2, 1)
WHERE `entry` IN (900103, 900106, 900109, 900112, 902202, 902205, 902208, 902211, 902214, 902217, 902220, 902223, 902226,
    902002, 902005, 902008, 902011, 902232, 902235, 902238, 902241, 902244, 902247, 902250, 902253, 902256);

DROP TEMPORARY TABLE `bonk_shop_armor`;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
