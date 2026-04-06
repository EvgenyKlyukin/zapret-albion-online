@echo off
setlocal enabledelayedexpansion
chcp 65001 >nul 2>&1
title Albion Online — DPI Bypass

:: Enable ANSI colors (Windows 10+)
reg add HKCU\Console /v VirtualTerminalLevel /t REG_DWORD /d 1 /f >nul 2>&1

:: --- Paths ---
set "ROOT=%~dp0"
set "WINWS=%ROOT%bin\winws.exe"
set "HOSTLIST=%ROOT%lists\albion-hosts.txt"
set "SETTINGS=%ROOT%lists\settings.ini"
set "LOGFILE=%ROOT%lists\winws.log"

:: --- Colors ---
for /f %%a in ('echo prompt $E^| cmd /q') do set "ESC=%%a"
set "C_GREEN=%ESC%[32m"
set "C_YELLOW=%ESC%[33m"
set "C_RED=%ESC%[31m"
set "C_CYAN=%ESC%[36m"
set "C_RESET=%ESC%[0m"

:: --- Test host for auto-select ---
set "TEST_HOST=loginserver.live.albion.zone"
set "TEST_PORT=443"

:: --- Check administrator privileges ---
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo.
    echo %C_RED% Run this script as Administrator!%C_RESET%
    echo  Right-click ^> Run as administrator
    echo.
    pause
    exit /b 1
)

:: --- Check winws.exe exists ---
if not exist "%WINWS%" (
    echo.
    echo %C_RED% ERROR: bin\winws.exe not found!%C_RESET%
    echo.
    echo  Make sure bin\winws.exe, bin\WinDivert.dll
    echo  and bin\WinDivert64.sys are in the same folder as this script.
    echo.
    pause
    exit /b 1
)

:: --- Create Albion Online domain list ---
if not exist "%ROOT%lists" mkdir "%ROOT%lists"
(
echo albiononline.com
echo albion.zone
echo loginserver.live.albion.zone
echo live.albiononline.com
echo assets.albiononline.com
echo live02-loginserver.ams.albion.zone
echo live03-loginserver.sg.albion.zone
echo battleye.com
echo gcdn.co
echo gcorelabs.com
echo gcore.com
) > "%HOSTLIST%"

:: --- Load settings ---
set "LAST="
set "LOG_ENABLED=0"
if exist "%SETTINGS%" (
    for /f "usebackq tokens=1,2 delims==" %%a in ("%SETTINGS%") do (
        if /i "%%a"=="last_strategy" if not "%%b"=="" set "LAST=%%b"
        if /i "%%a"=="log_enabled"   if not "%%b"=="" set "LOG_ENABLED=%%b"
    )
)

:: ============================================================================
:MENU
cls
echo.
echo  %C_CYAN%╔══════════════════════════════════════════════════╗%C_RESET%
echo  %C_CYAN%║        ALBION ONLINE — DPI BYPASS TOOL          ║%C_RESET%
echo  %C_CYAN%╚══════════════════════════════════════════════════╝%C_RESET%
echo.
set "STATUS="
if defined LAST set "STATUS=!C_YELLOW!Last: strategy !LAST!!C_RESET!   "
if "!LOG_ENABLED!"=="1" (
    set "STATUS=!STATUS!!C_GREEN![LOG: ON]!C_RESET!"
) else (
    set "STATUS=!STATUS!!C_YELLOW![LOG: OFF]!C_RESET!"
)
echo   !STATUS!
echo.
echo  %C_GREEN% [A]%C_RESET%  Auto-select strategy  (tests all 1-9)
echo.
echo  %C_CYAN%  -- Universal --%C_RESET%
echo  %C_GREEN% [1]%C_RESET%  Soft        fake + split2             most ISPs
echo  %C_GREEN% [2]%C_RESET%  Medium      fake + multidisorder
echo  %C_GREEN% [3]%C_RESET%  Aggressive  multisplit + seqovl       heavy DPI
echo  %C_GREEN% [4]%C_RESET%  Full bypass all HTTPS, no domain filter
echo.
echo  %C_CYAN%  -- ISP-specific --%C_RESET%
echo  %C_GREEN% [5]%C_RESET%  Beeline     disorder2 + md5sig
echo  %C_GREEN% [6]%C_RESET%  MTS         split2 + datanoack
echo  %C_GREEN% [7]%C_RESET%  Megafon     multidisorder + datanoack
echo  %C_GREEN% [8]%C_RESET%  TTK         multisplit + seqovl4
echo  %C_GREEN% [9]%C_RESET%  Maximum     all HTTPS, disorder2, max repeats
echo.
echo  %C_YELLOW% [D]%C_RESET%  Diagnostics   (tracert + nslookup)
echo  %C_YELLOW% [N]%C_RESET%  Configure DNS (Cloudflare 1.1.1.1)
echo  %C_YELLOW% [L]%C_RESET%  Toggle logging  (lists\winws.log)
echo.
echo  %C_RED% [0]%C_RESET%  Exit
echo.
set /p "CHOICE=  Choice: "

