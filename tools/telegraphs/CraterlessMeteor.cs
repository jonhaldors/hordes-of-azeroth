using System;
using System.Collections.Generic;
using System.IO;

namespace BonkTelegraphs
{
    static class CraterlessMeteor
    {
        const int TransparencyCountOffset = 0x64, TransparencyOffset = 0x68, TrackSize = 28;
        const int TrackValuesCountOffset = 20, TrackValuesOffset = 24, ValueSize = 2;
        const int EffectModelField = 2, SpellVisualField = 115, VisualAreaModelField = 12;
        const uint FirstEffectId = 3700, FirstVisualId = 8650;

        class Impact
        {
            public string Name;
            public uint Spell, Visual, Effect;
            public string Model, NewModel;
            public int GroundTrack, Tracks;
        }

        static readonly Impact[] Impacts =
        {
            new Impact { Name = "Meteor", Spell = 26558, Visual = 7479, Effect = 3007,
                Model = "Spells\\Meteor_Impact_Base.m2", NewModel = "Spells\\BonkMeteorFall", GroundTrack = 4, Tracks = 5 },
            new Impact { Name = "Flamestrike", Spell = 2120, Visual = 33, Effect = 420,
                Model = "Spells\\Flamestrike_Impact_Base.m2", NewModel = "Spells\\BonkFlamestrikePillar", GroundTrack = 3, Tracks = 5 },
        };

        public static List<string> Add(ClientData client, IDictionary<string, byte[]> files, Dbc spells, Dbc visuals, Dbc effects)
        {
            List<string> manifest = new List<string>();
            for (uint i = 0; i < Impacts.Length; i++)
                manifest.AddRange(AddImpact(client, files, spells, visuals, effects, Impacts[i], FirstEffectId + i, FirstVisualId + i));
            return manifest;
        }

        static List<string> AddImpact(ClientData client, IDictionary<string, byte[]> files, Dbc spells, Dbc visuals, Dbc effects, Impact impact, uint newEffectId, uint newVisualId)
        {
            byte[] source = client.Read(impact.Model);
            uint[] spell = spells.Find(impact.Spell), visual = visuals.Find(impact.Visual), effect = effects.Find(impact.Effect);
            if (source == null || spell == null || visual == null || effect == null)
                throw new FileNotFoundException(impact.Model + ", spell " + impact.Spell + " or its visual is not in the client's data.");
            if (spell[SpellVisualField] != impact.Visual || visual[VisualAreaModelField] != impact.Effect)
                throw new InvalidDataException("Spell " + impact.Spell + " no longer uses visual " + impact.Visual + " with effect " + impact.Effect + ".");
            if (effects.Find(newEffectId) != null || visuals.Find(newVisualId) != null)
                throw new InvalidOperationException(impact.Name + " ids " + newEffectId + " or " + newVisualId + " are taken.");

            files[impact.NewModel + ".m2"] = WithoutGround(source, impact);

            uint[] newEffect = (uint[])effect.Clone();
            newEffect[0] = newEffectId;
            newEffect[EffectModelField] = effects.AddString(impact.NewModel + ".mdx");
            effects.Records.Add(newEffect);

            uint[] newVisual = (uint[])visual.Clone();
            newVisual[0] = newVisualId;
            newVisual[VisualAreaModelField] = newEffectId;
            visuals.Records.Add(newVisual);

            spell[SpellVisualField] = newVisualId;
            return new List<string>
            {
                string.Format("effect {0}: {1} without its lava ground, {2}.m2", newEffectId, impact.Model, impact.NewModel),
                string.Format("spell {0} ({1}): visual {2} plays effect {3}", impact.Spell, impact.Name, newVisualId, newEffectId),
            };
        }

        static byte[] WithoutGround(byte[] source, Impact impact)
        {
            byte[] m2 = (byte[])source.Clone();
            uint tracks = BitConverter.ToUInt32(m2, TransparencyCountOffset);
            if (tracks != impact.Tracks)
                throw new InvalidDataException(impact.Model + " has " + tracks + " transparency tracks, not " + impact.Tracks + ".");
            int track = (int)BitConverter.ToUInt32(m2, TransparencyOffset) + impact.GroundTrack * TrackSize;
            uint count = BitConverter.ToUInt32(m2, track + TrackValuesCountOffset);
            int values = (int)BitConverter.ToUInt32(m2, track + TrackValuesOffset);
            if (count == 0 || values + count * ValueSize > m2.Length)
                throw new InvalidDataException(impact.Model + "'s ground transparency track is not where 1.12 has it.");
            for (int i = 0; i < count * ValueSize; i++)
                m2[values + i] = 0;
            return m2;
        }
    }
}
