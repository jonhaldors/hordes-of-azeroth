DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261025130000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261025130000');

DELETE FROM `bonk_weapon_upgrade` WHERE `weapon_id` IN (1000, 1013);
DELETE FROM `bonk_weapon` WHERE `id` IN (1000, 1013);
INSERT INTO `bonk_weapon` (`id`, `name`, `icon`, `description`, `spell_id`, `target`, `cooldown_ms`, `range`, `damage_fraction`, `class_mask`, `starter_class_mask`, `starter_option_mask`,
    `evolves_from`, `heal_pct`, `duration_ms`, `chains`, `behavior`, `behavior_value`, `tick_ms`, `base_targets`, `alt_spell_id`, `alt_every`, `alt_damage`, `base_jumps`, `kill_below_pct`,
    `flags`, `applies`, `apply_stacks`, `uses`, `uses_pct`, `spec`) VALUES
(1013, 'Shapeshift', 'Ability_Druid_CatForm', 'Your Shapeshift key (R by default) shifts you into your next form: Moonkin, Cat, Bear, then Tree of Life. Each form attacks on its own. Moonkin hurls Wrath at the nearest enemy, filling Lunar Eclipse. Cat claws the nearest enemy quickly and applies 1 stack of Bleed. Bear mauls up to 3 nearby enemies, and you take 35% less damage but deal 20% less with your other spells. Tree of Life lashes 3 enemies with vines, each hit healing you for 0.15% of your maximum health. Your other Druid spells deal and heal 30% more in their own form.',
    5176, 0, 1500, 30, 1.0, 1024, 1024, 0, 0, 0, 0, 0, 131, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0);

INSERT INTO `bonk_weapon_upgrade` (`weapon_id`, `upgrade`, `step`) VALUES
(1013, 2, 10), (1013, 3, 8);

UPDATE `bonk_weapon` SET `description` = 'Moonkin form spell. Calls down a bolt of starlight on the strongest enemy within 30 yards. Each Starfire brings Solar Eclipse closer, twice as fast against moonfired enemies. Solar Eclipse lasts 8 sec: your Nature spells deal 50% more damage. Lunar Eclipse, filled by Wrath in Moonkin form, makes Starfire always critically strike.' WHERE `id` = 1001;
UPDATE `bonk_weapon` SET `description` = 'Moonkin form spell. Every sec, burns the 5 nearest enemies with moonlight, applying 1 stack of Moonfire. Enemies without Moonfire are chosen first. Wrath and Starfire fill Eclipse twice as fast against moonfired enemies.' WHERE `id` = 1002;
UPDATE `bonk_weapon` SET `description` = CONCAT('Moonkin form spell. ', `description`) WHERE `id` = 1003;
UPDATE `bonk_weapon` SET `description` = CONCAT('Cat form spell. ', `description`) WHERE `id` IN (1004, 1005);
UPDATE `bonk_weapon` SET `description` = CONCAT('Bear form spell. ', `description`) WHERE `id` IN (1006, 1007, 1012);
UPDATE `bonk_weapon` SET `description` = CONCAT('Tree of Life spell. ', `description`) WHERE `id` IN (1008, 1009, 1010, 1011);

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
