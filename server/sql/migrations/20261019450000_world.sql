DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261019450000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261019450000');

ALTER TABLE `bonk_map`
    ADD COLUMN `summary` VARCHAR(128) NOT NULL DEFAULT '' AFTER `icon`,
    ADD COLUMN `description` VARCHAR(512) NOT NULL DEFAULT '' AFTER `summary`;

UPDATE `bonk_map` SET `summary` = 'Defias thugs, gnolls, murlocs',
    `description` = 'Farmland overrun by the Defias Brotherhood. Edwin VanCleef leads the stage.' WHERE `id` = 1;
UPDATE `bonk_map` SET `summary` = 'Fire elementals, core hounds, Molten Giants',
    `description` = 'The burning heart of Blackrock Mountain. Magmadar leads the stage, with Garr, Lucifron and Gehennas close behind.' WHERE `id` = 2;
UPDATE `bonk_map` SET `summary` = 'Quilboars, centaurs, hyenas',
    `description` = 'Endless dry plains full of Razormane and Kolkar raiders. Charlga Razorflank leads the stage.' WHERE `id` = 3;
UPDATE `bonk_map` SET `summary` = 'Undead, worgen, ogres',
    `description` = 'A dark forest where the dead walk. Stitches leads the stage.' WHERE `id` = 4;
UPDATE `bonk_map` SET `summary` = 'Gurubashi trolls, bats, tigers',
    `description` = 'The temple city of the Gurubashi. Hakkar leads the stage, with Jin''do, Venoxis and Mar''li close behind.' WHERE `id` = 5;
UPDATE `bonk_map` SET `summary` = 'Silithid swarms, Qiraji, Anubisath',
    `description` = 'The ruined gates of Ahn''Qiraj. Ossirian the Unscarred leads the stage.' WHERE `id` = 6;
UPDATE `bonk_map` SET `summary` = 'Hyenas, ogres, Wastewander bandits',
    `description` = 'Sun-baked dunes around Zul''Farrak. Gahz''rilla leads the stage.' WHERE `id` = 7;
UPDATE `bonk_map` SET `summary` = 'Devilsaurs, raptors, oozes',
    `description` = 'A primal crater ruled by giant beasts. King Mosh leads the stage.' WHERE `id` = 8;
UPDATE `bonk_map` SET `summary` = 'Jungle trolls, tigers, gorillas',
    `description` = 'Thick jungle full of Bloodscalp and Skullsplitter trolls. The Mosh''Ogg Lord leads the stage.' WHERE `id` = 9;
UPDATE `bonk_map` SET `summary` = 'Centaurs, scorpids, satyrs',
    `description` = 'A barren land of warring centaur clans. Princess Theradras leads the stage.' WHERE `id` = 10;
UPDATE `bonk_map` SET `summary` = 'Troggs, Dark Iron dwarves, whelps',
    `description` = 'Scorched canyons above Uldaman. Archaedas leads the stage.' WHERE `id` = 11;
UPDATE `bonk_map` SET `summary` = 'Ogres, Witherbark trolls, Syndicate',
    `description` = 'Rolling highlands held by ogres and outlaws. Fozruk leads the stage.' WHERE `id` = 12;
UPDATE `bonk_map` SET `summary` = 'Crocolisks, Lost Ones, Atal''ai',
    `description` = 'A sunken swamp around the Temple of Atal''Hakkar. The Avatar of Hakkar leads the stage.' WHERE `id` = 13;
UPDATE `bonk_map` SET `summary` = 'Blackrock orcs, black dragonkin',
    `description` = 'Ash and fire below Blackrock Spire. Emperor Thaurissan and General Drakkisath lead the stages.' WHERE `id` = 14;
UPDATE `bonk_map` SET `summary` = 'Scourge, abominations, plaguehounds',
    `description` = 'The heart of the plague, below Stratholme. Baron Rivendare and Balnazzar lead the stages.' WHERE `id` = 15;
UPDATE `bonk_map` SET `summary` = 'Scarlet Crusade, ghouls, plague beasts',
    `description` = 'Fields between Scholomance and the Scarlet camps. Darkmaster Gandling leads the stage.' WHERE `id` = 16;
UPDATE `bonk_map` SET `summary` = 'Gnolls, ogres, Dire Maul',
    `description` = 'Ancient forests around Dire Maul. King Gordok and Prince Tortheldrin lead the stages.' WHERE `id` = 17;
UPDATE `bonk_map` SET `summary` = 'Dark Iron dwarves, golems, lava spiders',
    `description` = 'Molten slag pits at the foot of Blackrock Mountain. Rend Blackhand and The Beast lead the stages.' WHERE `id` = 18;
UPDATE `bonk_map` SET `summary` = 'Satyrs, demons, Jadefire',
    `description` = 'A corrupted forest full of demons. Lord Kazzak and Kroshius lead the stages.' WHERE `id` = 19;
UPDATE `bonk_map` SET `summary` = 'Troggs, Frostmane trolls, Gnomeregan',
    `description` = 'The frozen shore of Iceflow Lake below Gnomeregan. Troggs and trolls come first, then Mekgineer Thermaplugg and his machines.' WHERE `id` = 20;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