if /i "%CHOICE%"=="A" goto AUTO
if  "%CHOICE%"=="1"  goto STRATEGY1
if  "%CHOICE%"=="2"  goto STRATEGY2
if  "%CHOICE%"=="3"  goto STRATEGY3
if  "%CHOICE%"=="4"  goto STRATEGY4
if  "%CHOICE%"=="5"  goto STRATEGY5
if  "%CHOICE%"=="6"  goto STRATEGY6
if  "%CHOICE%"=="7"  goto STRATEGY7
if  "%CHOICE%"=="8"  goto STRATEGY8
if  "%CHOICE%"=="9"  goto STRATEGY9
if /i "%CHOICE%"=="D" goto DIAG
if /i "%CHOICE%"=="N" goto DNS
if /i "%CHOICE%"=="L" goto TOGGLE_LOG
if  "%CHOICE%"=="0"  goto EXIT
echo  %C_RED% Invalid choice.%C_RESET%
timeout /t 1 >nul
goto MENU

:: ============================================================================
:: AUTO-SELECT STRATEGY
:: ============================================================================
:AUTO
cls
echo.
echo  %C_CYAN%── Auto-select strategy ──%C_RESET%
echo.
echo  Testing connection to %TEST_HOST%:%TEST_PORT%
echo  Strategies 1-9, timeout 8s each
echo.

taskkill /f /im winws.exe >nul 2>&1
timeout /t 1 >nul

set "FOUND_STRATEGY="

for %%S in (1 2 3 4 5 6 7 8 9) do (
    if not defined FOUND_STRATEGY (
        echo  %C_YELLOW%[%%S/9]%C_RESET% Trying strategy %%S...
        call :RUN_BG %%S
        timeout /t 3 >nul

        call :TEST_CONNECTION
        if !TEST_OK!==1 (
            set "FOUND_STRATEGY=%%S"
            echo  %C_GREEN%✓ Strategy %%S works!%C_RESET%
        ) else (
            echo  %C_RED%✗ Strategy %%S failed%C_RESET%
            taskkill /f /im winws.exe >nul 2>&1
            timeout /t 1 >nul
        )
    )
)

echo.
if defined FOUND_STRATEGY (
    echo  %C_GREEN%═══════════════════════════════════════%C_RESET%
    echo  %C_GREEN%  Strategy !FOUND_STRATEGY! selected — winws is running%C_RESET%
    echo  %C_GREEN%═══════════════════════════════════════%C_RESET%
    echo.
    echo  Launch Albion Online. Keep this window open.
    call :SAVE_LAST !FOUND_STRATEGY!
    echo.
    echo  %C_YELLOW%  Press any key to stop winws and return to menu%C_RESET%
    pause >nul
    taskkill /f /im winws.exe >nul 2>&1
) else (
    echo  %C_RED%═══════════════════════════════════════%C_RESET%
    echo  %C_RED%  No strategy worked%C_RESET%
    echo  %C_RED%═══════════════════════════════════════%C_RESET%
    echo.
    echo  Recommendations:
    echo  - Configure DNS via option [N]
    echo  - Run diagnostics [D]
    echo  - Try strategy [9] manually
)
echo.
pause
goto MENU

:: ============================================================================
:: STRATEGY SECTIONS — each shows info, runs winws, waits for Ctrl+C
:: ============================================================================
:STRATEGY1
call :SAVE_LAST 1
echo.
echo  %C_GREEN%► Strategy 1: Soft (fake + split2)%C_RESET%
echo  %C_YELLOW%  Press Ctrl+C to stop%C_RESET%
echo.
call :RUN_FG 1
goto END

