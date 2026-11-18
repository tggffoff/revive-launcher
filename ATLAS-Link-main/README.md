<p align="center">
  <img width="520" alt="Revive" src="atlas_link_flutter/assets/images/revive_wordmark.png" />
</p>

<h1 align="center">Revive</h1>

<p align="center">
  An independent Windows launcher for organizing and managing Fortnite builds.
</p>

<p align="center">
  <strong>Built for your builds. Designed around your experience.</strong>
</p>

---

## About Revive

**Revive** is a community launcher project built on the foundations of ATLAS Link. It brings build management, launch options, mod organization, backend tools and account features together in one desktop experience.

Revive is an independent rebrand and is not an official release of ATLAS Link. The original project and its contributors remain credited below, and their license terms continue to apply.

## What Revive includes

### Build library

- Import existing Fortnite installations into a central library.
- Import multiple builds from a parent folder.
- Rename builds and update their root folders.
- Open build folders directly from the launcher.
- Mark favorite builds, search, filter and sort the library.

### Build archives

- Dedicated Build Archives section.
- Quick links to community build archives, including FortForge, Carbon and Helix.

### Launching and server tools

- Launch selected builds from the library.
- Configure and host game-server sessions with available launch options.
- Automatic restart support for hosted sessions.
- Optional cleanup for `GFSDK_Aftermath_Lib.dll`.
- Multi-client launching support.

### Injector and mods

- Manage a personal DLL library and select files for the injector.
- Browse separate Pak and DLL mod categories.
- View mod descriptions, previews, versions and compatibility information.
- Install, uninstall and update supported mods across selected builds.
- Optional automatic file updates when Revive launches.

### Backend tools

- Optional embedded support for LawinServer and Neonite.
- Backend installation and launch helpers.
- Backend status, connection controls and saved backend lists.

### Profile and quality-of-life features

- Profile name and avatar customization.
- Revive account sign-in through Discord OAuth and Supabase.
- Discord Rich Presence.
- Per-build and total playtime tracking.
- Startup animation settings, update notes and data-management tools.

## Project structure

```text
ATLAS-Link-main/
├── atlas_link_flutter/       Flutter desktop application
├── discord_rpc_proxy/        Discord RPC proxy source/build files
├── installer/                Windows installer scripts
├── network-gate/             Network access helper
├── backends/                 Backend-related project files
├── config/                   Launcher configuration
└── README.md
```

## Build Revive on Windows

### Requirements

- Windows 10 or newer.
- Flutter SDK with Windows desktop support.
- Visual Studio 2022 or Build Tools with the **Desktop development with C++** workload.
- PowerShell.
- Inno Setup 6 (only if you want to build the installer).

### Get the source

```powershell
git clone <YOUR-REVIVE-REPOSITORY-URL>
cd ATLAS-Link-main
cd atlas_link_flutter
flutter pub get
```

### Run the launcher

From the repository root:

```powershell
.\launch-atlas-link.cmd
```

Or from the Flutter project directory:

```powershell
cd atlas_link_flutter
flutter run -d windows
```

### Build the Windows release

From the Flutter project directory:

```powershell
flutter build windows --release
```

The GitHub Actions workflow can also build the Windows release and publish the output as a downloadable workflow artifact.

## Revive account configuration

Discord sign-in uses the configured Supabase project and a local loopback callback. Follow the instructions in [REVIVE_SETUP.md](REVIVE_SETUP.md) to configure the Supabase redirect allow-list and Discord provider.

The Discord Gate/Tailscale network access flow remains separate from Revive account sign-in. Rich Presence also remains a separate feature.

## Project status

Revive is an independently maintained community project. Features and build compatibility may change as the launcher evolves. Always use trusted source code and follow the terms of the included licenses and the terms of any third-party components.

---

## Credits and acknowledgements

Revive is based on **ATLAS Link** by cipherfps and its contributors. This project retains the original attribution and license requirements. Revive is not an official ATLAS Link release.

- **cipherfps and the ATLAS Link contributors** — original launcher project and foundational code.
- [Auties00](https://github.com/Auties00) — [Reboot Launcher](https://github.com/Auties00/Reboot-Launcher), an upstream project acknowledged by ATLAS Link.
- [Lawin0129](https://github.com/Lawin0129) — LawinServer, included as an optional embedded backend.
- [HybridFNBR](https://github.com/HybridFNBR) — NeoniteV2, included as an optional embedded backend.
- **Flutter and package maintainers** — the framework and third-party packages used by the launcher.

Please consult the included [LICENSE](LICENSE) and each third-party project's license before redistributing code or bundled components. All respective copyrights and licenses remain with their original owners.
