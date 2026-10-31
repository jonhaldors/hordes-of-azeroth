using System;
using System.Collections.Generic;
using System.IO;

namespace BonkTelegraphs
{
    static class Projectiles
    {
        public const uint FirstDisplayId = 18002;
        const uint FirstModelId = 2502;
        public const uint FirstEnemyDisplayId = 18600;
        const uint FirstEnemyModelId = 2700;
        const uint TemplateDisplayId = 16587;
        const uint TemplateModelId = 2268;
        const string CopyFolder = "Creature\\BonkMissile\\";
        const ushort StandId = 0, InFlightId = 144;

        static readonly string[,] Missiles =
        {
            { "Frostbolt",     "Spells\\Frostbolt" },
            { "Fireball",      "Spells\\Fireball_Missile_Low" },
            { "Pyroblast",     "Spells\\PyroBlast_Missile" },
            { "FireBolt",      "Spells\\FireBolt_Missile_Low" },
            { "ArcaneMissile", "Spells\\Arcane_Missile_Lvl1" },
            { "ShadowBolt",    "Spells\\DeathCoil_Missile" },
            { "ArcaneShot",    "Spells\\ArcaneShot_Missile" },
            { "MultiShot",     "Spells\\MultiShot_Missile" },
            { "PoisonShot",    "Spells\\PoisonShot_Missile" },
            { "ThrownAxe",     "Spells\\missile_axe_copper" },
        };

        static readonly string[,] EnemyMissiles =
        {
            { "LightningBolt", "Spells\\LightningBolt_Missile" },
            { "Boulder",       "Spells\\Boulder_Missile" },
            { "GooBolt",       "Spells\\GooBolt_Missile_Low" },
        };

        public static List<string> AddProjectiles(ClientData client, IDictionary<string, byte[]> files, Dbc displays, Dbc models)
        {
            return AddMissiles(client, files, displays, models, Missiles, FirstDisplayId, FirstModelId);
        }

        public static List<string> AddEnemyMissiles(ClientData client, IDictionary<string, byte[]> files, Dbc displays, Dbc models)
        {
            return AddMissiles(client, files, displays, models, EnemyMissiles, FirstEnemyDisplayId, FirstEnemyModelId);
        }

        static List<string> AddMissiles(ClientData client, IDictionary<string, byte[]> files, Dbc displays, Dbc models, string[,] missiles,
            uint firstDisplayId, uint firstModelId)
        {
            uint[] templateDisplay = displays.Find(TemplateDisplayId), templateModel = models.Find(TemplateModelId);
            if (templateDisplay == null || templateModel == null)
                throw new InvalidDataException("The rows projectiles copy are not where 1.12 has them.");

            List<string> manifest = new List<string>();
            uint one = BitConverter.ToUInt32(BitConverter.GetBytes(1.0f), 0);
            for (int i = 0; i < missiles.GetLength(0); i++)
            {
                string name = missiles[i, 0], path = missiles[i, 1];
                uint displayId = firstDisplayId + (uint)i;
                if (displays.Find(displayId) != null)
                    throw new InvalidOperationException("Creature display " + displayId + " is taken.");
                uint modelId = models.ClaimId(firstModelId + (uint)i);

                byte[] source = client.Read(path + ".m2");
                if (source == null)
                    throw new FileNotFoundException(path + ".m2 is not in the client's archives.");
                byte[] inFlight = PlayInFlight(source, path);
                if (inFlight != null)
                {
                    path = CopyFolder + name;
                    files[path + ".m2"] = inFlight;
                }

                uint[] model = (uint[])templateModel.Clone();
                model[0] = modelId;
                model[2] = models.AddString(path + ".mdx");
                model[4] = one;
                model[13] = 0;
                models.Records.Add(model);

                uint[] display = (uint[])templateDisplay.Clone();
                display[0] = displayId;
                display[1] = modelId;
                display[2] = 0;
                display[4] = one;
                display[6] = display[7] = display[8] = 0;
                display[11] = 0;
                displays.Records.Add(display);

                manifest.Add(name + (inFlight != null ? " (plays InFlight)" : ""));
            }
            return manifest;
        }

        static byte[] PlayInFlight(byte[] source, string path)
        {
            if (BitConverter.ToUInt32(source, 4) != 256)
                throw new InvalidDataException(path + " is not a version 256 model.");
            uint count = BitConverter.ToUInt32(source, 0x1C), offset = BitConverter.ToUInt32(source, 0x20);
            int stand = -1, inFlight = -1;
            for (int i = 0; i < count; i++)
            {
                ushort id = BitConverter.ToUInt16(source, (int)(offset + i * 68));
                if (id == StandId && stand < 0)
                    stand = i;
                else if (id == InFlightId && inFlight < 0)
                    inFlight = i;
            }
            if (inFlight < 0)
                return null;
            uint lookupCount = BitConverter.ToUInt32(source, 0x24), lookupOfs = BitConverter.ToUInt32(source, 0x28);
            if (stand < 0 || lookupCount == 0)
                throw new InvalidDataException(path + " has an InFlight sequence but no Stand to replace.");

            byte[] m2 = (byte[])source.Clone();
            Buffer.BlockCopy(BitConverter.GetBytes((short)inFlight), 0, m2, (int)lookupOfs, 2);
            int from = (int)(offset + stand * 68), to = (int)(offset + inFlight * 68);
            Buffer.BlockCopy(source, from + 16, m2, to + 16, 4);
            Buffer.BlockCopy(source, from + 20, m2, to + 20, 2);
            Buffer.BlockCopy(source, from + 24, m2, to + 24, 8);
            return m2;
        }
    }
}
