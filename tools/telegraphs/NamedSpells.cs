using System;
using System.Collections.Generic;
using System.IO;

namespace BonkTelegraphs
{
    static class NamedSpells
    {
        const int SpellIconField = 117, NameField = 120;
        const int IconPathField = 1;

        sealed class NamedSpell
        {
            public uint SpellId;
            public uint CopyOf;
            public string Name;
            public string Icon;
        }

        static readonly NamedSpell[] Spells =
        {
            new NamedSpell { SpellId = 33700, CopyOf = 24239, Name = "Avenger's Shield", Icon = "Spell_Holy_SealOfProtection" },
            new NamedSpell { SpellId = 33701, CopyOf = 8246, Name = "Maelstrom Weapon", Icon = "Spell_Nature_Lightning" },
            new NamedSpell { SpellId = 33702, CopyOf = 25809, Name = "Viper Trap", Icon = "INV_Misc_MonsterFang_01" },
        };

        public static List<string> AddNamedSpells(Dbc spells, Dbc icons)
        {
            List<string> manifest = new List<string>();
            foreach (NamedSpell named in Spells)
            {
                uint[] source = spells.Find(named.CopyOf);
                if (source == null)
                    throw new InvalidDataException("Spell " + named.CopyOf + " is not in Spell.dbc.");
                if (spells.Find(named.SpellId) != null)
                    throw new InvalidOperationException("Spell " + named.SpellId + " is taken.");
                uint[] spell = (uint[])source.Clone();
                spell[0] = named.SpellId;
                spell[NameField] = spells.AddString(named.Name);
                spell[SpellIconField] = FindIcon(icons, named.Icon);
                spells.Records.Add(spell);
                manifest.Add(string.Format("spell {0} ({1}): copy of {2} under its own name", named.SpellId, named.Name, named.CopyOf));
            }
            return manifest;
        }

        static uint FindIcon(Dbc icons, string name)
        {
            string suffix = "\\" + name;
            foreach (uint[] icon in icons.Records)
                if (icons.GetString(icon[IconPathField]).EndsWith(suffix, StringComparison.OrdinalIgnoreCase))
                    return icon[0];
            throw new InvalidDataException("Icon " + name + " is not in SpellIcon.dbc.");
        }
    }
}
