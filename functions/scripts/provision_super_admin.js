const admin = require("firebase-admin");

admin.initializeApp({ projectId: "balajipoints" });
const db = admin.firestore();
const email = "aajitechstudio@gmail.com";
const phone = "8947038661";
const applyChanges = process.argv.includes("--apply");

async function main() {
  const authUser = await admin.auth().getUserByEmail(email);
  if (!authUser.emailVerified) {
    throw new Error(
      `Firebase Auth account ${email} is not verified; no user profile was changed.`,
    );
  }

  const userRef = db.collection("users").doc(authUser.uid);
  const userSnapshot = await userRef.get();
  const profile = {
    uid: authUser.uid,
    userId: authUser.uid,
    email,
    firstName: "Jagdish",
    lastName: "Kumar",
    phone,
    phoneNumber: "+91" + phone,
    role: "super_admin",
    branchId: null,
    status: "active",
    verifiedBy: "configured-super-admin",
    lastLoginAt: admin.firestore.FieldValue.serverTimestamp(),
  };
  if (!userSnapshot.exists) {
    profile.totalPoints = 0;
    profile.tier = "Bronze";
    profile.createdAt = admin.firestore.FieldValue.serverTimestamp();
  }

  console.log(
    JSON.stringify(
      {
        mode: applyChanges ? "apply" : "dry-run",
        firebaseUid: authUser.uid,
        email,
        userDocument: `users/${authUser.uid}`,
        existingProfile: userSnapshot.exists,
        role: "super_admin",
        branchId: null,
        deletes: 0,
      },
      null,
      2,
    ),
  );

  if (applyChanges) {
    await userRef.set(profile, { merge: true });
    console.log(
      "Verified super-admin profile provisioned; no records were deleted.",
    );
  } else {
    console.log("Dry run only. Re-run with --apply to write this profile.");
  }
}

main()
  .catch((error) => {
    console.error("Super-admin provisioning failed:", error.message || error);
    process.exitCode = 1;
  })
  .finally(async () => {
    await admin.app().delete();
  });
