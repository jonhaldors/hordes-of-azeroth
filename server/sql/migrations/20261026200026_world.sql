DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261026200026');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261026200026');

UPDATE `bonk_mastery` SET `value_per_rank` = 24.3, `description` = 'Increases the radius of Mortal Strike by 2 yards.' WHERE `id` = 10126;
UPDATE `bonk_mastery` SET `value_per_rank` = 24.3, `description` = 'Increases the radius of Cleave by 2 yards.' WHERE `id` = 10221;
UPDATE `bonk_mastery` SET `value_per_rank` = 32.3, `description` = 'Increases the radius of Thunder Clap by 2 yards.' WHERE `id` = 10321;
UPDATE `bonk_mastery` SET `value_per_rank` = 24.3, `description` = 'Increases the radius of Shield Slam by 2 yards.' WHERE `id` = 10323;
UPDATE `bonk_mastery` SET `value_per_rank` = 65.9, `description` = 'Increases the radius of Crusader Strike''s splash by 2 yards.' WHERE `id` = 20122;
UPDATE `bonk_mastery` SET `description` = 'Increases the radius of Light''s Hammer''s blasts by 10%.' WHERE `id` = 20123;
UPDATE `bonk_mastery` SET `value_per_rank` = 24.3, `description` = 'Increases the radius of Consecration by 2 yards.' WHERE `id` = 20221;
UPDATE `bonk_mastery` SET `value_per_rank` = 24.3, `description` = 'Increases the radius of Divine Storm by 2 yards.' WHERE `id` = 20321;
UPDATE `bonk_mastery` SET `value_per_rank` = 65.9, `description` = 'Increases the radius of Hunter''s Mark by 4 yards.' WHERE `id` = 30226;
UPDATE `bonk_mastery` SET `value_per_rank` = 41.6, `description` = 'Increases the radius of Frost Trap by 30%.' WHERE `id` = 30322;
UPDATE `bonk_mastery` SET `value_per_rank` = 41.6, `description` = 'Increases the radius of Explosive Trap''s explosion by 30%.' WHERE `id` = 30328;
UPDATE `bonk_mastery` SET `value_per_rank` = 24.3, `description` = 'Increases the radius of Fan of Knives by 2 yards.' WHERE `id` = 40104;
UPDATE `bonk_mastery` SET `value_per_rank` = 32.3, `description` = 'Increases the radius of Psychic Scream by 2 yards.' WHERE `id` = 50125;
UPDATE `bonk_mastery` SET `description` = 'Increases the radius of Halo by 6%.' WHERE `id` = 50204;
UPDATE `bonk_mastery` SET `value_per_rank` = 32.3, `description` = 'Increases the radius of Mind Blast''s shatter by 2 yards.' WHERE `id` = 50305;
UPDATE `bonk_mastery` SET `description` = 'Increases the radius of Magma Totem''s pulse by 10%.' WHERE `id` = 70305;
UPDATE `bonk_mastery` SET `value_per_rank` = 32.3, `description` = 'Increases the range of Searing Totem by 25%.' WHERE `id` = 70326;
UPDATE `bonk_mastery` SET `value_per_rank` = 41.6, `description` = 'Increases the radius of Pyroblast''s splash by 30%.' WHERE `id` = 80228;
UPDATE `bonk_mastery` SET `value_per_rank` = 24.3, `description` = 'Increases the radius of Hellfire by 20%.' WHERE `id` = 90325;
END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
