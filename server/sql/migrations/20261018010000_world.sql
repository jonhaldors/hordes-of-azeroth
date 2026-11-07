DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261018010000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261018010000');

ALTER TABLE `bonk_pet_ability` ADD COLUMN IF NOT EXISTS `kit` INT(10) UNSIGNED NOT NULL DEFAULT 0 AFTER `value`;

DELETE FROM `bonk_pet_ability` WHERE `kind` = 3 AND `family` IN (2, 3, 4);
INSERT INTO `bonk_pet_ability` (`family`, `spell_id`, `kind`, `cooldown_ms`, `damage`, `stacks`, `value`, `kit`, `comment`) VALUES
(2, 122,   3, 5000, 1,   2, 6, 160,  'Water Elemental: small Frost Nova, 6 yd, 1 bite worth, 2 Chill, no root'),
(3, 20153, 3, 2000, 0.5, 1, 5, 6310, 'Fire Elemental: burning aura, 5 yd, half a bite worth, 1 Burning'),
(4, 1449,  3, 3000, 1.5, 0, 6, 1004, 'Arcane Elemental: small Arcane Explosion, 6 yd, 1.5 bites worth');

UPDATE `bonk_weapon` SET `description` = 'Summons an elemental to fight for you, following the school most of your spells belong to. A Water Elemental casts Frostbolts that apply Chill, and a small Frost Nova every 5 sec that applies 2 stacks of Chill to enemies within 6 yards. A Fire Elemental casts Fireballs that leave enemies burning, and burns enemies within 5 yards every 2 sec, applying 1 stack of Burning. An Arcane Elemental casts Arcane Bolts, and a small Arcane Explosion every 3 sec that hits enemies within 6 yards.' WHERE `id` = 410;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
