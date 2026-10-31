using System;
using System.Collections.Generic;
using System.IO;
using System.Text;

namespace BonkTelegraphs
{
    static class Wisps
    {
        public const uint GreenDisplayId = 18000;
        public const uint RedDisplayId = 18001;
        public const uint PurpleDisplayId = 17999;
        public const uint BlueOrbDisplayId = 17998;
        const float DustRate = 0.4f;
        const uint BlueDisplayId = 10045;
        const uint BlueModelId = 207;
        const float BlueScale = 0.35f;
        const int DisplayScaleField = 4;
        public const int ModelSoundField = 13;

        const string Folder = "Creature\\Wisp\\";

        class Colour
        {
            public string Name;
            public uint DisplayId;
            public uint ModelId;
            public float Scale;
            public ColourRule Rule;
        }

        static readonly Colour[] Colours =
        {
            new Colour { Name = "Blue",   DisplayId = BlueOrbDisplayId, ModelId = 2498, Scale = 0.35f, Rule = Blue },
        };

        public static void AddWisps(ClientData client, IDictionary<string, byte[]> files, Dbc displays, Dbc models)
        {
            uint[] blueDisplay = displays.Find(BlueDisplayId), blueModel = models.Find(BlueModelId);
            if (blueDisplay == null || blueModel == null || blueDisplay[1] != BlueModelId)
                throw new InvalidDataException("The blue wisp's rows are not where 1.12 has them.");

            byte[] wisp = Require(client, Folder + "Wisp.m2");
            byte[] glow = Require(client, Folder + "WispGlow.blp"), skin = Require(client, Folder + "Wisp.blp");
            foreach (Colour colour in Colours)
            {
                if (displays.Find(colour.DisplayId) != null)
                    throw new InvalidOperationException("Creature display " + colour.DisplayId + " is taken.");
                uint modelId = models.ClaimId(colour.ModelId);

                string name = "WispOrb" + colour.Name;
                Dictionary<string, string> textures = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase)
                {
                    { Folder + "WispGlow.blp", Folder + name + "Glow.blp" },
                    { Folder + "Wisp.blp", Folder + name + ".blp" },
                };
                files[Folder + name + "Glow.blp"] = Blp.Recolour(glow, colour.Rule);
                files[Folder + name + ".blp"] = Blp.Recolour(skin, colour.Rule);
                files[Folder + name + ".m2"] = Recolour(wisp, textures, colour.Rule, BlueScale / colour.Scale);

                uint[] model = (uint[])blueModel.Clone();
                model[0] = modelId;
                model[2] = models.AddString(Folder + name + ".mdx");
                model[ModelSoundField] = 0;
                models.Records.Add(model);

                uint[] display = (uint[])blueDisplay.Clone();
                display[0] = colour.DisplayId;
                display[1] = modelId;
                display[DisplayScaleField] = BitConverter.ToUInt32(BitConverter.GetBytes(1.0f), 0);
                displays.Records.Add(display);
            }
        }

        static byte[] Require(ClientData client, string name)
        {
            byte[] data = client.Read(name);
            if (data == null)
                throw new FileNotFoundException(name + " is not in the client's archives.");
            return data;
        }

        public static void Blue(ref float r, ref float g, ref float b)
        {
        }

        public static void Green(ref float r, ref float g, ref float b)
        {
            float max = Math.Max(r, Math.Max(g, b)), min = Math.Min(r, Math.Min(g, b));
            r = min;
            g = max;
            b = min;
        }

        public static void Red(ref float r, ref float g, ref float b)
        {
            float max = Math.Max(r, Math.Max(g, b)), min = Math.Min(r, Math.Min(g, b));
            r = max;
            g = min;
            b = min;
        }

        public static void Purple(ref float r, ref float g, ref float b)
        {
            float max = Math.Max(r, Math.Max(g, b)), min = Math.Min(r, Math.Min(g, b));
            r = min + 0.6f * (max - min);
            g = min;
            b = max;
        }

