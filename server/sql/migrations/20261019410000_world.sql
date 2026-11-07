DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261019410000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261019410000');

UPDATE `bonk_weapon` SET `damage_fraction` = 1.6, `cooldown_ms` = 3000, `range` = 12, `apply_stacks` = 2,
    `description` = REPLACE(REPLACE(`description`, 'within 10 yards', 'within 12 yards'), 'applying 1 stack of Poison', 'applying 2 stacks of Poison')
    WHERE `id` IN (606, 624, 625);
UPDATE `bonk_weapon` SET `description` = 'For 8 seconds, your single-target hits also strike 4 additional enemies within 8 yards for 50% of their damage. The extra hits carry your poisons and openers.' WHERE `id` = 601;
UPDATE `bonk_weapon` SET `description` = 'Your single-target hits always strike 1 additional enemy within 8 yards for 50% of their damage. The extra hits carry your poisons and openers.' WHERE `id` = 614;
UPDATE `bonk_weapon` SET `description` = 'For 8 seconds, your single-target hits also strike 4 additional enemies within 8 yards for 50% of their damage as Shadow damage. Every extra hit counts as a first hit for Ambush.' WHERE `id` = 615;
UPDATE `bonk_mastery` SET `description` = 'Your single-target hits strike 1 additional enemy within 8 yards for 50% of their damage, with or without Blade Flurry. Your critical strike chance is reduced by 10%.' WHERE `id` = 40210;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
