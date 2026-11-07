DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261025250000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261025250000');

UPDATE `bonk_weapon` SET `description` = CONCAT(
    'Shapeshift (R) shifts you into your next form. Each form attacks on its own; Druid spells deal and heal 30% more in their own form.|n|n',
    '|cffffffffMoonkin Form:|r Hurls Wrath at the nearest enemy, splashing 30% on enemies within 5 yards. Every 3 sec, Starfall strikes a random enemy with Moonfire.|n|n',
    '|cffffffffCat Form:|r Claws the nearest enemy, splashing 40% on enemies within 5 yards, and applies 1 stack of Bleed. You move 15% faster, and your critical strikes apply 1 stack of Bleed.|n|n',
    '|cffffffffBear Form:|r Mauls the nearest enemy, splashing 30% on enemies within 5 yards. You take 35% less damage, and your spells of other forms deal 20% less. Maul and Swipe deal 8% more per enemy within 8 yards, up to 64%. Every 6 sec, a roar Dazes enemies within 10 yards; they deal 25% less damage for 4 sec.|n|n',
    '|cffffffffTree of Life:|r Vines lash 3 enemies, splashing 20% on enemies within 5 yards, and each hit heals you 0.15% of your maximum health. Calls 1 additional Treant, and Rejuvenation blooms 50% faster.')
    WHERE `id` = 1013;

UPDATE `bonk_weapon` SET `description` = 'Calls down starlight on the strongest enemy within 30 yards for heavy Arcane damage. Empowered in Moonkin Form.' WHERE `id` = 1001;
UPDATE `bonk_weapon` SET `description` = 'Burns the 2 nearest enemies with moonlight for Arcane damage and 1 stack of Moonfire, choosing enemies without Moonfire first. Empowered in Moonkin Form.' WHERE `id` = 1002;
UPDATE `bonk_weapon` SET `description` = 'A storm rages over the largest group of enemies for 4 sec, dealing Nature damage every sec to enemies within 8 yards and leaving them Dazed. Empowered in Moonkin Form.' WHERE `id` = 1003;
UPDATE `bonk_weapon` SET `description` = 'Rakes the 3 nearest enemies within 10 yards for damage and 2 stacks of Bleed. Empowered in Cat Form.' WHERE `id` = 1004;
UPDATE `bonk_weapon` SET `description` = 'Shreds the enemy within 10 yards with the most stacks of Bleed for damage, 5% more per stack of Bleed on it, up to 30 stacks. Empowered in Cat Form.' WHERE `id` = 1005;
UPDATE `bonk_weapon` SET `description` = 'Swipes every enemy within 10 yards for damage. Empowered in Bear Form.' WHERE `id` = 1006;
UPDATE `bonk_weapon` SET `description` = 'Heals you for 0.25% of your maximum health per enemy within 8 yards, up to 5 enemies. Empowered in Bear Form.' WHERE `id` = 1007;
UPDATE `bonk_weapon` SET `description` = 'Heals you for 0.3% of your maximum health, and its thorny bloom lashes the 3 nearest enemies within 10 yards for Nature damage. Empowered in Tree of Life.' WHERE `id` = 1008;
UPDATE `bonk_weapon` SET `description` = 'Summons 2 Treants that fight at your side. Their swings apply 1 stack of Moonfire, and every 6 sec a Treant''s strike roots its target and normal enemies within 5 yards for 2 sec. Empowered in Tree of Life, which also calls 1 additional Treant.' WHERE `id` = 1009;
UPDATE `bonk_weapon` SET `description` = 'Roots grasp the 3 nearest enemies within 25 yards for Nature damage and root normal enemies for 2 sec. Empowered in Tree of Life.' WHERE `id` = 1010;
UPDATE `bonk_weapon` SET `description` = 'Calms the air around you for 4 sec. Every sec, deals Nature damage to every enemy within 10 yards and heals you for 0.5% of your maximum health. Empowered in Tree of Life.' WHERE `id` = 1011;
UPDATE `bonk_weapon` SET `description` = 'Enemies that strike you take Nature damage, at most 5 times a sec. Empowered in Bear Form.' WHERE `id` = 1012;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
