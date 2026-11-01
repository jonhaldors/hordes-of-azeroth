using System;
using System.Collections.Generic;
using System.IO;

namespace BonkTelegraphs
{
    static class DropGlows
    {
        const uint SpotlightSpell = 25824;
        const uint SpotlightVisual = 7402;
        const uint PartyFeverStateKit = 560;
        const uint FirstPoolSpellId = 33640, FirstPoolVisualId = 8470, FirstPoolKitId = 7470, FirstPoolEffectId = 3210;
        const uint FirstCoreSpellId = 33642, FirstCoreVisualId = 8472, FirstCoreKitId = 7472, FirstCoreEffectId = 3212;
        const uint FirstSwirlSpellId = 33646, FirstSwirlVisualId = 8476, FirstSwirlKitId = 7476;
        const uint DownedSpellId = 33650, DownedVisualId = 8480, DownedKitId = 7480, DownedEffectId = 3220;
        const uint ShadowSwirlEffect = 814, PurpleSwirlEffect = 3216;
        const string ShadowSwirlModel = "Spells\\Shadow_Precast_Uber_Base.m2";
        const string PurpleSwirlModel = "Spells\\BonkPurpleSwirl";
        const int ParticlesCountOffset = 316, ParticlesOffset = 320, ParticleSize = 504, ParticleColoursOffset = 336;
        const int EffectModelField = 2;

        const int SpellVisualField = 115, NameField = 120;
        const int VisualStateKitField = 4;
        const int KitChestEffectField = 4, KitBaseEffectField = 5;
        const uint None = uint.MaxValue;
        const float CoreWidth = 0.11f, CoreWhite = 0.5f, CoreGain = 1.3f;

        static readonly LootBeams.Beam[] Pools =
        {
            new LootBeams.Beam { Name = "TicketPool", R = 1.0f, G = 0.1f, B = 0.25f, WhiteCore = 0.0f, Gain = 1.5f, Width = 0.5f, Height = 0.1f },
            new LootBeams.Beam { Name = "GlyphPool", R = 0.6f, G = 0.15f, B = 1.0f, WhiteCore = 0.0f, Gain = 1.5f, Width = 0.5f, Height = 0.1f },
        };

        static readonly LootBeams.Beam[] Cores =
        {
            new LootBeams.Beam { Name = "UncommonCore",  R = 0.12f, G = 1.0f,  B = 0.0f, WhiteCore = CoreWhite, Gain = CoreGain, Width = CoreWidth },
            new LootBeams.Beam { Name = "RareCore",      R = 0.0f,  G = 0.35f, B = 1.0f, WhiteCore = CoreWhite, Gain = CoreGain, Width = CoreWidth },
            new LootBeams.Beam { Name = "EpicCore",      R = 0.55f, G = 0.1f,  B = 1.0f, WhiteCore = CoreWhite, Gain = CoreGain, Width = CoreWidth },
            new LootBeams.Beam { Name = "LegendaryCore", R = 1.0f,  G = 0.5f,  B = 0.0f, WhiteCore = CoreWhite, Gain = CoreGain, Width = CoreWidth },
        };

        static readonly LootBeams.Beam[] Downed =
        {
            new LootBeams.Beam { Name = "Downed", R = 1.0f, G = 0.12f, B = 0.08f, WhiteCore = 0.0f, Gain = 1.6f, Width = 0.4f, Height = 4.0f },
        };

        class Swirl
        {
            public string Name;
            public uint Effect;
        }

        static readonly Swirl[] Swirls =
        {
            new Swirl { Name = "Rare Swirl", Effect = 122 },
            new Swirl { Name = "Epic Swirl", Effect = PurpleSwirlEffect },
            new Swirl { Name = "Legendary Swirl", Effect = 211 },
        };

        public static List<string> AddDropGlows(ClientData client, IDictionary<string, byte[]> files, Dbc spells, Dbc visuals, Dbc kits, Dbc effects)
        {
            List<string> manifest = LootBeams.AddBeams(client, files, spells, visuals, kits, effects, Pools,
                FirstPoolSpellId, FirstPoolVisualId, FirstPoolKitId, FirstPoolEffectId);
            manifest.AddRange(LootBeams.AddBeams(client, files, spells, visuals, kits, effects, Cores,
                FirstCoreSpellId, FirstCoreVisualId, FirstCoreKitId, FirstCoreEffectId));
            manifest.AddRange(LootBeams.AddBeams(client, files, spells, visuals, kits, effects, Downed,
                DownedSpellId, DownedVisualId, DownedKitId, DownedEffectId));
            manifest.Add(AddPurpleSwirl(client, files, effects));
            manifest.AddRange(AddSwirls(spells, visuals, kits, effects));
            return manifest;
        }

