# Revive launcher setup notes

## Discord OAuth through Supabase

The launcher uses the existing Supabase project and Discord OAuth provider. It starts a temporary loopback HTTP callback on `127.0.0.1` and uses PKCE; the Discord Gate/Tailscale authentication flow remains separate and unchanged.

In Supabase Dashboard → Authentication → URL Configuration

they are not embedded in the launcher.

The publishable Supabase key is used by the desktop client. No `service_role` key is included. Access and refresh tokens are stored using Windows secure storage.

## Discord Rich Presence

The launcher keeps the existing Discord Application ID and the existing Windows IPC Rich Presence implementation. The large image key is now `revive-logo`. Upload the Revive emblem to the same Discord Developer Portal application under Rich Presence → Art Assets using the exact asset key `revive-logo` for the image to appear. Until that asset exists, Discord may omit the large image; text presence remains available.

The presence invite button points to `https://discord.gg/jgAxnBrP9`.

## Revive release feed

Self-update checks are intentionally disabled until Revive has its own release repository/feed. This prevents a Revive installation from offering an upstream ATLAS Link update that could overwrite the fork's branding. The original ATLAS Link source/repository remains credited in the project.

## Build

Run `flutter pub get` after opening `atlas_link_flutter`, then build with the Windows Flutter toolchain. This environment did not have Flutter/Dart installed, so a Windows compile could not be run here.

## Branding assets

`atlas_link_flutter/assets/images/atlas_logo.png` is the Revive emblem used for the app icon and compact logo placements. `atlas_link_flutter/assets/images/revive_wordmark.png` is the supplied Revive wordmark with its black background removed; it is used only for the launcher startup brand text. The rest of the launcher typography and interface styling are intentionally unchanged.
