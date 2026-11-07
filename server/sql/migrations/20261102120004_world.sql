DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261102120004');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261102120004');

DELETE FROM `spell_template` WHERE `entry` = 33701;
DROP TEMPORARY TABLE IF EXISTS `bonk_maelstrom_bolt`;
CREATE TEMPORARY TABLE `bonk_maelstrom_bolt` SELECT * FROM `spell_template` WHERE `entry` = 8246;
UPDATE `bonk_maelstrom_bolt` SET `entry` = 33701, `name` = 'Maelstrom Weapon';
INSERT INTO `spell_template` SELECT * FROM `bonk_maelstrom_bolt`;
DROP TEMPORARY TABLE IF EXISTS `bonk_maelstrom_bolt`;

UPDATE `bonk_weapon` SET `spell_id` = 33701 WHERE `id` IN (706, 724, 725);
UPDATE `bonk_weapon` SET `damage_fraction` = 2.0 WHERE `id` = 706;
UPDATE `bonk_weapon` SET `damage_fraction` = 2.4 WHERE `id` IN (724, 725);
UPDATE `bonk_weapon` SET `description` = 'Every 3rd hit from your other Shaman spells and Feral Spirit bites hurls a free Lightning Bolt at the nearest enemy, or at the 3 nearest if you have Chain Lightning, dealing Nature damage. Totem hits don''t count.' WHERE `id` = 706;
UPDATE `bonk_weapon` SET `description` = 'Every 3rd hit from your other Shaman spells and Feral Spirit bites hurls a free Lightning Bolt at the 3 nearest enemies, or at the 5 nearest if you have Chain Lightning, dealing Nature damage. Totem hits don''t count.' WHERE `id` = 724;
UPDATE `bonk_weapon` SET `description` = 'Every 3rd hit from your other Shaman spells and Feral Spirit bites hurls a free Lightning Bolt at the nearest enemy, or at the 3 nearest if you have Chain Lightning, dealing Nature damage and 5 stacks of Static, so it discharges at once. Totem hits don''t count.' WHERE `id` = 725;
UPDATE `bonk_mastery` SET `description` = 'Windfury Weapon triggers Windfury every 2nd swing instead of every 3rd. Maelstrom Weapon needs 2 hits instead of 3.' WHERE `id` = 70210;

UPDATE `bonk_weapon` SET `description` = 'Surrounds you with up to 3 lightning charges. Every 1.5 sec it zaps 1 enemy within 10 yards for each charge you hold, dealing Nature damage and 1 stack of Static, and each zap gives you a Shield of 0.5% of your maximum health, up to 5%. An enemy that strikes you spends a charge and is zapped too. One charge returns every 1.5 sec.' WHERE `id` = 711;
UPDATE `bonk_weapon` SET `description` = 'Surrounds you with up to 3 lightning charges. Every 1.5 sec it zaps 1 enemy within 10 yards for each charge you hold, dealing Nature damage and 1 stack of Static, and each zap gives you a Shield of 1.5% of your maximum health, up to 15%. An enemy that strikes you spends a charge and is zapped too. One charge returns every 1.5 sec.' WHERE `id` = 734;
UPDATE `bonk_weapon` SET `description` = 'Surrounds you with up to 3 lightning charges. Every 1.5 sec it zaps 1 enemy within 10 yards for each charge you hold, plus enemies within 4 yards of each, dealing Nature damage and 1 stack of Static, and each zap gives you a Shield of 0.5% of your maximum health, up to 5%. When an enemy strikes you or your melee hits land, a charge is spent on another zap. One charge returns every 1.5 sec.' WHERE `id` = 735;

UPDATE `bonk_weapon` SET `damage_fraction` = 1.8 WHERE `id` = 703;
UPDATE `bonk_weapon` SET `damage_fraction` = 1.2 WHERE `id` IN (718, 719);
UPDATE `bonk_weapon` SET `damage_fraction` = 3.0 WHERE `id` = 705;
UPDATE `bonk_weapon` SET `damage_fraction` = 2.6 WHERE `id` IN (722, 723);

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
