@echo off
REM Unified firmware download script
REM Usage: download.bat [TARGET] [DEBUGGER]
REM TARGET: MSDK, MBL, ALL
REM DEBUGGER: GDLink, JLink

setlocal enabledelayedexpansion

set TARGET=%1
set DEBUGGER=%2

REM set custom OpenOCD path
::set OPENOCD_PATH=path/to/openocd/bin

REM OpenOCD check and setup
:: Check for custom OpenOCD path first
if NOT "%OPENOCD_PATH%"=="" (
    if EXIST "%OPENOCD_PATH%" (
        echo Using custom OpenOCD path: %OPENOCD_PATH%
        SET "PATH=%PATH%;%OPENOCD_PATH%"
        goto openocd_done
    )
)

:: Check if OpenOCD is found in PATH
where openocd >NUL 2>&1

:: Check if OpenOCD is found in %CD%\tools
if ERRORLEVEL 1 (
    IF NOT EXIST "%CD%\tools\xpack-openocd-0.11.0-3_windows" (
        IF EXIST "%CD%\tools\xpack-openocd-0.11.0-3_windows.7z" (
            echo Unzipping gd32vw55x OpenOCD .......
            "%PROGRAMFILES%\7-Zip\7z.exe" x "%CD%\tools\xpack-openocd-0.11.0-3_windows.7z" -o"%CD%\tools"
        ) ELSE (
            echo "Please download the gd32vw55x OpenOCD from the website and put it in PATH"
            EXIT /B 1
        )
    )
    SET "PATH=%PATH%;%CD%\tools\xpack-openocd-0.11.0-3_windows\bin"
) else (
    for /f "delims=" %%i in ('where openocd') do (
        echo OpenOCD found in PATH: %%i
    )
)

:openocd_done

REM Default to MSDK if target not specified
if "%TARGET%"=="" set TARGET=MSDK
REM Default to GDLink if debugger not specified
if "%DEBUGGER%"=="" set DEBUGGER=GDLink

cd /d "%~dp0\.."
set WORK_DIR=%cd%

REM Validate target
if /i not "%TARGET%"=="MSDK" if /i not "%TARGET%"=="MBL" if /i not "%TARGET%"=="ALL" (
    echo Error: Invalid TARGET. Usage: download.bat [MSDK^|MBL^|ALL] [GDLink^|JLink]
    exit /b 1
)

REM Validate debugger
if /i not "%DEBUGGER%"=="GDLink" if /i not "%DEBUGGER%"=="JLink" (
    echo Error: Invalid DEBUGGER. Usage: download.bat [MSDK^|MBL^|ALL] [GDLink^|JLink]
    exit /b 1
)

REM Set binary file and flash address based on target
if /i "%TARGET%"=="MSDK" (
    echo Downloading MSDK via !DEBUGGER!...
    set BIN_FILE=!WORK_DIR!\MSDK\projects\cmake\output\bin\msdk.bin
    set FLASH_ADDR=0x0800A000
) else if /i "%TARGET%"=="MBL" (
    echo Downloading MBL via !DEBUGGER!...
    set BIN_FILE=!WORK_DIR!\MBL\project\cmake\bin\mbl.bin
    set FLASH_ADDR=0x08000000
) else if /i "%TARGET%"=="ALL" (
    echo Downloading ALL via !DEBUGGER!...
    set BIN_FILE=!WORK_DIR!\scripts\images\image-all.bin
    set FLASH_ADDR=0x08000000
)

REM Set OpenOCD config based on debugger
if /i "%DEBUGGER%"=="GDLink" (
    set CONFIG_FILE=!WORK_DIR!\MSDK\projects\eclipse\msdk\openocd_gdlink.cfg
) else if /i "%DEBUGGER%"=="JLink" (
    set CONFIG_FILE=!WORK_DIR!\MSDK\projects\eclipse\msdk\openocd_jlink.cfg
)

REM Convert backslashes to forward slashes for OpenOCD compatibility
set BIN_FILE=!BIN_FILE:\=/!

echo.
echo Target: %TARGET%
echo Debugger: %DEBUGGER%
echo Binary: !BIN_FILE!
echo Flash Address: %FLASH_ADDR%
echo.

REM Run OpenOCD with appropriate config
"openocd.exe" -f "!CONFIG_FILE!" -c "init" -c "program !BIN_FILE! %FLASH_ADDR% verify reset" -c "exit"

if errorlevel 1 (
    echo.
    echo Download failed!
    exit /b 1
) else (
    echo.
    echo Download completed successfully!
)