        static byte[] Recolour(byte[] source, IDictionary<string, string> textures, ColourRule rule, float boxScale)
        {
            MemoryStream ms = new MemoryStream();
            ms.Write(source, 0, source.Length);
            byte[] m2 = ms.GetBuffer();
            if (BitConverter.ToUInt32(m2, 4) != 256)
                throw new InvalidDataException("Wisp.m2 is not a version 256 model.");

            uint count = BitConverter.ToUInt32(m2, 92), offset = BitConverter.ToUInt32(m2, 96);
            int swapped = 0;
            for (uint i = 0; i < count; i++)
            {
                int entry = (int)(offset + i * 16);
                string name = Encoding.ASCII.GetString(m2, (int)BitConverter.ToUInt32(m2, entry + 12),
                    (int)BitConverter.ToUInt32(m2, entry + 8) - 1);
                string recoloured;
                if (!textures.TryGetValue(name, out recoloured))
                    continue;
                ms.Position = ms.Length;
                ms.Write(new byte[(16 - ms.Length % 16) % 16], 0, (int)((16 - ms.Length % 16) % 16));
                uint nameOfs = (uint)ms.Length;
                byte[] bytes = Encoding.ASCII.GetBytes(recoloured + "\0");
                ms.Write(bytes, 0, bytes.Length);
                m2 = ms.GetBuffer();
                WriteUInt32(m2, entry + 8, (uint)bytes.Length);
                WriteUInt32(m2, entry + 12, nameOfs);
                ++swapped;
            }
            if (swapped != textures.Count)
                throw new InvalidDataException("Wisp.m2 does not name the textures expected.");

            count = BitConverter.ToUInt32(m2, 28);
            offset = BitConverter.ToUInt32(m2, 32);
            for (uint i = 0; i < count; i++)
            {
                int sequence = (int)(offset + i * 68);
                for (int f = 0; f < 7; f++)
                {
                    int at = sequence + 36 + f * 4;
                    Buffer.BlockCopy(BitConverter.GetBytes(BitConverter.ToSingle(m2, at) * boxScale), 0, m2, at, 4);
                }
            }

            count = BitConverter.ToUInt32(m2, 84);
            offset = BitConverter.ToUInt32(m2, 88);
            for (uint i = 0; i < count; i++)
                RecolourTrack(m2, (int)(offset + i * 56), rule);

            count = BitConverter.ToUInt32(m2, 308);
            offset = BitConverter.ToUInt32(m2, 312);
            for (uint i = 0; i < count; i++)
            {
                int ribbon = (int)(offset + i * 220);
                if (BitConverter.ToInt32(m2, ribbon) != -1)
                    throw new InvalidDataException("Wisp.m2's ribbons are not laid out as expected.");
                RecolourTrack(m2, ribbon + 36, rule);
            }

            count = BitConverter.ToUInt32(m2, 316);
            offset = BitConverter.ToUInt32(m2, 320);
            int thinned = 0;
            uint leadingDust = 0;
            for (uint i = 0; i < count; i++)
            {
                int particle = (int)(offset + i * 504);
                if (BitConverter.ToInt32(m2, particle) != -1)
                    throw new InvalidDataException("Wisp.m2's particles are not laid out as expected.");
                int texture = (int)(BitConverter.ToUInt32(m2, 96) + BitConverter.ToUInt16(m2, particle + 22) * 16);
                string textureName = Encoding.ASCII.GetString(m2, (int)BitConverter.ToUInt32(m2, texture + 12),
                    (int)BitConverter.ToUInt32(m2, texture + 8) - 1);
                bool dust = textureName.IndexOf("\\DUST", StringComparison.OrdinalIgnoreCase) >= 0;
                if (dust && leadingDust == i)
                {
                    ++leadingDust;
                    int rate = particle + 52 + 6 * 28;
                    uint keys = BitConverter.ToUInt32(m2, rate + 20), values = BitConverter.ToUInt32(m2, rate + 24);
                    for (uint k = 0; k < keys; k++)
                    {
                        int at = (int)(values + k * 4);
                        Buffer.BlockCopy(BitConverter.GetBytes(BitConverter.ToSingle(m2, at) * DustRate), 0, m2, at, 4);
                    }
                    ++thinned;
                }
                for (int c = 0; c < 3; c++)
                {
                    int bgra = particle + 336 + c * 4;
                    float b = m2[bgra] / 255f, g = m2[bgra + 1] / 255f, r = m2[bgra + 2] / 255f;
                    rule(ref r, ref g, ref b);
                    m2[bgra] = (byte)Math.Round(b * 255);
                    m2[bgra + 1] = (byte)Math.Round(g * 255);
                    m2[bgra + 2] = (byte)Math.Round(r * 255);
                }
            }
            if (thinned == 0)
                throw new InvalidDataException("Wisp.m2 has no dust emitters to thin.");
            WriteUInt32(m2, 316, leadingDust);
            return ms.ToArray();
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
