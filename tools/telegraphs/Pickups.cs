using System;
using System.Collections.Generic;
using System.IO;
using System.Text;

namespace BonkTelegraphs
{
    static class Pickups
    {
        public const uint FirstJewelDisplayId = 17990;
        const uint FirstJewelModelId = 2490;
        public const uint TicketDisplayId = 7900;
        public const uint TurkeyDisplayId = 17994;
        const uint TurkeyModelId = 2494;
        const string TurkeyModel = "World\\Generic\\Human\\Passive Doodads\\Food&Utensils\\TurkeyLeg";
        const uint TemplateDisplayId = 10045;
        const uint TemplateModelId = 207;
        const int DisplayScaleField = 4;
        const float BlueScale = 0.3f;

        const string Goober = "World\\Goober\\";
        const string Folder = "World\\Goober\\BonkPickups\\";
        static readonly string[] BlueTextures = { "World\\Generic\\PassiveDoodads\\ParticleEmitters\\Blue_Glow2.blp", "Spells\\Blue_Star2.blp", Goober + "G_JewelBlue01.blp" };

        class Jewel
        {
            public string Name;
            public string Source;
            public ColourRule Rule;
            public float Scale;
            public float Glow = 1.0f;
        }

        static readonly Jewel[] Jewels =
        {
            new Jewel { Name = "Blue",   Source = "G_JewelBlue", Rule = null,         Scale = 0.3f },
            new Jewel { Name = "Green",  Source = "G_JewelBlue", Rule = Wisps.Green,  Scale = 0.36f, Glow = 0.45f },
            new Jewel { Name = "Red",    Source = "G_JewelRed",  Rule = null,         Scale = 0.42f },
            new Jewel { Name = "Purple", Source = "G_JewelBlue", Rule = Wisps.Purple, Scale = 0.5f },
        };

        public static void AddJewels(ClientData client, IDictionary<string, byte[]> files, Dbc displays, Dbc models)
        {
            uint[] templateDisplay = displays.Find(TemplateDisplayId), templateModel = models.Find(TemplateModelId);
            if (templateDisplay == null || templateModel == null)
                throw new InvalidDataException("The blue wisp's rows are not where 1.12 has them.");

            for (int i = 0; i < Jewels.Length; i++)
            {
                Jewel jewel = Jewels[i];
                uint displayId = FirstJewelDisplayId + (uint)i;
                if (displays.Find(displayId) != null)
                    throw new InvalidOperationException("Jewel display " + displayId + " is taken.");
                uint modelId = models.ClaimId(FirstJewelModelId + (uint)i);

                byte[] m2 = Require(client, Goober + jewel.Source + ".m2");
                if (jewel.Rule != null)
                {
                    ColourRule rule = jewel.Rule, glow = jewel.Rule;
                    float strength = jewel.Glow;
                    if (strength != 1.0f)
                        glow = (ref float r, ref float g, ref float b) =>
                        {
                            rule(ref r, ref g, ref b);
                            r *= strength;
                            g *= strength;
                            b *= strength;
                        };
                    Dictionary<string, string> swaps = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);
                    for (int t = 0; t < BlueTextures.Length; t++)
                    {
                        string texture = BlueTextures[t];
                        string recoloured = Folder + "Jewel" + jewel.Name + MpqPath.FileName(texture);
                        files[recoloured] = Blp.Recolour(Require(client, texture), t < 2 ? glow : rule);
                        swaps[texture] = recoloured;
                    }
                    m2 = SwapTextures(m2, swaps);
                }
                StopFlash(m2);
                ScaleBoxes(m2, BlueScale / jewel.Scale);
                string path = Folder + "Jewel" + jewel.Name;
                files[path + ".m2"] = m2;

                uint[] modelRow = (uint[])templateModel.Clone();
                modelRow[0] = modelId;
                modelRow[2] = models.AddString(path + ".mdx");
                modelRow[Wisps.ModelSoundField] = 0;
                models.Records.Add(modelRow);

                uint[] display = (uint[])templateDisplay.Clone();
                display[0] = displayId;
                display[1] = modelId;
                display[DisplayScaleField] = BitConverter.ToUInt32(BitConverter.GetBytes(1.0f), 0);
                display[6] = display[7] = display[8] = 0;
                displays.Records.Add(display);
            }
        }

