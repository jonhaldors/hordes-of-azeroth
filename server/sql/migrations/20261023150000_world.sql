DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261023150000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261023150000');

UPDATE `bonk_pet_ability` SET `damage` = 3, `comment` = 'Imp: volley of 2 fel Firebolts at different enemies from 30 yd, 3 bites worth each, 1 Burning each' WHERE `family` = 12 AND `spell_id` = 11763;
UPDATE `bonk_weapon` SET `description` = 'Summons an Imp that hurls volleys of 2 fel Firebolts at different enemies within 30 yards, leaving them burning.' WHERE `id` = 900;
UPDATE `bonk_weapon` SET `description` = 'Summons an Imp that hurls volleys of 2 fel Firebolts at different enemies within 30 yards. Each Firebolt jumps to 2 additional nearby enemies for 60% damage.' WHERE `id` = 911;
UPDATE `bonk_weapon` SET `description` = 'Summons an Imp that hurls volleys of 2 fel Firebolts at different enemies. An enemy killed by its Firebolts calls a lesser Imp that fights for 6 sec, up to 6 at once.' WHERE `id` = 912;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
