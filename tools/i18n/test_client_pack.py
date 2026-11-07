# SPDX-License-Identifier: GPL-3.0-only
"""Tests for the generated client language packs."""

from __future__ import annotations

import json
import unittest

import gen_client_pack
from catalogue import load


class ClientPackTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.result = load()
        cls.packs = {
            locale: json.loads(payload)
            for locale, payload in gen_client_pack.render().items()
        }

    def test_catalogue_is_valid(self) -> None:
        self.assertEqual(self.result.errors, [])

    def test_every_ui_entry_has_both_languages(self) -> None:
        ui = [entry for entry in self.result.entries if entry["id"].startswith("hoa.ui.")]
        self.assertGreater(len(ui), 0)
        for entry in ui:
            self.assertTrue(entry["enUS"].strip(), entry["id"])
            self.assertTrue(entry["zhCN"].strip(), entry["id"])
            self.assertTrue(entry.get("zhTW", "").strip(), entry["id"])

    def test_generated_packs_match_the_sources(self) -> None:
        for locale, document in self.packs.items():
            self.assertEqual(document["version"], 1)
            self.assertEqual(document["locale"], locale)
            self.assertEqual(document["fallback"], "enUS")
            self.assertTrue(document["messages"], locale)
            self.assertEqual(
                set(document["messages"]),
                set(document["fallbackMessages"]),
                locale,
            )

    def test_glue_aliases_are_unique_or_agree(self) -> None:
        aliases = self.packs["enUS"]["aliases"]
        messages = self.packs["zhCN"]["messages"]
        fallback = self.packs["enUS"]["fallbackMessages"]
        alias_ids = set(aliases.values())
        by_english = {}
        for message_id in alias_ids:
            english = fallback[message_id]
            previous = by_english.get(english)
            if previous is not None:
                self.assertEqual(
                    messages[previous],
                    messages[message_id],
                    f"{english!r}: two zhCN texts",
                )
            by_english[english] = message_id
        self.assertEqual(set(aliases), set(by_english))


if __name__ == "__main__":
    unittest.main()
