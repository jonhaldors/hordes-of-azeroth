DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261025320000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261025320000');

UPDATE `bonk_pet_ability` SET `damage` = 0.6, `comment` = 'Ancient of War: War Stomp, 8 yd, 0.6 bites worth, 1 Moonfire' WHERE `family` = 17;
UPDATE `bonk_weapon` SET `damage_fraction` = 0.4, `apply_stacks` = 1,
    `description` = 'Thrashes every enemy within 8 yards for damage and 1 stack of Bleed. Empowered in Cat Form.' WHERE `id` = 1020;
UPDATE `bonk_weapon` SET `description` = REPLACE(`description`, 'dealing 50% damage to enemies within 8 yards', 'dealing 15% damage to enemies within 8 yards') WHERE `id` = 1014;
UPDATE `bonk_weapon` SET `description` = REPLACE(`description`, 'applying 1 stack of Moonfire to every enemy within 5 yards of each target', 'applying 1 stack of Moonfire to up to 3 enemies within 5 yards of each target') WHERE `id` = 1016;
UPDATE `bonk_weapon` SET `description` = REPLACE(`description`, 'mangles every enemy within 5 yards of it for 50% damage', 'mangles up to 4 enemies within 5 yards of it for 25% damage') WHERE `id` = 1022;
UPDATE `bonk_weapon` SET `description` = REPLACE(`description`, 'and dealing double damage to every enemy within 10 yards', 'and dealing Nature damage to every enemy within 10 yards') WHERE `id` = 1028;
UPDATE `bonk_weapon` SET `description` = REPLACE(`description`, 'up to double damage at full health', 'up to 60% more damage at full health') WHERE `id` = 1035;
UPDATE `bonk_weapon` SET `description` = REPLACE(`description`, 'that form''s attack for 50% damage', 'that form''s attack for 25% damage') WHERE `id` = 1039;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
