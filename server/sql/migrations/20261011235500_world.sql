DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261011235500');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261011235500');

DELETE FROM `bonk_tier` WHERE `id` = 3;
INSERT INTO `bonk_tier` (`id`, `key`, `name`, `health_multiplier`, `damage_multiplier`, `stage_health_growth`, `stage_damage_growth`,
    `stage_spawn_growth`, `chest_cost`, `chest_cost_growth`, `unlock_tier`, `unlock_stage`,
    `shard_chance_normal`, `shard_chance_elite`, `shards_miniboss`, `shards_boss`, `description`, `art`) VALUES
(3, 'medium', 'Medium', 1, 1, 0.82, 0.37, 0.22, 25, 1, 1, 3, 0.15, 16, 1, 3,
    'Rougher lands with tighter spots between the open ground. Tougher foes, and more Talent Shards.',
    'Interface\\Glues\\LoadingScreens\\LoadScreenKalimdor');

UPDATE `bonk_tier` SET `unlock_tier` = 3, `unlock_stage` = 3 WHERE `id` = 2;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
