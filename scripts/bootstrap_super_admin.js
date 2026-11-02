/**
 * Bootstrap Super Admin Script
 *
 * Configures the Platform Super Admin account in Firebase Firestore:
 * - Email: aaijitechstudio@gmail.com
 * - Phone: +918947038661 (8947038661)
 * - Role: super_admin
 *
 * Usage:
 *   node scripts/bootstrap_super_admin.js [path-to-service-account.json]
 */

const fs = require("fs");
const path = require("path");
const admin = require("firebase-admin");

const SUPER_ADMIN_EMAIL = "aaijitechstudio@gmail.com";
const SUPER_ADMIN_PHONE = "+918947038661";
const SUPER_ADMIN_RAW_PHONE = "8947038661";
const SUPER_ADMIN_NAME = "Jagdish Kumar";

// Find service account key
const possibleKeyPaths = [
  process.argv[2],
  path.join(__dirname, "serviceAccountKey.json"),
  path.join(__dirname, "../serviceAccountKey.json"),
  path.join(__dirname, "../functions/serviceAccountKey.json"),
].filter(Boolean);

let serviceAccountPath = possibleKeyPaths.find((p) => fs.existsSync(p));

if (!serviceAccountPath && !process.env.GOOGLE_APPLICATION_CREDENTIALS) {
  console.log("⚠️  No serviceAccountKey.json found directly.");
  console.log("Trying default application credentials...");
  admin.initializeApp();
} else {
  if (serviceAccountPath) {
    const serviceAccount = require(path.resolve(serviceAccountPath));
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
    });
    console.log(`✅ Loaded service account from ${serviceAccountPath}`);
  } else {
    admin.initializeApp();
  }
}

const db = admin.firestore();
const auth = admin.auth();

async function bootstrapSuperAdmin() {
  console.log("\n=========================================");
  console.log("🚀 Bootstrapping Balaji Points Super Admin");
  console.log("=========================================");
  console.log(`Email: ${SUPER_ADMIN_EMAIL}`);
  console.log(`Phone: ${SUPER_ADMIN_PHONE}`);
  console.log(`Role:  super_admin\n`);

  let authUser;
  try {
    authUser = await auth.getUserByEmail(SUPER_ADMIN_EMAIL);
    console.log(`Found existing Firebase Auth user with UID: ${authUser.uid}`);
  } catch (err) {
    if (err.code === "auth/user-not-found") {
      try {
        authUser = await auth.getUserByPhoneNumber(SUPER_ADMIN_PHONE);
        console.log(
          `Found existing Firebase Auth user by phone with UID: ${authUser.uid}`,
        );
      } catch (phoneErr) {
        if (phoneErr.code === "auth/user-not-found") {
          console.log(
            "No existing Firebase Auth user found. Creating new Auth record...",
          );
          authUser = await auth.createUser({
            email: SUPER_ADMIN_EMAIL,
            phoneNumber: SUPER_ADMIN_PHONE,
            displayName: SUPER_ADMIN_NAME,
            emailVerified: true,
          });
          console.log(`✅ Created Firebase Auth record: UID=${authUser.uid}`);
        } else {
          throw phoneErr;
        }
      }
    } else {
      throw err;
    }
  }

  // Set custom user claims for super_admin
  await auth.setCustomUserClaims(authUser.uid, {
    role: "super_admin",
    isSuperAdmin: true,
  });
  console.log(`✅ Assigned custom user claims: { role: 'super_admin' }`);

  const now = admin.firestore.FieldValue.serverTimestamp();

  // 1. Write to global_users in master_db
  await db.collection("global_users").doc(authUser.uid).set(
    {
      uid: authUser.uid,
      name: SUPER_ADMIN_NAME,
      email: SUPER_ADMIN_EMAIL,
      phoneE164: SUPER_ADMIN_PHONE,
      rawPhone: SUPER_ADMIN_RAW_PHONE,
      role: "super_admin",
      branchId: null,
      status: "active",
      emailVerified: true,
      phoneVerified: true,
      updatedAt: now,
    },
    { merge: true },
  );
  console.log(`✅ Upserted master_db global_users/${authUser.uid}`);

  // 2. Write to users collection (for backward compatibility with current client checks)
  await db.collection("users").doc(authUser.uid).set(
    {
      uid: authUser.uid,
      id: authUser.uid,
      userId: authUser.uid,
      name: SUPER_ADMIN_NAME,
      displayName: SUPER_ADMIN_NAME,
      email: SUPER_ADMIN_EMAIL,
      phone: SUPER_ADMIN_RAW_PHONE,
      phoneNumber: SUPER_ADMIN_PHONE,
      role: "super_admin",
      branchId: null,
      status: "active",
      isEmailVerified: true,
      updatedAt: now,
      lastLogin: now,
    },
    { merge: true },
  );
  console.log(`✅ Upserted users/${authUser.uid}`);

  // Also ensure phone document exists if legacy phone-based indexing is used
  await db.collection("users").doc(SUPER_ADMIN_RAW_PHONE).set(
    {
      uid: authUser.uid,
      id: authUser.uid,
      userId: authUser.uid,
      name: SUPER_ADMIN_NAME,
      email: SUPER_ADMIN_EMAIL,
      phone: SUPER_ADMIN_RAW_PHONE,
      phoneNumber: SUPER_ADMIN_PHONE,
      role: "super_admin",
      branchId: null,
      status: "active",
      canonicalUid: authUser.uid,
      updatedAt: now,
    },
    { merge: true },
  );
  console.log(`✅ Upserted legacy users/${SUPER_ADMIN_RAW_PHONE}`);

  console.log("\n=========================================");
  console.log("🎉 Super Admin Bootstrap Complete!");
  console.log("=========================================\n");
}

bootstrapSuperAdmin().catch((err) => {
  console.error("❌ Failed to bootstrap Super Admin:", err);
  process.exit(1);
});
