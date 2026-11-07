DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261022216000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261022216000');

UPDATE `bonk_keyword` SET `value_per_stack` = 0.1 WHERE `id` = 14;

UPDATE `bonk_pet_ability` SET `damage` = 2, `comment` = 'Imp: volley of 3 fel Firebolts from 30 yd, 2 bites worth each, 1 Burning each' WHERE `family` = 12 AND `spell_id` = 11763;
UPDATE `bonk_pet_ability` SET `value` = 10, `comment` = 'Succubus: Lash of Pain, every enemy in a wide arc in front of her within 10 yd, 2 bites worth, 1 Shadow Vulnerability' WHERE `family` = 14 AND `spell_id` = 7814;
UPDATE `bonk_pet_ability` SET `comment` = 'Felhunter: Shadow Bite, 4 bites worth, 10% more for each of your afflictions on the target; it also interrupts a casting prey' WHERE `family` = 15 AND `spell_id` = 17253;

UPDATE `bonk_weapon` SET `description` = 'Summons an Imp that hurls volleys of 3 fel Firebolts at enemies within 30 yards, leaving them burning.' WHERE `id` = 900;
UPDATE `bonk_weapon` SET `description` = 'Summons a Succubus whose Lash of Pain strikes all enemies in a wide arc in front of her and applies Shadow Vulnerability.' WHERE `id` = 902;
UPDATE `bonk_weapon` SET `description` = 'Summons a Felhunter whose Shadow Bite deals 10% more damage for each of your afflictions on the target (Decay, Agony, Burning) and interrupts spells. Every 10 sec it devours one harmful effect from you.' WHERE `id` = 903;
UPDATE `bonk_weapon` SET `cooldown_ms` = 1000, `base_targets` = 5, `apply_stacks` = 1, `damage_fraction` = 2.5,
    `description` = 'Every sec, corrupts the 5 nearest enemies, adding 1 stack of Decay. Stacks build up for as long as they stay near you, and each stack from Corruption is 2.5 times as strong.' WHERE `id` = 904;
UPDATE `bonk_weapon` SET `cooldown_ms` = 1500, `base_targets` = 5, `apply_stacks` = 1, `damage_fraction` = 0,
    `description` = 'Every 1.5 sec, curses the 5 enemies with the most health, adding 1 stack of Agony. Each stack deals more damage every sec it stays on the enemy.' WHERE `id` = 905;
UPDATE `bonk_weapon` SET `cooldown_ms` = 2000, `apply_stacks` = 2,
    `description` = 'Fel fire strikes the 2 nearest enemies and applies 2 stacks of Burning.' WHERE `id` = 908;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
