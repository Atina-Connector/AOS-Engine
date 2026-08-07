/*
 * AOS.exe - launcher nativo de AOS Suite para Windows.
 *
 * No es una GUI. Localiza el runtime portable de Octave y app\AOS.m en
 * forma relativa a su propia ubicacion (funciona bajo Program Files sin
 * variables de entorno globales ni tocar el PATH del usuario), lanza
 * octave-cli.exe heredando la consola actual (stdin/stdout/stderr
 * intactos, totalmente interactivo) y propaga su exit code.
 *
 * Layout esperado, relativo a la carpeta que contiene este .exe:
 *   runtime\octave\mingw64\bin\octave-cli.exe
 *   app\AOS.m
 */

#define WIN32_LEAN_AND_MEAN
#ifndef UNICODE
#define UNICODE
#endif
#ifndef _UNICODE
#define _UNICODE
#endif

#include <windows.h>
#include <stdio.h>
#include <wchar.h>

static void PrintLastError(const wchar_t *contexto) {
    DWORD err = GetLastError();
    fwprintf(stderr, L"AOS: %ls (error de Windows %lu).\n", contexto, err);
}

int main(void) {
    wchar_t exePath[MAX_PATH];
    DWORD len = GetModuleFileNameW(NULL, exePath, MAX_PATH);
    if (len == 0 || len == MAX_PATH) {
        fwprintf(stderr, L"AOS: no se pudo determinar la ubicacion de AOS.exe.\n");
        return 1;
    }

    wchar_t exeDir[MAX_PATH];
    if (wcscpy_s(exeDir, MAX_PATH, exePath) != 0) {
        fwprintf(stderr, L"AOS: ruta de instalacion demasiado larga.\n");
        return 1;
    }
    wchar_t *lastSlash = wcsrchr(exeDir, L'\\');
    if (!lastSlash) {
        fwprintf(stderr, L"AOS: ruta de instalacion inesperada: %ls\n", exePath);
        return 1;
    }
    *lastSlash = L'\0';

    wchar_t octavePath[MAX_PATH];
    wchar_t aosScriptPath[MAX_PATH];
    if (_snwprintf_s(octavePath, MAX_PATH, _TRUNCATE,
                      L"%ls\\runtime\\octave\\mingw64\\bin\\octave-cli.exe", exeDir) < 0 ||
        _snwprintf_s(aosScriptPath, MAX_PATH, _TRUNCATE,
                      L"%ls\\app\\AOS.m", exeDir) < 0) {
        fwprintf(stderr, L"AOS: la ruta de instalacion es demasiado larga.\n");
        return 1;
    }

    if (GetFileAttributesW(octavePath) == INVALID_FILE_ATTRIBUTES) {
        fwprintf(stderr,
            L"AOS: no se encontro el runtime de Octave en:\n  %ls\n"
            L"La instalacion de AOS parece incompleta o danada. Reinstale AOS.\n",
            octavePath);
        return 1;
    }
    if (GetFileAttributesW(aosScriptPath) == INVALID_FILE_ATTRIBUTES) {
        fwprintf(stderr,
            L"AOS: no se encontro app\\AOS.m en:\n  %ls\n"
            L"La instalacion de AOS parece incompleta o danada. Reinstale AOS.\n",
            aosScriptPath);
        return 1;
    }

    wchar_t cmdLine[2 * MAX_PATH + 64];
    if (_snwprintf_s(cmdLine, sizeof(cmdLine) / sizeof(cmdLine[0]), _TRUNCATE,
                      L"\"%ls\" --quiet --no-history --no-init-file \"%ls\"",
                      octavePath, aosScriptPath) < 0) {
        fwprintf(stderr, L"AOS: no se pudo construir la linea de comandos de Octave.\n");
        return 1;
    }

    /* AOS.m ya sabe suprimir ventanas de graficos si AOS_GRAPHICS_MODE=file
     * (set(0,'defaultfigurevisible','off')) -- es como Docker se queda en
     * modo CLI puro (headless ahi por no tener display en absoluto; en
     * Windows el runtime de Octave si trae Qt/GUI, asi que hace falta
     * pedirlo explicitamente). Se setea en el propio proceso del launcher
     * y se hereda en el hijo al pasar lpEnvironment=NULL. */
    if (!SetEnvironmentVariableW(L"AOS_GRAPHICS_MODE", L"file")) {
        PrintLastError(L"no se pudo configurar el modo headless");
        return 1;
    }

    STARTUPINFOW si;
    PROCESS_INFORMATION pi;
    ZeroMemory(&si, sizeof(si));
    si.cb = sizeof(si);
    ZeroMemory(&pi, sizeof(pi));

    /* Sin STARTF_USESTDHANDLES y sin CREATE_NEW_CONSOLE: el proceso hijo
     * hereda directamente la consola del padre. Totalmente interactivo,
     * igual que si el usuario hubiera tipeado octave-cli.exe a mano. */
    BOOL ok = CreateProcessW(
        octavePath,
        cmdLine,
        NULL,
        NULL,
        TRUE,       /* bInheritHandles */
        0,          /* sin flags de creacion especiales */
        NULL,       /* hereda el entorno del launcher, incluido AOS_GRAPHICS_MODE */
        exeDir,     /* working directory; AOS.m igual hace cd(root_dir) solo */
        &si,
        &pi);

    if (!ok) {
        PrintLastError(L"no se pudo iniciar Octave");
        return 1;
    }

    CloseHandle(pi.hThread);
    WaitForSingleObject(pi.hProcess, INFINITE);

    DWORD exitCode = 1;
    GetExitCodeProcess(pi.hProcess, &exitCode);
    CloseHandle(pi.hProcess);

    return (int)exitCode;
}
