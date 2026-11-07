DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261027810002');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261027810002');

CREATE TABLE IF NOT EXISTS `bonk_glossary` (
  `term` VARCHAR(64) NOT NULL,
  `words` VARCHAR(255) NOT NULL DEFAULT '',
  `keyword` INT UNSIGNED NOT NULL DEFAULT 0,
  `description` VARCHAR(1024) NOT NULL DEFAULT '',
  `sort` INT NOT NULL DEFAULT 0,
  PRIMARY KEY (`term`)
);

DELETE FROM `bonk_glossary`;
INSERT INTO `bonk_glossary` (`term`, `words`, `keyword`, `description`, `sort`) VALUES
('Enrage', 'Enrage,Enraged', 0, 'Gain 25% Haste for 4 sec. Bloodthirst critical strikes, Execute kills and Berserker Rage Enrage you.', 1),
('Shield', 'Shield,Shields', 0, 'Absorbs damage before your health does. Holds up to 50% of your maximum health.', 2),
('Chill', 'Chill,Chilled', 1, '', 10),
('Frozen', 'Frozen,Freeze,Freezes,freezes', 2, '', 11),
('Burning', 'Burning', 3, '', 12),
('Bleed', 'Bleed,Bleeding,Bleeds', 4, '', 13),
('Poison', 'Poison,Poisons,Poisoned', 5, '', 14),
('Shadow Vulnerability', 'Shadow Vulnerability', 8, '', 15),
('Hunter''s Mark', 'Mark,Marked,Marks', 9, '', 16),
('Dazed', 'Dazed', 10, '', 17),
('Static', 'Static', 11, '', 18),
('Nature Vulnerability', 'Nature Vulnerability', 12, '', 19),
('Decay', 'Decay', 13, '', 20),
('Agony', 'Agony', 14, '', 21),
('Moonfire', 'Moonfire', 15, '', 22);

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
