DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261025230000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261025230000');

UPDATE `bonk_weapon` SET `description` = CONCAT(
    'R (your Shapeshift key) shifts you: Moonkin, Cat, Bear, Tree of Life. Each form attacks on its own. Druid spells deal and heal 30% more in their own form.|n|n',
    'Moonkin: Wrath at the nearest enemy, 30% splash within 5 yd. Starfall: every 3 sec, a star strikes a random moonfired enemy.|n|n',
    'Cat: fast claws on the nearest enemy, 30% splash within 5 yd, 1 Bleed. 15% movement speed; your critical strikes apply 1 Bleed.|n|n',
    'Bear: mauls the nearest enemy, 50% splash within 5 yd. You take 35% less damage; spells of other forms deal 20% less. Maul and Swipe deal 8% more per enemy within 8 yd, up to 64%. Every 6 sec, a roar dazes enemies within 10 yd and they deal 25% less damage for 4 sec.|n|n',
    'Tree of Life: vines lash 3 enemies, 20% splash within 5 yd, each hit heals you 0.15% of maximum health. 1 additional Treant; Rejuvenation blooms 50% faster.')
    WHERE `id` = 1013;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