        public static void AddTurkey(ClientData client, Dbc displays, Dbc models)
        {
            uint[] templateDisplay = displays.Find(TemplateDisplayId), templateModel = models.Find(TemplateModelId);
            if (templateDisplay == null || templateModel == null)
                throw new InvalidDataException("The blue wisp's rows are not where 1.12 has them.");
            if (displays.Find(TurkeyDisplayId) != null)
                throw new InvalidOperationException("Turkey display " + TurkeyDisplayId + " is taken.");
            uint turkeyModelId = models.ClaimId(TurkeyModelId);
            Require(client, TurkeyModel + ".m2");

            uint[] modelRow = (uint[])templateModel.Clone();
            modelRow[0] = turkeyModelId;
            modelRow[2] = models.AddString(TurkeyModel + ".mdx");
            modelRow[Wisps.ModelSoundField] = 0;
            models.Records.Add(modelRow);

            uint[] display = (uint[])templateDisplay.Clone();
            display[0] = TurkeyDisplayId;
            display[1] = turkeyModelId;
            display[DisplayScaleField] = BitConverter.ToUInt32(BitConverter.GetBytes(1.0f), 0);
            display[6] = display[7] = display[8] = 0;
            displays.Records.Add(display);
        }

        const float TicketLift = 0.25f;

        public static byte[] ReadTicket(ClientData client)
        {
            return Require(client, "World\\Kalimdor\\DireMaul\\ActiveDoodads\\CrystalCorrupter\\CorruptedCrystalShard.m2");
        }

        public static void AddTicket(byte[] shard, IDictionary<string, byte[]> files, Dbc displays)
        {
            if (displays.Find(TicketDisplayId) != null || displays.MaxId() >= TicketDisplayId)
                throw new InvalidOperationException("Game object display " + TicketDisplayId + " is taken.");
            byte[] m2 = (byte[])shard.Clone();
            StandUp(m2, TicketLift);
            string path = Folder + "TicketShard";
            files[path + ".m2"] = m2;

            uint[] row = new uint[displays.FieldCount];
            row[0] = TicketDisplayId;
            row[1] = displays.AddString(path + ".mdx");
            displays.Records.Add(row);
        }

        static byte[] Require(ClientData client, string name)
        {
            byte[] data = client.Read(name);
            if (data == null)
                throw new FileNotFoundException(name + " is not in the client's archives.");
            return data;
        }

        static byte[] SwapTextures(byte[] source, IDictionary<string, string> swaps)
        {
            MemoryStream ms = new MemoryStream();
            ms.Write(source, 0, source.Length);
            byte[] m2 = ms.GetBuffer();
            uint count = BitConverter.ToUInt32(m2, 92), offset = BitConverter.ToUInt32(m2, 96);
            int swapped = 0;
            for (uint i = 0; i < count; i++)
            {
                int entry = (int)(offset + i * 16);
                string name = Encoding.ASCII.GetString(m2, (int)BitConverter.ToUInt32(m2, entry + 12), (int)BitConverter.ToUInt32(m2, entry + 8) - 1);
                string replacement;
                if (!swaps.TryGetValue(name, out replacement))
                    continue;
                ms.Position = ms.Length;
                ms.Write(new byte[(16 - ms.Length % 16) % 16], 0, (int)((16 - ms.Length % 16) % 16));
                uint nameOfs = (uint)ms.Length;
                byte[] bytes = Encoding.ASCII.GetBytes(replacement + "\0");
                ms.Write(bytes, 0, bytes.Length);
                m2 = ms.GetBuffer();
                Put(m2, entry + 8, (uint)bytes.Length);
                Put(m2, entry + 12, nameOfs);
                ++swapped;
            }
            if (swapped != swaps.Count)
                throw new InvalidDataException("The jewel does not name the textures expected.");
            return ms.ToArray();
        }

        const float MaxSwell = 1.25f;

        static void StopFlash(byte[] m2)
        {
            uint bones = BitConverter.ToUInt32(m2, 52), bonesAt = BitConverter.ToUInt32(m2, 56);
            int calmed = 0;
            for (uint i = 0; i < bones; i++)
            {
                int track = (int)(bonesAt + i * 108 + 12 + 2 * 28);
                uint ranges = BitConverter.ToUInt32(m2, track + 4), rangesAt = BitConverter.ToUInt32(m2, track + 8);
                uint keys = BitConverter.ToUInt32(m2, track + 20), values = BitConverter.ToUInt32(m2, track + 24);
                if (ranges == 0 || keys == 0)
                    continue;
                uint first = BitConverter.ToUInt32(m2, (int)rangesAt), last = Math.Min(BitConverter.ToUInt32(m2, (int)rangesAt + 4), keys - 1);
                float rest = BitConverter.ToSingle(m2, (int)(values + first * 12));
                float cap = rest * MaxSwell, floor = rest / MaxSwell;
                for (uint k = first; k <= last; k++)
                    for (int c = 0; c < 3; c++)
                    {
                        int at = (int)(values + k * 12 + c * 4);
                        float scale = BitConverter.ToSingle(m2, at);
                        if (scale > cap || scale < floor)
                        {
                            PutFloat(m2, at, Math.Max(floor, Math.Min(cap, scale)));
                            ++calmed;
                        }
                    }
            }
            if (calmed == 0)
                throw new InvalidDataException("The jewel has no glow swell to calm.");
        }

