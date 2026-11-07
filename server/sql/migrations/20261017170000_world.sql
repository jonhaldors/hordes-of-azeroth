DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261017170000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261017170000');

ALTER TABLE `bonk_card` MODIFY `description` VARCHAR(1024) NOT NULL DEFAULT '';
ALTER TABLE `bonk_glyph` MODIFY `description` VARCHAR(1024) NOT NULL DEFAULT '';
ALTER TABLE `bonk_item_set_bonus` MODIFY `description` VARCHAR(1024) NOT NULL;
ALTER TABLE `bonk_mastery` MODIFY `description` VARCHAR(1024) NOT NULL;
ALTER TABLE `bonk_passive` MODIFY `description` VARCHAR(1024) NOT NULL DEFAULT '';
ALTER TABLE `bonk_quest` MODIFY `description` VARCHAR(1024) NOT NULL;
ALTER TABLE `bonk_talent` MODIFY `description` VARCHAR(1024) NOT NULL DEFAULT '';
ALTER TABLE `bonk_tier` MODIFY `description` VARCHAR(1024) NOT NULL DEFAULT '';
ALTER TABLE `bonk_upgrade` MODIFY `description` VARCHAR(1024) NOT NULL DEFAULT '';
ALTER TABLE `bonk_weapon` MODIFY `description` VARCHAR(1024) NOT NULL DEFAULT '';

UPDATE `bonk_weapon` SET `description` = 'Marks every enemy within 10 yards of the largest group for 8 sec. Marked enemies take 15% more damage. The flare burns on the ground for 6 sec, and each of your shots that hits an enemy inside it fires 1 additional shot at the nearest other enemy inside it.' WHERE `id` = 220;
UPDATE `bonk_weapon` SET `description` = 'A spirit wolf fights for you. Every 15 sec it howls, and your other pets deal double damage to all enemies in front for 6 sec. Each howl also calls a Boar, a Bear or a Wyvern for 8 sec. The Boar charges through the largest group of enemies, the Bear mauls enemies around it and leaves them bleeding, and the Wyvern''s screech makes all your pets deal 20% more damage.' WHERE `id` = 230;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
