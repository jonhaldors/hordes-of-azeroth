using System;
using System.Collections.Generic;
using System.IO;
using System.IO.Compression;
using System.Text;

namespace BonkTelegraphs
{
    static class MpqCrypt
    {
        static readonly uint[] Table = BuildTable();

        static uint[] BuildTable()
        {
            uint[] table = new uint[0x500];
            uint seed = 0x00100001;
            for (uint index1 = 0; index1 < 0x100; index1++)
            {
                uint index2 = index1;
                for (int i = 0; i < 5; i++, index2 += 0x100)
                {
                    seed = (seed * 125 + 3) % 0x2AAAAB;
                    uint high = (seed & 0xFFFF) << 16;
                    seed = (seed * 125 + 3) % 0x2AAAAB;
                    table[index2] = high | (seed & 0xFFFF);
                }
            }
            return table;
        }

        public static uint Hash(string name, uint hashType)
        {
            uint seed1 = 0x7FED7FED, seed2 = 0xEEEEEEEE;
            foreach (char c in name.Replace('/', '\\').ToUpperInvariant())
            {
                uint ch = c;
                seed1 = Table[(hashType << 8) + ch] ^ (seed1 + seed2);
                seed2 = ch + seed1 + seed2 + (seed2 << 5) + 3;
            }
            return seed1;
        }

        public static void Decrypt(uint[] data, uint key)
        {
            uint seed = 0xEEEEEEEE;
            for (int i = 0; i < data.Length; i++)
            {
                seed += Table[0x400 + (key & 0xFF)];
                uint plain = data[i] ^ (key + seed);
                key = ((~key << 21) + 0x11111111) | (key >> 11);
                seed = plain + seed + (seed << 5) + 3;
                data[i] = plain;
            }
        }

        public static void Encrypt(uint[] data, uint key)
        {
            uint seed = 0xEEEEEEEE;
            for (int i = 0; i < data.Length; i++)
            {
                seed += Table[0x400 + (key & 0xFF)];
                uint plain = data[i];
                data[i] = plain ^ (key + seed);
                key = ((~key << 21) + 0x11111111) | (key >> 11);
                seed = plain + seed + (seed << 5) + 3;
            }
        }
    }

    sealed class MpqReader : IDisposable
    {
        const uint FileImplode = 0x00000100;
        const uint FileCompress = 0x00000200;
        const uint FileEncrypted = 0x00010000;
        const uint FileSingleUnit = 0x01000000;
        const uint FileExists = 0x80000000;

        readonly FileStream m_stream;
        readonly long m_base;
        readonly int m_sectorSize;
        readonly uint[] m_hashes;
        readonly uint[] m_blocks;

        public string Path { get; private set; }

        public MpqReader(string path)
        {
            Path = path;
            m_stream = File.OpenRead(path);
            BinaryReader reader = new BinaryReader(m_stream);
            for (m_base = 0; ; m_base += 512)
            {
                if (m_base + 32 > m_stream.Length)
                    throw new InvalidDataException(path + " is not an MPQ archive.");
                m_stream.Position = m_base;
                if (reader.ReadUInt32() == 0x1A51504D)
                    break;
            }
            reader.ReadUInt32();
            reader.ReadUInt32();
            reader.ReadUInt16();
            m_sectorSize = 512 << reader.ReadUInt16();
            uint hashPos = reader.ReadUInt32();
            uint blockPos = reader.ReadUInt32();
            uint hashCount = reader.ReadUInt32();
            uint blockCount = reader.ReadUInt32();
            m_hashes = ReadTable(reader, hashPos, hashCount, MpqCrypt.Hash("(hash table)", 3));
            m_blocks = ReadTable(reader, blockPos, blockCount, MpqCrypt.Hash("(block table)", 3));
        }

        uint[] ReadTable(BinaryReader reader, uint pos, uint count, uint key)
        {
            m_stream.Position = m_base + pos;
            uint[] table = new uint[count * 4];
            for (int i = 0; i < table.Length; i++)
                table[i] = reader.ReadUInt32();
            MpqCrypt.Decrypt(table, key);
            return table;
        }

        int FindBlock(string name)
        {
            uint count = (uint)(m_hashes.Length / 4);
            uint index = MpqCrypt.Hash(name, 0) & (count - 1);
            uint a = MpqCrypt.Hash(name, 1), b = MpqCrypt.Hash(name, 2);
            for (uint i = 0; i < count; i++)
            {
                uint entry = ((index + i) & (count - 1)) * 4;
                uint block = m_hashes[entry + 3];
                if (block == 0xFFFFFFFF)
                    return -1;
                if (m_hashes[entry] == a && m_hashes[entry + 1] == b && block != 0xFFFFFFFE)
                    return (int)block;
            }
            return -1;
        }

