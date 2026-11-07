#include "BonkIntegrity.h"
#include "Log.h"

#include <atomic>
#include <cstddef>
#include <cstdint>
#include <cstring>

#ifdef _WIN32
#include <windows.h>
#else
#include <link.h>
#include <unistd.h>
#endif

namespace
{
    struct CodeRange
    {
        unsigned char const* start = nullptr;
        size_t size = 0;
    };

    size_t const MAX_CODE_RANGES = 8;
    CodeRange s_ranges[MAX_CODE_RANGES];
    size_t s_rangeCount = 0;
    uint64_t s_baseline = 0;
    bool s_ready = false;
    std::atomic<bool> s_modified{ false };

    size_t RoundUpToPage(size_t size, size_t page)
    {
        return (size + page - 1) / page * page;
    }

    void AddRange(unsigned char const* start, size_t size)
    {
        if (s_rangeCount < MAX_CODE_RANGES && start && size)
            s_ranges[s_rangeCount++] = { start, size };
    }

#ifdef _WIN32
    void FindCodeRanges()
    {
        unsigned char const* base = reinterpret_cast<unsigned char const*>(GetModuleHandleW(nullptr));
        if (!base)
            return;
        SYSTEM_INFO system;
        GetSystemInfo(&system);
        IMAGE_DOS_HEADER const* dos = reinterpret_cast<IMAGE_DOS_HEADER const*>(base);
        IMAGE_NT_HEADERS const* nt = reinterpret_cast<IMAGE_NT_HEADERS const*>(base + dos->e_lfanew);
        IMAGE_SECTION_HEADER const* section = IMAGE_FIRST_SECTION(nt);
        for (WORD index = 0; index < nt->FileHeader.NumberOfSections; ++index, ++section)
            if (section->Characteristics & IMAGE_SCN_MEM_EXECUTE)
                AddRange(base + section->VirtualAddress, RoundUpToPage(section->Misc.VirtualSize, system.dwPageSize));
    }
#else
    int AddMainProgramRanges(dl_phdr_info* info, size_t, void*)
    {
        size_t const page = size_t(sysconf(_SC_PAGESIZE));
        for (ElfW(Half) index = 0; index < info->dlpi_phnum; ++index)
        {
            ElfW(Phdr) const& header = info->dlpi_phdr[index];
            if (header.p_type == PT_LOAD && (header.p_flags & PF_X))
            {
                uintptr_t const start = (info->dlpi_addr + header.p_vaddr) / page * page;
                uintptr_t const end = info->dlpi_addr + header.p_vaddr + header.p_memsz;
                AddRange(reinterpret_cast<unsigned char const*>(start), RoundUpToPage(end - start, page));
            }
        }
        return 1;
    }

    void FindCodeRanges()
    {
        dl_iterate_phdr(AddMainProgramRanges, nullptr);
    }
#endif

    uint64_t HashCode()
    {
        uint64_t hash = 14695981039346656037ull;
        for (size_t index = 0; index < s_rangeCount; ++index)
        {
            CodeRange const& range = s_ranges[index];
            size_t const words = range.size / sizeof(uint64_t);
            for (size_t word = 0; word < words; ++word)
            {
                uint64_t value;
                std::memcpy(&value, range.start + word * sizeof(uint64_t), sizeof(value));
                hash = (hash ^ value) * 1099511628211ull;
            }
        }
        return hash;
    }
}

void BonkIntegrity::Snapshot()
{
    FindCodeRanges();
    s_baseline = HashCode();
    s_ready = s_rangeCount > 0;
}

bool BonkIntegrity::IsServerModified()
{
    if (s_modified.load())
        return true;
    if (!s_ready || HashCode() == s_baseline)
        return false;
    if (!s_modified.exchange(true))
        sLog.Out(LOG_BASIC, LOG_LVL_MINIMAL, "Integrity: the server's code was changed while it was running; clears no longer count for the leaderboard.");
    return true;
}
