DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261025420000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261025420000');

UPDATE `bonk_glyph` SET `description` = '+60% pickup range. Power-ups last twice as long.' WHERE `id` = 2;
UPDATE `bonk_glyph` SET `description` = 'When an elite, mini-boss or boss dies within 30 yards, heal for 30% of your maximum health.' WHERE `id` = 5;
UPDATE `bonk_glyph` SET `description` = 'Capture Ley Lines twice as fast. They offer 4 blessings.' WHERE `id` = 6;
UPDATE `bonk_glyph` SET `drawback` = 'Chests have a 10% chance to explode for 10% of your maximum health.' WHERE `id` = 9;
UPDATE `bonk_glyph` SET `description` = 'Once per stage, fatal damage restores you to full health instead.' WHERE `id` = 11;
UPDATE `bonk_glyph` SET `description` = 'Level-up spell ranks are 1 rarity higher.', `drawback` = 'Level-ups offer 2 choices and can''t be rerolled.' WHERE `id` = 15;
UPDATE `bonk_glyph` SET `description` = 'Every 3 sec, lightning strikes up to 8 nearby enemies. Always critically strikes.' WHERE `id` = 16;
UPDATE `bonk_glyph` SET `description` = 'Every 6 sec, a meteor strikes the largest nearby group of enemies.' WHERE `id` = 17;
UPDATE `bonk_glyph` SET `description` = '+1 dash charge. Dash recharges 30% faster.' WHERE `id` = 18;
UPDATE `bonk_glyph` SET `description` = '+2 rerolls each stage.' WHERE `id` = 19;
UPDATE `bonk_glyph` SET `description` = 'An extra chest appears near you a minute into each stage.' WHERE `id` = 20;
UPDATE `bonk_glyph` SET `description` = 'Elites you kill drop a power-up.' WHERE `id` = 21;
UPDATE `bonk_glyph` SET `description` = 'Your starter spell starts 2 ranks higher.' WHERE `id` = 22;
UPDATE `bonk_glyph` SET `description` = 'Mini-boss waves bring 1 extra mini-boss. Mini-bosses give double rewards.' WHERE `id` = 23;
UPDATE `bonk_glyph` SET `description` = 'Twice as many elites, each giving triple experience.', `drawback` = 'More elites, more danger.' WHERE `id` = 24;
UPDATE `bonk_glyph` SET `description` = 'Below 30% health, +40% Haste and +20% movement speed.' WHERE `id` = 25;
UPDATE `bonk_glyph` SET `description` = '+30% Power and Armor while standing still.' WHERE `id` = 26;
UPDATE `bonk_glyph` SET `description` = '+25% Power while moving.', `drawback` = 'Losing health flips it to -25% Power for 5 sec. Shield absorbs don''t count.' WHERE `id` = 27;

UPDATE `bonk_card` SET `description` = '+60% pickup range. Power-ups last twice as long.' WHERE `id` = 151;
UPDATE `bonk_card` SET `description` = 'Your hits have a 3% chance to deal 150% of the hit as Fire within 6 yards.' WHERE `id` = 16;
UPDATE `bonk_card` SET `description` = 'Your hits have a 3% chance to strike 3 enemies with lightning for 100% of the hit.' WHERE `id` = 18;
UPDATE `bonk_card` SET `description` = 'Your hits have a 6% chance to cast Chain Lightning, striking 5 enemies for 150% of the hit.' WHERE `id` = 101;
UPDATE `bonk_card` SET `description` = 'Your hits have a 5% chance to deal 200% of the hit as Shadow within 8 yards, healing you for 10% of the damage.' WHERE `id` = 102;
UPDATE `bonk_card` SET `description` = 'Your hits have a 6% chance to deal 200% of the hit as Fire within 8 yards.' WHERE `id` = 103;
UPDATE `bonk_card` SET `description` = '+1 Count and +15% Area.' WHERE `id` = 105;

UPDATE `item_template` i JOIN `bonk_item_card` ic ON ic.`entry` = i.`entry` JOIN `bonk_card` c ON c.`id` = ic.`card_id`
SET i.`description` = c.`description` WHERE i.`description` NOT LIKE '%Extraction Vault%';

UPDATE `bonk_passive` SET `description` = '+{8}% Haste.' WHERE `id` = 2;
UPDATE `bonk_passive` SET `description` = '+{30}% pickup range.' WHERE `id` = 9;
UPDATE `bonk_passive` SET `description` = '+{10}% Area.' WHERE `id` = 11;
UPDATE `bonk_passive` SET `description` = '+{10} Armor.' WHERE `id` = 13;
UPDATE `bonk_passive` SET `description` = '+{5}% dodge chance.' WHERE `id` = 15;
UPDATE `bonk_passive` SET `description` = 'Gain a Shield of {10}% of your maximum health.' WHERE `id` = 17;
UPDATE `bonk_passive` SET `description` = '+{5} Luck.' WHERE `id` = 18;
UPDATE `bonk_passive` SET `description` = '+{1} Count.' WHERE `id` = 19;
UPDATE `bonk_passive` SET `description` = 'Your hits have a {10}% chance to heal you for 1% of your maximum health, up to {0.3}% per second.' WHERE `id` = 20;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
