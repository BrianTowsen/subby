/* eslint-disable consistent-return */

// claimProjectInvite — redeems a join code created by createProjectInvite.
// Validates the code in a transaction and creates the project_members doc
// server-side (membership is never minted from the client).

const functions = require("firebase-functions");
const admin = require("firebase-admin");

if (admin.apps.length === 0) {
  admin.initializeApp();
}

const db = admin.firestore();

const REGION = "us-central1";

const CODE_LENGTH = 6;

const ROLE_DEFAULT_PERMISSIONS = {
  office: {
    viewTimeline: true,
    viewDocs: true,
    viewCost: false,
    editTasks: true,
    siteBook: true,
    snags: true,
    quotes: true,
  },
  client: {
    viewTimeline: true,
    viewDocs: true,
    viewCost: false,
    editTasks: false,
    siteBook: false,
    snags: false,
    quotes: false,
  },
};

// Accepts "SUB-4K7KQ2", "sub 4k7kq2", "4K7KQ2" etc.
function normalizeCode(raw) {
  const cleaned = (raw || "")
    .toString()
    .toUpperCase()
    .replace(/[^A-Z0-9]/g, "");
  // Only strip a leading "SUB" prefix when there are more chars than a bare
  // code body — a body that itself starts with SUB (e.g. SUBK7Q2) survives.
  const body =
    cleaned.startsWith("SUB") && cleaned.length > CODE_LENGTH
      ? cleaned.slice(3)
      : cleaned;
  if (body.length !== CODE_LENGTH) return null;
  return "SUB-" + body;
}

