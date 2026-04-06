# zapret-albion-online

DPI bypass tool for **Albion Online** in Russia, based on [zapret](https://github.com/bol-van/zapret).

Supports all game servers: Americas, Europe, Asia.

---

## Requirements

- Windows 7 x64 / Windows 10 / Windows 11
- Administrator privileges

---

## Quick Start

1. Download the repository (**Code → Download ZIP**) and extract it
2. Right-click `AlbionOnline_Launcher.bat` → **Run as administrator**
3. Select **[A] Auto-select strategy**
4. Wait for the result, then launch Albion Online — keep the launcher window open

---

## If [A] Didn't Help

1. Select **[6] Configure DNS** — switches DNS to Cloudflare 1.1.1.1
2. Run **[A]** again

---

## Menu

| Option | Description |
|--------|-------------|
| **[A]** | Automatically tests strategies 1→4 and picks the working one |
| **[1]** | Soft: fake + split2. Works for most ISPs |
| **[2]** | Medium: fake + multidisorder |
| **[3]** | Aggressive: multisplit + seqovl. For Rostelecom-like DPI |
| **[4]** | Full bypass of all HTTPS traffic. Last resort |
| **[5]** | Diagnostics: tracert + nslookup to Albion servers |
| **[6]** | Set DNS to Cloudflare 1.1.1.1 |

---

## Antivirus

`WinDivert64.sys` may trigger false positives — it is a traffic interception driver required by zapret. Add the `bin\` folder to your antivirus exclusions. Original files can be verified at [reqrypt.org](https://reqrypt.org/download).

---

## ARM64 / Windows 7

By default the launcher works on Windows 10/11 x64. For special configurations:

**ARM64** (Surface Pro X, Snapdragon laptops, etc.)

The standard `WinDivert64.sys` driver cannot load on ARM without test signing mode. If winws fails to start — run `arm64\install_arm64.cmd` and reboot. A "Test Mode" watermark will appear on the desktop.

**Windows 7**

A different version of WinDivert is required for Windows 7. If the driver fails to load — run `win7\install_win7.cmd`, which replaces files in `bin\` with compatible ones. Alternatively, install Microsoft ESU updates.

---

## Links

- [zapret](https://github.com/bol-van/zapret) — original project
- [zapret-win-bundle](https://github.com/bol-van/zapret-win-bundle) — Windows build
