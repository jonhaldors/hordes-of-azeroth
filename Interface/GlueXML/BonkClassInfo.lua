local L = BonkGlueL;

BONK_CLASS_INFO = {
	WARRIOR = {
		blurb = L["Fights in the thick of the horde. Every swing hits all around you, and there is no Rage to manage."],
		starter = { name = L["Bloodthirst"], icon = "Interface\\Icons\\Spell_Nature_BloodLust", line = L["Strikes 3 enemies and heals you"], tip = L["Strikes the 3 nearest enemies within 8 yards for damage and heals you for 0.5% of your maximum health per enemy hit, up to 2.5%. Critical strikes Enrage you: 25% Haste for 4 sec."] },
		shared = {
			{ name = L["Cleave"], icon = "Interface\\Icons\\Ability_Warrior_Cleave", line = L["Strikes every enemy within 8 yards"], tip = L["Strikes all enemies within 8 yards of you for damage."] },
		},
		specs = {
			{ name = L["Arms"], icon = "Interface\\Icons\\Ability_Warrior_SavageBlow", text = L["Stack Bleed on the pack, then cash it in with Mortal Strike."], spells = {
				{ name = L["Rend"], icon = "Interface\\Icons\\Ability_Gouge", line = L["Makes the 3 nearest enemies Bleed"], tip = L["Wounds the 3 nearest enemies within 10 yards with 3 stacks of Bleed."] },
				{ name = L["Deep Wounds"], icon = "Interface\\Icons\\Ability_BackStab", line = L["Your critical strikes make enemies Bleed"], tip = L["Your critical strikes wound the enemy with 2 stacks of Bleed, at most once every 0.5 sec per enemy."] },
				{ name = L["Mortal Strike"], icon = "Interface\\Icons\\Ability_Warrior_SavageBlow", line = L["Hits harder for each stack of Bleed"], tip = L["Strikes all enemies within 8 yards of you for damage, 8% more per stack of Bleed on the target, up to 30 stacks."] },
			} },
			{ name = L["Fury"], icon = "Interface\\Icons\\Ability_Warrior_InnerRage", text = L["Critical strikes and kills Enrage you, and Enrage makes you strike faster."], spells = {
				{ name = L["Bloodthirst"], icon = "Interface\\Icons\\Spell_Nature_BloodLust", line = L["Strikes 3 enemies and heals you"], tip = L["Strikes the 3 nearest enemies within 8 yards for damage and heals you for 0.5% of your maximum health per enemy hit, up to 2.5%. Critical strikes Enrage you: 25% Haste for 4 sec."] },
				{ name = L["Execute"], icon = "Interface\\Icons\\INV_Sword_48", line = L["Slays normal enemies below 20% health"], tip = L["Strikes all enemies within 8 yards of you for damage. Normal enemies below 20% health die instantly; elites and bosses below 20% take triple damage. Kills Enrage you: 25% Haste for 4 sec."] },
				{ name = L["Whirlwind"], icon = "Interface\\Icons\\Ability_Whirlwind", line = L["Spins through the pack, twice when Enraged"], tip = L["Spins, striking all enemies within 8 yards of you for damage. Spins twice while you are Enraged."] },
			} },
			{ name = L["Protection"], icon = "Interface\\Icons\\INV_Shield_06", text = L["Get hit, absorb it with your Shield, and punish it."], spells = {
				{ name = L["Shield Block"], icon = "Interface\\Icons\\Ability_Defend", line = L["A Shield that soaks damage, stacking up"], tip = L["Adds a Shield of 10% of your maximum health that lasts until it absorbs damage, stacking up to 50%."] },
				{ name = L["Thunder Clap"], icon = "Interface\\Icons\\Ability_ThunderClap", line = L["Blasts nearby enemies and slows their attacks"], tip = L["Blasts all enemies within 8 yards of you for damage. Enemies hit attack 20% slower for 6 sec."] },
				{ name = L["Revenge"], icon = "Interface\\Icons\\Ability_Warrior_Revenge", line = L["Strikes back when you are hit"], tip = L["When you are struck, strikes all enemies within 6 yards of you for damage, at most once every 2 sec."] },
				{ name = L["Shield Slam"], icon = "Interface\\Icons\\INV_Shield_05", line = L["Hits harder the bigger your Shield"], tip = L["Slams all enemies within 6 yards of you for damage, 2% more for each 1% of your maximum health in your Shield, up to 200% more."] },
			} },
		},
	},
	PALADIN = {
		blurb = L["Seals change every strike and Judgement releases them. Holy light burns all around you, and hammers finish the wounded."],
		starter = { name = L["Crusader Strike"], icon = "Interface\\Icons\\Spell_Holy_HolySmite", line = L["Heavy strike with splash damage"], tip = L["Strikes the nearest enemy for heavy damage and 30% of it to enemies within 5 yards of the target."] },
		shared = {
		},
		specs = {
			{ name = L["Holy"], icon = "Interface\\Icons\\Spell_Holy_HolyBolt", text = L["Holy strikes from afar: Exorcism, falling hammers and light that heals with every strike."], spells = {
				{ name = L["Exorcism"], icon = "Interface\\Icons\\Spell_Holy_Excorcism_02", line = L["Heavy Holy strike on the strongest enemy"], tip = L["Strikes the strongest enemy within 30 yards for heavy Holy damage. Undead and Demons take triple damage, elites and bosses double. Critical strikes from your other Paladin spells reset its cooldown, at most once a sec."] },
				{ name = L["Seal of Light"], icon = "Interface\\Icons\\Spell_Holy_HealingAura", line = L["Your strikes heal you"], tip = L["Every strike from your other Paladin spells heals you for 0.5% of your maximum health, at most 6 times a sec."] },
				{ name = L["Light's Hammer"], icon = "Interface\\Icons\\Spell_Holy_FistOfJustice", line = L["Hammers of light fall on the pack"], tip = L["Hammers of light fall on 3 random enemies within 25 yards, each dealing Holy damage to every enemy within 5 yards."] },
			} },
			{ name = L["Protection"], icon = "Interface\\Icons\\Spell_Holy_DevotionAura", text = L["Holy ground and auras burn whoever comes close, while Divine Shield blocks the big hits."], spells = {
				{ name = L["Consecration"], icon = "Interface\\Icons\\Spell_Holy_InnerFire", line = L["Holy ground that burns enemies on it"], tip = L["Consecrates the ground beneath you for 8 sec, dealing Holy damage every sec to enemies on it. You deal 15% more damage while standing on it."] },
				{ name = L["Divine Shield"], icon = "Interface\\Icons\\Spell_Holy_DivineIntervention", line = L["A bubble that blocks the next big hit"], tip = L["A golden bubble forms around you and blocks the next enemy hit that would take more than 5% of your maximum health."] },
				{ name = L["Retribution Aura"], icon = "Interface\\Icons\\Spell_Holy_AuraOfLight", line = L["Burns every enemy close to you"], tip = L["Burns every enemy within 10 yards of you with holy light, dealing Holy damage every sec. Enemies that strike you take double."] },
				{ name = L["Hammer of Justice"], icon = "Interface\\Icons\\Spell_Holy_SealOfMight", line = L["Stuns the strongest enemy"], tip = L["Hurls a hammer at the strongest enemy within 20 yards, dealing Holy damage and stunning it for 2 sec. Bosses are not stunned."] },
			} },
			{ name = L["Retribution"], icon = "Interface\\Icons\\Spell_Holy_AuraOfLight", text = L["Crusader Strike and Seals on every swing, released by Judgement, with hammers for the wounded."], spells = {
				{ name = L["Crusader Strike"], icon = "Interface\\Icons\\Spell_Holy_HolySmite", line = L["Heavy strike with splash damage"], tip = L["Strikes the nearest enemy for heavy damage and 30% of it to enemies within 5 yards of the target."] },
				{ name = L["Judgement"], icon = "Interface\\Icons\\Spell_Holy_RighteousFury", line = L["Hammers 3 enemies and releases your Seals"], tip = L["Slams the 3 strongest enemies within 20 yards with a hammer of light for Holy damage, with double critical strike chance. Releases your Seals: Righteousness adds 50% damage, Command hits enemies within 5 yards of each target for half, Light heals you for 1% of your maximum health per enemy hit."] },
				{ name = L["Seal of Command"], icon = "Interface\\Icons\\Ability_Warrior_InnerRage", line = L["Every 3rd strike bursts with light"], tip = L["Every 3rd strike from your other Paladin spells releases a burst of light, dealing Holy damage to the target and every enemy within 5 yards of it."] },
				{ name = L["Seal of Righteousness"], icon = "Interface\\Icons\\Ability_ThunderBolt", line = L["Your hits deal extra Holy damage"], tip = L["Every hit from your other Paladin spells, splash and area hits included, deals 20% extra as Holy damage."] },
				{ name = L["Divine Storm"], icon = "Interface\\Icons\\Spell_Holy_SealOfWrath", line = L["Holy burst around you that heals"], tip = L["Holy light bursts around you, dealing Holy damage to every enemy within 10 yards and healing you for 0.5% of your maximum health per enemy hit, up to 3%."] },
				{ name = L["Hammer of Wrath"], icon = "Interface\\Icons\\Ability_ThunderClap", line = L["Slays wounded enemies"], tip = L["Hurls hammers at up to 3 enemies below 20% health within 30 yards. Normal enemies are slain; elites and bosses take heavy Holy damage."] },
			} },
		},
	},
	HUNTER = {
		blurb = L["Shoots from range while pets fight at your side. Marks, stings and traps set up the kill."],
		starter = { name = L["Arcane Shot"], icon = "Interface\\Icons\\Ability_ImpalingBolt", line = L["Shoots the nearest enemy"], tip = L["Shoots the nearest enemy for Arcane damage."] },
		shared = {
		},
		specs = {
			{ name = L["Beast Mastery"], icon = "Interface\\Icons\\Ability_Hunter_BeastTaming", text = L["Pets do the fighting: your cat bleeds the pack and the spirit wolf leads it."], spells = {
				{ name = L["Call Pet"], icon = "Interface\\Icons\\Ability_Hunter_BeastCall", line = L["Your cat fights for you"], tip = L["Summons your cat to fight for you. Its Claw applies Bleed, and its Swipe hits every enemy in front of it."] },
				{ name = L["Pack Leader"], icon = "Interface\\Icons\\Spell_Nature_SpiritWolf", line = L["A spirit wolf that empowers your pets"], tip = L["A spirit wolf fights for you, biting for damage. Every 15 sec it howls, and your other pets deal double damage to all enemies in front for 6 sec."] },
			} },
			{ name = L["Marksmanship"], icon = "Interface\\Icons\\Ability_Marksmanship", text = L["Shots, volleys and piercing arrows, with Hunter's Mark on the biggest group."], spells = {
				{ name = L["Arcane Shot"], icon = "Interface\\Icons\\Ability_ImpalingBolt", line = L["Shoots the nearest enemy"], tip = L["Shoots the nearest enemy for Arcane damage."] },
				{ name = L["Multi-Shot"], icon = "Interface\\Icons\\Ability_UpgradeMoonGlaive", line = L["6 arrows in a cone"], tip = L["Fires 6 arrows in a cone in front of you, dealing damage."] },
				{ name = L["Volley"], icon = "Interface\\Icons\\Ability_Marksmanship", line = L["Rains arrows on the largest group"], tip = L["Rains arrows on the largest group of enemies for 4 sec, dealing damage, 5% more for each different debuff on the target."] },
				{ name = L["Aimed Shot"], icon = "Interface\\Icons\\INV_Spear_07", line = L["A shot that pierces a whole line"], tip = L["Fires a shot that pierces every enemy in a line, dealing damage. Aims at the Marked group, or else the largest group."] },
				{ name = L["Hunter's Mark"], icon = "Interface\\Icons\\Ability_Hunter_SniperShot", line = L["Marked enemies take more damage"], tip = L["Marks every enemy within 10 yards of the largest group for 8 sec. Marked enemies take 15% more damage."] },
			} },
			{ name = L["Survival"], icon = "Interface\\Icons\\Ability_Hunter_SwiftStrike", text = L["Poison stings, and traps that burn or slow whatever walks in."], spells = {
				{ name = L["Serpent Sting"], icon = "Interface\\Icons\\Ability_Hunter_Quickshot", line = L["Poisons the nearest enemies"], tip = L["Stings the nearest enemy and 2 enemies near it with 3 stacks of Poison."] },
				{ name = L["Explosive Trap"], icon = "Interface\\Icons\\Spell_Fire_SelfDestruct", line = L["A trap that explodes and burns the ground"], tip = L["Places a fire trap that explodes when an enemy comes close, dealing damage and burning the ground for 4 sec, applying Burning."] },
				{ name = L["Frost Trap"], icon = "Interface\\Icons\\Spell_Frost_FreezingBreath", line = L["A trap that slows the pack"], tip = L["Places a frost trap that goes off when an enemy comes close, slowing normal enemies inside by 60% for 6 sec. They take 5% more damage."] },
			} },
		},
	},
	ROGUE = {
		blurb = L["The fastest single-target attacks in the game. Every stab carries a poison or an opener."],
		starter = { name = L["Sinister Strike"], icon = "Interface\\Icons\\Spell_Shadow_RitualOfSacrifice", line = L["Fast stabs on the nearest enemy"], tip = L["Stabs the nearest enemy for damage."] },
		shared = {
		},
		specs = {
			{ name = L["Assassination"], icon = "Interface\\Icons\\Ability_Rogue_Eviscerate", text = L["Poison on every hit, then Envenom the most poisoned enemy."], spells = {
				{ name = L["Mutilate"], icon = "Interface\\Icons\\Ability_BackStab", line = L["Two poisoned stabs on the nearest enemy"], tip = L["Stabs the nearest enemy with both daggers for damage, each stab applying 1 stack of Poison. Deals 30% more to Poisoned enemies."] },
				{ name = L["Deadly Poison"], icon = "Interface\\Icons\\Ability_Rogue_DualWeild", line = L["Your hits apply Poison"], tip = L["Your other abilities apply 1 stack of Poison with every hit."] },
				{ name = L["Fan of Knives"], icon = "Interface\\Icons\\INV_ThrowingKnife_04", line = L["Knives in every direction"], tip = L["Throws knives in every direction, striking all enemies within 10 yards for damage and applying 2 stacks of Poison. Every knife carries your poisons and openers."] },
				{ name = L["Envenom"], icon = "Interface\\Icons\\Ability_Creature_Poison_06", line = L["Strikes the most poisoned enemy"], tip = L["Strikes the enemy with the most Poison for Nature damage, and your hits apply 2 more stacks of Poison for 5 sec."] },
			} },
			{ name = L["Combat"], icon = "Interface\\Icons\\Ability_BackStab", text = L["Fast blades: Blade Flurry, Eviscerate and Killing Spree through the pack."], spells = {
				{ name = L["Sinister Strike"], icon = "Interface\\Icons\\Spell_Shadow_RitualOfSacrifice", line = L["Fast stabs on the nearest enemy"], tip = L["Stabs the nearest enemy for damage."] },
				{ name = L["Blade Flurry"], icon = "Interface\\Icons\\Ability_Warrior_PunishingBlow", line = L["Your hits strike 4 more enemies"], tip = L["Your single-target hits also strike 4 more enemies within 8 yards at 50% damage for 8 sec. The extra hits carry your poisons and openers."] },
				{ name = L["Eviscerate"], icon = "Interface\\Icons\\Ability_Rogue_Eviscerate", line = L["Heavy strike with double crit chance"], tip = L["Guts the nearest enemy for heavy damage, with double critical strike chance."] },
				{ name = L["Killing Spree"], icon = "Interface\\Icons\\Ability_Rogue_SliceDice", line = L["8 strikes on random enemies"], tip = L["Strikes 8 times over 2 sec, each strike hitting a random enemy within 10 yards for damage and carrying your poisons and openers."] },
			} },
			{ name = L["Subtlety"], icon = "Interface\\Icons\\Ability_Stealth", text = L["Ambush every new enemy you hit, and Shadow Dance to do it again."], spells = {
				{ name = L["Shuriken Toss"], icon = "Interface\\Icons\\INV_ThrowingAxe_06", line = L["Shurikens at fresh enemies"], tip = L["Throws shurikens at the 3 nearest enemies within 20 yards, ones you have not hit yet first, dealing damage."] },
				{ name = L["Ambush"], icon = "Interface\\Icons\\Ability_Rogue_Ambush", line = L["Your first hit on each enemy ambushes it"], tip = L["Your first hit on each enemy with your other abilities is followed by an Ambush for heavy damage, with double critical strike chance."] },
				{ name = L["Shadow Dance"], icon = "Interface\\Icons\\Spell_Shadow_Charm", line = L["More damage, and Ambush again"], tip = L["Your hits deal 30% more damage for 4 sec and can set off Ambush again, once a sec per enemy."] },
				{ name = L["Evasion"], icon = "Interface\\Icons\\Spell_Shadow_ShadowWard", line = L["Dodge far more attacks for a while"], tip = L["You dodge 50% more attacks for 5 sec."] },
			} },
		},
	},
	PRIEST = {
		blurb = L["Healing that overflows into damage, a ring of light that hits far, and Decay that spreads from mind to mind."],
		starter = { name = L["Smite"], icon = "Interface\\Icons\\Spell_Holy_HolySmite", line = L["Smites the 2 nearest enemies"], tip = L["Smites the 2 nearest enemies for Holy damage. Each Smite reduces the cooldown of Holy Word: Chastise by 1 sec."] },
		shared = {
		},
		specs = {
			{ name = L["Discipline"], icon = "Interface\\Icons\\Spell_Holy_WordFortitude", text = L["Shields, fear and binding, while Penance punishes whoever strikes you."], spells = {
				{ name = L["Power Word: Shield"], icon = "Interface\\Icons\\Spell_Holy_PowerWordShield", line = L["A shield that makes you faster"], tip = L["Shields you for 10% of your maximum health; each cast tops it back up instead of stacking. You move 10% faster while shielded."] },
				{ name = L["Penance"], icon = "Interface\\Icons\\Spell_Holy_HolyBolt", line = L["Holy bolts at whoever struck you"], tip = L["Fires 3 holy bolts at the enemies that struck you last, or the nearest enemies, each dealing Holy damage and healing you for 0.5% of your maximum health. Healing past full health becomes Shield."] },
				{ name = L["Psychic Scream"], icon = "Interface\\Icons\\Spell_Shadow_PsychicScream", line = L["Nearby enemies flee in fear"], tip = L["Normal enemies within 8 yards flee in fear for 2 sec and take Shadow damage every sec. Elites, mini-bosses and bosses do not flee."] },
				{ name = L["Shackle"], icon = "Interface\\Icons\\Spell_Nature_Slow", line = L["Binds the strongest enemy"], tip = L["Binds the strongest enemy nearby, elites first, for 2 sec. It takes Holy damage when bound and every sec while bound. Bosses and mini-bosses cannot be bound but still take the first hit."] },
			} },
			{ name = L["Holy"], icon = "Interface\\Icons\\Spell_Holy_PrayerOfHealing02", text = L["Heals that overflow into damage, and Holy Word strikes the strongest enemy."], spells = {
				{ name = L["Smite"], icon = "Interface\\Icons\\Spell_Holy_HolySmite", line = L["Smites the 2 nearest enemies"], tip = L["Smites the 2 nearest enemies for Holy damage. Each Smite reduces the cooldown of Holy Word: Chastise by 1 sec."] },
				{ name = L["Renew"], icon = "Interface\\Icons\\Spell_Holy_Renew", line = L["Heals you, then smites at full health"], tip = L["Heals you for 1% of your maximum health every sec. At full health, it smites the nearest enemy within 30 yards for Holy damage instead."] },
				{ name = L["Halo"], icon = "Interface\\Icons\\Spell_Holy_PrayerOfHealing02", line = L["A ring of light that heals you"], tip = L["A ring of light hits every enemy within 12 yards of you for Holy damage and heals you for 0.5% of your maximum health per enemy hit, up to 2%."] },
				{ name = L["Holy Word: Chastise"], icon = "Interface\\Icons\\Spell_Holy_Excorcism_02", line = L["Heavy Holy strike on the strongest enemy"], tip = L["The Light strikes the strongest enemy nearby, elites first, for heavy Holy damage. Each Smite or Halo reduces its cooldown by 1 sec."] },
			} },
			{ name = L["Shadow"], icon = "Interface\\Icons\\Spell_Shadow_ShadowWordPain", text = L["Plant Decay on the far edge of the horde and spread it from mind to mind."], spells = {
				{ name = L["Shadow Word: Pain"], icon = "Interface\\Icons\\Spell_Shadow_ShadowWordPain", line = L["Plants Decay on far enemies"], tip = L["Afflicts the 3 enemies farthest from you within 35 yards with 6 stacks of Decay."] },
				{ name = L["Mind Flay"], icon = "Interface\\Icons\\Spell_Shadow_SiphonMana", line = L["Flays the nearest enemy until it dies"], tip = L["Flays the nearest enemy within 20 yards, dealing Shadow damage, applying 1 stack of Decay and slowing it by 30%. Keeps flaying it until it dies or leaves range."] },
				{ name = L["Mind Blast"], icon = "Interface\\Icons\\Spell_Shadow_UnholyFrenzy", line = L["Spreads Decay from the most decayed enemy"], tip = L["Blasts the enemy with the most Decay for Shadow damage. Every enemy within 8 yards of it gains as many Decay stacks as it has, up to 10."] },
				{ name = L["Shadowfiend"], icon = "Interface\\Icons\\Spell_Shadow_GatherShadows", line = L["A Shadowfiend that heals you"], tip = L["Summons a Shadowfiend whose attacks apply Decay and heal you for 0.5% of your maximum health."] },
			} },
		},
	},
	SHAMAN = {
		blurb = L["Lightning that builds Static, Windfury bursts in melee, and totems that hold the ground."],
		starter = { name = L["Lightning Bolt"], icon = "Interface\\Icons\\Spell_Nature_Lightning", line = L["Lightning that bounces once"], tip = L["Hurls lightning at the nearest enemy, bouncing to 1 more, dealing Nature damage and 1 stack of Static to each."] },
		shared = {
			{ name = L["Lightning Shield"], icon = "Interface\\Icons\\Spell_Nature_LightningShield", line = L["Zaps enemies that strike you"], tip = L["Surrounds you with up to 3 lightning charges. An enemy that strikes you is zapped for Nature damage and 1 stack of Static. One charge returns every 3 sec."] },
		},
		specs = {
			{ name = L["Elemental"], icon = "Interface\\Icons\\Spell_Nature_Lightning", text = L["Lightning builds Static on the pack, and shocks cash it in."], spells = {
				{ name = L["Lightning Bolt"], icon = "Interface\\Icons\\Spell_Nature_Lightning", line = L["Lightning that bounces once"], tip = L["Hurls lightning at the nearest enemy, bouncing to 1 more, dealing Nature damage and 1 stack of Static to each."] },
				{ name = L["Chain Lightning"], icon = "Interface\\Icons\\Spell_Nature_ChainLightning", line = L["Lightning that jumps to 4 more"], tip = L["Hurls lightning at the nearest enemy, jumping to 4 more, dealing Nature damage and 1 stack of Static to each."] },
				{ name = L["Flame Shock"], icon = "Interface\\Icons\\Spell_Fire_FlameShock", line = L["Burns the strongest enemy"], tip = L["Shocks the strongest enemy nearby, elites first, dealing Fire damage and applying 6 stacks of Burning."] },
				{ name = L["Earth Shock"], icon = "Interface\\Icons\\Spell_Nature_EarthShock", line = L["Discharges Static on the pack"], tip = L["Shocks the enemy with the most Static for Nature damage, 50% more per Static stack. Consumes the stacks in a discharge that also hits up to 3 nearby enemies."] },
			} },
			{ name = L["Enhancement"], icon = "Interface\\Icons\\Spell_Nature_LightningShield", text = L["Windfury swings in melee, and every 5th hit hurls free lightning."], spells = {
				{ name = L["Windfury Weapon"], icon = "Interface\\Icons\\Spell_Nature_Cyclone", line = L["Swings with Windfury bursts"], tip = L["Swings at the nearest enemy for damage. Every 3rd swing calls Windfury: 2 extra swings that also hit enemies within 4 yards of the target."] },
				{ name = L["Stormstrike"], icon = "Interface\\Icons\\Spell_Holy_SealOfMight", line = L["Two strikes that build Static"], tip = L["Strikes the nearest enemy within 12 yards twice, with weapon and lightning, for damage, applying 2 stacks of Static and 2 stacks of Nature Vulnerability."] },
				{ name = L["Maelstrom Weapon"], icon = "Interface\\Icons\\Spell_Nature_StormReach", line = L["Every 5th hit hurls free lightning"], tip = L["Every 5th melee hit hurls a free Lightning Bolt at the nearest enemy, or a Chain Lightning if you have it, dealing Nature damage. Melee hits are Windfury Weapon swings, Stormstrike and Feral Spirit bites."] },
				{ name = L["Feral Spirit"], icon = "Interface\\Icons\\Spell_Nature_SpiritWolf", line = L["2 spirit wolves fight for you"], tip = L["Summons 2 spirit wolves whose bites apply Static."] },
			} },
			{ name = L["Totemic"], icon = "Interface\\Icons\\Spell_Nature_MagicImmunity", text = L["Totems at your feet burn the pack and heal you while you hold the ground."], spells = {
				{ name = L["Searing Totem"], icon = "Interface\\Icons\\Spell_Fire_SearingTotem", line = L["A totem that hurls fire"], tip = L["Plants a Searing Totem at your feet that hurls fire at 2 enemies within 20 yards, applying Burning. It is replanted when you move away."] },
				{ name = L["Magma Totem"], icon = "Interface\\Icons\\Spell_Fire_SelfDestruct", line = L["A totem that pulses fire around you"], tip = L["Plants a Magma Totem at your feet that pulses fire every 2 sec, dealing Fire damage and 1 stack of Burning to enemies within 8 yards."] },
				{ name = L["Healing Stream Totem"], icon = "Interface\\Icons\\INV_Spear_04", line = L["A totem that heals you"], tip = L["Plants a Healing Stream Totem at your feet that heals you for 1% of your maximum health every sec while you stay within 15 yards."] },
			} },
		},
	},
	MAGE = {
		blurb = L["Frost controls and shatters, Fire burns and nukes, and Arcane blinks through the horde."],
		starter = { name = L["Frostbolt"], icon = "Interface\\Icons\\Spell_Frost_FrostBolt02", line = L["Shatters frozen enemies"], tip = L["Launches a bolt of frost at the nearest enemy, dealing Frost damage and applying 1 stack of Chill. Deals 50% more to Frozen enemies, and your Frost spells always critically strike them."] },
		shared = {
			{ name = L["Summon Elemental"], icon = "Interface\\Icons\\Spell_Frost_SummonWaterElemental", line = L["An elemental fights for you"], tip = L["Summons an elemental to fight for you, following the school most of your spells belong to."] },
		},
		specs = {
			{ name = L["Arcane"], icon = "Interface\\Icons\\Spell_Holy_MagicalSentry", text = L["Blink through the horde. Every Blink sets off Arcane Explosion and Missiles."], spells = {
				{ name = L["Blink"], icon = "Interface\\Icons\\Spell_Arcane_Blink", line = L["Your dash teleports and explodes"], tip = L["Your dash becomes Blink, teleporting you, with 1 additional charge and a 30% shorter cooldown. Each Blink sets off an Arcane Explosion where you leave, dealing Arcane damage to enemies within 10 yards. Takes a spell slot."] },
				{ name = L["Arcane Explosion"], icon = "Interface\\Icons\\Spell_Nature_WispSplode", line = L["Arcane blast around you"], tip = L["Blasts all enemies within 10 yards of you with arcane energy, dealing Arcane damage. Also goes off where you land after each Blink."] },
				{ name = L["Arcane Missiles"], icon = "Interface\\Icons\\Spell_Nature_StarFall", line = L["5 missiles at the nearest enemy"], tip = L["Launches 5 Arcane Missiles at the nearest enemy over 1 sec, each dealing Arcane damage. After each Blink, it fires all 5 at once."] },
			} },
			{ name = L["Fire"], icon = "Interface\\Icons\\Spell_Fire_FireBolt02", text = L["Burn everything, then nuke the most burning enemies."], spells = {
				{ name = L["Fireball"], icon = "Interface\\Icons\\Spell_Fire_FlameBolt", line = L["Fire bolt that leaves enemies Burning"], tip = L["Hurls a fiery ball at the nearest enemy, dealing Fire damage and applying 2 stacks of Burning."] },
				{ name = L["Flamestrike"], icon = "Interface\\Icons\\Spell_Fire_SelfDestruct", line = L["A pillar of fire on the largest group"], tip = L["Calls down a pillar of fire on the largest group of enemies, dealing Fire damage and applying 2 stacks of Burning."] },
				{ name = L["Pyroblast"], icon = "Interface\\Icons\\Spell_Fire_Fireball02", line = L["Huge fireball on elites and bosses"], tip = L["Hurls a huge fireball at an elite or boss, or else the largest group, dealing heavy Fire damage to the target and 35% of it to enemies within 6 yards."] },
				{ name = L["Fire Blast"], icon = "Interface\\Icons\\Spell_Fire_Fireball", line = L["Blasts the most burning enemies"], tip = L["Blasts the 3 enemies with the most Burning, dealing Fire damage, 10% more per Burning stack, up to 30 stacks."] },
			} },
			{ name = L["Frost"], icon = "Interface\\Icons\\Spell_Frost_FrostBolt02", text = L["Chill and freeze the pack, then shatter frozen enemies with Frostbolt."], spells = {
				{ name = L["Frostbolt"], icon = "Interface\\Icons\\Spell_Frost_FrostBolt02", line = L["Shatters frozen enemies"], tip = L["Launches a bolt of frost at the nearest enemy, dealing Frost damage and applying 1 stack of Chill. Deals 50% more to Frozen enemies, and your Frost spells always critically strike them."] },
				{ name = L["Blizzard"], icon = "Interface\\Icons\\Spell_Frost_IceStorm", line = L["Ice shards on the largest group"], tip = L["Ice shards pelt the largest group of enemies for 4 sec, dealing Frost damage and applying 1 stack of Chill every sec."] },
				{ name = L["Frost Nova"], icon = "Interface\\Icons\\Spell_Frost_FrostNova", line = L["Frost blast around you"], tip = L["Blasts all enemies within 10 yards of you with frost, dealing Frost damage and applying 3 stacks of Chill."] },
			} },
		},
	},
	WARLOCK = {
		blurb = L["A crew of demons at your side, afflictions that grow with time, and fel fire that rains on the pack."],
		starter = { name = L["Shadow Bolt"], icon = "Interface\\Icons\\Spell_Shadow_ShadowBolt", line = L["Kills fire more Shadow Bolts"], tip = L["Fires a Shadow Bolt at the nearest enemy, dealing damage. Nightfall: enemies that die with your afflictions on them fire a free bolt, at most 1 a sec."] },
		shared = {
		},
		specs = {
			{ name = L["Affliction"], icon = "Interface\\Icons\\Spell_Shadow_DeathCoil", text = L["Corruption and Curse of Agony grow with time while Drain Life keeps you alive."], spells = {
				{ name = L["Corruption"], icon = "Interface\\Icons\\Spell_Shadow_AbominationExplosion", line = L["Decay that grows on the nearest enemies"], tip = L["Corrupts the 2 nearest enemies with 1 stack of Decay, or 2 on an enemy without Decay."] },
				{ name = L["Curse of Agony"], icon = "Interface\\Icons\\Spell_Shadow_CurseOfSargeras", line = L["Agony on the healthiest enemies"], tip = L["Curses the 2 enemies with the most health with 1 stack of Agony, or 2 on an uncursed enemy."] },
				{ name = L["Drain Life"], icon = "Interface\\Icons\\Spell_Shadow_LifeDrain02", line = L["Drains life while you move"], tip = L["Drains the nearest enemy within 16 yards, dealing damage every sec and healing you for 0.2% of your maximum health per enemy drained."] },
			} },
			{ name = L["Demonology"], icon = "Interface\\Icons\\Spell_Shadow_Metamorphosis", text = L["A crew of demons out at once: Imp, Voidwalker, Succubus and Felhunter."], spells = {
				{ name = L["Imp"], icon = "Interface\\Icons\\Spell_Shadow_SummonImp", line = L["An Imp that hurls fire"], tip = L["Summons an Imp that hurls 2 Firebolts at a time at enemies within 30 yards, leaving them burning."] },
				{ name = L["Voidwalker"], icon = "Interface\\Icons\\Spell_Shadow_SummonVoidWalker", line = L["A Voidwalker that bursts in a void nova"], tip = L["Summons a Voidwalker that consumes enemies dying near it. After 8 it bursts in a void nova that hits every enemy around it."] },
				{ name = L["Succubus"], icon = "Interface\\Icons\\Spell_Shadow_SummonSuccubus", line = L["A Succubus that lashes a wide arc"], tip = L["Summons a Succubus whose Lash of Pain strikes all enemies in a wide arc in front of her and applies Shadow Vulnerability."] },
				{ name = L["Felhunter"], icon = "Interface\\Icons\\Spell_Shadow_SummonFelHunter", line = L["A Felhunter that bites afflicted enemies"], tip = L["Summons a Felhunter whose Shadow Bite deals 10% more damage per affliction on the target and interrupts spells, and whose Shadow Cleave hits every enemy in front of it. Every 10 sec it removes a harmful effect from you."] },
			} },
			{ name = L["Destruction"], icon = "Interface\\Icons\\Spell_Shadow_RainOfFire", text = L["Fel fire: Shadow Bolt, Immolate, Hellfire and Rain of Fire on the pack."], spells = {
				{ name = L["Shadow Bolt"], icon = "Interface\\Icons\\Spell_Shadow_ShadowBolt", line = L["Kills fire more Shadow Bolts"], tip = L["Fires a Shadow Bolt at the nearest enemy, dealing damage. Nightfall: enemies that die with your afflictions on them fire a free bolt, at most 1 a sec."] },
				{ name = L["Immolate"], icon = "Interface\\Icons\\Spell_Fire_Immolation", line = L["Fire that leaves enemies Burning"], tip = L["Strikes the 2 nearest enemies with fire, dealing damage and applying 2 stacks of Burning."] },
				{ name = L["Hellfire"], icon = "Interface\\Icons\\Spell_Fire_Incinerate", line = L["Fire burns everything around you"], tip = L["Fire burns every enemy within 8 yards of you, dealing damage."] },
				{ name = L["Rain of Fire"], icon = "Interface\\Icons\\Spell_Shadow_RainOfFire", line = L["Fire rains on the largest group"], tip = L["Rains fire on the largest group of enemies for 4 sec, dealing damage and applying 1 stack of Burning every sec."] },
			} },
		},
	},
	DRUID = {
		blurb = L["A shapeshifter that changes between Moonkin, Cat, Bear and Tree of Life. Every spell works in every form, and the right form makes it 30% stronger."],
		starter = { name = L["Shapeshift"], icon = "Interface\\Icons\\Ability_Druid_CatForm", line = L["Press 'R' to change form"], tip = L["Press R to shift into your next form. Druid spells deal and heal 30% more in their form.|n|n|cffffffffMoonkin Form (30 yd range):|r Wrath strikes the nearest enemy for Nature damage, splashing nearby enemies. Every 3 sec, Starfall strikes 3 enemies afflicted by Moonfire.|n|n|cffffffffCat Form (10 yd range):|r Claws the nearest enemy for Physical damage and causes Bleed. Movement speed increased by 15%. Critical strikes cause Bleed.|n|n|cffffffffBear Form (10 yd range):|r Mauls the nearest enemy for Physical damage. Damage taken reduced by 35%, but spells of other forms deal 20% less. Swipe deals 8% more per nearby enemy. Every 6 sec, roars to Daze nearby enemies and reduce their damage by 25%.|n|n|cffffffffTree of Life (20 yd range):|r Vines lash 3 enemies for Nature damage, each hit healing you for 0.3% of your maximum health. Calls 1 additional Treant. Rejuvenation blooms 50% faster."] },
		shared = {
		},
		specs = {
			{ name = L["Balance"], icon = "Interface\\Icons\\Spell_Nature_StarFall", text = L["Moonkin form. Starlight on the strongest enemy, Moonfire on the pack and storms on the crowd."], spells = {
				{ name = L["Starfire"], icon = "Interface\\Icons\\Spell_Arcane_StarFire", line = L["Starlight on the strongest enemy"], tip = L["Calls down starlight on the strongest enemy for heavy Arcane damage. Empowered in Moonkin Form."] },
				{ name = L["Moonfire"], icon = "Interface\\Icons\\Spell_Nature_StarFall", line = L["Moonfire on the nearest enemies"], tip = L["Burns the 2 nearest enemies for Arcane damage and applies 1 stack of Moonfire. Empowered in Moonkin Form."] },
				{ name = L["Hurricane"], icon = "Interface\\Icons\\Spell_Nature_Cyclone", line = L["A storm on the largest group"], tip = L["A storm rages over the largest group of enemies for 4 sec, dealing Nature damage every sec and Dazing them. Empowered in Moonkin Form."] },
			} },
			{ name = L["Feral"], icon = "Interface\\Icons\\Ability_Racial_BearForm", text = L["Cat and Bear form. Bleed the pack, Shred the deepest bleeder, and shift to Bear when you are hurt."], spells = {
				{ name = L["Rake"], icon = "Interface\\Icons\\Ability_Druid_Disembowel", line = L["Makes the 3 nearest enemies Bleed"], tip = L["Rakes the 3 nearest enemies for damage and 2 stacks of Bleed. Empowered in Cat Form."] },
				{ name = L["Shred"], icon = "Interface\\Icons\\Spell_Shadow_VampiricAura", line = L["Strikes the enemy with the most Bleed stacks"], tip = L["Shreds the most Bleeding enemy for damage, increased by 3% per stack of Bleed on it. Empowered in Cat Form."] },
				{ name = L["Swipe"], icon = "Interface\\Icons\\INV_Misc_MonsterClaw_03", line = L["Hits every enemy within 10 yards"], tip = L["Swipes all nearby enemies for damage. Empowered in Bear Form."] },
				{ name = L["Frenzied Regeneration"], icon = "Interface\\Icons\\Ability_BullRush", line = L["Heals you for each enemy close by"], tip = L["Every sec, heals you for 0.25% of your maximum health per nearby enemy, up to 5. Empowered in Bear Form."] },
			} },
			{ name = L["Restoration"], icon = "Interface\\Icons\\Spell_Nature_HealingTouch", text = L["Tree of Life. Heals that hurt, while Treants and roots hold the crowd."], spells = {
				{ name = L["Rejuvenation"], icon = "Interface\\Icons\\Spell_Nature_Rejuvenation", line = L["Heals you and lashes nearby enemies"], tip = L["Heals you for 0.3% of your maximum health. Its thorny bloom lashes the 3 nearest enemies for Nature damage. Empowered in Tree of Life."] },
				{ name = L["Force of Nature"], icon = "Interface\\Icons\\Spell_Nature_NatureTouchGrow", line = L["2 Treants fight at your side"], tip = L["Summons 2 Treants. Their attacks apply Moonfire, and every 6 sec they root their target and nearby enemies for 2 sec. Empowered in Tree of Life, which calls 1 additional Treant."] },
				{ name = L["Entangling Roots"], icon = "Interface\\Icons\\Spell_Nature_StrangleVines", line = L["Roots the 3 nearest enemies"], tip = L["Roots grasp the 3 nearest enemies for Nature damage and root them for 2 sec. Empowered in Tree of Life."] },
				{ name = L["Tranquility"], icon = "Interface\\Icons\\Spell_Nature_Tranquility", line = L["Pulses that hurt enemies and heal you"], tip = L["Calms the air for 4 sec. Every sec, deals Nature damage to nearby enemies and heals you for 0.5% of your maximum health. Empowered in Tree of Life."] },
				{ name = L["Thorns"], icon = "Interface\\Icons\\Spell_Nature_Thorns", line = L["Enemies that strike you take damage"], tip = L["Enemies that strike you take Nature damage. Empowered in Bear Form."] },
			} },
		},
	},
};
