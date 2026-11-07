DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261031215224');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261031215224');

UPDATE `bonk_string_locale` SET `content` = '法术书需要艾泽拉斯之潮插件。' WHERE `entry` = 333 AND `locale` = 'zhCN';
UPDATE `bonk_mastery_locale` SET `description` = '影袭造成的伤害提高10%。', `name` = '强化影袭' WHERE `id` = 40202 AND `locale` = 'zhCN';
UPDATE `bonk_mastery_locale` SET `description` = '影袭额外刺击1个敌人。不能与强化杀戮盛筵同时学习。' WHERE `id` = 40207 AND `locale` = 'zhCN';
UPDATE `bonk_mastery_locale` SET `description` = '免费。影袭是起手法术。', `name` = '影袭' WHERE `id` = 40221 AND `locale` = 'zhCN';
UPDATE `bonk_mastery_locale` SET `description` = '影袭有20%几率刺击两次。' WHERE `id` = 40229 AND `locale` = 'zhCN';
UPDATE `bonk_mastery_locale` SET `description` = '影袭会使普通敌人昏迷1秒。每个敌人每6秒一次。' WHERE `id` = 40230 AND `locale` = 'zhCN';
UPDATE `bonk_mastery_locale` SET `description` = '魔爆术使普通敌人减速30%，持续2秒。', `name` = '强化魔爆术' WHERE `id` = 80106 AND `locale` = 'zhCN';
UPDATE `bonk_mastery_locale` SET `description` = '你的冲刺变为闪现术，且冷却时间减半。每次冲刺都会在你落地的位置引发你的魔爆术。可与闪现术法术叠加。' WHERE `id` = 80110 AND `locale` = 'zhCN';
UPDATE `bonk_pet_family_locale` SET `description` = '变为奥术元素：施放奥术箭，并每3秒施放一次小型魔爆术，命中6码内的敌人。' WHERE `id` = 4 AND `locale` = 'zhCN';
UPDATE `bonk_quest_locale` SET `description` = '以法师身份使用魔爆术击杀3,000个敌人。' WHERE `id` = 163 AND `locale` = 'zhCN';
UPDATE `bonk_quest_locale` SET `description` = '以盗贼身份使用影袭击杀3,000个敌人。' WHERE `id` = 261 AND `locale` = 'zhCN';
UPDATE `bonk_weapon_locale` SET `description` = '你的冲刺变为闪现术，使你瞬间传送，充能次数增加1次，冷却时间缩短30%。每次闪现都会在你离开的位置引发一次魔爆术，对10码内的敌人造成奥术伤害。占用一个法术槽位。' WHERE `id` = 407 AND `locale` = 'zhCN';
UPDATE `bonk_weapon_locale` SET `name` = '魔爆术' WHERE `id` = 408 AND `locale` = 'zhCN';
UPDATE `bonk_weapon_locale` SET `description` = '你的冲刺变为闪现术，充能次数增加1次，冷却时间缩短30%。每次闪现都会在你离开的位置引发一次魔爆术，对10码内的敌人造成奥术伤害，命中沿途的所有敌人，并使你免疫伤害1秒。' WHERE `id` = 425 AND `locale` = 'zhCN';
UPDATE `bonk_weapon_locale` SET `description` = '你的冲刺变为闪现术，充能次数增加3次，冷却时间缩短30%。每次闪现都会在你离开的位置引发一次魔爆术，对10码内的敌人造成奥术伤害，并重置魔爆术的冷却时间。' WHERE `id` = 426 AND `locale` = 'zhCN';
UPDATE `bonk_weapon_locale` SET `name` = '影袭' WHERE `id` = 600 AND `locale` = 'zhCN';

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
