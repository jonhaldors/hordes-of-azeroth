DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261012031000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261012031000');

UPDATE `bonk_weapon` SET `spell_id` = 8078, `range` = 10, `damage_fraction` = 0.5,
    `description` = 'Thunder around you that damages and slows every enemy it hits.'
    WHERE `id` = 1;

UPDATE `bonk_passive` SET `description` = '+10% spell damage.' WHERE `id` = 1;
UPDATE `bonk_passive` SET `description` = 'Spells recharge 8% faster.' WHERE `id` = 2;
UPDATE `bonk_passive` SET `description` = '+1 projectile for bolt spells.' WHERE `id` = 3;
UPDATE `bonk_passive` SET `description` = 'Heal for 2% of the damage your spells deal.' WHERE `id` = 10;

UPDATE `bonk_upgrade` SET `description` = '+5% spell damage.' WHERE `id` = 1;
UPDATE `bonk_upgrade` SET `description` = 'Spells recharge 4% faster.' WHERE `id` = 2;
UPDATE `bonk_upgrade` SET `description` = '+1 projectile for bolt spells.' WHERE `id` = 8;

UPDATE `bonk_item_set_bonus` SET `description` = 'Spells recharge 8% faster.' WHERE `set_id` = 2 AND `pieces` = 2;
UPDATE `bonk_item_set_bonus` SET `description` = '+15% Power, and heal for 3% of the damage your spells deal.' WHERE `set_id` = 2 AND `pieces` = 4;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
