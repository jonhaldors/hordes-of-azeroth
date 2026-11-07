DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261021210000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261021210000');

UPDATE `bonk_weapon` SET `cooldown_ms` = 5000, `damage_fraction` = 2.0,
    `description` = 'A hammer of light slams the 3 strongest enemies within 20 yards for Holy damage, and critically strikes twice as often. Releases your Seals: Righteousness adds 50% damage, Command strikes every enemy within 5 yards of each target for half damage, Light heals you for 1% of your maximum health for each enemy hit.'
    WHERE `id` = 801;

UPDATE `bonk_weapon` SET
    `description` = 'Strikes the strongest enemy within 30 yards for heavy Holy damage. Undead and Demons take triple damage, elites and bosses double. When another Paladin spell critically strikes, Exorcism strikes at once, at most once every 2 sec.'
    WHERE `id` = 805;

UPDATE `bonk_weapon` SET `name` = 'Divine Storm', `icon` = 'Spell_Holy_SealOfWrath',
    `description` = 'A storm of holy light bursts around you, dealing Holy damage to every enemy within 8 yards. Heals you for 0.5% of your maximum health for each enemy hit, up to 3%.',
    `cooldown_ms` = 3000, `range` = 8, `damage_fraction` = 0.9, `spec` = 203
    WHERE `id` = 806;

DELETE FROM `bonk_weapon_upgrade` WHERE `weapon_id` IN (808, 812, 814);
DELETE FROM `bonk_weapon` WHERE `id` IN (808, 812, 814);
INSERT INTO `bonk_weapon` (`id`, `name`, `icon`, `description`, `spell_id`, `target`, `cooldown_ms`, `range`, `damage_fraction`, `class_mask`, `starter_class_mask`, `starter_option_mask`,
    `evolves_from`, `heal_pct`, `duration_ms`, `chains`, `behavior`, `behavior_value`, `tick_ms`, `base_targets`, `alt_spell_id`, `alt_every`, `alt_damage`, `base_jumps`, `kill_below_pct`,
    `flags`, `applies`, `apply_stacks`, `uses`, `uses_pct`, `spec`) VALUES
(812, 'Light''s Hammer', 'Spell_Holy_FistOfJustice', 'Hammers of light fall from the sky on 3 random enemies within 25 yards, each dealing Holy damage to every enemy within 5 yards of where it lands.',
    17286, 0, 4000, 25, 1.25, 2, 0, 0, 0, 0, 0, 0, 116, 0, 0, 3, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 201);

INSERT INTO `bonk_weapon_upgrade` (`weapon_id`, `upgrade`, `step`) VALUES
(812, 3, 8);

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
