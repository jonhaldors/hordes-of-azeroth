DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261015000000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261015000000');

UPDATE `creature_template` SET `name` = 'Sayge', `subname` = 'Darkmoon Faire', `display_id1` = 491 WHERE `entry` = 900003;
UPDATE `creature_template` SET `subname` = 'Talent Trainer' WHERE `entry` = 900008;

UPDATE `broadcast_text` SET
    `male_text` = 'Care to hear your fortune, $n? The cards ask a Darkmoon Ticket or two. A bright Fortune makes the road kinder; a Dark Fortune makes it harder, and pays better for it. Tickets turn up rarely out there, and elites and bosses carry more.',
    `female_text` = 'Care to hear your fortune, $n? The cards ask a Darkmoon Ticket or two. A bright Fortune makes the road kinder; a Dark Fortune makes it harder, and pays better for it. Tickets turn up rarely out there, and elites and bosses carry more.'
    WHERE `entry` = 900004;
UPDATE `broadcast_text` SET
    `male_text` = 'Every class walks its own road, $n. Bring me what your runs have taught you, and I will shape it into talents - for this class, and this class alone.',
    `female_text` = 'Every class walks its own road, $n. Bring me what your runs have taught you, and I will shape it into talents - for this class, and this class alone.'
    WHERE `entry` = 900008;
UPDATE `broadcast_text` SET
    `male_text` = 'Your class''s talents are still being written down. Keep fighting: every run already counts toward your Mastery, and none of it will be lost.',
    `female_text` = 'Your class''s talents are still being written down. Keep fighting: every run already counts toward your Mastery, and none of it will be lost.'
    WHERE `entry` = 900009;

UPDATE `bonk_shop_tree` SET `name` = 'Utility' WHERE `id` = 3;
UPDATE `bonk_shop_tree` SET `name` = 'Fortune' WHERE `id` = 4;
UPDATE `bonk_shop_tree` SET `name` = 'Dark Fortune' WHERE `id` = 5;

UPDATE `gameobject_template` SET `name` = 'Darkmoon Ticket' WHERE `entry` = 900007;

UPDATE `bonk_quest` SET `name` = 'Ticket Collector', `description` = 'Find 10 Darkmoon Tickets.' WHERE `id` = 13;
UPDATE `bonk_quest` SET `icon` = 'INV_Misc_Ticket_Darkmoon_01' WHERE `icon` = 'INV_Enchant_ShardBrilliantLarge';

UPDATE `bonk_tier` SET `description` = REPLACE(`description`, 'Talent Shards', 'Darkmoon Tickets');

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
