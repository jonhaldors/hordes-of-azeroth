using System;
using System.Collections.Generic;
using System.Globalization;
using System.IO;

namespace BonkTelegraphs
{
    static class StandIns
    {
        public const uint FirstDisplayId = 18012;
        const uint FirstModelId = 2512;
        const uint FirstSizedModelId = 3000;
        const uint TemplateDisplayId = 16587;
        const uint TemplateModelId = 2268;
        const string Folder = "World\\Generic\\BonkTelegraph\\";

        static readonly string[] SizedShapes = { "Circle", "Cone" };
        public static readonly float[] Sizes = { 1f, 1.5f, 2f, 2.5f, 3f, 3.5f, 4f, 4.5f, 5f, 5.5f, 6f, 6.5f, 7f, 7.5f, 8f, 9f, 10f, 11f, 12f, 13f, 14f, 15f };

        public static int AddStandIns(Dbc displays, Dbc models)
        {
            uint[] templateDisplay = displays.Find(TemplateDisplayId), templateModel = models.Find(TemplateModelId);
            if (templateDisplay == null || templateModel == null)
                throw new InvalidDataException("The rows stand-ins copy are not where 1.12 has them.");

            uint displayId = FirstDisplayId, modelId = FirstModelId, sizedModelId = FirstSizedModelId;
            foreach (string shape in SizedShapes)
            {
                List<string> names = new List<string> { shape + "Outline" };
                foreach (uint ms in Kit.FillMs)
                    names.Add(shape + "Fill" + ms);
                foreach (string name in names)
                    foreach (float size in Sizes)
                        AddDisplay(displays, templateDisplay, displayId++, AddModel(models, templateModel, sizedModelId++, SizedName(name, size)), 1f);
            }

            List<string> lineNames = new List<string> { "LineOutline", "LineStartOutline", "LineEndOutline" };
            foreach (uint ms in Kit.LinePieceFillMs)
                for (int piece = 0; piece < Kit.LineMaxPieces; piece++)
                    lineNames.Add("LineFill" + ms + "_" + piece);
            foreach (string name in lineNames)
                AddDisplay(displays, templateDisplay, displayId++, AddModel(models, templateModel, modelId++, name), 1f);

            return (int)(displayId - FirstDisplayId);
        }

        public static string SizedName(string name, float size)
        {
            return name + "_" + size.ToString("0.#", CultureInfo.InvariantCulture).Replace('.', '_');
        }

        public static void AddSizedDisplay(Dbc displays, Dbc models, uint displayId, uint modelId, string name)
        {
            uint[] templateDisplay = displays.Find(TemplateDisplayId), templateModel = models.Find(TemplateModelId);
            if (templateDisplay == null || templateModel == null)
                throw new InvalidDataException("The rows stand-ins copy are not where 1.12 has them.");
            AddDisplay(displays, templateDisplay, displayId, AddModel(models, templateModel, modelId, name), 1f);
        }

        static uint AddModel(Dbc models, uint[] template, uint modelId, string name)
        {
            modelId = models.ClaimId(modelId);
            uint[] model = (uint[])template.Clone();
            model[0] = modelId;
            model[2] = models.AddString(Folder + name + ".mdx");
            model[4] = BitConverter.ToUInt32(BitConverter.GetBytes(1f), 0);
            model[13] = 0;
            models.Records.Add(model);
            return modelId;
        }

        static void AddDisplay(Dbc displays, uint[] template, uint displayId, uint modelId, float size)
        {
            if (displays.Find(displayId) != null)
                throw new InvalidOperationException("Creature display " + displayId + " is taken.");
            uint[] display = (uint[])template.Clone();
            display[0] = displayId;
            display[1] = modelId;
            display[2] = 0;
            display[4] = BitConverter.ToUInt32(BitConverter.GetBytes(size), 0);
            display[6] = display[7] = display[8] = 0;
            display[11] = 0;
            displays.Records.Add(display);
        }
    }
}
