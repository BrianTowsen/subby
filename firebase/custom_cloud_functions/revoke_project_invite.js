/* eslint-disable consistent-return */

// revokeProjectInvite — cancels a pending invite so its code can no longer
// be redeemed. Caller must be the project owner or a non-client team member.

const functions = require("firebase-functions");
const admin = require("firebase-admin");

if (admin.apps.length === 0) {
  admin.initializeApp();
}

const db = admin.firestore();

const REGION = "us-central1";

// Caller must be the project owner or an existing non-client member.
async function assertCanInvite(uid, projectRef) {
  const projectSnap = await projectRef.get();
  if (!projectSnap.exists) {
    throw new functions.https.HttpsError("not-found", "Project not found.");
  }
  const project = projectSnap.data() || {};
  const userRef = db.doc("users/" + uid);

  const ownerRef = project.ownerRef;
  if (ownerRef && ownerRef.path === userRef.path) return project;

  const memberQuery = await db
    .collection("project_members")
    .where("projectRef", "==", projectRef)
    .where("userRef", "==", userRef)
    .limit(1)
    .get();
  if (!memberQuery.empty) {
    const role = (memberQuery.docs[0].data().role || "").toString();
    if (role !== "client") return project;
  }
  throw new functions.https.HttpsError(
    "permission-denied",
    "Only the project owner or a project team member can manage invites.",
  );
}

exports.revokeProjectInvite = functions
  .region(REGION)
  .https.onCall(async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "Sign in to revoke an invite.",
      );
    }
    const uid = context.auth.uid;

    const invitePath = (data.invitePath || "").toString().trim();
    if (!/^project_invites\/[^/]+$/.test(invitePath)) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "invitePath must look like project_invites/{id}.",
      );
    }
    const inviteRef = db.doc(invitePath);
    const inviteSnap = await inviteRef.get();
    if (!inviteSnap.exists) {
      throw new functions.https.HttpsError("not-found", "Invite not found.");
    }
    const invite = inviteSnap.data() || {};
    if (!invite.projectRef) {
      throw new functions.https.HttpsError(
        "failed-precondition",
        "This invite is missing its project.",
      );
    }
    await assertCanInvite(uid, invite.projectRef);
    if (invite.status !== "pending") {
      throw new functions.https.HttpsError(
        "failed-precondition",
        "Only pending invites can be revoked.",
      );
    }
    await inviteRef.update({ status: "revoked" });
    return { ok: true };
  });
