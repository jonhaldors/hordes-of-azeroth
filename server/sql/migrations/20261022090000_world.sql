DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261022090000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261022090000');

UPDATE `bonk_card` SET `description` = 'When below 35% health, heal for 30% of your maximum health. 60 sec cooldown, 15% shorter per additional copy.' WHERE `id` = 1;
UPDATE `bonk_card` SET `description` = 'Critical strikes have a 25% chance to heal 1% of your maximum health, at most 2% a second.' WHERE `id` = 8;
UPDATE `bonk_card` SET `description` = 'Gain a Shield of 8% of your maximum health. When it breaks, fire scorches enemies within 8 yards.' WHERE `id` = 11;
UPDATE `bonk_card` SET `description` = 'After you are hit, take no damage for 0.5 sec. 8 sec cooldown, 15% shorter per additional copy.' WHERE `id` = 13;
UPDATE `bonk_card` SET `description` = 'Your hits have a 3% chance to erupt in flame for 150% of the hit within 6 yards.' WHERE `id` = 16;
UPDATE `bonk_card` SET `description` = 'Your hits have a 3% chance to call lightning on 3 enemies for 100% of the hit.' WHERE `id` = 18;
UPDATE `bonk_card` SET `description` = 'Your next level-up offers an evolution for a spell at rank 10 or higher. Used up once offered.' WHERE `id` = 31;
UPDATE `bonk_card` SET `description` = 'Your hits have a 6% chance to call Chain Lightning on 5 enemies for 150% of the hit.' WHERE `id` = 101;
UPDATE `bonk_card` SET `description` = 'Your hits have a 5% chance to unleash shadow for 200% of the hit within 8 yards, healing you 10% of it.' WHERE `id` = 102;
UPDATE `bonk_card` SET `description` = 'Your hits have a 6% chance to erupt in flame for 200% of the hit within 8 yards.' WHERE `id` = 103;
UPDATE `bonk_card` SET `description` = '+1 Count and +15% Area for all your spells.' WHERE `id` = 105;
UPDATE `bonk_card` SET `description` = 'Critical strikes have a 50% chance to heal 1% of your maximum health, at most 3% a second.' WHERE `id` = 106;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