:STRATEGY2
call :SAVE_LAST 2
echo.
echo  %C_GREEN%► Strategy 2: Medium (fake + multidisorder)%C_RESET%
echo  %C_YELLOW%  Press Ctrl+C to stop%C_RESET%
echo.
call :RUN_FG 2
goto END

:STRATEGY3
call :SAVE_LAST 3
echo.
echo  %C_GREEN%► Strategy 3: Aggressive (multisplit + seqovl)%C_RESET%
echo  %C_YELLOW%  Press Ctrl+C to stop%C_RESET%
echo.
call :RUN_FG 3
goto END

:STRATEGY4
call :SAVE_LAST 4
echo.
echo  %C_GREEN%► Strategy 4: Full bypass (all HTTPS)%C_RESET%
echo  %C_RED%  WARNING: may slow down other sites%C_RESET%
echo  %C_YELLOW%  Press Ctrl+C to stop%C_RESET%
echo.
call :RUN_FG 4
goto END

:STRATEGY5
call :SAVE_LAST 5
echo.
echo  %C_GREEN%► Strategy 5: Beeline (disorder2 + md5sig)%C_RESET%
echo  %C_YELLOW%  Press Ctrl+C to stop%C_RESET%
echo.
call :RUN_FG 5
goto END

:STRATEGY6
call :SAVE_LAST 6
echo.
echo  %C_GREEN%► Strategy 6: MTS (split2 + datanoack)%C_RESET%
echo  %C_YELLOW%  Press Ctrl+C to stop%C_RESET%
echo.
call :RUN_FG 6
goto END

:STRATEGY7
call :SAVE_LAST 7
echo.
echo  %C_GREEN%► Strategy 7: Megafon (multidisorder + datanoack)%C_RESET%
echo  %C_YELLOW%  Press Ctrl+C to stop%C_RESET%
echo.
call :RUN_FG 7
goto END

:STRATEGY8
call :SAVE_LAST 8
echo.
echo  %C_GREEN%► Strategy 8: TTK (multisplit + seqovl4)%C_RESET%
echo  %C_YELLOW%  Press Ctrl+C to stop%C_RESET%
echo.
call :RUN_FG 8
goto END

:STRATEGY9
call :SAVE_LAST 9
echo.
echo  %C_GREEN%► Strategy 9: Maximum (all HTTPS, max params)%C_RESET%
echo  %C_RED%  WARNING: affects all HTTPS traffic%C_RESET%
echo  %C_YELLOW%  Press Ctrl+C to stop%C_RESET%
echo.
call :RUN_FG 9
goto END

