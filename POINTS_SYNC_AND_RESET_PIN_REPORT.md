# Points Sync and Reset PIN Audit Report

**Original audit date:** 2026-04-10  
**Last updated:** 2026-04-10 (after global points sync implementation)

**Scope:** `home`, `wallet`, `profile` points sync + reset PIN verification flow

**Modes:**  
- Initial sections: static code audit.  
- **Implementation update:** `UserPointsSyncService` added and wired; behavior described from current codebase.

---

## Implementation update — global points sync (done)

A **single global sync layer** is now in place:

| Component | Role |
|-----------|------|
| `lib/services/user_points_service.dart` | Resolves the current user’s `user_points` document ref (`userId` / `phone` / `userId` field query). |
| `lib/services/user_points_sync_service.dart` | **Singleton** — one live Firestore snapshot subscription to that doc; exposes `ValueNotifier<Map<String, dynamic>?>` `pointsData`; `start()` / `refresh()`. |
| `lib/presentation/screens/home/home_page.dart` | Listens to `pointsData`, merges into `_currentUserData` / `_currentUserPoints`, refreshes rankings. |
| `lib/presentation/screens/wallet/wallet_page.dart` | Total points card reads `pointsData`; pull-to-refresh calls `refresh()`. |
| `lib/presentation/screens/profile/profile_page.dart` | Listens to `pointsData`, merges into `_userData` for points/tier. |

**Effect:** When an admin approves a bill, `BillService.approveBill()` updates `user_points` (and `users`). All three carpenter screens consume the **same** stream via `UserPointsSyncService`, so points/tier stay aligned without duplicate per-screen Firestore subscriptions for points.

---

## Requested scenario check

Scenario:

1. Install app from Play Store  
2. Create new account  
3. Update profile  
4. Add bill  
5. Admin approves bill  
6. Points should sync in Home, Wallet, and Profile  

**Backend:** `BillService.approveBill()` still updates `bills`, `users` (`totalPoints` / `tier`), and `user_points` in one batch.

**Client:** Home, Wallet, and Profile now share **`UserPointsSyncService`** for live `user_points` data.

---

## Executive result (current)

- Bill approval continues to update both `users` and `user_points` atomically — good.
- **Global sync:** **Met** — one subscription + shared `pointsData` for Home, Wallet, and Profile.
- Doc resolution for that subscription still goes through **`UserPointsService`** (single resolver; no duplicate Home-only resolver).
- Reset PIN findings below are **unchanged** by this work (still recommended follow-ups).

---

## Findings (ordered by severity)

### 1) ~~High~~ **Resolved** — Global points sync across Home / Wallet / Profile

**Was:** Home duplicated `_resolveCurrentUserPointsDocRef` / `_subscribeUserPointsForCurrentUser`; Wallet/Profile used `UserPointsService` separately.

**Now:** `UserPointsSyncService` owns the subscription; Home, Wallet, and Profile attach listeners to `pointsData` and call `start()` (Wallet also `refresh()` on pull).

**Files:**  
`lib/services/user_points_sync_service.dart`, `user_points_service.dart`, `home_page.dart`, `wallet_page.dart`, `profile_page.dart`

**Status:** **Done** (as of report update).

---

### 2) Medium — Wallet bill queries still keyed off phone only

**Still applies**

- Wallet loads `_userId` from `SessionService.getPhoneNumber()` and uses it for `bills` queries (`carpenterId`).
- `add_bill` uses `getUserId() ?? phone` for `carpenterId`.

**Risk:** If `userId` ≠ phone in session for some accounts, bill list/counts on Wallet can disagree with stored bills.

**Files:** `wallet_page.dart`, `add_bill_page.dart`

**Recommendation:** Use the same candidate strategy as points (`userId` first, then phone) for bill queries.

**Status:** **Open**

---

### 3) Medium — Reset PIN: silent failure on logged-in phone mismatch

**Still applies**

- If logged-in phone ≠ typed phone, `_checkPhone()` can return without a user-visible message.

**File:** `lib/features/auth/presentation/pages/reset_pin_page.dart`

**Recommendation:** Show an explicit error (e.g. only the logged-in number can be used).

**Status:** **Open**

---

### 4) Medium — Logged-out reset uses `setPinForPhone` after `hasPin` only

**Still applies** — no OTP / current PIN / admin gate on that path from a product-security perspective.

**Files:** `reset_pin_page.dart`, `pin_auth_service.dart`

**Status:** **Open**

---

### 5) Low — Duplicate reset PIN page files

**Still applies**

- Router uses `lib/features/auth/presentation/pages/reset_pin_page.dart`
- Legacy duplicate: `lib/presentation/screens/auth/reset_pin_page.dart`

**Status:** **Open**

---

## Scenario outcome vs expectation (current)

| Topic | Expected | Current status |
|--------|-----------|----------------|
| Bill approval → points | Updates reflect in Home, Wallet, Profile | **PASS** — batch writes + shared `UserPointsSyncService` |
| Global class for points | One shared sync for all screens | **PASS** — `UserPointsSyncService` |
| Wallet bills vs `userId` | Consistent carpenter id for bills | **Partial** — see finding #2 |
| Reset PIN UX / security | Clear feedback + safe logged-out reset | **Issues remain** — findings #3–#5 |

---

## Practical next actions

| # | Action | Status |
|---|--------|--------|
| 1 | Shared points sync for Home / Wallet / Profile | **Done** (`UserPointsSyncService`) |
| 2 | Align Wallet bill queries with session `userId` + phone fallback | **Open** |
| 3 | Reset PIN: logged-in mismatch message | **Open** |
| 4 | Reset PIN: harden logged-out flow (OTP / admin) | **Open** |
| 5 | Remove or deprecate duplicate `presentation/screens/auth/reset_pin_page.dart` | **Open** |

---

## Quick reference — key types

```text
UserPointsService.resolveCurrentUserPointsDocRef() → DocumentReference?
UserPointsSyncService().pointsData  → ValueNotifier<Map<String, dynamic>?>
UserPointsSyncService().start()     → attach / reuse subscription
UserPointsSyncService().refresh()   → re-resolve doc + resubscribe (e.g. pull-to-refresh)
```
