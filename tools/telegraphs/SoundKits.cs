using System;
using System.Collections.Generic;
using System.IO;

namespace BonkTelegraphs
{
    static class SoundKits
    {
        const int KitSoundField = 13;
        const int KitShakeField = 14;
        const int KitAnimationField = 2;
        const int FirstModelField = 3;
        const int LastModelField = 12;
        const uint NoValue = uint.MaxValue;
        const uint SoundOnlyTemplateKit = 563;

        struct SoundKit
        {
            public uint KitId;
            public uint SoundId;
            public uint ShakeId;
            public string Use;
        }

        static readonly SoundKit[] Kits =
        {
            new SoundKit { KitId = 7500, SoundId = 3324, Use = "Smoke Bomb lands (Vanish)" },
            new SoundKit { KitId = 7501, SoundId = 4295, Use = "Caltrops scatter (DaggerThrowHit)" },
            new SoundKit { KitId = 7502, SoundId = 3323, Use = "Cheap Shot stuns (KidneyShot)" },
            new SoundKit { KitId = 7503, SoundId = 3076, Use = "Frost Trap springs (FrostNova)" },
            new SoundKit { KitId = 7504, SoundId = 2579, Use = "Treants sprout (EntanglingRoots)" },
            new SoundKit { KitId = 7505, SoundId = 1151, Use = "dagger strike lands (Dagger1H_ArmorFlesh)" },
            new SoundKit { KitId = 7506, SoundId = 143, Use = "one-hand sword strike lands (Sword1H_ArmorFlesh)" },
            new SoundKit { KitId = 7507, SoundId = 129, Use = "two-hand sword strike lands (Sword2H_ArmorFlesh)" },
            new SoundKit { KitId = 7508, SoundId = 171, Use = "one-hand axe strike lands (Axe1H_ArmorFlesh)" },
            new SoundKit { KitId = 7509, SoundId = 157, Use = "two-hand axe or polearm strike lands (Axe2H_ArmorFlesh)" },
            new SoundKit { KitId = 7510, SoundId = 941, Use = "one-hand mace strike lands (Mace1H_ArmorFlesh)" },
            new SoundKit { KitId = 7511, SoundId = 955, Use = "two-hand mace or staff strike lands (Mace2H_ArmorFlesh)" },
            new SoundKit { KitId = 7512, SoundId = 1014, Use = "unarmed or fist strike lands (Unarmed_Generic)" },
            new SoundKit { KitId = 7513, ShakeId = 3, Use = "light camera shake (Thunder Clap's)" },
            new SoundKit { KitId = 7514, ShakeId = 4, Use = "heavy camera shake (Shockwave's)" },
        };

        public static List<string> AddSoundKits(Dbc kits)
        {
            uint[] template = kits.Find(SoundOnlyTemplateKit);
            if (template == null || !IsSoundOnly(template))
                throw new InvalidDataException("Spell visual kit " + SoundOnlyTemplateKit + " is not a sound-only kit.");

            List<string> manifest = new List<string>();
            foreach (SoundKit sound in Kits)
            {
                if (kits.Find(sound.KitId) != null)
                    throw new InvalidOperationException("Spell visual kit " + sound.KitId + " is taken.");
                uint[] kit = (uint[])template.Clone();
                kit[0] = sound.KitId;
                kit[KitSoundField] = sound.SoundId;
                kit[KitShakeField] = sound.ShakeId;
                kits.Records.Add(kit);
                manifest.Add(string.Format("kit {0}: sound {1}, shake {2}, nothing else: {3}", sound.KitId, sound.SoundId, sound.ShakeId, sound.Use));
            }
            return manifest;
        }

        static bool IsSoundOnly(uint[] kit)
        {
            if (kit[KitAnimationField] != NoValue)
                return false;
            for (int field = FirstModelField; field <= LastModelField; ++field)
                if (kit[field] != 0 && kit[field] != NoValue)
                    return false;
            return true;
        }
    }
}
