using System;
using System.Collections.Generic;
using System.IO;
using System.Text;

namespace BonkTelegraphs
{
    static class FelFire
    {
        const uint FirstEffectId = 3300;
        const uint FirstKitId = 7600;
        const uint FirstVisualId = 8700;
        const string FelFolder = "Spells\\Fel\\";
        const string VoidFolder = "Spells\\Void\\";
        public const uint FelImpDisplayId = 18900;
        const uint FelImpModelId = 3900;
        const uint ImpDisplayId = 4449;
        const int DisplayModelField = 1, ModelPathField = 2;

        const int SpellVisualField = 115;
        const int SpellNameField = 120;
        const float Brightness = 0.82f;
        const int EffectNameField = 1, EffectPathField = 2, EffectScaleField = 4;
        const int FirstKitEffectField = 3, LastKitEffectField = 12;
        const int VisualMissileModelField = 7;
        static readonly int[] VisualKitFields = { 1, 2, 3, 4, 5 };
        const int KitStartAnimField = 1, KitAnimField = 2;
        const uint DrainBeamSpell = 755;

        class FelSpell
        {
            public uint SpellId;
            public string Name;
            public string Rename;
            public uint VisualFrom;
            public bool Void;
            public bool Shadow;
            public uint FelSpellId;
            public string FelName;
            public int ShardSlot = -1;
            public float MissileScale = 1f;
        }

        static readonly FelSpell[] Spells =
        {
            new FelSpell { SpellId = 11763, Name = "Imp Firebolt", FelSpellId = 33500, FelName = "Fel Firebolt" },
            new FelSpell { SpellId = 19717, Name = "Rain of Fire", FelSpellId = 33501, FelName = "Rain of Felfire", ShardSlot = FelShardSlot },
            new FelSpell { SpellId = 348, Name = "Immolate", FelSpellId = 33502, FelName = "Fel Immolate" },
            new FelSpell { SpellId = 5857, Name = "Hellfire Effect", Rename = "Hellfire", FelSpellId = 33503, FelName = "Fel Hellfire" },
            new FelSpell { SpellId = 686, Name = "Shadow Bolt", FelSpellId = 33504, FelName = "Chaos Bolt", MissileScale = 1.2f, Shadow = true },
            new FelSpell { SpellId = 1112, Name = "Shadow Nova II", Rename = "Consume Shadows", VisualFrom = 1449, Void = true },
        };

        static readonly string[,] Icons =
        {
            { "Interface\\Icons\\Spell_Shadow_RainOfFire.blp", "Interface\\Icons\\Spell_Fel_RainOfFelfire.blp" },
            { "Interface\\Icons\\Spell_Fire_FireBolt.blp", "Interface\\Icons\\Spell_Fel_FireBolt.blp" },
            { "Interface\\Icons\\Spell_Shadow_ImpPhaseShift.blp", "Interface\\Icons\\Spell_Fel_ImpSwarm.blp" },
            { "Interface\\Icons\\Spell_Fire_Fireball.blp", "Interface\\Icons\\Spell_Fel_Conflagrate.blp" },
            { "Interface\\Icons\\Spell_Fire_Immolation.blp", "Interface\\Icons\\Spell_Fel_Shadowflame.blp" },
            { "Interface\\Icons\\Spell_Fire_Volcano.blp", "Interface\\Icons\\Spell_Fel_Inferno.blp" },
            { "Interface\\Icons\\Spell_Fire_SealOfFire.blp", "Interface\\Icons\\Spell_Fel_DemonicImmolation.blp" },
        };

        static readonly string[,] ShadowIcons =
        {
            { "Interface\\Icons\\Spell_Shadow_ShadowBolt.blp", "Interface\\Icons\\Spell_Fel_ChaosBolt.blp" },
        };

        static readonly string[] ReplacedModels = { };