exports.claimProjectInvite = functions
  .region(REGION)
  .https.onCall(async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "Sign in to join a project.",
      );
    }
    const uid = context.auth.uid;
    const userRef = db.doc("users/" + uid);

    const code = normalizeCode(data.code);
    if (!code) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "That code doesn't look right. It should look like SUB-4K7KQ2.",
      );
    }

    const inviteQuery = await db
      .collection("project_invites")
      .where("code", "==", code)
      .where("status", "==", "pending")
      .limit(1)
      .get();
    if (inviteQuery.empty) {
      throw new functions.https.HttpsError(
        "not-found",
        "This invite code is invalid or has already been used.",
      );
    }
    const inviteRef = inviteQuery.docs[0].ref;
    const invitePeek = inviteQuery.docs[0].data() || {};

    // ── Provider invites: link the claimant's Network listing to the
    // project team (project_listings) instead of creating a guest member.
    if ((invitePeek.role || "") === "provider") {
      // Tell an expired-code holder BEFORE sending them through Network
      // registration.
      if (
        invitePeek.expiresAt &&
        invitePeek.expiresAt.toMillis() < Date.now()
      ) {
        throw new functions.https.HttpsError(
          "deadline-exceeded",
          "This invite has expired. Ask for a new code.",
        );
      }

      const listingSnap = await db
        .collection("subby_listings")
        .where("ownerRef", "==", userRef)
        .limit(1)
        .get();

      // No listing yet → do NOT consume the invite. The app routes them to
      // Network registration and they re-enter the same code afterwards.
      if (listingSnap.empty) {
        return {
          needsListing: true,
          role: "provider",
          projectName: (invitePeek.projectName || "").toString(),
        };
      }

      const listingDoc = listingSnap.docs[0];
      const listingRef = listingDoc.ref;
      const listing = listingDoc.data() || {};

      return await db.runTransaction(async (tx) => {
        const inviteSnap = await tx.get(inviteRef);
        const invite = inviteSnap.exists ? inviteSnap.data() : null;
        if (!invite || invite.status !== "pending") {
          throw new functions.https.HttpsError(
            "not-found",
            "This invite code is invalid or has already been used.",
          );
        }
        if (invite.expiresAt && invite.expiresAt.toMillis() < Date.now()) {
          throw new functions.https.HttpsError(
            "deadline-exceeded",
            "This invite has expired. Ask for a new code.",
          );
        }
        const projectRef = invite.projectRef;
        if (!projectRef) {
          throw new functions.https.HttpsError(
            "failed-precondition",
            "This invite is missing its project.",
          );
        }

        // Already on the team? Just mark the invite claimed.
        const dup = await tx.get(
          db
            .collection("project_listings")
            .where("projectRef", "==", projectRef)
            .where("listingRef", "==", listingRef)
            .limit(1),
        );
        const alreadyMember = !dup.empty;

        if (!alreadyMember) {
          // Mirror the shape ListingDetailPageView writes when the owner
          // adds a listing to a project (both subtitle spellings included).
          const subtitle = (
            listing.speciality ||
            listing.category ||
            ""
          ).toString();
          const rating =
            typeof listing.rating === "number" ? listing.rating : null;
          const reviewCount =
            typeof listing.reviewCount === "number" ? listing.reviewCount : 0;
          const teamRef = db.collection("project_listings").doc();
          tx.set(teamRef, {
            projectRef: projectRef,
            listingRef: listingRef,
            addedAt: admin.firestore.FieldValue.serverTimestamp(),
            addedBy: userRef,
            title: (listing.name || "").toString(),
            subtitle: subtitle,
            subTitle: subtitle,
            ratingText:
              rating != null
                ? rating.toFixed(1) + " (" + reviewCount + ")"
                : "",
            photoUrl: (listing.heroPhotoUrl || "").toString(),
          });
        }

        tx.update(inviteRef, {
          status: "claimed",
          claimedByRef: userRef,
          claimedAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        return {
          projectPath: projectRef.path,
          projectName: (invite.projectName || "").toString(),
          role: "provider",
          alreadyMember: alreadyMember,
        };
      });
    }

    const result = await db.runTransaction(async (tx) => {
      const inviteSnap = await tx.get(inviteRef);
      const invite = inviteSnap.exists ? inviteSnap.data() : null;
      if (!invite || invite.status !== "pending") {
        throw new functions.https.HttpsError(
          "not-found",
          "This invite code is invalid or has already been used.",
        );
      }
      if (invite.expiresAt && invite.expiresAt.toMillis() < Date.now()) {
        throw new functions.https.HttpsError(
          "deadline-exceeded",
          "This invite has expired. Ask for a new code.",
        );
      }

      const projectRef = invite.projectRef;
      if (!projectRef) {
        throw new functions.https.HttpsError(
          "failed-precondition",
          "This invite is missing its project.",
        );
      }

      // Already a member? Just mark the invite claimed and return.
      const existing = await tx.get(
        db
          .collection("project_members")
          .where("projectRef", "==", projectRef)
          .where("userRef", "==", userRef)
          .limit(1),
      );
      if (!existing.empty) {
        tx.update(inviteRef, {
          status: "claimed",
          claimedByRef: userRef,
          claimedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        return {
          projectPath: projectRef.path,
          projectName: (invite.projectName || "").toString(),
          role: (existing.docs[0].data().role || "").toString(),
          alreadyMember: true,
        };
      }

      const permissions =
        invite.permissions && typeof invite.permissions === "object"
          ? invite.permissions
          : ROLE_DEFAULT_PERMISSIONS[invite.role] || {};

      const memberRef = db.collection("project_members").doc();
      tx.set(memberRef, {
        projectRef: projectRef,
        userRef: userRef,
        role: (invite.role || "client").toString(),
        canViewCost: permissions.viewCost === true,
        permissions: permissions,
        invitedByRef: invite.invitedByRef || null,
        onBehalfOfListingRef: invite.onBehalfOfListingRef || null,
        displayCompany: (invite.displayCompany || "").toString(),
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      tx.update(inviteRef, {
        status: "claimed",
        claimedByRef: userRef,
        claimedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      return {
        projectPath: projectRef.path,
        projectName: (invite.projectName || "").toString(),
        role: (invite.role || "client").toString(),
        alreadyMember: false,
      };
    });

    return result;
  });
