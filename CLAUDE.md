# Claude Instructions — zapret-albion-online

## Project Context

A DPI bypass tool for **Albion Online** in Russia, based on a fork of [bol-van/zapret-win-bundle](https://github.com/bol-van/zapret-win-bundle). Target audience: regular users, not technical specialists.

---

## Repository Structure

```
zapret-albion-online/
├── AlbionOnline_Launcher.bat   — single launcher, user entry point
├── readme.md                   — documentation
├── CONTRIBUTING.md             — contribution guidelines
├── bin/                        — zapret binaries (do not edit manually)
│   ├── winws.exe               — main DPI bypass tool
│   ├── WinDivert.dll           — driver library
│   ├── WinDivert64.sys         — Windows kernel driver
│   └── cygwin1.dll             — runtime for winws.exe
├── lists/                      — generated at runtime, excluded from git
│   ├── albion-hosts.txt        — domain list (created by launcher)
│   └── settings.ini            — auto-saved last strategy choice
├── arm64/                      — files for Windows ARM64
└── win7/                       — files for Windows 7
```

---

## How the Launcher Works

`AlbionOnline_Launcher.bat` — interactive menu with ANSI colors (Windows 10+):

- **[A]** Auto-select: launches winws in background (`start /b`), tests TLS connection to `loginserver.live.albion.zone:443` via PowerShell, tries strategies 1→4
- **[1–4]** Manual strategy launch — winws blocks bat execution until Ctrl+C
- **[5]** Network diagnostics (nslookup, ping, tracert)
- **[6]** Switch DNS to Cloudflare 1.1.1.1

Last selected strategy is saved to `lists/settings.ini`.

---

## winws Strategies

| # | Parameters | Purpose |
|---|------------|---------|
| 1 | fake + split2 | Soft, most ISPs |
| 2 | fake + multidisorder | Medium |
| 3 | multisplit + seqovl | Aggressive (Rostelecom-like DPI) |
| 4 | fake + multidisorder, no hostlist | Full HTTPS bypass |

Strategies 1–3 apply only to domains from `lists/albion-hosts.txt`.

---

## Important Constraints

- **Do not add server selection** (Americas/Europe/Asia) — all domains are already included in the hostlist
- **Do not auto-change DNS in [A] mode** — user does this explicitly via [6]
- **Do not touch `bin/`** — binaries come from the original zapret-win-bundle
- **`lists/` is in `.gitignore`** — generated locally at runtime
- **Keep it simple** — target users are non-technical, UX matters
- **Do not add blockcheck, cygwin** or other tools from the original fork — the project is intentionally simplified
- **Keep `arm64/` and `win7/`** — needed for non-standard configurations

---

## Releases

Pushing a tag `vX.Y` triggers GitHub Actions to create a release with a ZIP archive (`.github/workflows/release.yml`). The ZIP excludes `.git`, `.github`, `.claude`, `lists/albion-hosts.txt`, `lists/settings.ini`.

```
git tag v1.1
git push origin v1.1
```

---

## Commit Convention

All commits must be in English. Format: `type: short description`

Types: `feat`, `fix`, `refactor`, `docs`, `chore`
