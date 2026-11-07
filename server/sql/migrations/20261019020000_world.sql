DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261019020000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261019020000');

DELETE FROM `bonk_keyword` WHERE `id` = 12;
INSERT INTO `bonk_keyword` (`id`, `name`, `icon`, `spell_id`, `max_stacks`, `value_per_stack`, `tick_ms`, `duration_ms`, `spreads_on_death`, `description`) VALUES
(12, 'Nature Vulnerability', 'Spell_Holy_SealOfMight', 17364, 5, 4, 0, 12000, 0,
 'Increases Nature damage taken by 4% per stack. Stacks up to 5 times.');

DELETE FROM `spell_effect_mod` WHERE `Id` = 8042 AND `EffectIndex` = 1;
INSERT INTO `spell_effect_mod` (`Id`, `EffectIndex`, `Effect`, `EffectApplyAuraName`, `Comment`) VALUES
(8042, 1, 0, 0, 'Earth Shock: no interrupt');

UPDATE `bonk_weapon` SET `spell_id` = 8042, `target` = 0, `cooldown_ms` = 4000, `range` = 25, `damage_fraction` = 0.8, `behavior` = 83, `base_targets` = 1,
    `flags` = 128, `applies` = 0, `apply_stacks` = 0, `uses` = 11, `uses_pct` = 50
WHERE `id` IN (703, 718, 719);
UPDATE `bonk_weapon` SET `name` = 'Earth Shock', `icon` = 'Spell_Nature_EarthShock',
    `description` = 'Shocks the enemy with the most stacks of Static, dealing Nature damage. Deals 50% more damage for each stack of Static on the target, then consumes them in a discharge that also strikes up to 3 nearby enemies.'
WHERE `id` = 703;
UPDATE `bonk_weapon` SET
    `description` = 'Shocks the enemy with the most stacks of Static, dealing Nature damage. Deals 50% more damage for each stack of Static on the target, then consumes them in a discharge that also strikes up to 3 nearby enemies. The ground around the target shakes for 4 seconds; enemies inside are Dazed and take Nature damage every second.'
WHERE `id` = 718;
UPDATE `bonk_weapon` SET
    `description` = 'Shocks the enemy with the most stacks of Static, dealing Nature damage. Deals 50% more damage for each stack of Static on the target, then consumes them in a discharge that also strikes up to 3 nearby enemies. Every Static discharge within 10 yards of you also strikes all enemies within 6 yards of it.'
WHERE `id` = 719;
DELETE FROM `bonk_weapon_upgrade` WHERE `weapon_id` IN (703, 718, 719);
INSERT INTO `bonk_weapon_upgrade` (`weapon_id`, `upgrade`, `step`) VALUES
(703, 1, 10), (703, 2, 10), (703, 3, 8),
(718, 1, 10), (718, 2, 10), (718, 3, 8),
(719, 1, 10), (719, 2, 10), (719, 3, 8);

UPDATE `bonk_weapon` SET `target` = 4, `base_targets` = 1, `range` = 25, `damage_fraction` = 0.8, `apply_stacks` = 6 WHERE `id` IN (702, 716, 717);
UPDATE `bonk_weapon` SET `description` = 'Shocks the strongest enemy nearby, elites first, dealing Fire damage and applying 6 stacks of Burning.' WHERE `id` = 702;
UPDATE `bonk_weapon` SET `description` = 'Shocks the strongest enemy nearby, elites first, with frost, dealing Frost damage and applying 6 stacks of Chill.' WHERE `id` = 716;
UPDATE `bonk_weapon` SET `description` = 'Shocks the strongest enemy nearby, elites first, dealing Fire damage and applying 6 stacks of Burning. When a Burning enemy dies, Lightning Bolt fires at once.' WHERE `id` = 717;

UPDATE `bonk_weapon` SET `base_targets` = 1, `damage_fraction` = 1.5, `applies` = 12, `apply_stacks` = 2 WHERE `id` IN (705, 722, 723);
UPDATE `bonk_weapon` SET `description` = 'Strikes the nearest enemy within 12 yards twice, once with your weapon and once with lightning, applying 2 stacks of Static and 2 stacks of Nature Vulnerability.' WHERE `id` = 705;
UPDATE `bonk_weapon` SET `description` = 'Strikes the nearest enemy within 12 yards twice, once with your weapon and once with molten lava, applying 2 stacks of Static, 2 stacks of Nature Vulnerability and 2 stacks of Burning. The lava deals 50% more damage to Burning enemies.' WHERE `id` = 722;
UPDATE `bonk_weapon` SET `description` = 'Strikes the nearest enemy within 12 yards twice, once with your weapon and once with lightning, applying 2 stacks of Static and 2 stacks of Nature Vulnerability. The lightning also strikes all enemies within 8 yards of you, applying 1 stack of Static.' WHERE `id` = 723;

UPDATE `bonk_mastery` SET `name` = 'Improved Earth Shock', `icon` = 'Spell_Nature_EarthShock', `effect` = 20, `target` = 703, `value_per_rank` = 1,
    `description` = 'Earth Shock stuns normal enemies it hits for 1 sec. Each enemy can only be stunned once every 6 sec.'
WHERE `id` = 70106;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
