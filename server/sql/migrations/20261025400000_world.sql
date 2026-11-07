DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261025400000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261025400000');

UPDATE `bonk_weapon` SET `description` = CONCAT(
    'Press R to shift into your next form. Druid spells deal and heal 30% more in their form.|n|n',
    '|cffffffffMoonkin Form:|r Wrath strikes the nearest enemy for Nature damage, splashing nearby enemies. Every 3 sec, Starfall strikes 3 enemies afflicted by Moonfire.|n|n',
    '|cffffffffCat Form:|r Claws the nearest enemy for Physical damage and causes Bleed. Movement speed increased by 15%. Critical strikes cause Bleed.|n|n',
    '|cffffffffBear Form:|r Mauls the nearest enemy for Physical damage. Damage taken reduced by 35%, but spells of other forms deal 20% less. Swipe deals 8% more per nearby enemy. Every 6 sec, roars to Daze nearby enemies and reduce their damage by 25%.|n|n',
    '|cffffffffTree of Life:|r Vines lash 3 enemies for Nature damage, each hit healing you for 0.3% of your maximum health. Calls 1 additional Treant. Rejuvenation blooms 50% faster.')
    WHERE `id` = 1013;
UPDATE `bonk_weapon` SET `description` = 'Calls down starlight on the strongest enemy for heavy Arcane damage. Empowered in Moonkin Form.' WHERE `id` = 1001;
UPDATE `bonk_weapon` SET `description` = 'Burns the 2 nearest enemies for Arcane damage and applies 1 stack of Moonfire. Empowered in Moonkin Form.' WHERE `id` = 1002;
UPDATE `bonk_weapon` SET `description` = 'A storm rages over the largest group of enemies for 4 sec, dealing Nature damage every sec and Dazing them. Empowered in Moonkin Form.' WHERE `id` = 1003;
UPDATE `bonk_weapon` SET `description` = 'Rakes the 3 nearest enemies for damage and 2 stacks of Bleed. Empowered in Cat Form.' WHERE `id` = 1004;
UPDATE `bonk_weapon` SET `description` = 'Shreds the most Bleeding enemy for damage, increased by 3% per stack of Bleed on it. Empowered in Cat Form.' WHERE `id` = 1005;
UPDATE `bonk_weapon` SET `description` = 'Swipes all nearby enemies for damage. Empowered in Bear Form.' WHERE `id` = 1006;
UPDATE `bonk_weapon` SET `description` = 'Every sec, heals you for 0.25% of your maximum health per nearby enemy, up to 5. Empowered in Bear Form.' WHERE `id` = 1007;
UPDATE `bonk_weapon` SET `description` = 'Heals you for 0.3% of your maximum health. Its thorny bloom lashes the 3 nearest enemies for Nature damage. Empowered in Tree of Life.' WHERE `id` = 1008;
UPDATE `bonk_weapon` SET `description` = 'Summons 2 Treants. Their attacks apply Moonfire, and every 6 sec they root their target and nearby enemies for 2 sec. Empowered in Tree of Life, which calls 1 additional Treant.' WHERE `id` = 1009;
UPDATE `bonk_weapon` SET `description` = 'Roots grasp the 3 nearest enemies for Nature damage and root them for 2 sec. Empowered in Tree of Life.' WHERE `id` = 1010;
UPDATE `bonk_weapon` SET `description` = 'Calms the air for 4 sec. Every sec, deals Nature damage to nearby enemies and heals you for 0.5% of your maximum health. Empowered in Tree of Life.' WHERE `id` = 1011;
UPDATE `bonk_weapon` SET `description` = 'Enemies that strike you take Nature damage. Empowered in Bear Form.' WHERE `id` = 1012;

