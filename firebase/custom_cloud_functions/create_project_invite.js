const functions = require("firebase-functions");
const admin = require("firebase-admin");

if (admin.apps.length === 0) {
  admin.initializeApp();
}

const db = admin.firestore();

const REGION = "us-central1";

// No 0/O, 1/I/L — codes get read out over the phone and typed from WhatsApp.
const CODE_CHARSET = "23456789ABCDEFGHJKMNPQRSTUVWXYZ";
const CODE_LENGTH = 6;
const DEFAULT_EXPIRY_DAYS = 14;

const ROLES = ["office", "client", "custom"];

const PERMISSION_KEYS = [
  "viewTimeline",
  "viewDocs",
  "viewCost",
  "editTasks",
  "siteBook",
  "snags",
  "quotes",
];

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

function generateCode() {
  let out = "";
  for (let i = 0; i < CODE_LENGTH; i++) {
    out += CODE_CHARSET[Math.floor(Math.random() * CODE_CHARSET.length)];
  }
  return "SUB-" + out;
}

function sanitizePermissions(raw, role) {
  const defaults = ROLE_DEFAULT_PERMISSIONS[role] || {};
  const out = { ...defaults };
  if (raw && typeof raw === "object") {
    for (const key of PERMISSION_KEYS) {
      if (typeof raw[key] === "boolean") out[key] = raw[key];
    }
  }
  return out;
}

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
    "Only the project owner or a project team member can invite people.",
  );
}

exports.createProjectInvite = functions
  .region(REGION)
  .https.onCall(async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "Sign in to create an invite.",
      );
    }
    const uid = context.auth.uid;

    const projectPath = (data.projectPath || "").toString().trim();
    if (!/^projects\/[^/]+$/.test(projectPath)) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "projectPath must look like projects/{id}.",
      );
    }
    const role = (data.role || "").toString();
    if (!ROLES.includes(role)) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "role must be one of: " + ROLES.join(", "),
      );
    }

    const projectRef = db.doc(projectPath);
    const project = await assertCanInvite(uid, projectRef);

    const permissions = sanitizePermissions(data.permissions, role);

    const expiresInDays =
      Number.isFinite(data.expiresInDays) &&
      data.expiresInDays > 0 &&
      data.expiresInDays <= 90
        ? data.expiresInDays
        : DEFAULT_EXPIRY_DAYS;
    const expiresAt = admin.firestore.Timestamp.fromMillis(
      Date.now() + expiresInDays * 24 * 60 * 60 * 1000,
    );

    let onBehalfOfListingRef = null;
    const listingPath = (data.onBehalfOfListingPath || "").toString().trim();
    if (listingPath) {
      if (!/^subby_listings\/[^/]+$/.test(listingPath)) {
        throw new functions.https.HttpsError(
          "invalid-argument",
          "onBehalfOfListingPath must look like subby_listings/{id}.",
        );
      }
      onBehalfOfListingRef = db.doc(listingPath);
    }

    // Generate a code that isn't currently pending on another invite.
    let code = null;
    for (let attempt = 0; attempt < 8; attempt++) {
      const candidate = generateCode();
      const clash = await db
        .collection("project_invites")
        .where("code", "==", candidate)
        .where("status", "==", "pending")
        .limit(1)
        .get();
      if (clash.empty) {
        code = candidate;
        break;
      }
    }
    if (!code) {
      throw new functions.https.HttpsError(
        "internal",
        "Could not generate a unique invite code. Please try again.",
      );
    }

    const inviteRef = db.collection("project_invites").doc();
    await inviteRef.set({
      projectRef: projectRef,
      projectName: (project.name || "").toString(),
      invitedByRef: db.doc("users/" + uid),
      role: role,
      permissions: permissions,
      code: code,
      status: "pending",
      inviteeName: (data.inviteeName || "").toString().trim(),
      onBehalfOfListingRef: onBehalfOfListingRef,
      displayCompany: (data.displayCompany || "").toString().trim(),
      claimedByRef: null,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      expiresAt: expiresAt,
      claimedAt: null,
    });

    return {
      invitePath: inviteRef.path,
      code: code,
      role: role,
      expiresAt: expiresAt.toMillis(),
    };
  });