        const string RainShardModel = "Spells\\RainOfFire_Impact_Base";
        const string FelShardSlotModel = "Spells\\StarShards_Impact_Base";
        const int FelShardSlot = 6;
        const int VisualAreaModelField = 12, VisualAreaKitField = 13;
        const int KitProcTypeField = 15, KitProcParamZeroField = 19, KitProcCount = 4;
        const uint ShardEmitterProc = 9;

        class Ids
        {
            public uint NextEffect = FirstEffectId, NextKit = FirstKitId, NextVisual = FirstVisualId;
        }

        class Builder
        {
            public ClientData Client;
            public IDictionary<string, byte[]> Files;
            public Dbc Visuals, Kits, Effects;
            public Ids Ids;
            public ColourRule Rule = Fel;
            public string Prefix = "Fel";
            public string Folder = FelFolder;
            public Dictionary<uint, uint> EffectCopies = new Dictionary<uint, uint>();
            public Dictionary<uint, uint> KitCopies = new Dictionary<uint, uint>();
            public Dictionary<string, string> TextureCopies = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);
            public HashSet<string> Models = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
        }

        public static string AddFelCreatures(ClientData client, IDictionary<string, byte[]> files, Dbc displays, Dbc models)
        {
            uint[] display = displays.Find(ImpDisplayId);
            uint[] model = display != null ? models.Find(display[DisplayModelField]) : null;
            if (model == null)
                throw new InvalidDataException("Creature display " + ImpDisplayId + " (Imp) is not in the client's tables.");
            displays.Release(FelImpDisplayId);
            uint felModelId = models.ClaimId(FelImpModelId);

            Builder builder = new Builder { Client = client, Files = files };
            string stem = MpqPath.WithoutExtension(models.GetString(model[ModelPathField]));
            string felStem = MpqPath.Join(MpqPath.Directory(stem), "Fel" + MpqPath.FileName(stem));
            files[felStem + ".m2"] = RecolourModel(builder, stem + ".m2", true);

            uint[] felModel = (uint[])model.Clone();
            felModel[0] = felModelId;
            felModel[ModelPathField] = models.AddString(felStem + ".mdx");
            models.Records.Add(felModel);
            uint[] felDisplay = (uint[])display.Clone();
            felDisplay[0] = FelImpDisplayId;
            felDisplay[DisplayModelField] = felModelId;
            displays.Records.Add(felDisplay);
            return string.Format("creature display {0}: Imp with fel green hand fire (model {1}, {2})", FelImpDisplayId, felModelId, felStem);
        }