:: ============================================================================
:: WRITE_CMD — writes winws command for strategy %1 to %TEMP%\albion_run.bat
:: All args on a single line so the file can be executed with optional redirect
:: ============================================================================
:WRITE_CMD
if "%~1"=="1" echo "%WINWS%" --wf-l3=ipv4 --wf-tcp=80,443 --filter-tcp=80 --hostlist="%HOSTLIST%" --dpi-desync=fake,fakedsplit --dpi-desync-autottl=2 --dpi-desync-fooling=md5sig --new --filter-tcp=443 --hostlist="%HOSTLIST%" --dpi-desync=fake,split2 --dpi-desync-autottl=2 --dpi-desync-fooling=md5sig --dpi-desync-split-pos=1> "%TEMP%\albion_run.bat"
if "%~1"=="2" echo "%WINWS%" --wf-l3=ipv4 --wf-tcp=80,443 --filter-tcp=80 --hostlist="%HOSTLIST%" --dpi-desync=fake,fakedsplit --dpi-desync-autottl=2 --dpi-desync-fooling=md5sig --new --filter-tcp=443 --hostlist="%HOSTLIST%" --dpi-desync=fake,multidisorder --dpi-desync-split-pos=midsld --dpi-desync-repeats=6 --dpi-desync-fooling=badseq,md5sig> "%TEMP%\albion_run.bat"
if "%~1"=="3" echo "%WINWS%" --wf-l3=ipv4 --wf-tcp=80,443 --filter-tcp=80 --hostlist="%HOSTLIST%" --dpi-desync=fake,multisplit --dpi-desync-split-pos=1,method+1 --dpi-desync-split-seqovl=2 --dpi-desync-fooling=md5sig --new --filter-tcp=443 --hostlist="%HOSTLIST%" --dpi-desync=fake,multidisorder --dpi-desync-split-pos=1,midsld --dpi-desync-repeats=11 --dpi-desync-fooling=badseq,md5sig --dpi-desync-split-seqovl=1> "%TEMP%\albion_run.bat"
if "%~1"=="4" echo "%WINWS%" --wf-l3=ipv4 --wf-tcp=80,443 --filter-tcp=80 --dpi-desync=fake,fakedsplit --dpi-desync-autottl=2 --dpi-desync-fooling=md5sig --new --filter-tcp=443 --dpi-desync=fake,multidisorder --dpi-desync-split-pos=midsld --dpi-desync-repeats=6 --dpi-desync-fooling=badseq,md5sig --dpi-desync-any-protocol> "%TEMP%\albion_run.bat"
if "%~1"=="5" echo "%WINWS%" --wf-l3=ipv4 --wf-tcp=80,443 --filter-tcp=80 --hostlist="%HOSTLIST%" --dpi-desync=fake,disorder2 --dpi-desync-ttl=2 --dpi-desync-fooling=md5sig --new --filter-tcp=443 --hostlist="%HOSTLIST%" --dpi-desync=fake,disorder2 --dpi-desync-ttl=2 --dpi-desync-fooling=md5sig> "%TEMP%\albion_run.bat"
if "%~1"=="6" echo "%WINWS%" --wf-l3=ipv4 --wf-tcp=80,443 --filter-tcp=80 --hostlist="%HOSTLIST%" --dpi-desync=fake,fakedsplit --dpi-desync-autottl=2 --dpi-desync-fooling=datanoack --new --filter-tcp=443 --hostlist="%HOSTLIST%" --dpi-desync=fake,split2 --dpi-desync-autottl=2 --dpi-desync-fooling=datanoack --dpi-desync-split-pos=1> "%TEMP%\albion_run.bat"
if "%~1"=="7" echo "%WINWS%" --wf-l3=ipv4 --wf-tcp=80,443 --filter-tcp=80 --hostlist="%HOSTLIST%" --dpi-desync=fake,fakedsplit --dpi-desync-autottl=2 --dpi-desync-fooling=md5sig --new --filter-tcp=443 --hostlist="%HOSTLIST%" --dpi-desync=fake,multidisorder --dpi-desync-split-pos=1,midsld --dpi-desync-repeats=11 --dpi-desync-fooling=badseq,datanoack --dpi-desync-split-seqovl=1> "%TEMP%\albion_run.bat"
if "%~1"=="8" echo "%WINWS%" --wf-l3=ipv4 --wf-tcp=80,443 --filter-tcp=80 --hostlist="%HOSTLIST%" --dpi-desync=fake,multisplit --dpi-desync-split-pos=1,method+1 --dpi-desync-split-seqovl=4 --dpi-desync-fooling=badseq --new --filter-tcp=443 --hostlist="%HOSTLIST%" --dpi-desync=fake,multisplit --dpi-desync-split-pos=1,midsld --dpi-desync-split-seqovl=4 --dpi-desync-fooling=badseq,md5sig> "%TEMP%\albion_run.bat"
if "%~1"=="9" echo "%WINWS%" --wf-l3=ipv4 --wf-tcp=443 --filter-tcp=443 --dpi-desync=fake,disorder2 --dpi-desync-ttl=3 --dpi-desync-repeats=12 --dpi-desync-fooling=badseq,datanoack --dpi-desync-any-protocol> "%TEMP%\albion_run.bat"
exit /b

:: ============================================================================
:: RUN_FG — run strategy %1 in foreground (blocks until Ctrl+C)
:: ============================================================================
:RUN_FG
call :WRITE_CMD %~1
if "!LOG_ENABLED!"=="1" (
    echo  %C_YELLOW%[LOG] Writing to: %LOGFILE%%C_RESET%
    echo.
    echo ========== %DATE% %TIME% -- Strategy %~1 ========== >> "%LOGFILE%"
    call "%TEMP%\albion_run.bat" >> "%LOGFILE%" 2>&1
) else (
    call "%TEMP%\albion_run.bat"
)
exit /b

:: ============================================================================
:: RUN_BG — run strategy %1 in background (returns immediately)
:: ============================================================================
:RUN_BG
call :WRITE_CMD %~1
if "!LOG_ENABLED!"=="1" (
    echo ========== %DATE% %TIME% -- Strategy %~1 (bg) ========== >> "%LOGFILE%"
    (echo call "%TEMP%\albion_run.bat" 1^>>"%LOGFILE%" 2^>&1) > "%TEMP%\albion_run_log.bat"
    start /b "" "%TEMP%\albion_run_log.bat"
) else (
    start /b "" "%TEMP%\albion_run.bat"
)
exit /b

