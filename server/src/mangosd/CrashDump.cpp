#include "CrashDump.h"

#ifdef _WIN32

#include <windows.h>
#include <dbghelp.h>

#include <atomic>
#include <csignal>
#include <cstdio>
#include <ctime>
#include <exception>

#pragma comment(lib, "dbghelp.lib")

namespace
{
    char g_reportPath[MAX_PATH];
    char g_dumpPath[MAX_PATH];
    std::atomic<bool> g_written{ false };
    std::terminate_handler g_previousTerminate = nullptr;

    struct CrashContext
    {
        EXCEPTION_POINTERS* pointers;
        DWORD threadId;
        char const* reason;
    };

    bool IsFatal(DWORD code)
    {
        switch (code)
        {
            case EXCEPTION_ACCESS_VIOLATION:
            case EXCEPTION_STACK_OVERFLOW:
            case EXCEPTION_ILLEGAL_INSTRUCTION:
            case EXCEPTION_PRIV_INSTRUCTION:
            case EXCEPTION_INT_DIVIDE_BY_ZERO:
            case EXCEPTION_IN_PAGE_ERROR:
            case EXCEPTION_ARRAY_BOUNDS_EXCEEDED:
            case 0xC0000374:
                return true;
            default:
                return false;
        }
    }

    void WriteReport(CrashContext const& crash)
    {
        FILE* report = std::fopen(g_reportPath, "a");
        if (!report)
            return;

        std::time_t const now = std::time(nullptr);
        char stamp[32];
        std::strftime(stamp, sizeof(stamp), "%Y-%m-%d %H:%M:%S", std::localtime(&now));
        std::fprintf(report, "%s mangosd crashed: %s, thread %lu\n", stamp, crash.reason, crash.threadId);

        if (crash.pointers && crash.pointers->ExceptionRecord)
        {
            EXCEPTION_RECORD const* record = crash.pointers->ExceptionRecord;
            void* address = record->ExceptionAddress;
            HMODULE module = nullptr;
            char moduleName[MAX_PATH] = "unknown";
            if (GetModuleHandleExA(GET_MODULE_HANDLE_EX_FLAG_FROM_ADDRESS | GET_MODULE_HANDLE_EX_FLAG_UNCHANGED_REFCOUNT,
                static_cast<LPCSTR>(address), &module) && module)
                GetModuleFileNameA(module, moduleName, MAX_PATH);
            std::fprintf(report, "%s exception 0x%08lX at %p (%s+0x%llX)\n", stamp, record->ExceptionCode, address, moduleName,
                static_cast<unsigned long long>(reinterpret_cast<char*>(address) - reinterpret_cast<char*>(module)));
            if (record->ExceptionCode == EXCEPTION_ACCESS_VIOLATION && record->NumberParameters >= 2)
                std::fprintf(report, "%s %s address 0x%llX\n", stamp, record->ExceptionInformation[0] == 1 ? "writing" : "reading",
                    static_cast<unsigned long long>(record->ExceptionInformation[1]));
        }
        std::fprintf(report, "%s minidump: %s\n", stamp, g_dumpPath);
        std::fclose(report);
    }

    void WriteMiniDump(CrashContext const& crash)
    {
        HANDLE file = CreateFileA(g_dumpPath, GENERIC_WRITE, 0, nullptr, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, nullptr);
        if (file == INVALID_HANDLE_VALUE)
            return;

        MINIDUMP_EXCEPTION_INFORMATION exception;
        exception.ThreadId = crash.threadId;
        exception.ExceptionPointers = crash.pointers;
        exception.ClientPointers = FALSE;
        MINIDUMP_TYPE const type = static_cast<MINIDUMP_TYPE>(MiniDumpWithThreadInfo | MiniDumpWithUnloadedModules);
        MiniDumpWriteDump(GetCurrentProcess(), GetCurrentProcessId(), file, type, crash.pointers ? &exception : nullptr, nullptr, nullptr);
        CloseHandle(file);
    }

    DWORD WINAPI WriteCrashFiles(LPVOID parameter)
    {
        CrashContext const& crash = *static_cast<CrashContext*>(parameter);
        WriteReport(crash);
        WriteMiniDump(crash);
        return 0;
    }

    void WriteCrashFilesOnce(EXCEPTION_POINTERS* pointers, char const* reason)
    {
        if (g_written.exchange(true))
            return;

        CrashContext crash{ pointers, GetCurrentThreadId(), reason };
        HANDLE writer = CreateThread(nullptr, 1024 * 1024, WriteCrashFiles, &crash, 0, nullptr);
        if (!writer)
            return;
        WaitForSingleObject(writer, 60 * 1000);
        CloseHandle(writer);
    }

    LONG CALLBACK OnException(EXCEPTION_POINTERS* pointers)
    {
        if (pointers && pointers->ExceptionRecord && IsFatal(pointers->ExceptionRecord->ExceptionCode))
            WriteCrashFilesOnce(pointers, pointers->ExceptionRecord->ExceptionCode == EXCEPTION_STACK_OVERFLOW ? "stack overflow" : "fatal exception");
        return EXCEPTION_CONTINUE_SEARCH;
    }

    void OnTerminate()
    {
        WriteCrashFilesOnce(nullptr, "std::terminate");
        if (g_previousTerminate)
            g_previousTerminate();
        std::abort();
    }

    void OnAbort(int)
    {
        WriteCrashFilesOnce(nullptr, "abort");
    }

    void OnInvalidParameter(wchar_t const*, wchar_t const*, wchar_t const*, unsigned int, uintptr_t)
    {
        WriteCrashFilesOnce(nullptr, "invalid CRT parameter");
        std::abort();
    }

    void OnPureCall()
    {
        WriteCrashFilesOnce(nullptr, "pure virtual call");
        std::abort();
    }
}

void InstallCrashDumpWriter(std::string const& logsDir)
{
    std::string folder = logsDir;
    if (!folder.empty() && folder.back() != '/' && folder.back() != '\\')
        folder += '\\';
    std::snprintf(g_reportPath, sizeof(g_reportPath), "%sCrash.log", folder.c_str());
    std::snprintf(g_dumpPath, sizeof(g_dumpPath), "%smangosd-crash.dmp", folder.c_str());

    AddVectoredExceptionHandler(1, OnException);
    g_previousTerminate = std::set_terminate(OnTerminate);
    std::signal(SIGABRT, OnAbort);
    _set_invalid_parameter_handler(OnInvalidParameter);
    _set_purecall_handler(OnPureCall);
}

#else

void InstallCrashDumpWriter(std::string const&)
{
}

#endif
