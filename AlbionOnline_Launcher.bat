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

:: --- Colors ---
set "C_GREEN=[32m"
set "C_YELLOW=[33m"
set "C_RED=[31m"
set "C_CYAN=[36m"
set "C_RESET=[0m"

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

:: --- Load last choice ---
set "LAST="
if exist "%SETTINGS%" (
    for /f "tokens=2 delims==" %%a in ('findstr /i "last_strategy" "%SETTINGS%"') do set "LAST=%%a"
)

:: --- Menu ---
:MENU
cls
echo.
echo  %C_CYAN%╔══════════════════════════════════════════════════╗%C_RESET%
echo  %C_CYAN%║        ALBION ONLINE — DPI BYPASS TOOL          ║%C_RESET%
echo  %C_CYAN%╚══════════════════════════════════════════════════╝%C_RESET%
echo.
if defined LAST (
    echo  %C_YELLOW% Last run: strategy %LAST%%C_RESET%
    echo.
)
echo  %C_GREEN% [A]%C_RESET%  Auto-select strategy
echo       Tests each strategy and picks the one that works
echo.
echo  %C_GREEN% [1]%C_RESET%  Soft            (fake + split2)
echo       Start here. Works for most ISPs
echo.
echo  %C_GREEN% [2]%C_RESET%  Medium          (fake + multidisorder)
echo       If strategy 1 doesn't help
echo.
echo  %C_GREEN% [3]%C_RESET%  Aggressive      (multisplit + seqovl)
echo       Heavy filtering (Rostelecom-like DPI)
echo.
echo  %C_GREEN% [4]%C_RESET%  Full bypass     (all HTTPS, no domain filter)
echo       Last resort. May slow down other sites
echo.
echo  %C_YELLOW% [5]%C_RESET%  Diagnostics     (tracert + nslookup)
echo  %C_YELLOW% [6]%C_RESET%  Configure DNS   (Cloudflare 1.1.1.1)
echo.
echo  %C_RED% [0]%C_RESET%  Exit
echo.
set /p "CHOICE=  Choice: "

if /i "%CHOICE%"=="A" goto AUTO
if "%CHOICE%"=="1" goto STRATEGY1
if "%CHOICE%"=="2" goto STRATEGY2
if "%CHOICE%"=="3" goto STRATEGY3
if "%CHOICE%"=="4" goto STRATEGY4
if "%CHOICE%"=="5" goto DIAG
if "%CHOICE%"=="6" goto DNS
if "%CHOICE%"=="0" goto EXIT
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
echo  Timeout per attempt: 8 seconds
echo.

:: Stop winws if already running
taskkill /f /im winws.exe >nul 2>&1
timeout /t 1 >nul

set "FOUND_STRATEGY="