        public static List<string> AddFelFire(ClientData client, IDictionary<string, byte[]> files, Dbc spells, Dbc visuals, Dbc kits, Dbc effects)
        {
            Ids ids = new Ids();
            Builder builder = new Builder { Client = client, Files = files, Visuals = visuals, Kits = kits, Effects = effects, Ids = ids };
            Builder voidBuilder = new Builder { Client = client, Files = files, Visuals = visuals, Kits = kits, Effects = effects, Ids = ids,
                Rule = Void, Prefix = "Void", Folder = VoidFolder };
            Builder shadowBuilder = new Builder { Client = client, Files = files, Visuals = visuals, Kits = kits, Effects = effects, Ids = ids,
                Rule = FelShadow, Prefix = "FelShadow" };
            List<string> manifest = new List<string>();
            foreach (string model in ReplacedModels)
            {
                files[model + ".m2"] = RecolourModel(builder, model + ".m2");
                manifest.Add(model + ": recoloured fel green in place");
            }
            files[FelShardSlotModel + ".m2"] = RecolourModel(builder, RainShardModel + ".m2");
            manifest.Add(FelShardSlotModel + ": fel copy of " + RainShardModel + " (shard slot " + FelShardSlot + ")");

            AddIcons(client, files, Icons, FelWarm, manifest);
            AddIcons(client, files, ShadowIcons, FelShadow, manifest);

            foreach (FelSpell felSpell in Spells)
            {
                Builder painter = felSpell.Void ? voidBuilder : felSpell.Shadow ? shadowBuilder : builder;
                uint[] spell = spells.Find(felSpell.SpellId);
                uint[] source = felSpell.VisualFrom != 0 ? spells.Find(felSpell.VisualFrom) : spell;
                if (spell == null || source == null)
                    throw new InvalidDataException("Spell " + felSpell.SpellId + " or its look is not in Spell.dbc.");
                uint stockVisual = source[SpellVisualField];
                uint[] visual = visuals.Find(stockVisual);
                if (visual == null)
                    throw new InvalidDataException("Spell " + felSpell.SpellId + " has no spell visual.");

                uint id = ids.NextVisual++;
                if (visuals.Find(id) != null)
                    throw new InvalidOperationException("Spell visual " + id + " is taken.");
                uint[] copy = (uint[])visual.Clone();
                copy[0] = id;
                foreach (int field in VisualKitFields)
                    copy[field] = CopyKit(painter, copy[field]);
                copy[VisualMissileModelField] = CopyEffect(painter, copy[VisualMissileModelField]);
                if (felSpell.MissileScale != 1f)
                    copy[VisualMissileModelField] = ScaleEffect(painter, copy[VisualMissileModelField], felSpell.MissileScale);
                if (felSpell.FelSpellId != 0)
                {
                    copy[VisualAreaModelField] = CopyEffect(painter, copy[VisualAreaModelField]);
                    copy[VisualAreaKitField] = felSpell.ShardSlot >= 0 ? CopyShardKit(painter, copy[VisualAreaKitField], felSpell.ShardSlot) :
                        CopyKit(painter, copy[VisualAreaKitField]);
                }
                visuals.Records.Add(copy);
                if (felSpell.Rename != null)
                    spell[SpellNameField] = spells.AddString(felSpell.Rename);
                if (felSpell.FelSpellId == 0)
                {
                    spell[SpellVisualField] = id;
                    manifest.Add(string.Format("spell {0} ({1}): visual {2} -> {3} visual {4}", felSpell.SpellId, felSpell.Name, stockVisual, painter.Prefix.ToLowerInvariant(), id));
                    continue;
                }
                if (spells.Find(felSpell.FelSpellId) != null)
                    throw new InvalidOperationException("Spell " + felSpell.FelSpellId + " is taken.");
                uint[] felRow = (uint[])spell.Clone();
                felRow[0] = felSpell.FelSpellId;
                felRow[SpellVisualField] = id;
                felRow[SpellNameField] = spells.AddString(felSpell.FelName);
                spells.Records.Add(felRow);
                manifest.Add(string.Format("spell {0} ({1}): copy of {2} ({3}) with {4} visual {5}", felSpell.FelSpellId, felSpell.FelName, felSpell.SpellId,
                    felSpell.Name, painter.Prefix.ToLowerInvariant(), id));
            }
            manifest.Add(AddStillDrainBeam(spells, visuals, kits, ids));
            manifest.Add(string.Format("fel and void: {0} effects, {1} kits, {2} textures recoloured",
                builder.EffectCopies.Count + voidBuilder.EffectCopies.Count + shadowBuilder.EffectCopies.Count,
                builder.KitCopies.Count + voidBuilder.KitCopies.Count + shadowBuilder.KitCopies.Count,
                builder.TextureCopies.Count + voidBuilder.TextureCopies.Count + shadowBuilder.TextureCopies.Count));
            return manifest;
        }

