DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261102120009');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261102120009');

DELETE FROM `spell_template` WHERE `entry` = 33702;
DROP TEMPORARY TABLE IF EXISTS `bonk_viper_trap`;
CREATE TEMPORARY TABLE `bonk_viper_trap` SELECT * FROM `spell_template` WHERE `entry` = 25809;
UPDATE `bonk_viper_trap` SET `entry` = 33702, `name` = 'Viper Trap';
INSERT INTO `spell_template` SELECT * FROM `bonk_viper_trap`;
DROP TEMPORARY TABLE IF EXISTS `bonk_viper_trap`;

UPDATE `bonk_weapon` SET `name` = 'Viper Trap', `icon` = 'INV_Misc_MonsterFang_01', `spell_id` = 33702, `behavior` = 19, `behavior_value` = 900009,
    `target` = 7, `cooldown_ms` = 7000, `range` = 6, `radius` = 5, `damage_fraction` = 0, `tick_ms` = 0, `duration_ms` = 4000,
    `applies` = 5, `apply_stacks` = 1, `flags` = 536870912,
    `description` = 'Places a trap that releases 4 vipers when an enemy comes close. Each viper rushes one of the 4 nearest enemies and bursts into a poison cloud for 4 sec. Enemies inside gain 1 stack of Poison every 0.5 sec.'
    WHERE `id` = 204;
UPDATE `bonk_weapon` SET `name` = 'Corrosive Vipers', `icon` = 'Spell_Nature_CorrosiveBreath', `spell_id` = 33702, `behavior` = 19, `behavior_value` = 900009,
    `target` = 7, `cooldown_ms` = 7000, `range` = 6, `radius` = 5, `damage_fraction` = 0, `tick_ms` = 0, `duration_ms` = 4000,
    `applies` = 5, `apply_stacks` = 1, `flags` = 536870912,
    `description` = 'Places a trap that releases 4 vipers when an enemy comes close. Each viper rushes one of the 4 nearest enemies and bursts into a poison cloud for 4 sec. Enemies inside gain 1 stack of Poison and 1 stack of Nature Vulnerability every 0.5 sec.'
    WHERE `id` = 226;
UPDATE `bonk_weapon` SET `name` = 'Venom Burst', `icon` = 'Spell_Nature_Acid_01', `spell_id` = 33702, `behavior` = 19, `behavior_value` = 900009,
    `target` = 7, `cooldown_ms` = 7000, `range` = 6, `radius` = 3, `damage_fraction` = 1.0, `tick_ms` = 0, `duration_ms` = 2000,
    `applies` = 5, `apply_stacks` = 1, `flags` = 536870912,
    `description` = 'Places a trap that releases 4 vipers when an enemy comes close. Each viper rushes one of the 4 nearest enemies and explodes, dealing Nature damage and 5 stacks of Poison to enemies within 5 yards, then leaves a poison cloud for 2 sec. Enemies inside gain 1 stack of Poison every 0.5 sec.'
    WHERE `id` = 227;
DELETE FROM `bonk_weapon_upgrade` WHERE `weapon_id` IN (204, 226, 227);
INSERT INTO `bonk_weapon_upgrade` (`weapon_id`, `upgrade`, `step`) VALUES (204, 5, 15), (204, 9, 1), (204, 12, 4), (226, 5, 15), (226, 9, 1), (226, 12, 4), (227, 5, 15), (227, 9, 1), (227, 12, 4);

UPDATE `bonk_weapon` SET `name` = 'Volatile Trap', `icon` = 'Spell_Fire_Incinerate', `damage_fraction` = 1.5, `tick_ms` = 1000, `duration_ms` = 4000,
    `applies` = 3, `apply_stacks` = 1, `flags` = 1073741824,
    `description` = 'Places a fire trap that explodes when an enemy comes close, dealing damage and burning the ground for 4 sec, applying Burning. 2 sec later it explodes again for 60% damage.'
    WHERE `id` = 225;
DELETE FROM `bonk_weapon_upgrade` WHERE `weapon_id` = 225;
INSERT INTO `bonk_weapon_upgrade` (`weapon_id`, `upgrade`, `step`) VALUES (225, 5, 15), (225, 9, 1), (225, 12, 4), (225, 13, 10);

DELETE FROM `bonk_weapon_locale` WHERE `id` IN (204, 225, 226, 227);
DELETE FROM `bonk_mastery_locale` WHERE `id` IN (30305, 30306, 30322, 30331);

UPDATE `bonk_mastery` SET `description` = 'Explosive Trap fire and Viper Trap poison clouds last 15% longer.' WHERE `id` = 30305;
UPDATE `bonk_mastery` SET `description` = 'Viper Trap''s vipers freeze the normal enemies they reach. Once per enemy every 6 sec. Can''t be learned with Counterattack.' WHERE `id` = 30306;
UPDATE `bonk_mastery` SET `description` = 'Increases the radius of Viper Trap''s poison clouds by 30%.' WHERE `id` = 30322;
UPDATE `bonk_mastery` SET `name` = 'Lingering Venom', `description` = 'Viper Trap''s poison clouds last 3 sec longer.' WHERE `id` = 30331;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
