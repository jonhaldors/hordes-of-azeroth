DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261028100015');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261028100015');

UPDATE `bonk_weapon` SET `description` = 'Summons a three-headed hydra that spits Frost, Fire and Arcane bolts at enemies within 30 yards. Each head picks a different enemy. Its frost head applies Chill and its fire head Burning. It follows you when you move far away.' WHERE `id` = 431;
UPDATE `bonk_weapon` SET `description` = 'Plants a Searing Totem at your feet that hurls fire at 2 enemies within 20 yards, applying Burning. It is replanted when you move away.' WHERE `id` = 708;
UPDATE `bonk_weapon` SET `description` = 'Plants a Searing Totem at your feet that hurls fire at 2 enemies within 20 yards, applying Burning. Enemies within 15 yards of it take 15% more Fire damage.' WHERE `id` = 729;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
