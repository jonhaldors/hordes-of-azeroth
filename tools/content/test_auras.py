"""Tests for the aura registry and its source bindings."""

from __future__ import annotations

import re
import unittest
from pathlib import Path

from spells import load_spells, normalize_icon, parse_source, resolve_dynamic

ROOT = Path(__file__).resolve().parents[2]


class AuraRegistryTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.spells = {spell["id"]: spell for spell in load_spells()}

    def test_keeps_the_expected_aura_set(self) -> None:
        self.assertEqual(len(self.spells), 104)
        self.assertEqual(len([spell for spell in self.spells.values() if not spell["native"]]), 53)
        for spell_id in (
            17, 339, 594, 1833, 2070, 5116, 5277, 7922, 8122, 8233, 8921, 9484, 12485, 12654,
            12721, 13496, 14868, 15258, 17364, 17498, 18148, 18798, 19255, 19448, 19502,
            19574, 20368, 20374, 21183, 22518, 22576, 22577, 22578, 22579, 22580, 22581, 22959,
            23414, 26388, 27991, 28126, 28419, 31309, 33461, 33462, 33463, 33464, 33465, 33466,
            33467, 33468,
        ):
            self.assertTrue(self.spells[spell_id]["native"])
        self.assertNotIn(60009, self.spells)
        self.assertTrue(all(spell["source_kind"] for spell in self.spells.values()))

    def test_native_partial_display_keeps_the_dbc_icon(self) -> None:
        enrage = self.spells[33462]
        self.assertEqual(enrage["name"], "Enrage")
        self.assertEqual(enrage["icon"], "")
        self.assertIn("25%", enrage["description"])

    def test_native_look_aura_inherits_the_skill(self) -> None:
        blade_flurry = self.spells[33466]
        self.assertEqual(blade_flurry["name"], "Blade Flurry")
        self.assertEqual(blade_flurry["name_zhCN"], "剑刃乱舞")
        self.assertTrue(blade_flurry["icon"].endswith("Ability_Warrior_PunishingBlow"))
        self.assertIn("4 more enemies", blade_flurry["description"])

        renew = self.spells[33464]
        self.assertEqual(renew["name"], "Renew")
        self.assertTrue(renew["icon"].endswith("Spell_Holy_Renew"))

    def test_mastery_aura_inherits_the_skill_row(self) -> None:
        slice_and_dice = self.spells[60024]
        self.assertEqual(slice_and_dice["name"], "Slice and Dice")
        self.assertEqual(slice_and_dice["name_zhCN"], "切割")
        self.assertTrue(slice_and_dice["icon"].endswith("spell_shadow_curseoftounges"))
        self.assertIn("15% Haste", slice_and_dice["description"])

    def test_glyph_aura_inherits_the_glyph_row(self) -> None:
        bloodlust = self.spells[60018]
        self.assertEqual(bloodlust["name"], "Glyph of Bloodlust")
        self.assertEqual(bloodlust["name_zhCN"], "嗜血雕文")
        self.assertTrue(bloodlust["icon"].endswith("Spell_Holy_RighteousFury"))

    def test_card_auras_inherit_card_names_and_icons(self) -> None:
        blue_dragon = self.spells[60006]
        self.assertEqual(blue_dragon["name"], "Darkmoon Card: Blue Dragon")
        self.assertEqual(blue_dragon["name_zhCN"], "暗月卡片：蓝龙")
        self.assertTrue(blue_dragon["icon"].endswith("INV_Misc_Ticket_Tarot_BlueDragon_01"))
        self.assertEqual(blue_dragon["stack_amount"], 1)

        brooch = self.spells[60021]
        self.assertEqual(brooch["name"], "Bloodlust Brooch")
        self.assertEqual(brooch["stack_amount"], 255)

        talisman = self.spells[60022]
        self.assertEqual(talisman["name"], "Talisman of Ascendance")
        self.assertEqual(talisman["stack_amount"], 20)

    def test_danse_macabre_follows_its_mastery(self) -> None:
        danse = self.spells[60030]
        self.assertEqual(danse["name"], "Danse Macabre")
        self.assertEqual(danse["name_zhCN"], "断魂之舞")
        self.assertTrue(danse["icon"].endswith("spell_shadow_summonvoidwalker"))
        self.assertEqual(danse["stack_amount"], 10)
        self.assertIn("10 times", danse["description"])

    def test_glyph_drawback_aura_inherits_the_drawback(self) -> None:
        nomad = self.spells[60020]
        self.assertEqual(nomad["name"], "Glyph of the Nomad")
        self.assertIn("Losing health", nomad["description"])
        self.assertIn("力量降低25%", nomad["description_zhCN"])

    def test_arcane_potency_covers_the_improved_talent(self) -> None:
        potency = self.spells[60050]
        self.assertEqual(potency["stack_amount"], 0)
        self.assertIn("5 with Improved Arcane Potency", potency["description"])
        self.assertIn("强化奥术潜能", potency["description_zhCN"])

    def test_keyword_aura_inherits_the_keyword_row(self) -> None:
        chill = self.spells[12485]
        self.assertEqual(chill["name"], "Chill")
        self.assertEqual(chill["name_zhCN"], "冰寒")
        self.assertTrue(chill["icon"].endswith("Spell_Frost_IceStorm"))
        self.assertEqual(chill["stack_amount"], 10)
        self.assertIn("3% per stack", chill["description"])

    def test_pet_aura_binds_to_its_source(self) -> None:
        bestial = self.spells[19574]
        self.assertEqual(bestial["name"], "Bestial Wrath")
        self.assertTrue(bestial["icon"].endswith("Ability_Druid_FerociousBite"))
        self.assertEqual(bestial["source_kind"], "mastery")

    def test_affix_glow_has_a_state_name(self) -> None:
        swift = self.spells[22580]
        self.assertEqual(swift["name"], "Swift")
        self.assertEqual(swift["name_zhCN"], "迅捷")
        self.assertEqual(swift["duration_index"], 0)

    def test_state_debuffs_keep_their_state_names(self) -> None:
        exposed = self.spells[60047]
        self.assertEqual(exposed["name"], "Exposed")
        self.assertEqual(exposed["name_zhCN"], "破绽")
        self.assertIn("takes more damage", exposed["description"])

        seduced = self.spells[60045]
        self.assertEqual(seduced["name"], "Seduced")
        self.assertEqual(seduced["name_zhCN"], "魅惑")

    def test_no_source_auras_have_full_dynamic_display(self) -> None:
        determination = self.spells[60001]
        self.assertEqual(determination["source_kind"], "none")
        self.assertEqual(determination["stack_amount"], 5)
        self.assertEqual(determination["duration_index"], 0)
        self.assertEqual(determination["dynamic_kind"], "stack_percent")

        wounds = self.spells[60003]
        self.assertEqual(wounds["source_kind"], "none")
        self.assertEqual(wounds["stack_amount"], 4)
        self.assertEqual(wounds["dynamic_kind"], "wounds_heal_cut")

        shield = self.spells[60005]
        self.assertEqual(shield["dynamic_kind"], "shield_absorb")

    def test_permanent_auras_use_duration_zero(self) -> None:
        for spell_id in (60001, 60005, 60010, 60021, 60022, 60038, 60053, 60054):
            self.assertEqual(self.spells[spell_id]["duration_index"], 0)

    def test_bandage_and_campfire_follow_card_copies(self) -> None:
        for spell_id in (60053, 60054):
            self.assertEqual(self.spells[spell_id]["stack_amount"], 255)
            self.assertEqual(self.spells[spell_id]["dynamic_kind"], "card_total")

    def test_every_dynamic_template_has_a_placeholder(self) -> None:
        for spell in self.spells.values():
            if spell["dynamic_kind"] in ("shield_absorb", "wounds_heal_cut", "stack_percent"):
                self.assertIn("{1}", spell["dynamic_template"])
                self.assertIn("{1}", spell["dynamic_template_zhCN"])


