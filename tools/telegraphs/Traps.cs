using System;
using System.Collections.Generic;
using System.IO;

namespace BonkTelegraphs
{
    static class Traps
    {
        public const uint FirstDisplayId = 17986;
        const uint FirstModelId = 2486;
        const uint TemplateDisplayId = 16587;
        const uint TemplateModelId = 2268;
        const ushort SprungAnim = 153;
        const string Goober = "World\\Goober\\";
        const string Folder = "World\\Goober\\BonkTraps\\";
        static readonly string[] Names = { "ExplosiveTrap", "FrostTrap" };

        public static void AddTraps(ClientData client, IDictionary<string, byte[]> files, Dbc displays, Dbc models)
        {
            uint[] templateDisplay = displays.Find(TemplateDisplayId), templateModel = models.Find(TemplateModelId);
            if (templateDisplay == null || templateModel == null)
                throw new InvalidDataException("The rows trap looks copy are not where 1.12 has them.");

            uint displayId = FirstDisplayId, modelId = FirstModelId;
            foreach (string name in Names)
            {
                string source = Goober + "G_" + name;
                byte[] m2 = client.Read(source + ".m2");
                if (m2 == null)
                    throw new FileNotFoundException(source + ".m2 is not in the client's archives.");

                AddLook(displays, models, templateDisplay, templateModel, displayId++, modelId++, source);

                byte[] sprung = (byte[])m2.Clone();
                SetStandFallback(sprung, SprungAnim);
                string path = Folder + name + "Sprung";
                files[path + ".m2"] = sprung;
                AddLook(displays, models, templateDisplay, templateModel, displayId++, modelId++, path);
            }
        }

        static void AddLook(Dbc displays, Dbc models, uint[] templateDisplay, uint[] templateModel, uint displayId, uint modelId, string path)
        {
            displays.Release(displayId);
            modelId = models.ClaimId(modelId);

            uint[] model = (uint[])templateModel.Clone();
            model[0] = modelId;
            model[2] = models.AddString(path + ".mdx");
            model[4] = BitConverter.ToUInt32(BitConverter.GetBytes(1f), 0);
            model[13] = 0;
            models.Records.Add(model);

            uint[] display = (uint[])templateDisplay.Clone();
            display[0] = displayId;
            display[1] = modelId;
            display[2] = 0;
            display[4] = BitConverter.ToUInt32(BitConverter.GetBytes(1f), 0);
            display[6] = display[7] = display[8] = 0;
            display[11] = 0;
            displays.Records.Add(display);
        }

        static void SetStandFallback(byte[] m2, ushort anim)
        {
            uint count = BitConverter.ToUInt32(m2, 0x2C), offset = BitConverter.ToUInt32(m2, 0x30);
            uint lookupCount = BitConverter.ToUInt32(m2, 0x24), lookupOffset = BitConverter.ToUInt32(m2, 0x28);
            if (count == 0 || anim >= lookupCount || BitConverter.ToInt16(m2, (int)(lookupOffset + 2 * anim)) < 0)
                throw new InvalidDataException("The trap model has no animation " + anim + " to spring with.");
            BitConverter.GetBytes(anim).CopyTo(m2, (int)offset);
            BitConverter.GetBytes((ushort)0).CopyTo(m2, (int)offset + 2);
        }
    }
}