        public bool Contains(string name)
        {
            return FindBlock(name) >= 0;
        }

        public byte[] Read(string name)
        {
            int block = FindBlock(name);
            if (block < 0)
                return null;
            uint pos = m_blocks[block * 4], packed = m_blocks[block * 4 + 1], size = m_blocks[block * 4 + 2], flags = m_blocks[block * 4 + 3];
            if ((flags & FileExists) == 0)
                return null;
            if ((flags & FileEncrypted) != 0)
                throw new NotSupportedException(name + " is encrypted.");

            BinaryReader reader = new BinaryReader(m_stream);
            m_stream.Position = m_base + pos;
            if ((flags & (FileCompress | FileImplode)) == 0)
                return reader.ReadBytes((int)size);

            if ((flags & FileSingleUnit) != 0)
                return Unpack(reader.ReadBytes((int)packed), (int)size, flags, name);

            int sectors = (int)((size + m_sectorSize - 1) / m_sectorSize);
            uint[] offsets = new uint[sectors + 1];
            for (int i = 0; i <= sectors; i++)
                offsets[i] = reader.ReadUInt32();

            byte[] result = new byte[size];
            for (int i = 0; i < sectors; i++)
            {
                int want = (int)Math.Min(m_sectorSize, size - i * m_sectorSize);
                m_stream.Position = m_base + pos + offsets[i];
                byte[] data = reader.ReadBytes((int)(offsets[i + 1] - offsets[i]));
                Buffer.BlockCopy(Unpack(data, want, flags, name), 0, result, i * m_sectorSize, want);
            }
            return result;
        }

        static byte[] Unpack(byte[] data, int size, uint flags, string name)
        {
            if (data.Length >= size)
                return data;
            if ((flags & FileImplode) != 0)
                throw new NotSupportedException(name + " is imploded (PKWARE).");
            byte method = data[0];
            if (method != 0x02)
                throw new NotSupportedException(name + " uses compression 0x" + method.ToString("X2") + ".");
            using (MemoryStream input = new MemoryStream(data, 3, data.Length - 3))
            using (DeflateStream deflate = new DeflateStream(input, CompressionMode.Decompress))
            {
                byte[] output = new byte[size];
                int read = 0;
                while (read < size)
                {
                    int got = deflate.Read(output, read, size - read);
                    if (got <= 0)
                        break;
                    read += got;
                }
                return output;
            }
        }

        public void Dispose()
        {
            m_stream.Dispose();
        }
    }

    static class GameFiles
    {
        public static string Child(string directory, string name)
        {
            string exact = System.IO.Path.Combine(directory, name);
            if (File.Exists(exact) || Directory.Exists(exact) || !Directory.Exists(directory))
                return exact;
            foreach (string entry in Directory.EnumerateFileSystemEntries(directory))
                if (string.Equals(System.IO.Path.GetFileName(entry), name, StringComparison.OrdinalIgnoreCase))
                    return entry;
            return exact;
        }
    }

    sealed class ClientData : IDisposable
    {
        readonly List<MpqReader> m_archives = new List<MpqReader>();

        public ClientData(string dataDir, IEnumerable<string> skip)
        {
            HashSet<string> skipped = new HashSet<string>(skip, StringComparer.OrdinalIgnoreCase);
            string[] baseOrder = { "patch.MPQ", "dbc.MPQ", "model.MPQ", "texture.MPQ", "misc.MPQ", "interface.MPQ", "sound.MPQ", "base.MPQ" };
            Dictionary<string, string> present = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);
            foreach (string path in Directory.GetFiles(dataDir))
                present[System.IO.Path.GetFileName(path)] = path;
            List<string> order = NumberedPatches(dataDir);
            order.AddRange(baseOrder);
            foreach (string file in order)
            {
                string path;
                if (present.TryGetValue(file, out path) && !skipped.Contains(file))
                    m_archives.Add(new MpqReader(path));
            }
        }

        public static List<string> NumberedPatches(string dataDir)
        {
            List<string> patches = new List<string>();
            foreach (string path in Directory.GetFiles(dataDir))
                if (IsNumberedPatch(System.IO.Path.GetFileName(path)))
                    patches.Add(System.IO.Path.GetFileName(path));
            patches.Sort((a, b) => string.CompareOrdinal(b.ToLowerInvariant(), a.ToLowerInvariant()));
            return patches;
        }