class HelperTests(unittest.TestCase):
    def test_parse_source(self) -> None:
        self.assertEqual(parse_source("card:21"), ("card", 21))
        self.assertEqual(parse_source("none"), ("none", None))
        with self.assertRaises(SystemExit):
            parse_source("card")

    def test_normalize_icon(self) -> None:
        self.assertEqual(normalize_icon("Spell_Fire_Fire"), "Interface\\Icons\\Spell_Fire_Fire")
        self.assertEqual(
            normalize_icon("Interface\\Icons\\Spell_Fire_Fire"),
            "Interface\\Icons\\Spell_Fire_Fire",
        )

    def test_dynamic_templates_must_agree(self) -> None:
        with self.assertRaises(SystemExit):
            resolve_dynamic(
                {"id": 60099, "dynamic": {"kind": "percent", "enUS": "{1}%"}},
                "none",
            )


class UsageAuditTests(unittest.TestCase):
    def test_every_generated_spell_constant_is_used(self) -> None:
        header = (ROOT / "server/src/game/Bonk/BonkSpellIds.h").read_text(encoding="utf-8")
        defined = set(re.findall(r"BONK_SPELL_[A-Z0-9_]+", header))
        used: set[str] = set()
        for path in (ROOT / "server/src").rglob("*"):
            if path.suffix not in (".cpp", ".h") or path.name == "BonkSpellIds.h":
                continue
            used.update(re.findall(r"BONK_SPELL_[A-Z0-9_]+", path.read_text(errors="ignore")))
        self.assertEqual(defined - used, set())

    def test_bonk_code_uses_constants_not_raw_aura_ids(self) -> None:
        for path in (ROOT / "server/src/game/Bonk").rglob("*"):
            if path.suffix not in (".cpp", ".h") or path.name == "BonkSpellIds.h":
                continue
            for number, line in enumerate(path.read_text(errors="ignore").splitlines(), 1):
                for match in re.finditer(r"\b60(0[0-9]{2})\b", line):
                    value = int("60" + match.group(1))
                    if 60001 <= value <= 60099:
                        self.fail(f"{path}:{number} uses raw aura id {value}")


    def test_addon_uses_generated_aura_ids(self) -> None:
        for path in (ROOT / "addon/HordesOfAzeroth").rglob("*.lua"):
            if path.name == "VanillaBonkAuraIds.lua":
                continue
            for number, line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
                for match in re.finditer(r"\b60(0[0-9]{2})\b", line):
                    value = int("60" + match.group(1))
                    if 60001 <= value <= 60099:
                        self.fail(f"{path}:{number} uses raw aura id {value}")


if __name__ == "__main__":
    unittest.main()
