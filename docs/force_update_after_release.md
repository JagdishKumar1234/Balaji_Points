# Force update after a Play Store release

How to make everyone update once a new version is live. Written for release 1.1.1 (build 33), replacing live version 1.1.0 (build 31).

## The rule that matters

**Change the Firestore config only after the new version is live on Play at 100% rollout.**

If you change it earlier, users are blocked with "Update required" but Play has nothing to give them. They cannot use the app until you undo the change.

## Steps

1. Upload the `.aab` to Play Console. Test it on Internal testing first, including Google sign-in.
2. Publish it to Production at **full rollout, not staged**.
3. Wait until Play Console shows **Published**. This can take from minutes to several hours.
4. On a phone that still has 1.1.0, open the app's Play Store page and confirm the **Update** button appears.
5. Open Firebase Console > Firestore > `app_config` > `version` and change these two fields:

   | Field | Now | Change to |
   |---|---|---|
   | `androidLatestVersion` | `"1.0.19"` | `"1.1.1"` |
   | `androidMinimumVersion` | `"1.0.19"` | `"1.1.1"` |

   Keep them as text (string), with the quotes. Change nothing else.

6. On that same phone (still 1.1.0), close the app fully and reopen it. It should show "Update required".
7. Tap **Update now**. It should open the Balaji Points page in Play. Update, then open the app: it should go to home as normal.

## Check before saving

- Edit `app_config/version`. The app does not read `app_config/config`.
- `androidForceUpdate` is already `true`. Leave it.
- `androidUpdateUrl` is already correct. Leave it.
- Do not change the `ios...` fields for an Android release.

## If something goes wrong

Users blocked, or the update is not showing in Play? Set both fields back to `"1.0.19"`. The block is lifted the next time the app starts, with no new upload needed.

## What to expect

| Version on the phone | After the change |
|---|---|
| Below 1.1.1 (1.1.0, 1.0.19 and older) | Blocked. The only option is "Update now" |
| 1.1.1 or newer | Opens normally |

- **The check runs only when the app starts.** Someone with the app open in the background is not blocked until it restarts.
- **No internet, or the check fails:** the app opens as normal, so a few users can get past the block while offline.
- **Website:** not affected. The check only runs in the Android and iOS apps.

## Next releases

Repeat the same steps with the new version number. Always upload with a higher build number than any build already uploaded to Play.