        static string AddPurpleSwirl(ClientData client, IDictionary<string, byte[]> files, Dbc effects)
        {
            byte[] source = client.Read(ShadowSwirlModel);
            uint[] effect = effects.Find(ShadowSwirlEffect);
            if (source == null || effect == null)
                throw new FileNotFoundException(ShadowSwirlModel + " or its effect " + ShadowSwirlEffect + " is not in the client's data.");
            if (effects.Find(PurpleSwirlEffect) != null)
                throw new InvalidOperationException("Spell visual effect " + PurpleSwirlEffect + " is taken.");

            byte[] m2 = (byte[])source.Clone();
            uint count = BitConverter.ToUInt32(m2, ParticlesCountOffset), offset = BitConverter.ToUInt32(m2, ParticlesOffset);
            for (uint i = 0; i < count; i++)
                for (int c = 0; c < 3; c++)
                {
                    int bgra = (int)(offset + i * ParticleSize) + ParticleColoursOffset + c * 4;
                    byte b = m2[bgra], g = m2[bgra + 1], r = m2[bgra + 2];
                    if (g > r && g > b)
                    {
                        m2[bgra] = g;
                        m2[bgra + 1] = 0;
                        m2[bgra + 2] = (byte)(g * 0.6f);
                    }
                }
            files[PurpleSwirlModel + ".m2"] = m2;

            uint[] newEffect = (uint[])effect.Clone();
            newEffect[0] = PurpleSwirlEffect;
            newEffect[EffectModelField] = effects.AddString(PurpleSwirlModel + ".mdx");
            effects.Records.Add(newEffect);
            return string.Format("effect {0}: {1} with its green particles turned purple, {2}.m2", PurpleSwirlEffect, ShadowSwirlModel, PurpleSwirlModel);
        }

        static List<string> AddSwirls(Dbc spells, Dbc visuals, Dbc kits, Dbc effects)
        {
            uint[] spell = spells.Find(SpotlightSpell), visual = visuals.Find(SpotlightVisual), kit = kits.Find(PartyFeverStateKit);
            if (spell == null || visual == null || kit == null)
                throw new InvalidDataException("The Spotlight spell or the Party Fever kit is not where 1.12 has them.");

            List<string> manifest = new List<string>();
            for (uint i = 0; i < Swirls.Length; i++)
            {
                Swirl swirl = Swirls[i];
                uint spellId = FirstSwirlSpellId + i, visualId = FirstSwirlVisualId + i, kitId = FirstSwirlKitId + i;
                if (spells.Find(spellId) != null || visuals.Find(visualId) != null || kits.Find(kitId) != null)
                    throw new InvalidOperationException("Swirl ids for " + swirl.Name + " are taken.");
                if (effects.Find(swirl.Effect) == null)
                    throw new InvalidDataException("Spell visual effect " + swirl.Effect + " is not in the client's tables.");

                uint[] newKit = (uint[])kit.Clone();
                newKit[0] = kitId;
                newKit[KitChestEffectField] = None;
                newKit[KitBaseEffectField] = swirl.Effect;
                kits.Records.Add(newKit);

                uint[] newVisual = (uint[])visual.Clone();
                newVisual[0] = visualId;
                newVisual[VisualStateKitField] = kitId;
                visuals.Records.Add(newVisual);

                uint[] newSpell = (uint[])spell.Clone();
                newSpell[0] = spellId;
                newSpell[SpellVisualField] = visualId;
                newSpell[NameField] = spells.AddString(swirl.Name);
                spells.Records.Add(newSpell);

                manifest.Add(string.Format("spell {0} ({1}): visual {2}, state kit {3}, effect {4} at the feet", spellId, swirl.Name, visualId, kitId, swirl.Effect));
            }
            return manifest;
        }
    }
}
