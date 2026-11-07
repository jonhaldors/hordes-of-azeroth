DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261107112000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261107112000');

-- The custom vendors had no gossip text, so the client queried the default
-- text id, got no npc_text row, and never fired GOSSIP_SHOW.
DELETE FROM `broadcast_text` WHERE `entry` IN (900160, 900170);
INSERT INTO `broadcast_text` (`entry`, `male_text`, `female_text`) VALUES
(900160, 'I can enchant your gear. What do you need?', 'I can enchant your gear. What do you need?'),
(900170, 'Every piece you find adds its look to your collection. Choose a slot, then pick how it looks.',
        'Every piece you find adds its look to your collection. Choose a slot, then pick how it looks.');

DELETE FROM `npc_text` WHERE `ID` IN (900160, 900170);
INSERT INTO `npc_text` (`ID`, `BroadcastTextID0`, `Probability0`) VALUES
(900160, 900160, 1), (900170, 900170, 1);

DELETE FROM `gossip_menu` WHERE `entry` IN (65001, 65002) OR `text_id` IN (900160, 900170);
INSERT INTO `gossip_menu` (`entry`, `text_id`) VALUES
(65002, 900160), (65001, 900170);

UPDATE `creature_template` SET `gossip_menu_id` = 65002 WHERE `entry` = 900160;
UPDATE `creature_template` SET `gossip_menu_id` = 65001 WHERE `entry` = 900170;

DELETE FROM `locales_broadcast_text` WHERE `entry` IN (900160, 900170);
INSERT INTO `locales_broadcast_text` (`entry`, `male_text_loc4`, `female_text_loc4`) VALUES
(900160, '我可以为你的装备附魔。你需要什么？', '我可以为你的装备附魔。你需要什么？'),
(900170, '你找到的每件装备都会将其外观加入收藏。选择一个部位，然后挑选它的外观。',
        '你找到的每件装备都会将其外观加入收藏。选择一个部位，然后挑选它的外观。');

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
