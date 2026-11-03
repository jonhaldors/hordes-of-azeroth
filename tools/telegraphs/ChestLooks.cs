using System;
using System.Collections.Generic;
using System.IO;

namespace BonkTelegraphs
{
    static class ChestLooks
    {
        const uint SpotlightSpell = 25824;
        const uint SpotlightVisual = 7402;
        const uint PartyFeverStateKit = 560;
        const uint FirstSpellId = 33660, FirstVisualId = 8490, FirstKitId = 7490;
        const uint GhostEffect = 717, GoldGhostEffect = 3230;
        const string GhostModel = "Spells\\Ghost_state.m2";
        const string GoldGhostModel = "Spells\\BonkGoldGhost";
        const int ParticlesCountOffset = 316, ParticlesOffset = 320, ParticleSize = 504, ParticleColoursOffset = 336;
        const int EffectModelField = 2;
        const int SpellVisualField = 115, NameField = 120;
        const int VisualStateKitField = 4;
        const int KitChestEffectField = 4, KitBaseEffectField = 5;
        const uint None = uint.MaxValue;

        class Look
        {
            public string Name;
            public uint Effect;
        }

        static readonly Look[] Looks =
        {
            new Look { Name = "Valor Chest Glow", Effect = GhostEffect },
            new Look { Name = "Free Chest Glow", Effect = GoldGhostEffect },
            new Look { Name = "Valor Pouch Glow", Effect = 123 },
        };

        public static List<string> AddChestLooks(ClientData client, IDictionary<string, byte[]> files, Dbc spells, Dbc visuals, Dbc kits, Dbc effects)
        {
            List<string> manifest = new List<string> { AddGoldGhost(client, files, effects) };
            uint[] spell = spells.Find(SpotlightSpell), visual = visuals.Find(SpotlightVisual), kit = kits.Find(PartyFeverStateKit);
            if (spell == null || visual == null || kit == null)
                throw new InvalidDataException("The Spotlight spell or the Party Fever kit is not where 1.12 has them.");

            for (uint i = 0; i < Looks.Length; i++)
            {
                Look look = Looks[i];
                uint spellId = FirstSpellId + i, visualId = FirstVisualId + i, kitId = FirstKitId + i;
                if (spells.Find(spellId) != null || visuals.Find(visualId) != null || kits.Find(kitId) != null)
                    throw new InvalidOperationException("Chest look ids for " + look.Name + " are taken.");
                if (effects.Find(look.Effect) == null)
                    throw new InvalidDataException("Spell visual effect " + look.Effect + " is not in the client's tables.");

                uint[] newKit = (uint[])kit.Clone();
                newKit[0] = kitId;
                newKit[KitChestEffectField] = None;
                newKit[KitBaseEffectField] = look.Effect;
                kits.Records.Add(newKit);

                uint[] newVisual = (uint[])visual.Clone();
                newVisual[0] = visualId;
                newVisual[VisualStateKitField] = kitId;
                visuals.Records.Add(newVisual);

                uint[] newSpell = (uint[])spell.Clone();
                newSpell[0] = spellId;
                newSpell[SpellVisualField] = visualId;
                newSpell[NameField] = spells.AddString(look.Name);
                spells.Records.Add(newSpell);

                manifest.Add(string.Format("spell {0} ({1}): visual {2}, state kit {3}, effect {4} at the feet", spellId, look.Name, visualId, kitId, look.Effect));
            }
            return manifest;
        }

        static string AddGoldGhost(ClientData client, IDictionary<string, byte[]> files, Dbc effects)
        {
            byte[] source = client.Read(GhostModel);
            uint[] effect = effects.Find(GhostEffect);
            if (source == null || effect == null)
                throw new FileNotFoundException(GhostModel + " or its effect " + GhostEffect + " is not in the client's data.");
            if (effects.Find(GoldGhostEffect) != null)
                throw new InvalidOperationException("Spell visual effect " + GoldGhostEffect + " is taken.");

            byte[] m2 = (byte[])source.Clone();
            uint count = BitConverter.ToUInt32(m2, ParticlesCountOffset), offset = BitConverter.ToUInt32(m2, ParticlesOffset);
            for (uint i = 0; i < count; i++)
                for (int c = 0; c < 3; c++)
                {
                    int bgra = (int)(offset + i * ParticleSize) + ParticleColoursOffset + c * 4;
                    byte bright = Math.Max(m2[bgra], Math.Max(m2[bgra + 1], m2[bgra + 2]));
                    m2[bgra] = (byte)(bright * 0.15f);
                    m2[bgra + 1] = (byte)(bright * 0.7f);
                    m2[bgra + 2] = bright;
                }
            files[GoldGhostModel + ".m2"] = m2;

            uint[] newEffect = (uint[])effect.Clone();
            newEffect[0] = GoldGhostEffect;
            newEffect[EffectModelField] = effects.AddString(GoldGhostModel + ".mdx");
            effects.Records.Add(newEffect);
            return string.Format("effect {0}: {1} with its particles turned gold, {2}.m2", GoldGhostEffect, GhostModel, GoldGhostModel);
        }
    }
}