        static string AddStillDrainBeam(Dbc spells, Dbc visuals, Dbc kits, Ids ids)
        {
            uint[] spell = spells.Find(DrainBeamSpell);
            uint[] visual = spell != null ? visuals.Find(spell[SpellVisualField]) : null;
            if (visual == null)
                throw new InvalidDataException("Spell " + DrainBeamSpell + " or its visual is not in the client's tables.");

            uint visualId = ids.NextVisual++;
            if (visuals.Find(visualId) != null)
                throw new InvalidOperationException("Spell visual " + visualId + " is taken.");
            uint[] copy = (uint[])visual.Clone();
            copy[0] = visualId;
            foreach (int field in VisualKitFields)
            {
                uint[] kit = copy[field] == 0 || copy[field] == uint.MaxValue ? null : kits.Find(copy[field]);
                if (kit == null)
                    continue;
                uint kitId = ids.NextKit++;
                if (kits.Find(kitId) != null)
                    throw new InvalidOperationException("Spell visual kit " + kitId + " is taken.");
                uint[] still = (uint[])kit.Clone();
                still[0] = kitId;
                still[KitStartAnimField] = still[KitAnimField] = uint.MaxValue;
                kits.Records.Add(still);
                copy[field] = kitId;
            }
            visuals.Records.Add(copy);
            uint stockVisual = spell[SpellVisualField];
            spell[SpellVisualField] = visualId;
            return string.Format("spell {0} (drain beam): visual {1} -> {2}, kits without animations", DrainBeamSpell, stockVisual, visualId);
        }

        static uint ScaleEffect(Builder builder, uint effectId, float scale)
        {
            uint[] effect = effectId == 0 || effectId == uint.MaxValue ? null : builder.Effects.Find(effectId);
            if (effect == null)
                throw new InvalidDataException("Spell visual effect " + effectId + " can't be scaled.");
            uint id = builder.Ids.NextEffect++;
            if (builder.Effects.Find(id) != null)
                throw new InvalidOperationException("Spell visual effect " + id + " is taken.");
            uint[] copy = (uint[])effect.Clone();
            copy[0] = id;
            float current = BitConverter.ToSingle(BitConverter.GetBytes(effect[EffectScaleField]), 0);
            copy[EffectScaleField] = BitConverter.ToUInt32(BitConverter.GetBytes((current > 0 ? current : 1f) * scale), 0);
            builder.Effects.Records.Add(copy);
            return id;
        }

        static uint CopyShardKit(Builder builder, uint kitId, int slot)
        {
            uint[] kit = kitId == 0 || kitId == uint.MaxValue ? null : builder.Kits.Find(kitId);
            if (kit == null)
                throw new InvalidDataException("Spell visual kit " + kitId + " has no shard emitter to move.");
            uint id = builder.Ids.NextKit++;
            if (builder.Kits.Find(id) != null)
                throw new InvalidOperationException("Spell visual kit " + id + " is taken.");
            uint[] copy = (uint[])kit.Clone();
            copy[0] = id;
            for (int field = FirstKitEffectField; field <= LastKitEffectField; field++)
                copy[field] = CopyEffect(builder, copy[field]);
            bool moved = false;
            for (int proc = 0; proc < KitProcCount; proc++)
                if (copy[KitProcTypeField + proc] == ShardEmitterProc)
                {
                    copy[KitProcParamZeroField + proc] = BitConverter.ToUInt32(BitConverter.GetBytes((float)slot), 0);
                    moved = true;
                }
            if (!moved)
                throw new InvalidDataException("Spell visual kit " + kitId + " has no shard emitter to move.");
            builder.Kits.Records.Add(copy);
            return id;
        }

        static uint CopyKit(Builder builder, uint kitId)
        {
            if (kitId == 0 || kitId == uint.MaxValue)
                return kitId;
            uint copied;
            if (builder.KitCopies.TryGetValue(kitId, out copied))
                return copied;
            uint[] kit = builder.Kits.Find(kitId);
            if (kit == null)
                return kitId;

            uint id = builder.Ids.NextKit++;
            if (builder.Kits.Find(id) != null)
                throw new InvalidOperationException("Spell visual kit " + id + " is taken.");
            uint[] copy = (uint[])kit.Clone();
            copy[0] = id;
            for (int field = FirstKitEffectField; field <= LastKitEffectField; field++)
                copy[field] = CopyEffect(builder, copy[field]);
            builder.Kits.Records.Add(copy);
            builder.KitCopies[kitId] = id;
            return id;
        }

