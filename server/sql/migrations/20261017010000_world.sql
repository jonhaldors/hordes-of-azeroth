DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261017010000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261017010000');

DELETE FROM `command` WHERE `name` IN ('bonk evolve', 'bonk passive', 'bonk card', 'bonk mastery', 'bonk god');
INSERT INTO `command` (`name`, `security`, `help`, `flags`) VALUES
('bonk evolve', 2, 'Syntax: .bonk evolve #evolutionId\r\nGives you that evolution during a run (adds its base spell if you lack it). Use a base spell id to list its evolutions, e.g. .bonk evolve 7\r\nHunter: 212 Chimera Shot, 213 Ricochet (Arcane Shot 7); 214 Trick Shots, 215 Serpent Spread (Multi-Shot 37); 216 Chain Detonation, 217 Steady Aim (Aimed Shot 203); 218 Arrow Storm, 219 Gravity Volley (Volley 137); 220 Flare, 221 Marked for Death (Hunter''s Mark 205); 222 Venom Bolts, 223 Venom Cloud (Serpent Sting 38); 224 Cluster Trap, 225 Snake Trap (Explosive Trap 202); 226 Shatter Field, 227 Ice Path (Frost Trap 204); 228 Stampede, 229 Plague Beast (Call Pet 201); 230 Howl of the Pack Leader, 231 Feeding Frenzy (Pack Leader 211)', 0),
('bonk passive', 2, 'Syntax: .bonk passive #passiveId\r\nGives you one rank of that passive during a run. 21 = Toxicology.', 0),
('bonk card', 2, 'Syntax: .bonk card #cardId\r\nGives you that Darkmoon Card during a run. 31 = Darkmoon Card: Ascension.', 0),
('bonk mastery', 2, 'Syntax: .bonk mastery #xp\r\nAdds talent experience to your character (for talent points). Learn talents at the Talent Trainer in camp.', 0),
('bonk god', 2, 'Syntax: .bonk god\r\nToggles god mode: damage stops at 1 health.', 0);

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
