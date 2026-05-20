# Google Play Store — Release History

Source: Play Console production track (as of May 2026).  
Git baseline branch: **`production/v1.0.10-build18`** (from `multi_branch`).

## Live production

| Version code | Version name | Released (Play) | Git branch / commit |
|-------------|--------------|-----------------|---------------------|
| **18** | **1.0.10** | 14 Apr 2026 09:06 | `production/v1.0.10-build18` → `2defadd` (code base: `multi_branch` / `f456402`) |

## Full release history

| Code | Name | Released (Play) | Replaced | Git `pubspec` bump (if in repo) | Commit |
|------|------|-----------------|----------|----------------------------------|--------|
| 18 | 1.0.10 | 14 Apr 2026 09:06 | — (current) | `1.0.10+18` | `2defadd` |
| 17 | 1.0.9 | 28 Mar 2026 12:08 | 14 Apr 2026 09:06 | `1.0.9+17` | `089d4c8` |
| 16 | 1.0.8 | 21 Mar 2026 20:09 | 28 Mar 2026 12:08 | `1.0.8+16` | `6c99d30` |
| 15 | 1.0.7 | 19 Mar 2026 00:31 | 21 Mar 2026 20:09 | `1.0.7+15` | `044727e` |
| 14 | 1.0.6 | 9 Mar 2026 02:53 | 19 Mar 2026 00:31 | `1.0.6+14` | `4122abd` |
| 12 | 1.0.5 | 1 Mar 2026 11:05 | 9 Mar 2026 02:53 | `1.0.5+12` | `c36c0b4` |
| 11 | 1.0.5 | 25 Feb 2026 23:33 | 1 Mar 2026 11:05 | `1.0.5+11` | `ca76505` |
| 6 | 1.0.4 | (no date) | 25 Feb 2026 23:33 | — | Not tagged in recent git |

**Note:** Version code **13** was never published to production (Play jumps 12 → 14).

## Branch strategy

| Branch | Purpose |
|--------|---------|
| `multi_branch` | Latest feature work (pre-production version in `pubspec` until next release) |
| `production/v1.0.10-build18` | Matches **live Play** build 18 |
| `store_seperation` | Release line through 1.0.9+17 |
| `origin/super-admin-setup` | Future super-admin work (separate) |
| `development` | Older integration branch; behind production |

## Next upload

- Bump `pubspec.yaml` to **`1.0.11+19`** (or higher).
- Commit: `release: v1.0.11+19 - <summary>`
- Build: `flutter build appbundle --release`
- Update this file after Play Console upload.
