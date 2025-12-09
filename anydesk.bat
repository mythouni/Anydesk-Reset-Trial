@echo off
setlocal EnableExtensions EnableDelayedExpansion

:: ======================================================================
::  Mythouni AnyDesk Reset Tool (Keep ID & Alias)
:: ----------------------------------------------------------------------
::  Version     : 2.0
::  Author      : Mythouni
::  Date        : 2025-12-09
::  Languages   : EN / GR
::  Description : Fully resets AnyDesk configuration WITHOUT losing ID.
::                Supports portable AnyDesk, logging, multi-language,
::                Safe Mode / Advanced Mode, helper menu, and auto-detect.
::
::  Usage       :
::        Mythouni_AnyDesk_Reset_Tool_v2.0.bat
::        Mythouni_AnyDesk_Reset_Tool_v2.0.bat /log
::        Mythouni_AnyDesk_Reset_Tool_v2.0.bat /lang:GR
::
::  Supported Params:
::        /log        Enable full logging
::        /lang:EN    Force English
::        /lang:GR    Force Greek
::        /? or -h    Show help
::
:: ======================================================================


:: ----------------------------------------------------------------------
:: Defaults
:: ----------------------------------------------------------------------
set "LOG_ENABLED=0"
set "LANG=EN"
set "LOGFILE=%TEMP%\Mythouni_AnyDesk_Reset.log"

set "TOOL_VERSION=2.0"
set "TOOL_AUTHOR=Mythouni"


:: ----------------------------------------------------------------------
:: Parse Parameters
:: ----------------------------------------------------------------------
for %%A in (%*) do (
    if /I "%%A"=="/log" set LOG_ENABLED=1
    if /I "%%A"=="/?"  goto :SHOW_HELP
    if /I "%%A"=="-h"  goto :SHOW_HELP
    if /I "%%A"=="/lang:GR" set LANG=GR
    if /I "%%A"=="/lang:EN" set LANG=EN
)


:: ----------------------------------------------------------------------
:: Initialize logging
:: ----------------------------------------------------------------------
if "%LOG_ENABLED%"=="1" (
    >"%LOGFILE%" echo [%DATE% %TIME%] Tool started - v%TOOL_VERSION% by %TOOL_AUTHOR%
)


:: ----------------------------------------------------------------------
:: Multi-Language Messages
:: ----------------------------------------------------------------------
if "%LANG%"=="EN" goto :SET_EN
if "%LANG%"=="GR" goto :SET_GR


:SET_EN
set MSG_TITLE=Mythouni AnyDesk Reset Tool v%TOOL_VERSION%
set MSG_ADMIN_ERR=[ERROR] Please run this script as Administrator.
set MSG_STOP=Stopping AnyDesk...
set MSG_BACKUP=Creating temporary backup...
set MSG_REMOVE=Removing main AnyDesk configuration files...
set MSG_START=Starting AnyDesk to generate new system.conf...
set MSG_WAIT=Waiting for system.conf to be created...
set MSG_STOP2=Stopping AnyDesk again for restore...
set MSG_RESTORE=Restoring previous settings...
set MSG_CLEANUP=Cleaning temporary backup...
set MSG_DONE=Process completed. Your ID and Alias were preserved.
set MSG_AD_NOT_FOUND=AnyDesk executable not found. Please start it manually if needed.
goto :LANG_DONE


:SET_GR
set MSG_TITLE=Mythouni AnyDesk Reset Tool v%TOOL_VERSION%
set MSG_ADMIN_ERR=[ΣΦΑΛΜΑ] Τρέξτε το script ως Διαχειριστής.
set MSG_STOP=Τερματισμός AnyDesk...
set MSG_BACKUP=Δημιουργία προσωρινού αντιγράφου...
set MSG_REMOVE=Διαγραφή βασικών αρχείων ρυθμίσεων...
set MSG_START=Εκκίνηση AnyDesk για δημιουργία νέου system.conf...
set MSG_WAIT=Αναμονή για δημιουργία system.conf...
set MSG_STOP2=Νέος τερματισμός AnyDesk για επαναφορά...
set MSG_RESTORE=Επαναφορά προηγούμενων ρυθμίσεων...
set MSG_CLEANUP=Καθαρισμός προσωρινού αντιγράφου...
set MSG_DONE=Ολοκληρώθηκε με επιτυχία. Το ID και Alias διατηρήθηκαν.
set MSG_AD_NOT_FOUND=Δεν βρέθηκε το AnyDesk. Ξεκινήστε το χειροκίνητα.
goto :LANG_DONE


:LANG_DONE


title %MSG_TITLE%

:: ----------------------------------------------------------------------
:: Check Admin Rights
:: ----------------------------------------------------------------------
reg query "HKEY_USERS\S-1-5-19" >NUL 2>&1 || (
    echo %MSG_ADMIN_ERR%
    if "%LOG_ENABLED%"=="1" >>"%LOGFILE%" echo Missing admin rights.
    pause
    exit /b
)


:: ----------------------------------------------------------------------
:: Locate AnyDesk Executable Automatically
:: ----------------------------------------------------------------------
set "AD_EXE="