for %%S in (1 2 3 4) do (
    if not defined FOUND_STRATEGY (
        echo  %C_YELLOW%[%%S/4]%C_RESET% Trying strategy %%S...
        call :START_STRATEGY_BG %%S
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
    echo  %C_GREEN%  Strategy %FOUND_STRATEGY% selected — winws is running%C_RESET%
    echo  %C_GREEN%═══════════════════════════════════════%C_RESET%
    echo.
    echo  Launch Albion Online. Keep this window open.
    call :SAVE_LAST %FOUND_STRATEGY%
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
    echo  - Configure DNS via option [6]
    echo  - Run diagnostics [5]
    echo  - Try strategy [4] manually
)
echo.
pause
goto MENU

:: --- Launch strategy in background ---
:START_STRATEGY_BG
if "%~1"=="1" (
    start /b "" "%WINWS%" ^
        --wf-l3=ipv4 --wf-tcp=80,443 ^
        --filter-tcp=80 --hostlist="%HOSTLIST%" ^
        --dpi-desync=fake,fakedsplit --dpi-desync-autottl=2 --dpi-desync-fooling=md5sig ^
        --new ^
        --filter-tcp=443 --hostlist="%HOSTLIST%" ^
        --dpi-desync=fake,split2 --dpi-desync-autottl=2 --dpi-desync-fooling=md5sig ^
        --dpi-desync-split-pos=1
)
if "%~1"=="2" (
    start /b "" "%WINWS%" ^
        --wf-l3=ipv4 --wf-tcp=80,443 ^
        --filter-tcp=80 --hostlist="%HOSTLIST%" ^
        --dpi-desync=fake,fakedsplit --dpi-desync-autottl=2 --dpi-desync-fooling=md5sig ^
        --new ^
        --filter-tcp=443 --hostlist="%HOSTLIST%" ^
        --dpi-desync=fake,multidisorder --dpi-desync-split-pos=midsld ^
        --dpi-desync-repeats=6 --dpi-desync-fooling=badseq,md5sig
)
if "%~1"=="3" (
    start /b "" "%WINWS%" ^
        --wf-l3=ipv4 --wf-tcp=80,443 ^
        --filter-tcp=80 --hostlist="%HOSTLIST%" ^
        --dpi-desync=fake,multisplit --dpi-desync-split-pos=1,method+1 ^
        --dpi-desync-split-seqovl=2 --dpi-desync-fooling=md5sig ^
        --new ^
        --filter-tcp=443 --hostlist="%HOSTLIST%" ^
        --dpi-desync=fake,multidisorder --dpi-desync-split-pos=1,midsld ^
        --dpi-desync-repeats=11 --dpi-desync-fooling=badseq,md5sig ^
        --dpi-desync-split-seqovl=1
)
if "%~1"=="4" (
    start /b "" "%WINWS%" ^
        --wf-l3=ipv4 --wf-tcp=80,443 ^
        --filter-tcp=80 ^
        --dpi-desync=fake,fakedsplit --dpi-desync-autottl=2 --dpi-desync-fooling=md5sig ^
        --new ^
        --filter-tcp=443 ^
        --dpi-desync=fake,multidisorder --dpi-desync-split-pos=midsld ^
        --dpi-desync-repeats=6 --dpi-desync-fooling=badseq,md5sig ^
        --dpi-desync-any-protocol
)
exit /b

:: --- TLS connection test ---
:TEST_CONNECTION
set "TEST_OK=0"
powershell -NoProfile -NonInteractive -Command ^
    "try { $t = New-Object System.Net.Sockets.TcpClient; $r = $t.ConnectAsync('%TEST_HOST%', %TEST_PORT%); if ($r.Wait(8000) -and $t.Connected) { $s = $t.GetStream(); $ssl = New-Object System.Net.Security.SslStream($s, $false, {$true}); $ssl.AuthenticateAsClient('%TEST_HOST%', $null, 'Tls12', $false); if ($ssl.IsAuthenticated) { exit 0 } } exit 1 } catch { exit 1 }" >nul 2>&1
if %errorlevel%==0 set "TEST_OK=1"
exit /b

:: ============================================================================
:STRATEGY1
call :SAVE_LAST 1
echo.
echo  %C_GREEN%► Strategy 1: fake + split2%C_RESET%
echo  %C_YELLOW%  Press Ctrl+C to stop%C_RESET%
echo.
"%WINWS%" ^
    --wf-l3=ipv4 --wf-tcp=80,443 ^
    --filter-tcp=80 --hostlist="%HOSTLIST%" ^
    --dpi-desync=fake,fakedsplit --dpi-desync-autottl=2 --dpi-desync-fooling=md5sig ^
    --new ^
    --filter-tcp=443 --hostlist="%HOSTLIST%" ^
    --dpi-desync=fake,split2 --dpi-desync-autottl=2 --dpi-desync-fooling=md5sig ^
    --dpi-desync-split-pos=1
goto END

:: ============================================================================
:STRATEGY2
call :SAVE_LAST 2
echo.
echo  %C_GREEN%► Strategy 2: fake + multidisorder%C_RESET%
echo  %C_YELLOW%  Press Ctrl+C to stop%C_RESET%
echo.
"%WINWS%" ^
    --wf-l3=ipv4 --wf-tcp=80,443 ^
    --filter-tcp=80 --hostlist="%HOSTLIST%" ^
    --dpi-desync=fake,fakedsplit --dpi-desync-autottl=2 --dpi-desync-fooling=md5sig ^
    --new ^
    --filter-tcp=443 --hostlist="%HOSTLIST%" ^
    --dpi-desync=fake,multidisorder --dpi-desync-split-pos=midsld ^
    --dpi-desync-repeats=6 --dpi-desync-fooling=badseq,md5sig
goto END

:: ============================================================================
:STRATEGY3
call :SAVE_LAST 3
echo.
echo  %C_GREEN%► Strategy 3: multisplit + seqovl%C_RESET%
echo  %C_YELLOW%  Press Ctrl+C to stop%C_RESET%
echo.
"%WINWS%" ^
    --wf-l3=ipv4 --wf-tcp=80,443 ^
    --filter-tcp=80 --hostlist="%HOSTLIST%" ^
    --dpi-desync=fake,multisplit --dpi-desync-split-pos=1,method+1 ^
    --dpi-desync-split-seqovl=2 --dpi-desync-fooling=md5sig ^
    --new ^
    --filter-tcp=443 --hostlist="%HOSTLIST%" ^
    --dpi-desync=fake,multidisorder --dpi-desync-split-pos=1,midsld ^
    --dpi-desync-repeats=11 --dpi-desync-fooling=badseq,md5sig ^
    --dpi-desync-split-seqovl=1
goto END

:: ============================================================================
:STRATEGY4
call :SAVE_LAST 4
echo.
echo  %C_GREEN%► Strategy 4: full bypass (all HTTPS)%C_RESET%
echo  %C_RED%  WARNING: may slow down other sites%C_RESET%
echo  %C_YELLOW%  Press Ctrl+C to stop%C_RESET%
echo.
"%WINWS%" ^
    --wf-l3=ipv4 --wf-tcp=80,443 ^
    --filter-tcp=80 ^
    --dpi-desync=fake,fakedsplit --dpi-desync-autottl=2 --dpi-desync-fooling=md5sig ^
    --new ^
    --filter-tcp=443 ^
    --dpi-desync=fake,multidisorder --dpi-desync-split-pos=midsld ^
    --dpi-desync-repeats=6 --dpi-desync-fooling=badseq,md5sig ^
    --dpi-desync-any-protocol
goto END

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
netsh interface ipv6 set dnsservers "%ADAPTER%" static ::1 primary >nul 2>&1
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
:SAVE_LAST
echo last_strategy=%~1> "%SETTINGS%"
exit /b

:END
echo.
echo  %C_YELLOW% winws stopped.%C_RESET%
echo.
pause
goto MENU

:EXIT
exit /b 0