:: ============================================================================
:: TLS CONNECTION TEST
:: ============================================================================
:TEST_CONNECTION
set "TEST_OK=0"
powershell -NoProfile -NonInteractive -Command ^
    "try { $t = New-Object System.Net.Sockets.TcpClient; $r = $t.ConnectAsync('%TEST_HOST%', %TEST_PORT%); if ($r.Wait(8000) -and $t.Connected) { $s = $t.GetStream(); $ssl = New-Object System.Net.Security.SslStream($s, $false, {$true}); $ssl.AuthenticateAsClient('%TEST_HOST%', $null, 'Tls12', $false); if ($ssl.IsAuthenticated) { exit 0 } } exit 1 } catch { exit 1 }" >nul 2>&1
if %errorlevel%==0 set "TEST_OK=1"
exit /b

:: ============================================================================
:DIAG
echo.
echo  %C_CYAN%── Network Diagnostics ──%C_RESET%
echo.
echo  %C_YELLOW%[DNS] loginserver.live.albion.zone%C_RESET%
nslookup loginserver.live.albion.zone 1.1.1.1 2>nul | findstr /i "Address"
echo.
echo  %C_YELLOW%[DNS] live.albiononline.com%C_RESET%
nslookup live.albiononline.com 1.1.1.1 2>nul | findstr /i "Address"
echo.
echo  %C_YELLOW%[PING] albiononline.com%C_RESET%
ping -n 4 albiononline.com
echo.
echo  %C_YELLOW%[TRACERT] loginserver.live.albion.zone (Ctrl+C to abort)%C_RESET%
tracert -d -w 2000 loginserver.live.albion.zone
echo.
echo  %C_YELLOW%[DNS] Current DNS servers%C_RESET%
ipconfig /all | findstr /i "DNS"
echo.
pause
goto MENU

:: ============================================================================
:DNS
echo.
echo  %C_CYAN%── Set DNS to Cloudflare 1.1.1.1 ──%C_RESET%
echo.
for /f "tokens=1* delims=:" %%a in ('netsh interface show interface ^| findstr /i "Connected подключен"') do (
    for /f "tokens=4" %%c in ("%%b") do set "ADAPTER=%%c"
)
if not defined ADAPTER (
    echo  Could not detect active adapter automatically.
    set /p "ADAPTER=  Enter adapter name (e.g. Ethernet, Wi-Fi): "
)
echo  Adapter: %ADAPTER%
netsh interface ip set dns name="%ADAPTER%" static 1.1.1.1 primary >nul 2>&1
netsh interface ip add dns name="%ADAPTER%" 1.0.0.1 index=2 >nul 2>&1
netsh interface ipv6 set dnsservers "%ADAPTER%" static 2606:4700:4700::1111 primary >nul 2>&1
ipconfig /flushdns >nul 2>&1
echo.
echo  %C_GREEN%✓ DNS set to Cloudflare 1.1.1.1 / 1.0.0.1%C_RESET%
echo.
echo  To revert to automatic DNS:
echo  netsh interface ip set dns name="%ADAPTER%" dhcp
echo.
pause
goto MENU

:: ============================================================================
:TOGGLE_LOG
if "!LOG_ENABLED!"=="1" (
    set "LOG_ENABLED=0"
    echo.
    echo  %C_YELLOW% Logging disabled%C_RESET%
) else (
    set "LOG_ENABLED=1"
    echo.
    echo  %C_GREEN% Logging enabled%C_RESET%
    echo  %C_GREEN% Log file: %LOGFILE%%C_RESET%
)
call :SAVE_SETTINGS
timeout /t 1 >nul
goto MENU

:: ============================================================================
:SAVE_LAST
set "LAST=%~1"
call :SAVE_SETTINGS
exit /b

:SAVE_SETTINGS
(
echo last_strategy=!LAST!
echo log_enabled=!LOG_ENABLED!
) > "%SETTINGS%"
exit /b

:END
echo.
echo  %C_YELLOW% winws stopped.%C_RESET%
echo.
pause
goto MENU

:EXIT
exit /b 0
