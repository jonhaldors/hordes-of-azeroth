using System;
using System.IO;

namespace BonkTelegraphs
{
    static class Program
    {
        static int Main(string[] args)
        {
            try
            {
                if (args.Length >= 2 && args[0] == "build")
                {
                    Kit.Build(args[1]);
                    return 0;
                }
                if (args.Length >= 2 && args[0] == "check")
                {
                    using (MpqReader patch = new MpqReader(Path.Combine(args[1], "Data", Kit.PatchName)))
                    {
                        string list = System.Text.Encoding.ASCII.GetString(patch.Read("(listfile)"));
                        foreach (string name in list.Split(new[] { '\r', '\n' }, StringSplitOptions.RemoveEmptyEntries))
                            Console.WriteLine("{0,8}  {1}", patch.Read(name).Length, name);
                        Dump.M2(patch.Read("World\\Generic\\BonkTelegraph\\CircleFill2000.m2"));
                        Dump.Blp(patch.Read("World\\Generic\\BonkTelegraph\\CircleOutline.blp"));
                        Dbc dbc = new Dbc(patch.Read("DBFilesClient\\GameObjectDisplayInfo.dbc"));
                        uint[] row = dbc.Find(7000);
                        Console.WriteLine("rows {0}, 7000 -> {1}", dbc.Records.Count, row == null ? "missing" : dbc.GetString(row[1]));

                        using (ClientData client = new ClientData(Path.Combine(args[1], "Data"), Kit.OwnPatches))
                        {
                            byte[] beforeBytes = client.Read("DBFilesClient\\Spell.dbc"), afterBytes = patch.Read("DBFilesClient\\Spell.dbc");
                            Dbc before = new Dbc(beforeBytes), after = new Dbc(afterBytes);
                            int changed = 0;
                            for (int i = 0; i < before.Records.Count; i++)
                                for (int f = 0; f < before.FieldCount; f++)
                                    if (before.Records[i][f] != after.Records[i][f])
                                    {
                                        ++changed;
                                        Console.WriteLine("Spell {0} field {1}: {2} -> {3}", before.Records[i][0], f, before.Records[i][f], after.Records[i][f]);
                                    }
                            Console.WriteLine("Spell.dbc: {0} rows (was {1}), {2} bytes (was {3}), {4} fields changed",
                                after.Records.Count, before.Records.Count, afterBytes.Length, beforeBytes.Length, changed);
                            Dbc visuals = new Dbc(patch.Read("DBFilesClient\\SpellVisual.dbc")), kits = new Dbc(patch.Read("DBFilesClient\\SpellVisualKit.dbc"));
                            uint[] spell = after.Find(116), visual = visuals.Find(spell[115]), kit = kits.Find(visual[2]);
                            Console.WriteLine("Frostbolt: visual {0}, missile {1}, cast kit {2}, animation {3}, sound {4}",
                                spell[115], visual[7], visual[2], (int)kit[2], kit[13]);
                        }
                    }
                    return 0;
                }
                if (args.Length >= 3 && args[0] == "preview")
                {
                    using (MpqReader patch = new MpqReader(Path.Combine(args[1], "Data", Kit.PatchName)))
                        foreach (string name in new[] { "CircleOutline", "CircleFill", "ConeOutline", "ConeFill", "LineOutline", "LineFill" })
                            Preview.Save(patch.Read("World\\Generic\\BonkTelegraph\\" + name + ".blp"), Path.Combine(args[2], name + ".png"));
                    return 0;
                }
                if (args.Length >= 3 && args[0] == "list")
                {
                    Dump.List(args[1], args[2]);
                    return 0;
                }
                if (args.Length >= 3)
                {
                    using (ClientData client = new ClientData(Path.Combine(args[1], "Data"), Kit.OwnPatches))
                    {
                        byte[] data = client.Read(args[2]);
                        if (data == null)
                        {
                            Console.Error.WriteLine("Not found: " + args[2]);
                            return 1;
                        }
                        if (args[0] == "m2")
                            Dump.M2(data);
                        else if (args[0] == "blp")
                            Dump.Blp(data);
                        else if (args[0] == "hex" && args.Length >= 5)
                            Dump.Hex(data, int.Parse(args[3]), int.Parse(args[4]));
                        else if (args[0] == "save" && args.Length >= 4)
                            File.WriteAllBytes(args[3], data);
                        else if (args[0] == "row" && args.Length >= 4)
                        {
                            Dbc dbc = new Dbc(data);
                            uint[] row = dbc.Find(uint.Parse(args[3]));
                            Console.WriteLine(row == null ? "No such row." : string.Join(" ", Array.ConvertAll(row, v => v.ToString())));
                            if (row != null)
                                foreach (uint v in row)
                                    if (v > 0 && v < 4000000 && dbc.GetString(v).Length > 3)
                                        Console.WriteLine("  {0}: {1}", v, dbc.GetString(v));
                            Console.WriteLine("max id {0}, {1} rows", dbc.MaxId(), dbc.Records.Count);
                        }
                        return 0;
                    }
                }
                Console.Error.WriteLine("Usage: TelegraphKit build|list|m2|blp|hex|save ...");
                return 1;
            }
            catch (Exception e)
            {
                Console.Error.WriteLine(e);
                Console.Error.WriteLine(e.GetType().Name + ": " + e.Message);
                return 1;
            }
        }
    }
}