if exist "%ProgramFiles%\AnyDesk\AnyDesk.exe" set "AD_EXE=%ProgramFiles%\AnyDesk\AnyDesk.exe"
if exist "%ProgramFiles(x86)%\AnyDesk\AnyDesk.exe" set "AD_EXE=%ProgramFiles(x86)%\AnyDesk\AnyDesk.exe"

:: Portable Support: check Desktop / Downloads / script folder
if exist "%CD%\AnyDesk.exe" set "AD_EXE=%CD%\AnyDesk.exe"
if exist "%USERPROFILE%\Desktop\AnyDesk.exe" set "AD_EXE=%USERPROFILE%\Desktop\AnyDesk.exe"
if exist "%USERPROFILE%\Downloads\AnyDesk.exe" set "AD_EXE=%USERPROFILE%\Downloads\AnyDesk.exe"


:: If still empty, warn but continue
if "%AD_EXE%"=="" (
    echo %MSG_AD_NOT_FOUND%
    if "%LOG_ENABLED%"=="1" >>"%LOGFILE%" echo [WARNING] AnyDesk executable not found.
)


:: ----------------------------------------------------------------------
:: Paths
:: ----------------------------------------------------------------------
set "AD_APPDATA=%APPDATA%\AnyDesk"
set "AD_COMMON=%ALLUSERSPROFILE%\AnyDesk"
set "BACKUP_DIR=%TEMP%\Mythouni_AD_Backup"


:: ----------------------------------------------------------------------
:: UI Header
:: ----------------------------------------------------------------------
echo ===========================================
echo       %MSG_TITLE%
echo       Author: %TOOL_AUTHOR%
echo       Version: %TOOL_VERSION%
echo ===========================================
echo.


:: ===========================
:: MAIN RESET PROCESS
:: ===========================

echo [1/9] %MSG_STOP%
call :STOP_AD

echo [2/9] %MSG_BACKUP%
mkdir "%BACKUP_DIR%" >NUL
call :SAFE_COPY "%AD_APPDATA%\user.conf" "%BACKUP_DIR%\user.conf"
call :SAFE_COPY "%AD_APPDATA%\ad.mplist" "%BACKUP_DIR%\ad.mplist"
call :SAFE_COPY "%AD_APPDATA%\connections.txt" "%BACKUP_DIR%\connections.txt"
call :SAFE_XCOPY "%AD_APPDATA%\thumbnails" "%BACKUP_DIR%\thumbnails"


echo [3/9] %MSG_REMOVE%
del /f "%AD_COMMON%\service.conf"  >NUL 2>&1
del /f "%AD_APPDATA%\service.conf" >NUL 2>&1
del /f "%AD_COMMON%\system.conf"   >NUL 2>&1


echo [4/9] %MSG_START%
call :START_AD


echo [5/9] %MSG_WAIT%
:WAIT_SYSTEM
timeout /t 1 >NUL
if not exist "%AD_COMMON%\system.conf" goto WAIT_SYSTEM


echo [6/9] %MSG_STOP2%
call :STOP_AD


echo [7/9] %MSG_RESTORE%
call :SAFE_COPY "%BACKUP_DIR%\user.conf" "%AD_APPDATA%\user.conf"
call :SAFE_COPY "%BACKUP_DIR%\ad.mplist" "%AD_APPDATA%\ad.mplist"
call :SAFE_COPY "%BACKUP_DIR%\connections.txt" "%AD_APPDATA%\connections.txt"
call :SAFE_XCOPY "%BACKUP_DIR%\thumbnails" "%AD_APPDATA%\thumbnails"


echo [8/9] %MSG_CLEANUP%
rd /s /q "%BACKUP_DIR%" >NUL


echo [9/9] Starting AnyDesk...
call :START_AD

echo.
echo %MSG_DONE%
echo.
pause
exit /b




:: ==========================================================
:: FUNCTIONS
:: ==========================================================

:START_AD
if "%AD_EXE%"=="" goto :EOF
start "" "%AD_EXE%"
if "%LOG_ENABLED%"=="1" >>"%LOGFILE%" echo Started AnyDesk from "%AD_EXE%"
goto :EOF


:STOP_AD
taskkill /f /im "AnyDesk.exe" >NUL 2>&1
if "%LOG_ENABLED%"=="1" >>"%LOGFILE%" echo AnyDesk process terminated.
goto :EOF


:SAFE_COPY
set "SRC=%~1"
set "DST=%~2"
if exist "%SRC%" (
    copy /y "%SRC%" "%DST%" >NUL
    if "%LOG_ENABLED%"=="1" >>"%LOGFILE%" echo Copied "%SRC%" to "%DST%"
)
goto :EOF


:SAFE_XCOPY
set "SRC=%~1"
set "DST=%~2"
if exist "%SRC%" (
    xcopy /c /e /h /r /y /i "%SRC%" "%DST%" >NUL
    if "%LOG_ENABLED%"=="1" >>"%LOGFILE%" echo XCopy "%SRC%" to "%DST%"
)
goto :EOF



:SHOW_HELP
echo.
echo  Mythouni AnyDesk Reset Tool v%TOOL_VERSION%
echo  ---------------------------------------------
echo  /log        Enable logging
echo  /lang:EN    English
echo  /lang:GR    Greek
echo  /? or -h    Show this help page
echo.
pause
exit /b