        static uint CopyEffect(Builder builder, uint effectId)
        {
            if (effectId == 0 || effectId == uint.MaxValue)
                return effectId;
            uint copied;
            if (builder.EffectCopies.TryGetValue(effectId, out copied))
                return copied;
            uint[] effect = builder.Effects.Find(effectId);
            if (effect == null)
                return effectId;

            string path = builder.Effects.GetString(effect[EffectPathField]);
            string stem = MpqPath.WithoutExtension(path);
            if (Array.Exists(ReplacedModels, model => string.Equals(model, stem, StringComparison.OrdinalIgnoreCase)))
            {
                builder.EffectCopies[effectId] = effectId;
                return effectId;
            }

            string felStem = builder.Folder + builder.Prefix + MpqPath.FileName(stem);
            if (builder.Models.Add(felStem))
                builder.Files[felStem + ".m2"] = RecolourModel(builder, stem + ".m2");

            uint id = builder.Ids.NextEffect++;
            if (builder.Effects.Find(id) != null)
                throw new InvalidOperationException("Spell visual effect " + id + " is taken.");
            uint[] copy = (uint[])effect.Clone();
            copy[0] = id;
            copy[EffectNameField] = builder.Effects.AddString(builder.Prefix + " " + builder.Effects.GetString(effect[EffectNameField]));
            copy[EffectPathField] = builder.Effects.AddString(felStem + ".mdx");
            builder.Effects.Records.Add(copy);
            builder.EffectCopies[effectId] = id;
            return id;
        }

        static byte[] RecolourModel(Builder builder, string name, bool particlesOnly = false)
        {
            byte[] source = builder.Client.Read(name);
            if (source == null)
                throw new FileNotFoundException(name + " is not in the client's archives.");
            MemoryStream ms = new MemoryStream();
            ms.Write(source, 0, source.Length);
            byte[] m2 = ms.GetBuffer();
            if (BitConverter.ToUInt32(m2, 4) != 256)
                throw new InvalidDataException(name + " is not a version 256 model.");

            uint count = BitConverter.ToUInt32(m2, 92), offset = BitConverter.ToUInt32(m2, 96);
            for (uint i = 0; i < count; i++)
            {
                int entry = (int)(offset + i * 16);
                uint length = BitConverter.ToUInt32(m2, entry + 8);
                if (BitConverter.ToUInt32(m2, entry) != 0 || length <= 1)
                    continue;
                string texture = Encoding.ASCII.GetString(m2, (int)BitConverter.ToUInt32(m2, entry + 12), (int)length - 1);
                string recoloured = CopyTexture(builder, texture);
                if (recoloured == null)
                    continue;
                ms.Position = ms.Length;
                ms.Write(new byte[(16 - ms.Length % 16) % 16], 0, (int)((16 - ms.Length % 16) % 16));
                uint nameOfs = (uint)ms.Length;
                byte[] bytes = Encoding.ASCII.GetBytes(recoloured + "\0");
                ms.Write(bytes, 0, bytes.Length);
                m2 = ms.GetBuffer();
                WriteUInt32(m2, entry + 8, (uint)bytes.Length);
                WriteUInt32(m2, entry + 12, nameOfs);
            }

            count = particlesOnly ? 0 : BitConverter.ToUInt32(m2, 84);
            offset = BitConverter.ToUInt32(m2, 88);
            for (uint i = 0; i < count; i++)
                RecolourTrack(m2, (int)(offset + i * 56), builder.Rule);

            count = BitConverter.ToUInt32(m2, 308);
            offset = BitConverter.ToUInt32(m2, 312);
            for (uint i = 0; i < count; i++)
                RecolourTrack(m2, (int)(offset + i * 220) + 36, builder.Rule);

            count = BitConverter.ToUInt32(m2, 316);
            offset = BitConverter.ToUInt32(m2, 320);
            for (uint i = 0; i < count; i++)
            {
                int particle = (int)(offset + i * 504);
                for (int c = 0; c < 3; c++)
                {
                    int bgra = particle + 336 + c * 4;
                    float b = m2[bgra] / 255f, g = m2[bgra + 1] / 255f, r = m2[bgra + 2] / 255f;
                    builder.Rule(ref r, ref g, ref b);
                    m2[bgra] = (byte)Math.Round(b * 255);
                    m2[bgra + 1] = (byte)Math.Round(g * 255);
                    m2[bgra + 2] = (byte)Math.Round(r * 255);
                }
            }
            return ms.ToArray();
        }

