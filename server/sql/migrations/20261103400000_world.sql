DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261103400000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261103400000');

UPDATE `bonk_weapon` SET `damage_fraction` = 3.5 WHERE `id` = 522;
UPDATE `bonk_weapon` SET `damage_fraction` = 7,
    `description` = 'The Light strikes the strongest enemy nearby, elites first, for heavy Holy damage, hits enemies within 8 yards of it for half and heals you for 3% of your maximum health. Each Smite or Halo reduces its cooldown by 1 sec.' WHERE `id` = 518;

UPDATE `bonk_mastery` SET `effect` = 45, `target` = 119, `value_per_rank` = 500,
    `description` = 'Each enemy Penance kills reduces its cooldown by 0.5 sec. Can''t be learned with Martyrdom.' WHERE `id` = 50107;
UPDATE `bonk_mastery` SET `value_per_rank` = 2,
    `description` = 'Each of your living pets gives you +2% Power.' WHERE `id` = 30130;
UPDATE `bonk_mastery` SET
    `description` = 'Your pets are always frenzied: +50% damage, and their attacks hit every enemy in front of them. Pack Leader''s howl makes them deal 25% more. Your other spells deal 25% less damage.' WHERE `id` = 30110;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
