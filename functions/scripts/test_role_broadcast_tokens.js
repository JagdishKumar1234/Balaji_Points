/**
 * Read-only push check for sendRoleBroadcast: for each branch, picks the
 * members every role would reach and asks FCM to validate their tokens with
 * dryRun (nothing is shown on any phone, nothing is written).
 *
 *   node scripts/test_role_broadcast_tokens.js
 */
const admin = require("firebase-admin");
const r = require("../role_broadcast");

admin.initializeApp({projectId: process.env.GCLOUD_PROJECT || "balajipoints"});
const db = admin.firestore();

(async () => {
  const users = await db.collection("users").get();
  const byBranch = new Map();
  for (const d of users.docs) {
    const b = d.data().branchId;
    if (!b) continue;
    if (!byBranch.has(b)) byBranch.set(b, []);
    byBranch.get(b).push({id: d.id, data: d.data()});
  }
  for (const [branch, list] of byBranch) {
    const counts = r.MEMBER_ROLES.map((role) =>
      `${role}=${r.pickRecipients(list, [role]).userIds.length}`).join(" ");
    const {userIds, tokens} = r.pickRecipients(list, r.MEMBER_ROLES);
    let ok = 0;
    let bad = 0;
    const errors = {};
    for (const group of r.chunk(tokens, 500)) {
      const res = await admin.messaging().sendEachForMulticast({
        tokens: group,
        notification: {title: "dry run", body: "dry run"},
        data: {type: "announcement", category: "general"},
      }, true);
      ok += res.successCount;
      bad += res.failureCount;
      res.responses.forEach((x) => {
        if (x.error) errors[x.error.code] = (errors[x.error.code] || 0) + 1;
      });
    }
    console.log(`${branch}: ${userIds.length} members (${counts}); ` +
      `${tokens.length} tokens → valid ${ok}, invalid ${bad}`,
    Object.keys(errors).length ? errors : "");
  }
  process.exit(0);
})().catch((e) => {
  console.error(e);
  process.exit(1);
});