        static void ScaleBoxes(byte[] m2, float factor)
        {
            uint count = BitConverter.ToUInt32(m2, 28), offset = BitConverter.ToUInt32(m2, 32);
            for (uint i = 0; i < count; i++)
                for (int f = 0; f < 7; f++)
                {
                    int at = (int)(offset + i * 68 + 36 + f * 4);
                    PutFloat(m2, at, BitConverter.ToSingle(m2, at) * factor);
                }
        }

        static void StandUp(byte[] m2, float lift)
        {
            uint bones = BitConverter.ToUInt32(m2, 52), bonesAt = BitConverter.ToUInt32(m2, 56);
            for (uint i = 0; i < bones; i++)
                for (int track = 0; track < 3; track++)
                    if (BitConverter.ToUInt32(m2, (int)(bonesAt + i * 108 + 12 + track * 28 + 20)) != 0)
                        throw new InvalidDataException("The ticket's crystal has animated bones.");

            uint count = BitConverter.ToUInt32(m2, 68), at = BitConverter.ToUInt32(m2, 72);
            float minX = float.MaxValue, minY = float.MaxValue, minZ = float.MaxValue, maxX = float.MinValue, maxY = float.MinValue;
            for (uint i = 0; i < count; i++)
            {
                float[] p = Turned(m2, (int)(at + i * 48));
                minX = Math.Min(minX, p[0]); maxX = Math.Max(maxX, p[0]);
                minY = Math.Min(minY, p[1]); maxY = Math.Max(maxY, p[1]);
                minZ = Math.Min(minZ, p[2]);
            }
            float dx = -(minX + maxX) / 2, dy = -(minY + maxY) / 2, dz = lift - minZ;

            float[] lo = { float.MaxValue, float.MaxValue, float.MaxValue }, hi = { float.MinValue, float.MinValue, float.MinValue };
            for (uint i = 0; i < count; i++)
            {
                int v = (int)(at + i * 48);
                float[] p = Turned(m2, v), n = Turned(m2, v + 32);
                p[0] += dx; p[1] += dy; p[2] += dz;
                Write3(m2, v, p);
                Write3(m2, v + 32, n);
                for (int k = 0; k < 3; k++)
                {
                    lo[k] = Math.Min(lo[k], p[k]);
                    hi[k] = Math.Max(hi[k], p[k]);
                }
            }
            for (uint i = 0; i < bones; i++)
                Move(m2, (int)(bonesAt + i * 108 + 96), dx, dy, dz);
            uint particles = BitConverter.ToUInt32(m2, 316), particlesAt = BitConverter.ToUInt32(m2, 320);
            for (uint i = 0; i < particles; i++)
                Move(m2, (int)(particlesAt + i * 504 + 8), dx, dy, dz);

            float radius = 0;
            for (int k = 0; k < 3; k++)
                radius = Math.Max(radius, Math.Max(Math.Abs(lo[k]), Math.Abs(hi[k])));
            radius *= (float)Math.Sqrt(3);
            uint sequences = BitConverter.ToUInt32(m2, 28), sequencesAt = BitConverter.ToUInt32(m2, 32);
            for (uint i = 0; i < sequences; i++)
                WriteBox(m2, (int)(sequencesAt + i * 68 + 36), lo, hi, radius);
            WriteBox(m2, 180, lo, hi, radius);
        }

        static float[] Turned(byte[] m2, int at)
        {
            float x = BitConverter.ToSingle(m2, at), y = BitConverter.ToSingle(m2, at + 4), z = BitConverter.ToSingle(m2, at + 8);
            return new[] { -z, y, x };
        }

        static void Move(byte[] m2, int at, float dx, float dy, float dz)
        {
            float[] p = Turned(m2, at);
            p[0] += dx; p[1] += dy; p[2] += dz;
            Write3(m2, at, p);
        }

        static void WriteBox(byte[] m2, int at, float[] lo, float[] hi, float radius)
        {
            Write3(m2, at, lo);
            Write3(m2, at + 12, hi);
            PutFloat(m2, at + 24, radius);
        }

        static void Write3(byte[] m2, int at, float[] p)
        {
            for (int k = 0; k < 3; k++)
                PutFloat(m2, at + k * 4, p[k]);
        }

        static void PutFloat(byte[] m2, int at, float value)
        {
            Buffer.BlockCopy(BitConverter.GetBytes(value), 0, m2, at, 4);
        }

        static void Put(byte[] m2, int at, uint value)
        {
            Buffer.BlockCopy(BitConverter.GetBytes(value), 0, m2, at, 4);
        }
    }
}
