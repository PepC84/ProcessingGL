@echo off
setlocal EnableDelayedExpansion
echo.
echo   +================================================+
echo   ^|   gcc-processing  --  Windows Setup           ^|
echo   +================================================+
echo.

:: ── Locate MSYS2 (check common install paths) ───────────────────────────
set MSYS2_PATH=
for %%P in (
    "C:\msys64"
    "C:\msys2"
    "C:\tools\msys64"
    "%USERPROFILE%\msys64"
    "%LOCALAPPDATA%\msys64"
    "C:\gcc-processing\msys64"
) do (
    if exist "%%~P\usr\bin\pacman.exe" (
        if "!MSYS2_PATH!"=="" set "MSYS2_PATH=%%~P"
    )
)

if "!MSYS2_PATH!" NEQ "" goto :have_msys2

:: ── MSYS2 not found — download and install it silently ──────────────────
echo [INFO] MSYS2 not found. Downloading installer...
echo [INFO] This is a ~90MB download and will take a moment.
echo.

:: Use PowerShell to download (available on all Windows 7+)
set INSTALLER=%TEMP%\msys2-installer.exe
powershell -NoProfile -Command ^
    "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; ^
     $ProgressPreference = 'SilentlyContinue'; ^
     Invoke-WebRequest ^
       -Uri 'https://github.com/msys2/msys2-installer/releases/download/2024-01-13/msys2-x86_64-20240113.exe' ^
       -OutFile '%INSTALLER%'"

if not exist "%INSTALLER%" (
    echo [ERR] Download failed. Check your internet connection.
    echo.
    echo  You can install MSYS2 manually from: https://www.msys2.org/
    echo  Then re-run this script.
    pause
    exit /b 1
)

echo [OK]  Installer downloaded. Installing MSYS2 to C:\msys64 ...
echo [INFO] A progress window will appear. Please wait for it to finish.
echo.

:: Run installer silently — installs to C:\msys64 by default
"%INSTALLER%" install --root C:\msys64 --confirm-command --accept-messages
if %errorlevel% NEQ 0 (
    :: Try with the older NSIS-style silent flag
    "%INSTALLER%" /S /D=C:\msys64
)

del /f /q "%INSTALLER%" 2>nul

:: Check again
if exist "C:\msys64\usr\bin\pacman.exe" (
    set "MSYS2_PATH=C:\msys64"
    echo [OK]  MSYS2 installed at C:\msys64
    goto :have_msys2
)

echo [ERR] MSYS2 installation failed or did not complete.
echo  Try installing manually from https://www.msys2.org/
echo  Then re-run this script.
pause
exit /b 1

:have_msys2
echo [OK]  MSYS2 found at: !MSYS2_PATH!
echo.

:: ── Update pacman database first ────────────────────────────────────────
echo [INFO] Updating package database...
"!MSYS2_PATH!\usr\bin\bash.exe" -lc "pacman -Sy --noconfirm" 2>nul
echo.

:: ── Install build dependencies ───────────────────────────────────────────
echo [INFO] Installing build dependencies (gcc, glfw, glew)...
"!MSYS2_PATH!\usr\bin\bash.exe" -lc ^
    "pacman -S --needed --noconfirm mingw-w64-x86_64-gcc mingw-w64-x86_64-glfw mingw-w64-x86_64-glew mingw-w64-x86_64-freeglut mingw-w64-x86_64-make"
if %errorlevel% NEQ 0 (
    echo [WARN] pacman had warnings ^(packages may already be installed^) -- continuing
)
echo [OK]  Packages installed.
echo.

:: ── Download stb headers ─────────────────────────────────────────────────
if not exist "src" mkdir src

if not exist "src\stb_truetype.h" (
    echo [INFO] Downloading stb_truetype.h...
    "!MSYS2_PATH!\usr\bin\curl.exe" -sL ^
        "https://raw.githubusercontent.com/nothings/stb/master/stb_truetype.h" ^
        -o src\stb_truetype.h 2>nul
    if exist "src\stb_truetype.h" (echo [OK]  stb_truetype.h) else (echo [WARN] stb_truetype.h download failed)
) else ( echo [OK]  stb_truetype.h already present )

if not exist "src\stb_image.h" (
    echo [INFO] Downloading stb_image.h...
    "!MSYS2_PATH!\usr\bin\curl.exe" -sL ^
        "https://raw.githubusercontent.com/nothings/stb/master/stb_image.h" ^
        -o src\stb_image.h 2>nul
    if exist "src\stb_image.h" (echo [OK]  stb_image.h) else (echo [WARN] stb_image.h download failed)
) else ( echo [OK]  stb_image.h already present )

:: ── Write src/main.cpp ────────────────────────────────────────────────────
if not exist "src\main.cpp" (
    (
        echo #include "Processing.h"
        echo int main^(^) { Processing::run^(^); return 0; }
    ) > src\main.cpp
    echo [OK]  src/main.cpp written
) else ( echo [OK]  src/main.cpp already present )

:: ── Find a font ───────────────────────────────────────────────────────────
if not exist "default.ttf" (
    for %%F in (
        "%WINDIR%\Fonts\consola.ttf"
        "%WINDIR%\Fonts\cour.ttf"
        "%WINDIR%\Fonts\arial.ttf"
        "!MSYS2_PATH!\mingw64\share\fonts\DejaVuSansMono.ttf"
    ) do (
        if exist "%%~F" (
            if not exist "default.ttf" (
                copy "%%~F" default.ttf >nul
                echo [OK]  Font copied: %%~nxF
            )
        )
    )
    if not exist "default.ttf" echo [WARN] No font found -- place any .ttf here as default.ttf
) else ( echo [OK]  default.ttf already present )

:: ── Add MinGW to PATH for this session ────────────────────────────────────
set "MINGW_BIN=!MSYS2_PATH!\mingw64\bin"
set "PATH=!MINGW_BIN!;%PATH%"

:: ── Run the bash setup.sh to write build scripts and build the IDE ────────
echo.
echo [INFO] Running setup.sh to build the IDE...
echo.
"!MSYS2_PATH!\usr\bin\bash.exe" -lc "cd \"$(cygpath -u '%CD%')\" && bash setup.sh"
if %errorlevel% NEQ 0 (
    echo.
    echo [ERR] setup.sh reported an error.
    pause
    exit /b 1
)

:: ── Copy DLLs ─────────────────────────────────────────────────────────────
echo [INFO] Copying runtime DLLs...
for %%D in (libglfw3.dll glew32.dll libgcc_s_seh-1.dll libstdc++-6.dll libwinpthread-1.dll) do (
    if exist "!MINGW_BIN!\%%D" (
        copy "!MINGW_BIN!\%%D" . >nul 2>&1
        echo [OK]  %%D
    ) else ( echo [WARN] %%D not found )
)

echo.
echo   +================================================+
echo   ^|   Setup complete!                              ^|
echo   +================================================+
echo.
echo   Run the IDE:   ide.exe   (or double-click in Explorer)
echo   Build sketch:  bash build.sh src/MySketch.cpp
echo   Build IDE:     bash buildIDE.sh
echo.
pause
start "" ide.exe
