BONK_CLASS_INFO = {
	WARRIOR = {
		blurb = "Fights in the thick of the horde. Every swing hits all around you, and there is no Rage to manage.",
		starter = { name = "Bloodthirst", icon = "Interface\\Icons\\Spell_Nature_BloodLust", line = "Strikes 3 enemies and heals you", tip = "Strikes the 3 nearest enemies within 8 yards for damage and heals you for 0.5% of your maximum health per enemy hit, up to 2.5%. Critical strikes Enrage you: 25% Haste for 4 sec." },
		shared = {
			{ name = "Cleave", icon = "Interface\\Icons\\Ability_Warrior_Cleave", line = "Strikes every enemy within 8 yards", tip = "Strikes all enemies within 8 yards of you for damage." },
		},
		specs = {
			{ name = "Arms", icon = "Interface\\Icons\\Ability_Warrior_SavageBlow", text = "Stack Bleed on the pack, then cash it in with Mortal Strike.", spells = {
				{ name = "Rend", icon = "Interface\\Icons\\Ability_Gouge", line = "Makes the 3 nearest enemies Bleed", tip = "Wounds the 3 nearest enemies within 10 yards with 3 stacks of Bleed." },
				{ name = "Deep Wounds", icon = "Interface\\Icons\\Ability_BackStab", line = "Your critical strikes make enemies Bleed", tip = "Your critical strikes wound the enemy with 2 stacks of Bleed, at most once every 0.5 sec per enemy." },
				{ name = "Mortal Strike", icon = "Interface\\Icons\\Ability_Warrior_SavageBlow", line = "Hits harder for each stack of Bleed", tip = "Strikes all enemies within 8 yards of you for damage, 8% more per stack of Bleed on the target, up to 30 stacks." },
			} },
			{ name = "Fury", icon = "Interface\\Icons\\Ability_Warrior_InnerRage", text = "Critical strikes and kills Enrage you, and Enrage makes you strike faster.", spells = {
				{ name = "Bloodthirst", icon = "Interface\\Icons\\Spell_Nature_BloodLust", line = "Strikes 3 enemies and heals you", tip = "Strikes the 3 nearest enemies within 8 yards for damage and heals you for 0.5% of your maximum health per enemy hit, up to 2.5%. Critical strikes Enrage you: 25% Haste for 4 sec." },
				{ name = "Execute", icon = "Interface\\Icons\\INV_Sword_48", line = "Slays normal enemies below 20% health", tip = "Strikes all enemies within 8 yards of you for damage. Normal enemies below 20% health die instantly; elites and bosses below 20% take triple damage. Kills Enrage you: 25% Haste for 4 sec." },
				{ name = "Whirlwind", icon = "Interface\\Icons\\Ability_Whirlwind", line = "Spins through the pack, twice when Enraged", tip = "Spins, striking all enemies within 8 yards of you for damage. Spins twice while you are Enraged." },
			} },
			{ name = "Protection", icon = "Interface\\Icons\\INV_Shield_06", text = "Get hit, absorb it with your Shield, and punish it.", spells = {
				{ name = "Shield Block", icon = "Interface\\Icons\\Ability_Defend", line = "A Shield that soaks damage, stacking up", tip = "Adds a Shield of 10% of your maximum health that lasts until it absorbs damage, stacking up to 50%." },
				{ name = "Thunder Clap", icon = "Interface\\Icons\\Ability_ThunderClap", line = "Blasts nearby enemies and slows their attacks", tip = "Blasts all enemies within 8 yards of you for damage. Enemies hit attack 20% slower for 6 sec." },
				{ name = "Revenge", icon = "Interface\\Icons\\Ability_Warrior_Revenge", line = "Strikes back when you are hit", tip = "When you are struck, strikes all enemies within 6 yards of you for damage, at most once every 2 sec." },
				{ name = "Shield Slam", icon = "Interface\\Icons\\INV_Shield_05", line = "Hits harder the bigger your Shield", tip = "Slams all enemies within 6 yards of you for damage, 2% more for each 1% of your maximum health in your Shield, up to 200% more." },
			} },
		},
	},
	PALADIN = {
		blurb = "Seals change every strike and Judgement releases them. Holy light burns all around you, and hammers finish the wounded.",
		starter = { name = "Crusader Strike", icon = "Interface\\Icons\\Spell_Holy_HolySmite", line = "Heavy strike with splash damage", tip = "Strikes the nearest enemy for heavy damage and 30% of it to enemies within 5 yards of the target." },
		shared = {
		},
		specs = {
			{ name = "Holy", icon = "Interface\\Icons\\Spell_Holy_HolyBolt", text = "Holy strikes from afar: Exorcism, falling hammers and light that heals with every strike.", spells = {
				{ name = "Exorcism", icon = "Interface\\Icons\\Spell_Holy_Excorcism_02", line = "Heavy Holy strike on the strongest enemy", tip = "Strikes the strongest enemy within 30 yards for heavy Holy damage. Undead and Demons take triple damage, elites and bosses double. Critical strikes from your other Paladin spells reset its cooldown, at most once a sec." },
				{ name = "Seal of Light", icon = "Interface\\Icons\\Spell_Holy_HealingAura", line = "Your strikes heal you", tip = "Every strike from your other Paladin spells heals you for 0.5% of your maximum health, at most 6 times a sec." },
				{ name = "Light's Hammer", icon = "Interface\\Icons\\Spell_Holy_FistOfJustice", line = "Hammers of light fall on the pack", tip = "Hammers of light fall on 3 random enemies within 25 yards, each dealing Holy damage to every enemy within 5 yards." },
			} },
			{ name = "Protection", icon = "Interface\\Icons\\Spell_Holy_DevotionAura", text = "Holy ground and auras burn whoever comes close, while Divine Shield blocks the big hits.", spells = {
				{ name = "Consecration", icon = "Interface\\Icons\\Spell_Holy_InnerFire", line = "Holy ground that burns enemies on it", tip = "Consecrates the ground beneath you for 8 sec, dealing Holy damage every sec to enemies on it. You deal 15% more damage while standing on it." },
				{ name = "Divine Shield", icon = "Interface\\Icons\\Spell_Holy_DivineIntervention", line = "A bubble that blocks the next big hit", tip = "A golden bubble forms around you and blocks the next enemy hit that would take more than 5% of your maximum health." },
				{ name = "Retribution Aura", icon = "Interface\\Icons\\Spell_Holy_AuraOfLight", line = "Burns every enemy close to you", tip = "Burns every enemy within 10 yards of you with holy light, dealing Holy damage every sec. Enemies that strike you take double." },
				{ name = "Hammer of Justice", icon = "Interface\\Icons\\Spell_Holy_SealOfMight", line = "Stuns the strongest enemy", tip = "Hurls a hammer at the strongest enemy within 20 yards, dealing Holy damage and stunning it for 2 sec. Bosses are not stunned." },
			} },
			{ name = "Retribution", icon = "Interface\\Icons\\Spell_Holy_AuraOfLight", text = "Crusader Strike and Seals on every swing, released by Judgement, with hammers for the wounded.", spells = {
				{ name = "Crusader Strike", icon = "Interface\\Icons\\Spell_Holy_HolySmite", line = "Heavy strike with splash damage", tip = "Strikes the nearest enemy for heavy damage and 30% of it to enemies within 5 yards of the target." },
				{ name = "Judgement", icon = "Interface\\Icons\\Spell_Holy_RighteousFury", line = "Hammers 3 enemies and releases your Seals", tip = "Slams the 3 strongest enemies within 20 yards with a hammer of light for Holy damage, with double critical strike chance. Releases your Seals: Righteousness adds 50% damage, Command hits enemies within 5 yards of each target for half, Light heals you for 1% of your maximum health per enemy hit." },
				{ name = "Seal of Command", icon = "Interface\\Icons\\Ability_Warrior_InnerRage", line = "Every 3rd strike bursts with light", tip = "Every 3rd strike from your other Paladin spells releases a burst of light, dealing Holy damage to the target and every enemy within 5 yards of it." },
				{ name = "Seal of Righteousness", icon = "Interface\\Icons\\Ability_ThunderBolt", line = "Your hits deal extra Holy damage", tip = "Every hit from your other Paladin spells, splash and area hits included, deals 20% extra as Holy damage." },
				{ name = "Divine Storm", icon = "Interface\\Icons\\Spell_Holy_SealOfWrath", line = "Holy burst around you that heals", tip = "Holy light bursts around you, dealing Holy damage to every enemy within 10 yards and healing you for 0.5% of your maximum health per enemy hit, up to 3%." },
				{ name = "Hammer of Wrath", icon = "Interface\\Icons\\Ability_ThunderClap", line = "Slays wounded enemies", tip = "Hurls hammers at up to 3 enemies below 20% health within 30 yards. Normal enemies are slain; elites and bosses take heavy Holy damage." },
			} },
		},
	},
	HUNTER = {
		blurb = "Shoots from range while pets fight at your side. Marks, stings and traps set up the kill.",
		starter = { name = "Arcane Shot", icon = "Interface\\Icons\\Ability_ImpalingBolt", line = "Shoots the nearest enemy", tip = "Shoots the nearest enemy for Arcane damage." },
		shared = {
		},
		specs = {
			{ name = "Beast Mastery", icon = "Interface\\Icons\\Ability_Hunter_BeastTaming", text = "Pets do the fighting: your cat bleeds the pack and the spirit wolf leads it.", spells = {
				{ name = "Call Pet", icon = "Interface\\Icons\\Ability_Hunter_BeastCall", line = "Your cat fights for you", tip = "Summons your cat to fight for you. Its Claw applies Bleed, and its Swipe hits every enemy in front of it." },
				{ name = "Pack Leader", icon = "Interface\\Icons\\Spell_Nature_SpiritWolf", line = "A spirit wolf that empowers your pets", tip = "A spirit wolf fights for you, biting for damage. Every 15 sec it howls, and your other pets deal double damage to all enemies in front for 6 sec." },
			} },
			{ name = "Marksmanship", icon = "Interface\\Icons\\Ability_Marksmanship", text = "Shots, volleys and piercing arrows, with Hunter's Mark on the biggest group.", spells = {
				{ name = "Arcane Shot", icon = "Interface\\Icons\\Ability_ImpalingBolt", line = "Shoots the nearest enemy", tip = "Shoots the nearest enemy for Arcane damage." },
				{ name = "Multi-Shot", icon = "Interface\\Icons\\Ability_UpgradeMoonGlaive", line = "6 arrows in a cone", tip = "Fires 6 arrows in a cone in front of you, dealing damage." },
				{ name = "Volley", icon = "Interface\\Icons\\Ability_Marksmanship", line = "Rains arrows on the largest group", tip = "Rains arrows on the largest group of enemies for 4 sec, dealing damage, 5% more for each different debuff on the target." },
				{ name = "Aimed Shot", icon = "Interface\\Icons\\INV_Spear_07", line = "A shot that pierces a whole line", tip = "Fires a shot that pierces every enemy in a line, dealing damage. Aims at the Marked group, or else the largest group." },
				{ name = "Hunter's Mark", icon = "Interface\\Icons\\Ability_Hunter_SniperShot", line = "Marked enemies take more damage", tip = "Marks every enemy within 10 yards of the largest group for 8 sec. Marked enemies take 15% more damage." },
			} },
			{ name = "Survival", icon = "Interface\\Icons\\Ability_Hunter_SwiftStrike", text = "Poison stings, and traps that burn or slow whatever walks in.", spells = {
				{ name = "Serpent Sting", icon = "Interface\\Icons\\Ability_Hunter_Quickshot", line = "Poisons the nearest enemies", tip = "Stings the nearest enemy and 2 enemies near it with 3 stacks of Poison." },
				{ name = "Explosive Trap", icon = "Interface\\Icons\\Spell_Fire_SelfDestruct", line = "A trap that explodes and burns the ground", tip = "Places a fire trap that explodes when an enemy comes close, dealing damage and burning the ground for 4 sec, applying Burning." },
				{ name = "Frost Trap", icon = "Interface\\Icons\\Spell_Frost_FreezingBreath", line = "A trap that slows the pack", tip = "Places a frost trap that goes off when an enemy comes close, slowing normal enemies inside by 60% for 6 sec. They take 5% more damage." },
			} },
		},
	},
	ROGUE = {
		blurb = "The fastest single-target attacks in the game. Every stab carries a poison or an opener.",
		starter = { name = "Sinister Strike", icon = "Interface\\Icons\\Spell_Shadow_RitualOfSacrifice", line = "Fast stabs on the nearest enemy", tip = "Stabs the nearest enemy for damage." },
		shared = {
		},
		specs = {
			{ name = "Assassination", icon = "Interface\\Icons\\Ability_Rogue_Eviscerate", text = "Poison on every hit, then Envenom the most poisoned enemy.", spells = {
				{ name = "Mutilate", icon = "Interface\\Icons\\Ability_BackStab", line = "Two poisoned stabs on the nearest enemy", tip = "Stabs the nearest enemy with both daggers for damage, each stab applying 1 stack of Poison. Deals 30% more to Poisoned enemies." },
				{ name = "Deadly Poison", icon = "Interface\\Icons\\Ability_Rogue_DualWeild", line = "Your hits apply Poison", tip = "Your other abilities apply 1 stack of Poison with every hit." },
				{ name = "Fan of Knives", icon = "Interface\\Icons\\INV_ThrowingKnife_04", line = "Knives in every direction", tip = "Throws knives in every direction, striking all enemies within 10 yards for damage and applying 2 stacks of Poison. Every knife carries your poisons and openers." },
				{ name = "Envenom", icon = "Interface\\Icons\\Ability_Creature_Poison_06", line = "Strikes the most poisoned enemy", tip = "Strikes the enemy with the most Poison for Nature damage, and your hits apply 2 more stacks of Poison for 5 sec." },
			} },
			{ name = "Combat", icon = "Interface\\Icons\\Ability_BackStab", text = "Fast blades: Blade Flurry, Eviscerate and Killing Spree through the pack.", spells = {
				{ name = "Sinister Strike", icon = "Interface\\Icons\\Spell_Shadow_RitualOfSacrifice", line = "Fast stabs on the nearest enemy", tip = "Stabs the nearest enemy for damage." },
				{ name = "Blade Flurry", icon = "Interface\\Icons\\Ability_Warrior_PunishingBlow", line = "Your hits strike 4 more enemies", tip = "Your single-target hits also strike 4 more enemies within 8 yards at 50% damage for 8 sec. The extra hits carry your poisons and openers." },
				{ name = "Eviscerate", icon = "Interface\\Icons\\Ability_Rogue_Eviscerate", line = "Heavy strike with double crit chance", tip = "Guts the nearest enemy for heavy damage, with double critical strike chance." },
				{ name = "Killing Spree", icon = "Interface\\Icons\\Ability_Rogue_SliceDice", line = "8 strikes on random enemies", tip = "Strikes 8 times over 2 sec, each strike hitting a random enemy within 10 yards for damage and carrying your poisons and openers." },
			} },
			{ name = "Subtlety", icon = "Interface\\Icons\\Ability_Stealth", text = "Ambush every new enemy you hit, and Shadow Dance to do it again.", spells = {
				{ name = "Shuriken Toss", icon = "Interface\\Icons\\INV_ThrowingAxe_06", line = "Shurikens at fresh enemies", tip = "Throws shurikens at the 3 nearest enemies within 20 yards, ones you have not hit yet first, dealing damage." },
				{ name = "Ambush", icon = "Interface\\Icons\\Ability_Rogue_Ambush", line = "Your first hit on each enemy ambushes it", tip = "Your first hit on each enemy with your other abilities is followed by an Ambush for heavy damage, with double critical strike chance." },
				{ name = "Shadow Dance", icon = "Interface\\Icons\\Spell_Shadow_Charm", line = "More damage, and Ambush again", tip = "Your hits deal 30% more damage for 4 sec and can set off Ambush again, once a sec per enemy." },
				{ name = "Evasion", icon = "Interface\\Icons\\Spell_Shadow_ShadowWard", line = "Dodge far more attacks for a while", tip = "You dodge 50% more attacks for 5 sec." },
			} },
		},
	},
	PRIEST = {
		blurb = "Healing that overflows into damage, a ring of light that hits far, and Decay that spreads from mind to mind.",
		starter = { name = "Smite", icon = "Interface\\Icons\\Spell_Holy_HolySmite", line = "Smites the 2 nearest enemies", tip = "Smites the 2 nearest enemies for Holy damage. Each Smite reduces the cooldown of Holy Word: Chastise by 1 sec." },
		shared = {
		},
		specs = {
			{ name = "Discipline", icon = "Interface\\Icons\\Spell_Holy_WordFortitude", text = "Shields, fear and binding, while Penance punishes whoever strikes you.", spells = {
				{ name = "Power Word: Shield", icon = "Interface\\Icons\\Spell_Holy_PowerWordShield", line = "A shield that makes you faster", tip = "Shields you for 10% of your maximum health; each cast tops it back up instead of stacking. You move 10% faster while shielded." },
				{ name = "Penance", icon = "Interface\\Icons\\Spell_Holy_HolyBolt", line = "Holy bolts at whoever struck you", tip = "Fires 3 holy bolts at the enemies that struck you last, or the nearest enemies, each dealing Holy damage and healing you for 0.5% of your maximum health. Healing past full health becomes Shield." },
				{ name = "Psychic Scream", icon = "Interface\\Icons\\Spell_Shadow_PsychicScream", line = "Nearby enemies flee in fear", tip = "Normal enemies within 8 yards flee in fear for 2 sec and take Shadow damage every sec. Elites, mini-bosses and bosses do not flee." },
				{ name = "Shackle", icon = "Interface\\Icons\\Spell_Nature_Slow", line = "Binds the strongest enemy", tip = "Binds the strongest enemy nearby, elites first, for 2 sec. It takes Holy damage when bound and every sec while bound. Bosses and mini-bosses cannot be bound but still take the first hit." },
			} },
			{ name = "Holy", icon = "Interface\\Icons\\Spell_Holy_PrayerOfHealing02", text = "Heals that overflow into damage, and Holy Word strikes the strongest enemy.", spells = {
				{ name = "Smite", icon = "Interface\\Icons\\Spell_Holy_HolySmite", line = "Smites the 2 nearest enemies", tip = "Smites the 2 nearest enemies for Holy damage. Each Smite reduces the cooldown of Holy Word: Chastise by 1 sec." },
				{ name = "Renew", icon = "Interface\\Icons\\Spell_Holy_Renew", line = "Heals you, then smites at full health", tip = "Heals you for 1% of your maximum health every sec. At full health, it smites the nearest enemy within 30 yards for Holy damage instead." },
				{ name = "Halo", icon = "Interface\\Icons\\Spell_Holy_PrayerOfHealing02", line = "A ring of light that heals you", tip = "A ring of light hits every enemy within 12 yards of you for Holy damage and heals you for 0.5% of your maximum health per enemy hit, up to 2%." },
				{ name = "Holy Word: Chastise", icon = "Interface\\Icons\\Spell_Holy_Excorcism_02", line = "Heavy Holy strike on the strongest enemy", tip = "The Light strikes the strongest enemy nearby, elites first, for heavy Holy damage. Each Smite or Halo reduces its cooldown by 1 sec." },
			} },
			{ name = "Shadow", icon = "Interface\\Icons\\Spell_Shadow_ShadowWordPain", text = "Plant Decay on the far edge of the horde and spread it from mind to mind.", spells = {
				{ name = "Shadow Word: Pain", icon = "Interface\\Icons\\Spell_Shadow_ShadowWordPain", line = "Plants Decay on far enemies", tip = "Afflicts the 3 enemies farthest from you within 35 yards with 6 stacks of Decay." },
				{ name = "Mind Flay", icon = "Interface\\Icons\\Spell_Shadow_SiphonMana", line = "Flays the nearest enemy until it dies", tip = "Flays the nearest enemy within 20 yards, dealing Shadow damage, applying 1 stack of Decay and slowing it by 30%. Keeps flaying it until it dies or leaves range." },
				{ name = "Mind Blast", icon = "Interface\\Icons\\Spell_Shadow_UnholyFrenzy", line = "Spreads Decay from the most decayed enemy", tip = "Blasts the enemy with the most Decay for Shadow damage. Every enemy within 8 yards of it gains as many Decay stacks as it has, up to 10." },
				{ name = "Shadowfiend", icon = "Interface\\Icons\\Spell_Shadow_GatherShadows", line = "A Shadowfiend that heals you", tip = "Summons a Shadowfiend whose attacks apply Decay and heal you for 0.5% of your maximum health." },
			} },
		},
	},
	SHAMAN = {
		blurb = "Lightning that builds Static, Windfury bursts in melee, and totems that hold the ground.",
		starter = { name = "Lightning Bolt", icon = "Interface\\Icons\\Spell_Nature_Lightning", line = "Lightning that bounces once", tip = "Hurls lightning at the nearest enemy, bouncing to 1 more, dealing Nature damage and 1 stack of Static to each." },
		shared = {
			{ name = "Lightning Shield", icon = "Interface\\Icons\\Spell_Nature_LightningShield", line = "Zaps enemies that strike you", tip = "Surrounds you with up to 3 lightning charges. An enemy that strikes you is zapped for Nature damage and 1 stack of Static. One charge returns every 3 sec." },
		},
		specs = {
			{ name = "Elemental", icon = "Interface\\Icons\\Spell_Nature_Lightning", text = "Lightning builds Static on the pack, and shocks cash it in.", spells = {
				{ name = "Lightning Bolt", icon = "Interface\\Icons\\Spell_Nature_Lightning", line = "Lightning that bounces once", tip = "Hurls lightning at the nearest enemy, bouncing to 1 more, dealing Nature damage and 1 stack of Static to each." },
				{ name = "Chain Lightning", icon = "Interface\\Icons\\Spell_Nature_ChainLightning", line = "Lightning that jumps to 4 more", tip = "Hurls lightning at the nearest enemy, jumping to 4 more, dealing Nature damage and 1 stack of Static to each." },
				{ name = "Flame Shock", icon = "Interface\\Icons\\Spell_Fire_FlameShock", line = "Burns the strongest enemy", tip = "Shocks the strongest enemy nearby, elites first, dealing Fire damage and applying 6 stacks of Burning." },
				{ name = "Earth Shock", icon = "Interface\\Icons\\Spell_Nature_EarthShock", line = "Discharges Static on the pack", tip = "Shocks the enemy with the most Static for Nature damage, 50% more per Static stack. Consumes the stacks in a discharge that also hits up to 3 nearby enemies." },
			} },
			{ name = "Enhancement", icon = "Interface\\Icons\\Spell_Nature_LightningShield", text = "Windfury swings in melee, and every 5th hit hurls free lightning.", spells = {
				{ name = "Windfury Weapon", icon = "Interface\\Icons\\Spell_Nature_Cyclone", line = "Swings with Windfury bursts", tip = "Swings at the nearest enemy for damage. Every 3rd swing calls Windfury: 2 extra swings that also hit enemies within 4 yards of the target." },
				{ name = "Stormstrike", icon = "Interface\\Icons\\Spell_Holy_SealOfMight", line = "Two strikes that build Static", tip = "Strikes the nearest enemy within 12 yards twice, with weapon and lightning, for damage, applying 2 stacks of Static and 2 stacks of Nature Vulnerability." },
				{ name = "Maelstrom Weapon", icon = "Interface\\Icons\\Spell_Nature_StormReach", line = "Every 5th hit hurls free lightning", tip = "Every 5th melee hit hurls a free Lightning Bolt at the nearest enemy, or a Chain Lightning if you have it, dealing Nature damage. Melee hits are Windfury Weapon swings, Stormstrike and Feral Spirit bites." },
				{ name = "Feral Spirit", icon = "Interface\\Icons\\Spell_Nature_SpiritWolf", line = "2 spirit wolves fight for you", tip = "Summons 2 spirit wolves whose bites apply Static." },
			} },
			{ name = "Totemic", icon = "Interface\\Icons\\Spell_Nature_MagicImmunity", text = "Totems at your feet burn the pack and heal you while you hold the ground.", spells = {
				{ name = "Searing Totem", icon = "Interface\\Icons\\Spell_Fire_SearingTotem", line = "A totem that hurls fire", tip = "Plants a Searing Totem at your feet that hurls fire at 2 enemies within 20 yards, applying Burning. It is replanted when you move away." },
				{ name = "Magma Totem", icon = "Interface\\Icons\\Spell_Fire_SelfDestruct", line = "A totem that pulses fire around you", tip = "Plants a Magma Totem at your feet that pulses fire every 2 sec, dealing Fire damage and 1 stack of Burning to enemies within 8 yards." },
				{ name = "Healing Stream Totem", icon = "Interface\\Icons\\INV_Spear_04", line = "A totem that heals you", tip = "Plants a Healing Stream Totem at your feet that heals you for 1% of your maximum health every sec while you stay within 15 yards." },
			} },
		},
	},
	MAGE = {
		blurb = "Frost controls and shatters, Fire burns and nukes, and Arcane blinks through the horde.",
		starter = { name = "Frostbolt", icon = "Interface\\Icons\\Spell_Frost_FrostBolt02", line = "Shatters frozen enemies", tip = "Launches a bolt of frost at the nearest enemy, dealing Frost damage and applying 1 stack of Chill. Deals 50% more to Frozen enemies, and your Frost spells always critically strike them." },
		shared = {
			{ name = "Summon Elemental", icon = "Interface\\Icons\\Spell_Frost_SummonWaterElemental", line = "An elemental fights for you", tip = "Summons an elemental to fight for you, following the school most of your spells belong to." },
		},
		specs = {
			{ name = "Arcane", icon = "Interface\\Icons\\Spell_Holy_MagicalSentry", text = "Blink through the horde. Every Blink sets off Arcane Explosion and Missiles.", spells = {
				{ name = "Blink", icon = "Interface\\Icons\\Spell_Arcane_Blink", line = "Your dash teleports and explodes", tip = "Your dash becomes Blink, teleporting you, with 1 additional charge and a 30% shorter cooldown. Each Blink sets off an Arcane Explosion where you leave, dealing Arcane damage to enemies within 10 yards. Takes a spell slot." },
				{ name = "Arcane Explosion", icon = "Interface\\Icons\\Spell_Nature_WispSplode", line = "Arcane blast around you", tip = "Blasts all enemies within 10 yards of you with arcane energy, dealing Arcane damage. Also goes off where you land after each Blink." },
				{ name = "Arcane Missiles", icon = "Interface\\Icons\\Spell_Nature_StarFall", line = "5 missiles at the nearest enemy", tip = "Launches 5 Arcane Missiles at the nearest enemy over 1 sec, each dealing Arcane damage. After each Blink, it fires all 5 at once." },
			} },
			{ name = "Fire", icon = "Interface\\Icons\\Spell_Fire_FireBolt02", text = "Burn everything, then nuke the most burning enemies.", spells = {
				{ name = "Fireball", icon = "Interface\\Icons\\Spell_Fire_FlameBolt", line = "Fire bolt that leaves enemies Burning", tip = "Hurls a fiery ball at the nearest enemy, dealing Fire damage and applying 2 stacks of Burning." },
				{ name = "Flamestrike", icon = "Interface\\Icons\\Spell_Fire_SelfDestruct", line = "A pillar of fire on the largest group", tip = "Calls down a pillar of fire on the largest group of enemies, dealing Fire damage and applying 2 stacks of Burning." },
				{ name = "Pyroblast", icon = "Interface\\Icons\\Spell_Fire_Fireball02", line = "Huge fireball on elites and bosses", tip = "Hurls a huge fireball at an elite or boss, or else the largest group, dealing heavy Fire damage to the target and 35% of it to enemies within 6 yards." },
				{ name = "Fire Blast", icon = "Interface\\Icons\\Spell_Fire_Fireball", line = "Blasts the most burning enemies", tip = "Blasts the 3 enemies with the most Burning, dealing Fire damage, 10% more per Burning stack, up to 30 stacks." },
			} },
			{ name = "Frost", icon = "Interface\\Icons\\Spell_Frost_FrostBolt02", text = "Chill and freeze the pack, then shatter frozen enemies with Frostbolt.", spells = {
				{ name = "Frostbolt", icon = "Interface\\Icons\\Spell_Frost_FrostBolt02", line = "Shatters frozen enemies", tip = "Launches a bolt of frost at the nearest enemy, dealing Frost damage and applying 1 stack of Chill. Deals 50% more to Frozen enemies, and your Frost spells always critically strike them." },
				{ name = "Blizzard", icon = "Interface\\Icons\\Spell_Frost_IceStorm", line = "Ice shards on the largest group", tip = "Ice shards pelt the largest group of enemies for 4 sec, dealing Frost damage and applying 1 stack of Chill every sec." },
				{ name = "Frost Nova", icon = "Interface\\Icons\\Spell_Frost_FrostNova", line = "Frost blast around you", tip = "Blasts all enemies within 10 yards of you with frost, dealing Frost damage and applying 3 stacks of Chill." },
			} },
		},
	},
	WARLOCK = {
		blurb = "A crew of demons at your side, afflictions that grow with time, and fel fire that rains on the pack.",
		starter = { name = "Shadow Bolt", icon = "Interface\\Icons\\Spell_Shadow_ShadowBolt", line = "Kills fire more Shadow Bolts", tip = "Fires a Shadow Bolt at the nearest enemy, dealing damage. Nightfall: enemies that die with your afflictions on them fire a free bolt, at most 1 a sec." },
		shared = {
		},
		specs = {
			{ name = "Affliction", icon = "Interface\\Icons\\Spell_Shadow_DeathCoil", text = "Corruption and Curse of Agony grow with time while Drain Life keeps you alive.", spells = {
				{ name = "Corruption", icon = "Interface\\Icons\\Spell_Shadow_AbominationExplosion", line = "Decay that grows on the nearest enemies", tip = "Corrupts the 2 nearest enemies with 1 stack of Decay, or 2 on an enemy without Decay." },
				{ name = "Curse of Agony", icon = "Interface\\Icons\\Spell_Shadow_CurseOfSargeras", line = "Agony on the healthiest enemies", tip = "Curses the 2 enemies with the most health with 1 stack of Agony, or 2 on an uncursed enemy." },
				{ name = "Drain Life", icon = "Interface\\Icons\\Spell_Shadow_LifeDrain02", line = "Drains life while you move", tip = "Drains the nearest enemy within 16 yards, dealing damage every sec and healing you for 0.2% of your maximum health per enemy drained." },
			} },
			{ name = "Demonology", icon = "Interface\\Icons\\Spell_Shadow_Metamorphosis", text = "A crew of demons out at once: Imp, Voidwalker, Succubus and Felhunter.", spells = {
				{ name = "Imp", icon = "Interface\\Icons\\Spell_Shadow_SummonImp", line = "An Imp that hurls fire", tip = "Summons an Imp that hurls 2 Firebolts at a time at enemies within 30 yards, leaving them burning." },
				{ name = "Voidwalker", icon = "Interface\\Icons\\Spell_Shadow_SummonVoidWalker", line = "A Voidwalker that bursts in a void nova", tip = "Summons a Voidwalker that consumes enemies dying near it. After 8 it bursts in a void nova that hits every enemy around it." },
				{ name = "Succubus", icon = "Interface\\Icons\\Spell_Shadow_SummonSuccubus", line = "A Succubus that lashes a wide arc", tip = "Summons a Succubus whose Lash of Pain strikes all enemies in a wide arc in front of her and applies Shadow Vulnerability." },
				{ name = "Felhunter", icon = "Interface\\Icons\\Spell_Shadow_SummonFelHunter", line = "A Felhunter that bites afflicted enemies", tip = "Summons a Felhunter whose Shadow Bite deals 10% more damage per affliction on the target and interrupts spells, and whose Shadow Cleave hits every enemy in front of it. Every 10 sec it removes a harmful effect from you." },
			} },
			{ name = "Destruction", icon = "Interface\\Icons\\Spell_Shadow_RainOfFire", text = "Fel fire: Shadow Bolt, Immolate, Hellfire and Rain of Fire on the pack.", spells = {
				{ name = "Shadow Bolt", icon = "Interface\\Icons\\Spell_Shadow_ShadowBolt", line = "Kills fire more Shadow Bolts", tip = "Fires a Shadow Bolt at the nearest enemy, dealing damage. Nightfall: enemies that die with your afflictions on them fire a free bolt, at most 1 a sec." },
				{ name = "Immolate", icon = "Interface\\Icons\\Spell_Fire_Immolation", line = "Fire that leaves enemies Burning", tip = "Strikes the 2 nearest enemies with fire, dealing damage and applying 2 stacks of Burning." },
				{ name = "Hellfire", icon = "Interface\\Icons\\Spell_Fire_Incinerate", line = "Fire burns everything around you", tip = "Fire burns every enemy within 8 yards of you, dealing damage." },
				{ name = "Rain of Fire", icon = "Interface\\Icons\\Spell_Shadow_RainOfFire", line = "Fire rains on the largest group", tip = "Rains fire on the largest group of enemies for 4 sec, dealing damage and applying 1 stack of Burning every sec." },
			} },
		},
	},
	DRUID = {
		blurb = "A shapeshifter that changes between Moonkin, Cat, Bear and Tree of Life. Every spell works in every form, and the right form makes it 30% stronger.",
		starter = { name = "Shapeshift", icon = "Interface\\Icons\\Ability_Druid_CatForm", line = "Press 'R' to change form", tip = "Press R to shift into your next form. Druid spells deal and heal 30% more in their form.|n|n|cffffffffMoonkin Form (30 yd range):|r Wrath strikes the nearest enemy for Nature damage, splashing nearby enemies. Every 3 sec, Starfall strikes 3 enemies afflicted by Moonfire.|n|n|cffffffffCat Form (10 yd range):|r Claws the nearest enemy for Physical damage and causes Bleed. Movement speed increased by 15%. Critical strikes cause Bleed.|n|n|cffffffffBear Form (10 yd range):|r Mauls the nearest enemy for Physical damage. Damage taken reduced by 35%, but spells of other forms deal 20% less. Swipe deals 8% more per nearby enemy. Every 6 sec, roars to Daze nearby enemies and reduce their damage by 25%.|n|n|cffffffffTree of Life (20 yd range):|r Vines lash 3 enemies for Nature damage, each hit healing you for 0.3% of your maximum health. Calls 1 additional Treant. Rejuvenation blooms 50% faster." },
		shared = {
		},
		specs = {
			{ name = "Balance", icon = "Interface\\Icons\\Spell_Nature_StarFall", text = "Moonkin form. Starlight on the strongest enemy, Moonfire on the pack and storms on the crowd.", spells = {
				{ name = "Starfire", icon = "Interface\\Icons\\Spell_Arcane_StarFire", line = "Starlight on the strongest enemy", tip = "Calls down starlight on the strongest enemy for heavy Arcane damage. Empowered in Moonkin Form." },
				{ name = "Moonfire", icon = "Interface\\Icons\\Spell_Nature_StarFall", line = "Moonfire on the nearest enemies", tip = "Burns the 2 nearest enemies for Arcane damage and applies 1 stack of Moonfire. Empowered in Moonkin Form." },
				{ name = "Hurricane", icon = "Interface\\Icons\\Spell_Nature_Cyclone", line = "A storm on the largest group", tip = "A storm rages over the largest group of enemies for 4 sec, dealing Nature damage every sec and Dazing them. Empowered in Moonkin Form." },
			} },
			{ name = "Feral", icon = "Interface\\Icons\\Ability_Racial_BearForm", text = "Cat and Bear form. Bleed the pack, Shred the deepest bleeder, and shift to Bear when you are hurt.", spells = {
				{ name = "Rake", icon = "Interface\\Icons\\Ability_Druid_Disembowel", line = "Makes the 3 nearest enemies Bleed", tip = "Rakes the 3 nearest enemies for damage and 2 stacks of Bleed. Empowered in Cat Form." },
				{ name = "Shred", icon = "Interface\\Icons\\Spell_Shadow_VampiricAura", line = "Strikes the enemy with the most Bleed stacks", tip = "Shreds the most Bleeding enemy for damage, increased by 3% per stack of Bleed on it. Empowered in Cat Form." },
				{ name = "Swipe", icon = "Interface\\Icons\\INV_Misc_MonsterClaw_03", line = "Hits every enemy within 10 yards", tip = "Swipes all nearby enemies for damage. Empowered in Bear Form." },
				{ name = "Frenzied Regeneration", icon = "Interface\\Icons\\Ability_BullRush", line = "Heals you for each enemy close by", tip = "Every sec, heals you for 0.25% of your maximum health per nearby enemy, up to 5. Empowered in Bear Form." },
			} },
			{ name = "Restoration", icon = "Interface\\Icons\\Spell_Nature_HealingTouch", text = "Tree of Life. Heals that hurt, while Treants and roots hold the crowd.", spells = {
				{ name = "Rejuvenation", icon = "Interface\\Icons\\Spell_Nature_Rejuvenation", line = "Heals you and lashes nearby enemies", tip = "Heals you for 0.3% of your maximum health. Its thorny bloom lashes the 3 nearest enemies for Nature damage. Empowered in Tree of Life." },
				{ name = "Force of Nature", icon = "Interface\\Icons\\Spell_Nature_NatureTouchGrow", line = "2 Treants fight at your side", tip = "Summons 2 Treants. Their attacks apply Moonfire, and every 6 sec they root their target and nearby enemies for 2 sec. Empowered in Tree of Life, which calls 1 additional Treant." },
				{ name = "Entangling Roots", icon = "Interface\\Icons\\Spell_Nature_StrangleVines", line = "Roots the 3 nearest enemies", tip = "Roots grasp the 3 nearest enemies for Nature damage and root them for 2 sec. Empowered in Tree of Life." },
				{ name = "Tranquility", icon = "Interface\\Icons\\Spell_Nature_Tranquility", line = "Pulses that hurt enemies and heal you", tip = "Calms the air for 4 sec. Every sec, deals Nature damage to nearby enemies and heals you for 0.5% of your maximum health. Empowered in Tree of Life." },
				{ name = "Thorns", icon = "Interface\\Icons\\Spell_Nature_Thorns", line = "Enemies that strike you take damage", tip = "Enemies that strike you take Nature damage. Empowered in Bear Form." },
			} },
		},
	},
};
