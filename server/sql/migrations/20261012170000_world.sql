DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261012170000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261012170000');

UPDATE `bonk_passive` SET `name` = 'Blessing of Might',     `icon` = 'Spell_Holy_FistOfJustice',   `description` = '+10% Power.' WHERE `id` = 1;
UPDATE `bonk_passive` SET `name` = 'Berserking',            `icon` = 'Racial_Troll_Berserk',       `description` = '+8% Haste: spells fire and tick 8% more often.' WHERE `id` = 2;
UPDATE `bonk_passive` SET `name` = 'Aspect of the Cheetah', `icon` = 'Ability_Mount_JungleTiger',  `description` = '+10% movement speed.' WHERE `id` = 4;
UPDATE `bonk_passive` SET `name` = 'Power Word: Fortitude', `icon` = 'Spell_Holy_WordFortitude',   `description` = '+15% maximum health.' WHERE `id` = 5;
UPDATE `bonk_passive` SET `name` = 'Rested',                `icon` = 'Spell_Nature_Sleep',         `description` = '+15% experience.' WHERE `id` = 8;
UPDATE `bonk_passive` SET `name` = 'Goblin Grabber',        `icon` = 'INV_Gizmo_02',               `description` = '+30% pickup range for experience orbs and turkey legs.' WHERE `id` = 9;
UPDATE `bonk_passive` SET `name` = 'Arcane Brilliance',     `icon` = 'Spell_Holy_ArcaneIntellect', `description` = '+10% Area: bigger area spells and melee reach.' WHERE `id` = 11;
UPDATE `bonk_passive` SET `description` = 'Regain 0.5% of your health every second.' WHERE `id` = 6;

DELETE FROM `bonk_passive` WHERE `id` IN (3, 7, 10, 12);

UPDATE `bonk_quest` SET `reward_value` = 18 WHERE `id` = 50 AND `reward_type` = 3 AND `reward_value` = 12;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
