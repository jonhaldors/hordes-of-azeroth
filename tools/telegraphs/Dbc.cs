using System;
using System.Collections.Generic;
using System.IO;
using System.Text;

namespace BonkTelegraphs
{
    sealed class Dbc
    {
        public int FieldCount { get; private set; }
        public List<uint[]> Records { get; private set; }
        readonly MemoryStream m_strings = new MemoryStream();
        readonly Dictionary<string, uint> m_stringOffsets = new Dictionary<string, uint>();

        public Dbc(byte[] data)
        {
            BinaryReader r = new BinaryReader(new MemoryStream(data));
            if (r.ReadUInt32() != 0x43424457)
                throw new InvalidDataException("Not a DBC file.");
            int count = r.ReadInt32();
            FieldCount = r.ReadInt32();
            int recordSize = r.ReadInt32();
            int stringSize = r.ReadInt32();
            if (recordSize != FieldCount * 4)
                throw new InvalidDataException("Unexpected record size " + recordSize + ".");
            Records = new List<uint[]>(count);
            for (int i = 0; i < count; i++)
            {
                uint[] record = new uint[FieldCount];
                for (int f = 0; f < FieldCount; f++)
                    record[f] = r.ReadUInt32();
                Records.Add(record);
            }
            byte[] strings = r.ReadBytes(stringSize);
            m_strings.Write(strings, 0, strings.Length);
        }

        public string GetString(uint offset)
        {
            byte[] all = m_strings.GetBuffer();
            int end = (int)offset;
            while (end < m_strings.Length && all[end] != 0)
                ++end;
            return Encoding.ASCII.GetString(all, (int)offset, end - (int)offset);
        }

        public uint AddString(string value)
        {
            uint offset;
            if (m_stringOffsets.TryGetValue(value, out offset))
                return offset;
            offset = (uint)m_strings.Length;
            byte[] bytes = Encoding.ASCII.GetBytes(value + "\0");
            m_strings.Position = m_strings.Length;
            m_strings.Write(bytes, 0, bytes.Length);
            m_stringOffsets[value] = offset;
            return offset;
        }

        public uint[] Find(uint id)
        {
            foreach (uint[] record in Records)
                if (record[0] == id)
                    return record;
            return null;
        }

        public uint ClaimId(uint wanted)
        {
            return Find(wanted) == null ? wanted : MaxId() + 1;
        }

        public uint MaxId()
        {
            uint max = 0;
            foreach (uint[] record in Records)
                max = Math.Max(max, record[0]);
            return max;
        }

        public byte[] ToBytes()
        {
            using (MemoryStream output = new MemoryStream())
            {
                BinaryWriter w = new BinaryWriter(output);
                w.Write(0x43424457u);
                w.Write(Records.Count);
                w.Write(FieldCount);
                w.Write(FieldCount * 4);
                w.Write((int)m_strings.Length);
                foreach (uint[] record in Records)
                    foreach (uint value in record)
                        w.Write(value);
                w.Write(m_strings.GetBuffer(), 0, (int)m_strings.Length);
                return output.ToArray();
            }
        }
    }
}