        static string CopyTexture(Builder builder, string texture)
        {
            string copied;
            if (builder.TextureCopies.TryGetValue(texture, out copied))
                return copied;
            byte[] blp = builder.Client.Read(texture);
            if (blp == null || !Blp.CanRecolour(blp))
            {
                builder.TextureCopies[texture] = null;
                return null;
            }
            copied = builder.Folder + texture.Replace('\\', '_');
            builder.Files[copied] = Blp.Recolour(blp, builder.Rule);
            builder.TextureCopies[texture] = copied;
            return copied;
        }

        public static void Fel(ref float r, ref float g, ref float b)
        {
            float low = Math.Min(r, Math.Min(g, b));
            float high = Math.Max(r, g);
            float middle = Math.Min(r, g);
            r = (low + 0.55f * (middle - low)) * Brightness;
            g = high * Brightness;
            b = low * 0.85f * Brightness;
        }

        public static void Void(ref float r, ref float g, ref float b)
        {
            float light = Math.Max(r, Math.Max(g, b));
            r = 0.42f * light;
            g = 0.12f * light;
            b = 0.78f * light;
        }

        static void AddIcons(ClientData client, IDictionary<string, byte[]> files, string[,] icons, ColourRule rule, List<string> manifest)
        {
            for (int i = 0; i < icons.GetLength(0); i++)
            {
                byte[] icon = client.Read(icons[i, 0]);
                if (icon == null || !Blp.CanRecolour(icon))
                    throw new InvalidDataException(icons[i, 0] + " can't be recoloured.");
                files[icons[i, 1]] = Blp.Recolour(icon, rule);
                manifest.Add(icons[i, 1] + ": fel copy of " + icons[i, 0]);
            }
        }

        public static void FelShadow(ref float r, ref float g, ref float b)
        {
            float low = Math.Min(r, Math.Min(g, b));
            float high = Math.Max(r, Math.Max(g, b));
            r = low * Brightness;
            g = high * Brightness;
            b = low * 0.85f * Brightness;
        }

        public static void FelWarm(ref float r, ref float g, ref float b)
        {
            if (r > b && r >= g)
                Fel(ref r, ref g, ref b);
        }

        static void RecolourTrack(byte[] m2, int track, ColourRule rule)
        {
            uint keys = BitConverter.ToUInt32(m2, track + 20), values = BitConverter.ToUInt32(m2, track + 24);
            for (uint k = 0; k < keys; k++)
            {
                int at = (int)(values + k * 12);
                float r = BitConverter.ToSingle(m2, at), g = BitConverter.ToSingle(m2, at + 4), b = BitConverter.ToSingle(m2, at + 8);
                rule(ref r, ref g, ref b);
                Buffer.BlockCopy(BitConverter.GetBytes(r), 0, m2, at, 4);
                Buffer.BlockCopy(BitConverter.GetBytes(g), 0, m2, at + 4, 4);
                Buffer.BlockCopy(BitConverter.GetBytes(b), 0, m2, at + 8, 4);
            }
        }

        static void WriteUInt32(byte[] data, int at, uint value)
        {
            Buffer.BlockCopy(BitConverter.GetBytes(value), 0, data, at, 4);
        }
    }
}
