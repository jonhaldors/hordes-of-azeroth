local L = BonkGlueL;

BONK_CLASS_INFO = {
	WARRIOR = {
		blurb = L["hoa.ui.glue.fights_in_the_thick_of_the_horde_every_swing_hits_all_around"],
		starter = { name = L["hoa.ui.glue.bloodthirst"], icon = "Interface\\Icons\\Spell_Nature_BloodLust", line = L["hoa.ui.glue.strikes_3_enemies_and_heals_you"], tip = L["hoa.ui.glue.strikes_the_3_nearest_enemies_within_10_yards_and_heals_you_"] },
		shared = {
			{ name = L["hoa.ui.glue.cleave"], icon = "Interface\\Icons\\Ability_Warrior_Cleave", line = L["hoa.ui.glue.strikes_every_enemy_within_10_yards"], tip = L["hoa.ui.glue.strikes_all_enemies_within_10_yards_of_you"] },
		},
		specs = {
			{ name = L["hoa.ui.glue.arms"], icon = "Interface\\Icons\\Ability_Warrior_SavageBlow", text = L["hoa.ui.glue.stack_bleed_on_the_pack_then_cash_it_in_with_mortal_strike"], spells = {
				{ name = L["hoa.ui.glue.rend"], icon = "Interface\\Icons\\Ability_Gouge", line = L["hoa.ui.glue.makes_the_3_nearest_enemies_bleed"], tip = L["hoa.ui.glue.wounds_the_3_nearest_enemies_within_10_yards_applying_3_stac"] },
				{ name = L["hoa.ui.glue.deep_wounds"], icon = "Interface\\Icons\\Ability_BackStab", line = L["hoa.ui.glue.your_critical_strikes_make_enemies_bleed"], tip = L["hoa.ui.glue.your_critical_strikes_apply_2_stacks_of_bleed_at_most_once_e"] },
				{ name = L["hoa.ui.glue.mortal_strike"], icon = "Interface\\Icons\\Ability_Warrior_SavageBlow", line = L["hoa.ui.glue.hits_harder_for_each_stack_of_bleed"], tip = L["hoa.ui.glue.strikes_all_enemies_within_10_yards_of_you_dealing_8_more_da"] },
			} },
			{ name = L["hoa.ui.glue.fury"], icon = "Interface\\Icons\\Ability_Warrior_InnerRage", text = L["hoa.ui.glue.critical_strikes_and_kills_enrage_you_and_enrage_makes_you_s"], spells = {
				{ name = L["hoa.ui.glue.bloodthirst"], icon = "Interface\\Icons\\Spell_Nature_BloodLust", line = L["hoa.ui.glue.strikes_3_enemies_and_heals_you"], tip = L["hoa.ui.glue.strikes_the_3_nearest_enemies_within_10_yards_and_heals_you_"] },
				{ name = L["hoa.ui.glue.execute"], icon = "Interface\\Icons\\INV_Sword_48", line = L["hoa.ui.glue.slays_normal_enemies_below_20_health"], tip = L["hoa.ui.glue.strikes_all_enemies_within_10_yards_of_you_normal_enemies_be"] },
				{ name = L["hoa.ui.glue.whirlwind"], icon = "Interface\\Icons\\Ability_Whirlwind", line = L["hoa.ui.glue.spins_through_the_pack_twice_when_enraged"], tip = L["hoa.ui.glue.spins_striking_all_enemies_within_8_yards_of_you_for_damage_"] },
			} },
			{ name = L["hoa.ui.glue.protection"], icon = "Interface\\Icons\\INV_Shield_06", text = L["hoa.ui.glue.take_hits_soak_them_with_your_shield_and_strike_back"], spells = {
				{ name = L["hoa.ui.glue.shield_block"], icon = "Interface\\Icons\\Ability_Defend", line = L["hoa.ui.glue.a_stacking_damage_shield"], tip = L["hoa.ui.glue.adds_a_shield_absorbing_10_of_your_maximum_health_stacking_u"] },
				{ name = L["hoa.ui.glue.thunder_clap"], icon = "Interface\\Icons\\Ability_ThunderClap", line = L["hoa.ui.glue.blasts_nearby_enemies_and_slows_their_attacks"], tip = L["hoa.ui.glue.blasts_all_enemies_within_8_yards_of_you_for_damage_enemies_"] },
				{ name = L["hoa.ui.glue.revenge"], icon = "Interface\\Icons\\Ability_Warrior_Revenge", line = L["hoa.ui.glue.strikes_back_when_you_are_hit"], tip = L["hoa.ui.glue.when_you_are_struck_strikes_all_enemies_within_10_yards_of_y"] },
				{ name = L["hoa.ui.glue.shield_slam"], icon = "Interface\\Icons\\INV_Shield_05", line = L["hoa.ui.glue.hits_harder_the_bigger_your_shield"], tip = L["hoa.ui.glue.slams_all_enemies_within_10_yards_of_you_dealing_2_more_dama"] },
			} },
		},
	},
	PALADIN = {
		blurb = L["hoa.ui.glue.seals_empower_every_strike_and_judgement_releases_them_holy_"],
		starter = { name = L["hoa.ui.glue.crusader_strike"], icon = "Interface\\Icons\\Spell_Holy_HolySmite", line = L["hoa.ui.glue.heavy_strike_with_splash_damage"], tip = L["hoa.ui.glue.strikes_the_nearest_enemy_for_heavy_damage_and_30_of_it_to_e"] },
		shared = {
		},
		specs = {
			{ name = L["hoa.ui.glue.holy"], icon = "Interface\\Icons\\Spell_Holy_HolyBolt", text = L["hoa.ui.glue.holy_strikes_from_afar_exorcism_falling_hammers_and_light_th"], spells = {
				{ name = L["hoa.ui.glue.exorcism"], icon = "Interface\\Icons\\Spell_Holy_Excorcism_02", line = L["hoa.ui.glue.heavy_holy_strike_on_the_strongest_enemy"], tip = L["hoa.ui.glue.strikes_the_strongest_enemy_within_30_yards_for_heavy_holy_d"] },
				{ name = L["hoa.ui.glue.seal_of_light"], icon = "Interface\\Icons\\Spell_Holy_HealingAura", line = L["hoa.ui.glue.your_strikes_heal_you"], tip = L["hoa.ui.glue.every_strike_from_your_other_paladin_spells_heals_you_for_0_"] },
				{ name = L["hoa.ui.glue.light_s_hammer"], icon = "Interface\\Icons\\Spell_Holy_FistOfJustice", line = L["hoa.ui.glue.hammers_of_light_fall_on_the_pack"], tip = L["hoa.ui.glue.hammers_of_light_fall_on_3_random_enemies_within_25_yards_ea"] },
			} },
			{ name = L["hoa.ui.glue.protection"], icon = "Interface\\Icons\\Spell_Holy_DevotionAura", text = L["hoa.ui.glue.holy_ground_and_auras_burn_whoever_comes_close_while_divine_"], spells = {
				{ name = L["hoa.ui.glue.consecration"], icon = "Interface\\Icons\\Spell_Holy_InnerFire", line = L["hoa.ui.glue.holy_ground_that_burns_enemies_on_it"], tip = L["hoa.ui.glue.consecrates_the_ground_beneath_you_for_8_sec_dealing_holy_da"] },
				{ name = L["hoa.ui.glue.divine_shield"], icon = "Interface\\Icons\\Spell_Holy_DivineIntervention", line = L["hoa.ui.glue.a_bubble_that_blocks_the_next_big_hit"], tip = L["hoa.ui.glue.a_golden_bubble_forms_around_you_and_blocks_the_next_enemy_h"] },
				{ name = L["hoa.ui.glue.retribution_aura"], icon = "Interface\\Icons\\Spell_Holy_AuraOfLight", line = L["hoa.ui.glue.burns_every_enemy_close_to_you"], tip = L["hoa.ui.glue.burns_every_enemy_within_10_yards_of_you_with_holy_light_dea"] },
				{ name = L["hoa.ui.glue.hammer_of_justice"], icon = "Interface\\Icons\\Spell_Holy_SealOfMight", line = L["hoa.ui.glue.stuns_the_strongest_enemy"], tip = L["hoa.ui.glue.hurls_a_hammer_at_the_strongest_enemy_within_20_yards_dealin"] },
			} },
			{ name = L["hoa.ui.glue.retribution"], icon = "Interface\\Icons\\Spell_Holy_AuraOfLight", text = L["hoa.ui.glue.seals_on_every_swing_released_by_judgement_and_avenger_s_shi"], spells = {
				{ name = L["hoa.ui.glue.crusader_strike"], icon = "Interface\\Icons\\Spell_Holy_HolySmite", line = L["hoa.ui.glue.heavy_strike_with_splash_damage"], tip = L["hoa.ui.glue.strikes_the_nearest_enemy_for_heavy_damage_and_30_of_it_to_e"] },
				{ name = L["hoa.ui.glue.judgement"], icon = "Interface\\Icons\\Spell_Holy_RighteousFury", line = L["hoa.ui.glue.hammers_3_enemies_and_releases_your_seals"], tip = L["hoa.ui.glue.slams_the_3_strongest_enemies_within_20_yards_for_holy_damag"] },
				{ name = L["hoa.ui.glue.seal_of_command"], icon = "Interface\\Icons\\Ability_Warrior_InnerRage", line = L["hoa.ui.glue.every_2nd_strike_bursts_with_light"], tip = L["hoa.ui.glue.every_2nd_strike_from_your_other_paladin_spells_releases_a_b"] },
				{ name = L["hoa.ui.glue.seal_of_righteousness"], icon = "Interface\\Icons\\Ability_ThunderBolt", line = L["hoa.ui.glue.your_hits_deal_extra_holy_damage"], tip = L["hoa.ui.glue.hits_from_your_other_paladin_spells_splash_included_deal_30_"] },
				{ name = L["hoa.ui.glue.divine_storm"], icon = "Interface\\Icons\\Spell_Holy_SealOfWrath", line = L["hoa.ui.glue.holy_burst_around_you_that_heals"], tip = L["hoa.ui.glue.holy_light_bursts_around_you_dealing_holy_damage_to_all_enem"] },
				{ name = L["hoa.ui.glue.avenger_s_shield"], icon = "Interface\\Icons\\Spell_Holy_SealOfProtection", line = L["hoa.ui.glue.a_shield_that_jumps_between_5_enemies"], tip = L["hoa.ui.glue.hurls_a_holy_shield_at_the_nearest_enemy_within_25_yards_for"] },
			} },
		},
	},
	HUNTER = {
		blurb = L["hoa.ui.glue.shoots_from_range_while_pets_fight_at_your_side_marks_stings"],
		starter = { name = L["hoa.ui.glue.arcane_shot"], icon = "Interface\\Icons\\Ability_ImpalingBolt", line = L["hoa.ui.glue.shoots_the_nearest_enemy"], tip = L["hoa.ui.glue.shoots_the_nearest_enemy_for_arcane_damage"] },
		shared = {
		},
		specs = {
			{ name = L["hoa.ui.glue.beast_mastery"], icon = "Interface\\Icons\\Ability_Hunter_BeastTaming", text = L["hoa.ui.glue.pets_do_the_fighting_your_cat_bleeds_the_pack_and_the_spirit"], spells = {
				{ name = L["hoa.ui.glue.call_pet"], icon = "Interface\\Icons\\Ability_Hunter_BeastCall", line = L["hoa.ui.glue.your_cat_fights_for_you"], tip = L["hoa.ui.glue.summons_a_cat_that_fights_for_you_its_attacks_apply_1_stack_"] },
				{ name = L["hoa.ui.glue.pack_leader"], icon = "Interface\\Icons\\Spell_Nature_SpiritWolf", line = L["hoa.ui.glue.a_spirit_wolf_that_empowers_your_pets"], tip = L["hoa.ui.glue.a_spirit_wolf_fights_for_you_every_15_sec_it_howls_and_for_6"] },
			} },
			{ name = L["hoa.ui.glue.marksmanship"], icon = "Interface\\Icons\\Ability_Marksmanship", text = L["hoa.ui.glue.shots_volleys_and_piercing_arrows_with_hunter_s_mark_on_the_"], spells = {
				{ name = L["hoa.ui.glue.arcane_shot"], icon = "Interface\\Icons\\Ability_ImpalingBolt", line = L["hoa.ui.glue.shoots_the_nearest_enemy"], tip = L["hoa.ui.glue.shoots_the_nearest_enemy_for_arcane_damage"] },
				{ name = L["hoa.ui.glue.multi_shot"], icon = "Interface\\Icons\\Ability_UpgradeMoonGlaive", line = L["hoa.ui.glue.strikes_up_to_6_enemies_in_a_cone"], tip = L["hoa.ui.glue.strikes_up_to_6_enemies_within_18_yards_in_a_cone_toward_the"] },
				{ name = L["hoa.ui.glue.volley"], icon = "Interface\\Icons\\Ability_Marksmanship", line = L["hoa.ui.glue.rains_arrows_on_the_largest_group"], tip = L["hoa.ui.glue.rains_arrows_on_the_largest_group_of_enemies_within_20_yards"] },
				{ name = L["hoa.ui.glue.aimed_shot"], icon = "Interface\\Icons\\INV_Spear_07", line = L["hoa.ui.glue.a_shot_that_pierces_a_whole_line"], tip = L["hoa.ui.glue.fires_a_shot_that_pierces_every_enemy_in_a_line_dealing_dama_2"] },
				{ name = L["hoa.ui.glue.hunter_s_mark"], icon = "Interface\\Icons\\Ability_Hunter_SniperShot", line = L["hoa.ui.glue.marked_enemies_take_more_damage"], tip = L["hoa.ui.glue.marks_every_enemy_within_10_yards_of_the_largest_group_for_8"] },
			} },
			{ name = L["hoa.ui.glue.survival"], icon = "Interface\\Icons\\Ability_Hunter_SwiftStrike", text = L["hoa.ui.glue.poison_stings_and_traps_that_burn_or_slow_whatever_walks_in"], spells = {
				{ name = L["hoa.ui.glue.serpent_sting"], icon = "Interface\\Icons\\Ability_Hunter_Quickshot", line = L["hoa.ui.glue.poisons_the_nearest_enemies"], tip = L["hoa.ui.glue.stings_the_nearest_enemy_and_2_enemies_near_it_with_3_stacks"] },
				{ name = L["hoa.ui.glue.explosive_trap"], icon = "Interface\\Icons\\Spell_Fire_SelfDestruct", line = L["hoa.ui.glue.a_trap_that_explodes_and_burns_the_ground"], tip = L["hoa.ui.glue.places_a_fire_trap_that_explodes_when_an_enemy_comes_close_d_2"] },
				{ name = L["hoa.ui.glue.viper_trap"], icon = "Interface\\Icons\\INV_Misc_MonsterFang_01", line = L["hoa.ui.glue.vipers_that_poison_the_pack"], tip = L["hoa.ui.glue.places_a_trap_that_releases_4_vipers_when_an_enemy_comes_clo"] },
			} },
		},
	},
	ROGUE = {
		blurb = L["hoa.ui.glue.the_fastest_single_target_attacks_in_the_game_every_stab_car"],
		starter = { name = L["hoa.ui.glue.sinister_strike"], icon = "Interface\\Icons\\Spell_Shadow_RitualOfSacrifice", line = L["hoa.ui.glue.fast_stabs_on_the_nearest_enemy"], tip = L["hoa.ui.glue.stabs_the_nearest_enemy_for_damage"] },
		shared = {
		},
		specs = {
			{ name = L["hoa.ui.glue.assassination"], icon = "Interface\\Icons\\Ability_Rogue_Eviscerate", text = L["hoa.ui.glue.poison_on_every_hit_then_envenom_the_most_poisoned_enemy"], spells = {
				{ name = L["hoa.ui.glue.mutilate"], icon = "Interface\\Icons\\Ability_BackStab", line = L["hoa.ui.glue.two_poisoned_stabs_on_the_nearest_enemy"], tip = L["hoa.ui.glue.stabs_the_nearest_enemy_twice_for_damage_each_stab_applying_"] },
				{ name = L["hoa.ui.glue.deadly_poison"], icon = "Interface\\Icons\\Ability_Rogue_DualWeild", line = L["hoa.ui.glue.your_hits_apply_poison"], tip = L["hoa.ui.glue.your_other_abilities_apply_1_stack_of_poison_with_every_hit_"] },
				{ name = L["hoa.ui.glue.fan_of_knives"], icon = "Interface\\Icons\\INV_ThrowingKnife_04", line = L["hoa.ui.glue.knives_in_every_direction"], tip = L["hoa.ui.glue.throws_knives_in_every_direction_striking_all_enemies_within"] },
				{ name = L["hoa.ui.glue.envenom"], icon = "Interface\\Icons\\Ability_Creature_Poison_06", line = L["hoa.ui.glue.strikes_the_3_most_poisoned_enemies"], tip = L["hoa.ui.glue.strikes_the_3_enemies_with_the_most_poison_within_20_yards_f"] },
			} },
			{ name = L["hoa.ui.glue.combat"], icon = "Interface\\Icons\\Ability_BackStab", text = L["hoa.ui.glue.fast_blades_blade_flurry_eviscerate_and_killing_spree_throug"], spells = {
				{ name = L["hoa.ui.glue.sinister_strike"], icon = "Interface\\Icons\\Spell_Shadow_RitualOfSacrifice", line = L["hoa.ui.glue.fast_stabs_on_the_nearest_enemy"], tip = L["hoa.ui.glue.stabs_the_nearest_enemy_for_damage"] },
				{ name = L["hoa.ui.glue.blade_flurry"], icon = "Interface\\Icons\\Ability_Warrior_PunishingBlow", line = L["hoa.ui.glue.your_hits_strike_4_more_enemies"], tip = L["hoa.ui.glue.your_single_target_hits_also_strike_4_more_enemies_within_8_"] },
				{ name = L["hoa.ui.glue.eviscerate"], icon = "Interface\\Icons\\Ability_Rogue_Eviscerate", line = L["hoa.ui.glue.heavy_strike_with_double_crit_chance"], tip = L["hoa.ui.glue.guts_the_nearest_enemy_for_heavy_damage_with_double_critical_2"] },
				{ name = L["hoa.ui.glue.killing_spree"], icon = "Interface\\Icons\\Ability_Rogue_SliceDice", line = L["hoa.ui.glue.8_strikes_on_random_enemies"], tip = L["hoa.ui.glue.strikes_8_times_over_1_4_sec_each_strike_hitting_a_random_en"] },
			} },
			{ name = L["hoa.ui.glue.subtlety"], icon = "Interface\\Icons\\Ability_Stealth", text = L["hoa.ui.glue.ambush_every_new_enemy_you_hit_and_shadow_dance_to_do_it_aga"], spells = {
				{ name = L["hoa.ui.glue.shuriken_toss"], icon = "Interface\\Icons\\INV_ThrowingAxe_06", line = L["hoa.ui.glue.shurikens_at_fresh_enemies"], tip = L["hoa.ui.glue.throws_shurikens_at_the_3_nearest_enemies_within_20_yards_pr"] },
				{ name = L["hoa.ui.glue.ambush"], icon = "Interface\\Icons\\Ability_Rogue_Ambush", line = L["hoa.ui.glue.your_first_hit_on_each_enemy_ambushes_it"], tip = L["hoa.ui.glue.your_first_hit_on_each_enemy_with_your_other_abilities_is_fo"] },
				{ name = L["hoa.ui.glue.shadow_dance"], icon = "Interface\\Icons\\Spell_Shadow_Charm", line = L["hoa.ui.glue.more_damage_and_ambush_again"], tip = L["hoa.ui.glue.your_hits_deal_30_more_damage_for_4_sec_and_can_set_off_ambu"] },
				{ name = L["hoa.ui.glue.evasion"], icon = "Interface\\Icons\\Spell_Shadow_ShadowWard", line = L["hoa.ui.glue.50_dodge_chance"], tip = L["hoa.ui.glue.increases_your_dodge_chance_by_50_for_5_sec_up_to_85"] },
			} },
		},
	},
	PRIEST = {
		blurb = L["hoa.ui.glue.healing_that_overflows_into_damage_a_ring_of_light_that_hits"],
		starter = { name = L["hoa.ui.glue.smite"], icon = "Interface\\Icons\\Spell_Holy_HolySmite", line = L["hoa.ui.glue.smites_the_2_nearest_enemies"], tip = L["hoa.ui.glue.smites_the_2_nearest_enemies_for_holy_damage_each_smite_redu"] },
		shared = {
		},
		specs = {
			{ name = L["hoa.ui.glue.discipline"], icon = "Interface\\Icons\\Spell_Holy_WordFortitude", text = L["hoa.ui.glue.shields_fear_and_binding_while_penance_punishes_whoever_stri"], spells = {
				{ name = L["hoa.ui.glue.power_word_shield"], icon = "Interface\\Icons\\Spell_Holy_PowerWordShield", line = L["hoa.ui.glue.a_shield_that_makes_you_faster"], tip = L["hoa.ui.glue.shields_you_for_10_of_your_maximum_health_each_cast_tops_it_"] },
				{ name = L["hoa.ui.glue.penance"], icon = "Interface\\Icons\\Spell_Holy_HolyBolt", line = L["hoa.ui.glue.holy_bolts_at_whoever_struck_you"], tip = L["hoa.ui.glue.fires_3_holy_bolts_at_the_enemies_that_struck_you_in_the_las"] },
				{ name = L["hoa.ui.glue.psychic_scream"], icon = "Interface\\Icons\\Spell_Shadow_PsychicScream", line = L["hoa.ui.glue.nearby_enemies_flee_in_fear"], tip = L["hoa.ui.glue.normal_enemies_within_8_yards_flee_in_fear_for_2_sec_taking_"] },
				{ name = L["hoa.ui.glue.shackle"], icon = "Interface\\Icons\\Spell_Nature_Slow", line = L["hoa.ui.glue.binds_the_strongest_enemy"], tip = L["hoa.ui.glue.strikes_the_strongest_enemy_within_30_yards_for_holy_damage_"] },
			} },
			{ name = L["hoa.ui.glue.holy"], icon = "Interface\\Icons\\Spell_Holy_PrayerOfHealing02", text = L["hoa.ui.glue.heals_that_overflow_into_damage_and_holy_word_strikes_the_st"], spells = {
				{ name = L["hoa.ui.glue.smite"], icon = "Interface\\Icons\\Spell_Holy_HolySmite", line = L["hoa.ui.glue.smites_the_2_nearest_enemies"], tip = L["hoa.ui.glue.smites_the_2_nearest_enemies_for_holy_damage_each_smite_redu"] },
				{ name = L["hoa.ui.glue.renew"], icon = "Interface\\Icons\\Spell_Holy_Renew", line = L["hoa.ui.glue.heals_you_then_smites_at_full_health"], tip = L["hoa.ui.glue.heals_you_for_1_of_your_maximum_health_every_sec_at_full_hea_2"] },
				{ name = L["hoa.ui.glue.halo"], icon = "Interface\\Icons\\Spell_Holy_PrayerOfHealing02", line = L["hoa.ui.glue.a_ring_of_light_that_heals_you"], tip = L["hoa.ui.glue.a_ring_of_light_hits_every_enemy_within_12_yards_of_you_for_"] },
				{ name = L["hoa.ui.glue.holy_word_chastise"], icon = "Interface\\Icons\\Spell_Holy_Excorcism_02", line = L["hoa.ui.glue.heavy_holy_strike_on_the_strongest_enemy"], tip = L["hoa.ui.glue.the_light_strikes_the_strongest_enemy_within_30_yards_for_he"] },
			} },
			{ name = L["hoa.ui.glue.shadow"], icon = "Interface\\Icons\\Spell_Shadow_ShadowWordPain", text = L["hoa.ui.glue.plant_decay_on_the_far_edge_of_the_horde_and_spread_it_from_"], spells = {
				{ name = L["hoa.ui.glue.shadow_word_pain"], icon = "Interface\\Icons\\Spell_Shadow_ShadowWordPain", line = L["hoa.ui.glue.plants_decay_on_far_enemies"], tip = L["hoa.ui.glue.afflicts_the_3_enemies_farthest_from_you_within_35_yards_wit"] },
				{ name = L["hoa.ui.glue.mind_flay"], icon = "Interface\\Icons\\Spell_Shadow_SiphonMana", line = L["hoa.ui.glue.flays_the_nearest_enemy_until_it_dies"], tip = L["hoa.ui.glue.flays_the_nearest_enemy_within_20_yards_dealing_shadow_damag_2"] },
				{ name = L["hoa.ui.glue.mind_blast"], icon = "Interface\\Icons\\Spell_Shadow_UnholyFrenzy", line = L["hoa.ui.glue.spreads_decay_from_the_most_decayed_enemy"], tip = L["hoa.ui.glue.blasts_the_enemy_with_the_most_decay_for_shadow_damage_every"] },
				{ name = L["hoa.ui.glue.shadowfiend"], icon = "Interface\\Icons\\Spell_Shadow_GatherShadows", line = L["hoa.ui.glue.a_shadowfiend_that_heals_you"], tip = L["hoa.ui.glue.summons_a_shadowfiend_whose_attacks_apply_decay_and_whose_sh"] },
			} },
		},
	},
	SHAMAN = {
		blurb = L["hoa.ui.glue.lightning_that_builds_static_windfury_bursts_in_melee_and_to"],
		starter = { name = L["hoa.ui.glue.lightning_bolt"], icon = "Interface\\Icons\\Spell_Nature_Lightning", line = L["hoa.ui.glue.lightning_that_bounces_once"], tip = L["hoa.ui.glue.hurls_lightning_at_the_nearest_enemy_bouncing_to_1_more_deal_2"] },
		shared = {
			{ name = L["hoa.ui.glue.lightning_shield"], icon = "Interface\\Icons\\Spell_Nature_LightningShield", line = L["hoa.ui.glue.zaps_nearby_enemies_and_shields_you"], tip = L["hoa.ui.glue.holds_up_to_3_lightning_charges_gaining_1_every_1_5_sec_ever"] },
		},
		specs = {
			{ name = L["hoa.ui.glue.elemental"], icon = "Interface\\Icons\\Spell_Nature_Lightning", text = L["hoa.ui.glue.lightning_builds_static_on_the_pack_and_shocks_cash_it_in"], spells = {
				{ name = L["hoa.ui.glue.lightning_bolt"], icon = "Interface\\Icons\\Spell_Nature_Lightning", line = L["hoa.ui.glue.lightning_that_bounces_once"], tip = L["hoa.ui.glue.hurls_lightning_at_the_nearest_enemy_bouncing_to_1_more_deal_2"] },
				{ name = L["hoa.ui.glue.chain_lightning"], icon = "Interface\\Icons\\Spell_Nature_ChainLightning", line = L["hoa.ui.glue.lightning_that_jumps_to_4_more"], tip = L["hoa.ui.glue.hurls_lightning_at_the_nearest_enemy_jumping_to_4_more_deali_2"] },
				{ name = L["hoa.ui.glue.flame_shock"], icon = "Interface\\Icons\\Spell_Fire_FlameShock", line = L["hoa.ui.glue.burns_the_strongest_enemy"], tip = L["hoa.ui.glue.shocks_the_strongest_enemy_nearby_elites_first_dealing_fire_"] },
				{ name = L["hoa.ui.glue.earth_shock"], icon = "Interface\\Icons\\Spell_Nature_EarthShock", line = L["hoa.ui.glue.discharges_static_on_the_pack"], tip = L["hoa.ui.glue.shocks_the_enemy_with_the_most_static_for_nature_damage_50_m"] },
			} },
			{ name = L["hoa.ui.glue.enhancement"], icon = "Interface\\Icons\\Spell_Nature_LightningShield", text = L["hoa.ui.glue.windfury_swings_in_melee_and_every_3rd_shaman_hit_hurls_free"], spells = {
				{ name = L["hoa.ui.glue.windfury_weapon"], icon = "Interface\\Icons\\Spell_Nature_Cyclone", line = L["hoa.ui.glue.swings_with_windfury_bursts"], tip = L["hoa.ui.glue.swings_at_the_nearest_enemy_for_damage_every_3rd_swing_calls"] },
				{ name = L["hoa.ui.glue.stormstrike"], icon = "Interface\\Icons\\Spell_Holy_SealOfMight", line = L["hoa.ui.glue.two_strikes_that_build_static"], tip = L["hoa.ui.glue.strikes_the_nearest_enemy_within_12_yards_twice_with_weapon_"] },
				{ name = L["hoa.ui.glue.maelstrom_weapon"], icon = "Interface\\Icons\\Spell_Nature_StormReach", line = L["hoa.ui.glue.every_3rd_hit_hurls_free_lightning"], tip = L["hoa.ui.glue.every_3rd_hit_from_your_other_shaman_spells_and_feral_spirit"] },
				{ name = L["hoa.ui.glue.feral_spirit"], icon = "Interface\\Icons\\Spell_Nature_SpiritWolf", line = L["hoa.ui.glue.2_spirit_wolves_fight_for_you"], tip = L["hoa.ui.glue.summons_2_spirit_wolves_whose_bites_apply_1_stack_of_static_"] },
			} },
			{ name = L["hoa.ui.glue.totemic"], icon = "Interface\\Icons\\Spell_Nature_MagicImmunity", text = L["hoa.ui.glue.totems_burn_the_pack_and_heal_you_while_you_hold_the_ground"], spells = {
				{ name = L["hoa.ui.glue.searing_totem"], icon = "Interface\\Icons\\Spell_Fire_SearingTotem", line = L["hoa.ui.glue.a_totem_that_hurls_fire"], tip = L["hoa.ui.glue.plants_a_searing_totem_at_your_feet_that_hurls_fire_at_2_ene"] },
				{ name = L["hoa.ui.glue.magma_totem"], icon = "Interface\\Icons\\Spell_Fire_SelfDestruct", line = L["hoa.ui.glue.a_totem_hurled_onto_the_pack"], tip = L["hoa.ui.glue.hurls_a_magma_totem_onto_the_largest_group_of_enemies_within"] },
				{ name = L["hoa.ui.glue.healing_stream_totem"], icon = "Interface\\Icons\\INV_Spear_04", line = L["hoa.ui.glue.a_totem_that_heals_you"], tip = L["hoa.ui.glue.plants_a_healing_stream_totem_at_your_feet_that_heals_you_fo"] },
			} },
		},
	},
	MAGE = {
		blurb = L["hoa.ui.glue.frost_controls_and_shatters_fire_burns_and_nukes_and_arcane_"],
		starter = { name = L["hoa.ui.glue.frostbolt"], icon = "Interface\\Icons\\Spell_Frost_FrostBolt02", line = L["hoa.ui.glue.shatters_frozen_enemies"], tip = L["hoa.ui.glue.launches_a_bolt_of_frost_at_the_nearest_enemy_dealing_frost_"] },
		shared = {
			{ name = L["hoa.ui.glue.summon_elemental"], icon = "Interface\\Icons\\Spell_Frost_SummonWaterElemental", line = L["hoa.ui.glue.an_elemental_fights_for_you"], tip = L["hoa.ui.glue.summons_an_elemental_of_your_main_spell_school_to_fight_for_"] },
		},
		specs = {
			{ name = L["hoa.ui.glue.arcane"], icon = "Interface\\Icons\\Spell_Holy_MagicalSentry", text = L["hoa.ui.glue.blink_through_the_horde_every_blink_sets_off_arcane_explosio"], spells = {
				{ name = L["hoa.ui.glue.blink"], icon = "Interface\\Icons\\Spell_Arcane_Blink", line = L["hoa.ui.glue.your_dash_teleports_and_explodes"], tip = L["hoa.ui.glue.your_dash_becomes_blink_teleporting_you_with_1_additional_ch"] },
				{ name = L["hoa.ui.glue.arcane_explosion"], icon = "Interface\\Icons\\Spell_Nature_WispSplode", line = L["hoa.ui.glue.arcane_blast_around_you"], tip = L["hoa.ui.glue.blasts_all_enemies_within_10_yards_of_you_with_arcane_energy"] },
				{ name = L["hoa.ui.glue.arcane_missiles"], icon = "Interface\\Icons\\Spell_Nature_StarFall", line = L["hoa.ui.glue.5_missiles_at_the_nearest_enemy"], tip = L["hoa.ui.glue.launches_5_arcane_missiles_at_the_nearest_enemy_over_1_sec_e"] },
			} },
			{ name = L["hoa.ui.glue.fire"], icon = "Interface\\Icons\\Spell_Fire_FireBolt02", text = L["hoa.ui.glue.burn_everything_then_nuke_the_most_burning_enemies"], spells = {
				{ name = L["hoa.ui.glue.fireball"], icon = "Interface\\Icons\\Spell_Fire_FlameBolt", line = L["hoa.ui.glue.fire_bolt_that_leaves_enemies_burning"], tip = L["hoa.ui.glue.hurls_a_fiery_ball_at_the_nearest_enemy_dealing_fire_damage_"] },
				{ name = L["hoa.ui.glue.flamestrike"], icon = "Interface\\Icons\\Spell_Fire_SelfDestruct", line = L["hoa.ui.glue.a_pillar_of_fire_on_the_largest_group"], tip = L["hoa.ui.glue.calls_down_a_pillar_of_fire_on_the_largest_group_of_enemies__2"] },
				{ name = L["hoa.ui.glue.pyroblast"], icon = "Interface\\Icons\\Spell_Fire_Fireball02", line = L["hoa.ui.glue.huge_fireball_on_elites_and_bosses"], tip = L["hoa.ui.glue.hurls_a_huge_fireball_at_an_elite_or_boss_or_else_the_larges"] },
				{ name = L["hoa.ui.glue.fire_blast"], icon = "Interface\\Icons\\Spell_Fire_Fireball", line = L["hoa.ui.glue.blasts_the_enemies_with_the_most_burning"], tip = L["hoa.ui.glue.blasts_the_3_enemies_with_the_most_burning_dealing_fire_dama"] },
			} },
			{ name = L["hoa.ui.glue.frost"], icon = "Interface\\Icons\\Spell_Frost_FrostBolt02", text = L["hoa.ui.glue.chill_and_freeze_the_pack_then_shatter_frozen_enemies_with_f"], spells = {
				{ name = L["hoa.ui.glue.frostbolt"], icon = "Interface\\Icons\\Spell_Frost_FrostBolt02", line = L["hoa.ui.glue.shatters_frozen_enemies"], tip = L["hoa.ui.glue.launches_a_bolt_of_frost_at_the_nearest_enemy_dealing_frost_"] },
				{ name = L["hoa.ui.glue.blizzard"], icon = "Interface\\Icons\\Spell_Frost_IceStorm", line = L["hoa.ui.glue.ice_shards_on_the_largest_group"], tip = L["hoa.ui.glue.ice_shards_pelt_the_largest_group_of_enemies_for_4_sec_deali"] },
				{ name = L["hoa.ui.glue.frost_nova"], icon = "Interface\\Icons\\Spell_Frost_FrostNova", line = L["hoa.ui.glue.frost_blast_around_you"], tip = L["hoa.ui.glue.blasts_all_enemies_within_10_yards_of_you_with_frost_dealing"] },
			} },
		},
	},
	WARLOCK = {
		blurb = L["hoa.ui.glue.a_crew_of_demons_at_your_side_afflictions_that_grow_with_tim"],
		starter = { name = L["hoa.ui.glue.shadow_bolt"], icon = "Interface\\Icons\\Spell_Shadow_ShadowBolt", line = L["hoa.ui.glue.afflicted_kills_fire_free_shadow_bolts"], tip = L["hoa.ui.glue.fires_a_shadow_bolt_at_the_nearest_enemy_dealing_shadow_dama"] },
		shared = {
		},
		specs = {
			{ name = L["hoa.ui.glue.affliction"], icon = "Interface\\Icons\\Spell_Shadow_DeathCoil", text = L["hoa.ui.glue.corruption_and_curse_of_agony_grow_with_time_while_drain_lif"], spells = {
				{ name = L["hoa.ui.glue.corruption"], icon = "Interface\\Icons\\Spell_Shadow_AbominationExplosion", line = L["hoa.ui.glue.decay_that_grows_on_the_nearest_enemies"], tip = L["hoa.ui.glue.corrupts_2_enemies_within_30_yards_the_nearest_without_decay"] },
				{ name = L["hoa.ui.glue.curse_of_agony"], icon = "Interface\\Icons\\Spell_Shadow_CurseOfSargeras", line = L["hoa.ui.glue.agony_on_the_healthiest_enemies"], tip = L["hoa.ui.glue.curses_2_enemies_within_30_yards_uncursed_enemies_with_the_m"] },
				{ name = L["hoa.ui.glue.drain_life"], icon = "Interface\\Icons\\Spell_Shadow_LifeDrain02", line = L["hoa.ui.glue.drains_life_while_you_move"], tip = L["hoa.ui.glue.drains_the_nearest_enemy_within_16_yards_dealing_shadow_dama"] },
			} },
			{ name = L["hoa.ui.glue.demonology"], icon = "Interface\\Icons\\Spell_Shadow_Metamorphosis", text = L["hoa.ui.glue.a_crew_of_demons_out_at_once_imp_voidwalker_succubus_and_fel"], spells = {
				{ name = L["hoa.ui.glue.imp"], icon = "Interface\\Icons\\Spell_Shadow_SummonImp", line = L["hoa.ui.glue.an_imp_that_hurls_fire"], tip = L["hoa.ui.glue.summons_an_imp_that_hurls_2_firebolts_at_a_time_at_enemies_w"] },
				{ name = L["hoa.ui.glue.voidwalker"], icon = "Interface\\Icons\\Spell_Shadow_SummonVoidWalker", line = L["hoa.ui.glue.a_voidwalker_that_bursts_in_a_void_nova"], tip = L["hoa.ui.glue.summons_a_voidwalker_that_consumes_enemies_dying_near_it_aft_2"] },
				{ name = L["hoa.ui.glue.succubus"], icon = "Interface\\Icons\\Spell_Shadow_SummonSuccubus", line = L["hoa.ui.glue.a_succubus_that_lashes_a_wide_arc"], tip = L["hoa.ui.glue.summons_a_succubus_whose_lash_of_pain_strikes_all_enemies_in"] },
				{ name = L["hoa.ui.glue.felhunter"], icon = "Interface\\Icons\\Spell_Shadow_SummonFelHunter", line = L["hoa.ui.glue.a_felhunter_that_bites_afflicted_enemies"], tip = L["hoa.ui.glue.summons_a_felhunter_whose_shadow_bite_deals_10_more_damage_p"] },
			} },
			{ name = L["hoa.ui.glue.destruction"], icon = "Interface\\Icons\\Spell_Shadow_RainOfFire", text = L["hoa.ui.glue.fel_fire_shadow_bolt_immolate_hellfire_and_rain_of_fire_on_t"], spells = {
				{ name = L["hoa.ui.glue.shadow_bolt"], icon = "Interface\\Icons\\Spell_Shadow_ShadowBolt", line = L["hoa.ui.glue.afflicted_kills_fire_free_shadow_bolts"], tip = L["hoa.ui.glue.fires_a_shadow_bolt_at_the_nearest_enemy_dealing_shadow_dama"] },
				{ name = L["hoa.ui.glue.immolate"], icon = "Interface\\Icons\\Spell_Fire_Immolation", line = L["hoa.ui.glue.fire_that_leaves_enemies_burning"], tip = L["hoa.ui.glue.strikes_the_2_nearest_enemies_with_fire_dealing_damage_and_a"] },
				{ name = L["hoa.ui.glue.hellfire"], icon = "Interface\\Icons\\Spell_Fire_Incinerate", line = L["hoa.ui.glue.fire_burns_everything_around_you"], tip = L["hoa.ui.glue.fire_burns_every_enemy_within_8_yards_of_you_dealing_fire_da"] },
				{ name = L["hoa.ui.glue.rain_of_fire"], icon = "Interface\\Icons\\Spell_Shadow_RainOfFire", line = L["hoa.ui.glue.fire_rains_on_the_largest_group"], tip = L["hoa.ui.glue.rains_fire_on_the_largest_group_of_enemies_for_4_sec_dealing"] },
			} },
		},
	},
	DRUID = {
		blurb = L["hoa.ui.glue.a_shapeshifter_that_shifts_between_moonkin_cat_bear_and_tree"],
		starter = { name = L["hoa.ui.glue.shapeshift"], icon = "Interface\\Icons\\Ability_Druid_CatForm", line = L["hoa.ui.glue.press_r_to_shift_form"], tip = L["hoa.ui.glue.press_r_to_shift_into_your_next_form_druid_spells_deal_and_h_2"] },
		shared = {
		},
		specs = {
			{ name = L["hoa.ui.glue.balance"], icon = "Interface\\Icons\\Spell_Nature_StarFall", text = L["hoa.ui.glue.moonkin_form_starfire_on_the_strongest_enemy_moonfire_on_the"], spells = {
				{ name = L["hoa.ui.glue.starfire"], icon = "Interface\\Icons\\Spell_Arcane_StarFire", line = L["hoa.ui.glue.starlight_on_the_strongest_enemy"], tip = L["hoa.ui.glue.calls_down_starlight_on_the_strongest_enemy_for_heavy_arcane"] },
				{ name = L["hoa.ui.glue.moonfire"], icon = "Interface\\Icons\\Spell_Nature_StarFall", line = L["hoa.ui.glue.moonfire_on_fresh_enemies"], tip = L["hoa.ui.glue.burns_2_enemies_within_30_yards_those_without_moonfire_first"] },
				{ name = L["hoa.ui.glue.hurricane"], icon = "Interface\\Icons\\Spell_Nature_Cyclone", line = L["hoa.ui.glue.a_storm_on_the_largest_group"], tip = L["hoa.ui.glue.a_storm_rages_over_the_largest_group_of_enemies_for_4_sec_de"] },
			} },
			{ name = L["hoa.ui.glue.feral"], icon = "Interface\\Icons\\Ability_Racial_BearForm", text = L["hoa.ui.glue.cat_and_bear_form_bleed_the_pack_shred_the_worst_bleeding_en"], spells = {
				{ name = L["hoa.ui.glue.rake"], icon = "Interface\\Icons\\Ability_Druid_Disembowel", line = L["hoa.ui.glue.makes_the_3_nearest_enemies_bleed"], tip = L["hoa.ui.glue.rakes_the_3_nearest_enemies_for_damage_and_applies_2_stacks_"] },
				{ name = L["hoa.ui.glue.shred"], icon = "Interface\\Icons\\Spell_Shadow_VampiricAura", line = L["hoa.ui.glue.strikes_the_enemy_with_the_most_bleed_stacks"], tip = L["hoa.ui.glue.shreds_the_most_bleeding_enemy_for_damage_increased_by_3_per"] },
				{ name = L["hoa.ui.glue.swipe"], icon = "Interface\\Icons\\INV_Misc_MonsterClaw_03", line = L["hoa.ui.glue.hits_every_enemy_within_10_yards"], tip = L["hoa.ui.glue.swipes_all_nearby_enemies_for_damage_empowered_in_bear_form"] },
				{ name = L["hoa.ui.glue.frenzied_regeneration"], icon = "Interface\\Icons\\Ability_BullRush", line = L["hoa.ui.glue.heals_you_for_each_enemy_close_by"], tip = L["hoa.ui.glue.every_sec_heals_you_for_0_25_of_your_maximum_health_per_near"] },
			} },
			{ name = L["hoa.ui.glue.restoration"], icon = "Interface\\Icons\\Spell_Nature_HealingTouch", text = L["hoa.ui.glue.tree_of_life_heals_that_hurt_while_treants_and_roots_hold_th"], spells = {
				{ name = L["hoa.ui.glue.rejuvenation"], icon = "Interface\\Icons\\Spell_Nature_Rejuvenation", line = L["hoa.ui.glue.heals_you_and_lashes_nearby_enemies"], tip = L["hoa.ui.glue.every_sec_heals_you_for_0_3_of_your_maximum_health_and_lashe"] },
				{ name = L["hoa.ui.glue.force_of_nature"], icon = "Interface\\Icons\\Spell_Nature_NatureTouchGrow", line = L["hoa.ui.glue.2_treants_fight_at_your_side"], tip = L["hoa.ui.glue.summons_2_treants_whose_attacks_apply_1_stack_of_moonfire_ev"] },
				{ name = L["hoa.ui.glue.entangling_roots"], icon = "Interface\\Icons\\Spell_Nature_StrangleVines", line = L["hoa.ui.glue.roots_the_3_nearest_enemies"], tip = L["hoa.ui.glue.entangles_the_3_nearest_enemies_within_25_yards_dealing_natu"] },
				{ name = L["hoa.ui.glue.tranquility"], icon = "Interface\\Icons\\Spell_Nature_Tranquility", line = L["hoa.ui.glue.pulses_that_hurt_enemies_and_heal_you"], tip = L["hoa.ui.glue.calms_the_air_for_4_sec_every_sec_deals_nature_damage_to_nea"] },
				{ name = L["hoa.ui.glue.thorns"], icon = "Interface\\Icons\\Spell_Nature_Thorns", line = L["hoa.ui.glue.enemies_that_strike_you_take_damage"], tip = L["hoa.ui.glue.enemies_that_strike_you_take_nature_damage_and_gain_2_stacks"] },
			} },
		},
	},
};
