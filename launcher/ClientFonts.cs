using System;
using System.Collections.Concurrent;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Reflection;
using Avalonia.Media;
using Avalonia.Media.Fonts;
using Avalonia.Platform;
using BonkTelegraphs;

namespace HordesOfAzeroth.Launcher
{
    static class ClientFonts
    {
        const string CollectionKey = "fonts:client";
        const string Fallback = "Georgia, serif";

        public static FontFamily Title { get; private set; } = new FontFamily(Fallback);
        public static FontFamily Body { get; private set; } = new FontFamily(Fallback);

        public static void Load(GameFolder folder)
        {
            string archive = GameFiles.Child(folder.Data, "fonts.MPQ");
            if (!File.Exists(archive))
                return;
            try
            {
                byte[] title, body;
                using (MpqReader reader = new MpqReader(archive))
                {
                    title = reader.Read("Fonts\\MORPHEUS.TTF");
                    body = reader.Read("Fonts\\FRIZQT__.TTF");
                }
                FileFontCollection collection = new FileFontCollection(new Uri(CollectionKey), new[] { title, body }.Where(f => f != null));
                FontManager.Current.AddFontCollection(collection);
                Title = Family(collection, 0);
                Body = Family(collection, 1);
            }
            catch (Exception e) when (e is IOException || e is UnauthorizedAccessException || e is InvalidDataException || e is InvalidOperationException)
            {
            }
        }

        static FontFamily Family(FileFontCollection collection, int index) =>
            index < collection.Count ? new FontFamily($"{CollectionKey}#{collection[index].Name}, {Fallback}") : new FontFamily(Fallback);

        sealed class FileFontCollection : FontCollectionBase
        {
            readonly Uri m_key;
            readonly List<byte[]> m_fonts;
            readonly List<FontFamily> m_families = new List<FontFamily>();

            public FileFontCollection(Uri key, IEnumerable<byte[]> fonts)
            {
                m_key = key;
                m_fonts = fonts.ToList();
            }

            public override Uri Key => m_key;

            public override int Count => m_families.Count;

            public override FontFamily this[int index] => m_families[index];

            public override void Initialize(IFontManagerImpl fontManager)
            {
                foreach (byte[] font in m_fonts)
                {
                    IGlyphTypeface glyph = Create(fontManager, font);
                    if (glyph == null)
                        continue;
                    ConcurrentDictionary<FontCollectionKey, IGlyphTypeface> faces =
                        _glyphTypefaceCache.GetOrAdd(glyph.FamilyName, _ => new ConcurrentDictionary<FontCollectionKey, IGlyphTypeface>());
                    faces.TryAdd(new FontCollectionKey(glyph.Style, glyph.Weight, glyph.Stretch), glyph);
                    m_families.Add(new FontFamily(m_key, glyph.FamilyName));
                }
            }

            static IGlyphTypeface Create(IFontManagerImpl fontManager, byte[] font)
            {
                MethodInfo create = typeof(IFontManagerImpl).GetMethod("TryCreateGlyphTypeface",
                    new[] { typeof(Stream), typeof(FontSimulations), typeof(IGlyphTypeface).MakeByRefType() });
                object[] arguments = { new MemoryStream(font), FontSimulations.None, null };
                return create != null && (bool)create.Invoke(fontManager, arguments) ? (IGlyphTypeface)arguments[2] : null;
            }

            public override bool TryGetGlyphTypeface(string familyName, FontStyle style, FontWeight weight, FontStretch stretch, out IGlyphTypeface glyphTypeface)
            {
                glyphTypeface = null;
                if (!_glyphTypefaceCache.TryGetValue(familyName, out ConcurrentDictionary<FontCollectionKey, IGlyphTypeface> faces) || faces.IsEmpty)
                    return false;
                if (!faces.TryGetValue(new FontCollectionKey(style, weight, stretch), out glyphTypeface))
                    glyphTypeface = faces.Values.First();
                return true;
            }

            public override IEnumerator<FontFamily> GetEnumerator() => m_families.GetEnumerator();
        }
    }
}