UPDATE `bonk_weapon` `e` JOIN `bonk_weapon` `b` ON `b`.`id` = `e`.`evolves_from` SET `e`.`description` = CONCAT(`b`.`description`, ' ', CASE `e`.`id`
    WHEN 1014 THEN 'The starlight bursts, dealing 15% damage to nearby enemies and applying Moonfire.'
    WHEN 1015 THEN 'Enemies afflicted by Moonfire have a chance to be struck by Shooting Stars.'
    WHEN 1016 THEN 'Moonfire spreads to up to 3 nearby enemies of each target.'
    WHEN 1017 THEN 'Every 10th stack of Moonfire on an enemy calls down a Full Moon, dealing Arcane damage to it and nearby enemies.'
    WHEN 1018 THEN 'When the storm ends, it bursts for double damage and knocks enemies back.'
    WHEN 1019 THEN 'Every 2 sec, the storm applies Moonfire to enemies inside.'
    WHEN 1021 THEN 'Each Rake grants 5% Haste per enemy hit for 4 sec, up to 25%.'
    WHEN 1022 THEN 'Also mangles up to 4 nearby enemies for 25% damage.'
    WHEN 1023 THEN 'If it kills, it bites the next most Bleeding enemy, up to 3 times.'
    WHEN 1024 THEN 'Causes 1 stack of Bleed.'
    WHEN 1025 THEN 'Leaves a vortex for 3 sec that deals 50% damage and Dazes enemies inside every sec.'
    WHEN 1026 THEN 'Each tick also mauls up to 5 nearby enemies for damage.'
    WHEN 1027 THEN 'Each tick also grants a Shield of the same amount, up to 10% of your maximum health.'
    WHEN 1028 THEN 'Every 4th bloom heals you for 1% of your maximum health and deals Nature damage to all nearby enemies.'
    WHEN 1031 THEN 'Their roots plant mushrooms that burst after 3 sec, dealing Nature damage to nearby enemies.'
    WHEN 1032 THEN 'The roots spread to nearby enemies.'
    WHEN 1033 THEN 'Rooted enemies take Nature damage every sec, healing you for 0.05% of your maximum health each, up to 0.5% per sec.'
    WHEN 1034 THEN 'Each pulse reaches 3 yards further.'
    WHEN 1035 THEN 'Excess healing deals up to 60% additional damage to nearby enemies.'
    WHEN 1036 THEN 'Thorns also strike all other nearby enemies for 50% damage.'
    WHEN 1037 THEN 'Enemies that strike you are rooted for 1 sec.'
    WHEN 1038 THEN '|n|n|cffffffffShifting Surge:|r Entering a form unleashes it, once per 6 sec per form. Moonkin calls Starfall on 5 enemies, Cat causes 2 stacks of Bleed on nearby enemies, Bear roars, and Tree roots nearby enemies and heals you for 2% of your maximum health.'
    WHEN 1039 THEN '|n|n|cffffffffSpirit Forms:|r The form you leave stays behind as a spirit for 6 sec, attacking for 25% damage.'
    END)
    WHERE `e`.`id` IN (1014, 1015, 1016, 1017, 1018, 1019, 1021, 1022, 1023, 1024, 1025, 1026, 1027, 1028, 1031, 1032, 1033, 1034, 1035, 1036, 1037, 1038, 1039);
UPDATE `bonk_weapon` SET `description` = 'Thrashes all nearby enemies for damage and 1 stack of Bleed. Empowered in Cat Form.' WHERE `id` = 1020;
UPDATE `bonk_weapon` SET `description` = 'Grows a ring of flowers at your feet for 4 sec. While inside, you are healed for 0.3% of your maximum health every sec, and enemies inside take Nature damage. Empowered in Tree of Life.' WHERE `id` = 1029;
UPDATE `bonk_weapon` SET `description` = 'Summons an Ancient of War. Every 3 sec it stomps, dealing Nature damage to nearby enemies and applying Moonfire. Empowered in Tree of Life.' WHERE `id` = 1030;

UPDATE `bonk_mastery` SET `description` = 'You no longer shapeshift, and Shapeshift hurls Wrath for 35% less damage. Druid spells deal and heal 15% more per talent tree they come from, up to 45%.' WHERE `id` = 110310;
UPDATE `bonk_mastery` SET `description` = 'Starfall strikes in every form and hits 2 additional enemies. Your Power is reduced by 15%.' WHERE `id` = 110110;
UPDATE `bonk_mastery` SET `description` = 'In Cat Form, damage taken is reduced by 20%. In Bear Form, movement speed is increased by 15% and critical strikes cause Bleed. Your Power is reduced by 15%.' WHERE `id` = 110210;

DELETE FROM `bonk_weapon_upgrade` WHERE `weapon_id` = 1002 AND `upgrade` = 9;
INSERT INTO `bonk_weapon_upgrade` (`weapon_id`, `upgrade`, `step`) VALUES (1002, 18, 1), (1005, 1, 10), (1010, 18, 1);
DELETE FROM `bonk_weapon_upgrade` WHERE `weapon_id` BETWEEN 1014 AND 1039;
INSERT INTO `bonk_weapon_upgrade` (`weapon_id`, `upgrade`, `step`)
SELECT `w`.`id`, `u`.`upgrade`, `u`.`step` FROM `bonk_weapon` `w` JOIN `bonk_weapon_upgrade` `u` ON `u`.`weapon_id` = `w`.`evolves_from`
WHERE `w`.`id` BETWEEN 1014 AND 1039;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