        static bool IsNumberedPatch(string name)
        {
            return name.Length == "patch-?.MPQ".Length
                && name.StartsWith("patch-", StringComparison.OrdinalIgnoreCase)
                && name.EndsWith(".MPQ", StringComparison.OrdinalIgnoreCase);
        }

        public byte[] Read(string name)
        {
            foreach (MpqReader archive in m_archives)
            {
                byte[] data = archive.Read(name);
                if (data != null)
                    return data;
            }
            return null;
        }

        public void Dispose()
        {
            foreach (MpqReader archive in m_archives)
                archive.Dispose();
        }
    }

    static class MpqPath
    {
        public static string FileName(string path)
        {
            return path.Substring(LastSlash(path) + 1);
        }

        public static string Directory(string path)
        {
            int slash = LastSlash(path);
            return slash < 0 ? "" : path.Substring(0, slash);
        }

        public static string WithoutExtension(string path)
        {
            int dot = path.LastIndexOf('.');
            return dot > LastSlash(path) ? path.Substring(0, dot) : path;
        }

        public static string Join(string directory, string name)
        {
            return directory.Length == 0 ? name : directory + "\\" + name;
        }

        static int LastSlash(string path)
        {
            return Math.Max(path.LastIndexOf('\\'), path.LastIndexOf('/'));
        }
    }

    static class MpqWriter
    {
        public static void Write(string path, IDictionary<string, byte[]> files)
        {
            SortedDictionary<string, byte[]> all = new SortedDictionary<string, byte[]>(StringComparer.OrdinalIgnoreCase);
            foreach (KeyValuePair<string, byte[]> file in files)
                all[file.Key.Replace('/', '\\')] = file.Value;
            StringBuilder list = new StringBuilder();
            foreach (string name in all.Keys)
                list.Append(name).Append("\r\n");
            all["(listfile)"] = Encoding.ASCII.GetBytes(list.ToString());

            uint hashCount = 16;
            while (hashCount < all.Count * 2)
                hashCount *= 2;
            uint[] hashes = new uint[hashCount * 4];
            for (int i = 0; i < hashes.Length; i += 4)
            {
                hashes[i] = 0xFFFFFFFF;
                hashes[i + 1] = 0xFFFFFFFF;
                hashes[i + 2] = 0xFFFFFFFF;
                hashes[i + 3] = 0xFFFFFFFF;
            }
            uint[] blocks = new uint[all.Count * 4];

            using (MemoryStream body = new MemoryStream())
            {
                body.Position = 32;
                int blockIndex = 0;
                foreach (KeyValuePair<string, byte[]> file in all)
                {
                    uint pos = (uint)body.Position;
                    body.Write(file.Value, 0, file.Value.Length);
                    blocks[blockIndex * 4] = pos;
                    blocks[blockIndex * 4 + 1] = (uint)file.Value.Length;
                    blocks[blockIndex * 4 + 2] = (uint)file.Value.Length;
                    blocks[blockIndex * 4 + 3] = 0x80000000;

                    uint index = MpqCrypt.Hash(file.Key, 0) & (hashCount - 1);
                    while (hashes[index * 4 + 3] != 0xFFFFFFFF)
                        index = (index + 1) & (hashCount - 1);
                    hashes[index * 4] = MpqCrypt.Hash(file.Key, 1);
                    hashes[index * 4 + 1] = MpqCrypt.Hash(file.Key, 2);
                    hashes[index * 4 + 2] = 0;
                    hashes[index * 4 + 3] = (uint)blockIndex;
                    ++blockIndex;
                }

                uint hashPos = (uint)body.Position;
                MpqCrypt.Encrypt(hashes, MpqCrypt.Hash("(hash table)", 3));
                WriteTable(body, hashes);
                uint blockPos = (uint)body.Position;
                MpqCrypt.Encrypt(blocks, MpqCrypt.Hash("(block table)", 3));
                WriteTable(body, blocks);

                BinaryWriter header = new BinaryWriter(body);
                body.Position = 0;
                header.Write(0x1A51504Du);
                header.Write(32u);
                header.Write((uint)body.Length);
                header.Write((ushort)0);
                header.Write((ushort)3);
                header.Write(hashPos);
                header.Write(blockPos);
                header.Write(hashCount);
                header.Write((uint)all.Count);
                File.WriteAllBytes(path, body.ToArray());
            }
        }

        static void WriteTable(Stream stream, uint[] table)
        {
            BinaryWriter writer = new BinaryWriter(stream);
            foreach (uint value in table)
                writer.Write(value);
        }
    }
}
