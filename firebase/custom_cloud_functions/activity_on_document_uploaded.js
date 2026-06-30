/* eslint-disable consistent-return */

const functions = require("firebase-functions");
const admin = require("firebase-admin");

if (admin.apps.length === 0) {
  admin.initializeApp();
}

const db = admin.firestore();

const REGION = "us-central1";

async function resolveActorName(actorRef, fallbackName) {
  const n = (fallbackName || "").toString().trim();
  if (n) return n;
  if (!actorRef || typeof actorRef.get !== "function") return "";
  try {
    const snap = await actorRef.get();
    const d = snap.exists ? snap.data() || {} : {};
    return (d.display_name || d.displayName || "").toString().trim();
  } catch (e) {
    return "";
  }
}

async function pickUpdateActor(after) {
  if (after.updatedBy) {
    return {
      ref: after.updatedBy,
      name: await resolveActorName(after.updatedBy, after.updatedByName),
    };
  }
  return {
    ref: after.createdBy || null,
    name: await resolveActorName(after.createdBy, after.createdByName),
  };
}

async function writeActivity(args) {
  const projectRef = args.projectRef;
  if (!projectRef || typeof projectRef.path !== "string") return;
  await db.collection("activity").add({
    projectRef: projectRef,
    type: args.type,
    title: (args.title || "").toString().trim() || "Untitled",
    actorRef: args.actorRef || null,
    actorName: (args.actorName || "").toString().trim(),
    targetRef: args.targetRef || null,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });
}

function snagStatusLabel(status) {
  switch ((status || "").toString()) {
    case "in_progress":
      return "In progress";
    case "closed":
      return "Closed";
    case "open":
      return "Reopened";
    default:
      return "Updated";
  }
}

exports.activityOnDocumentUploaded = functions
  .region(REGION)
  .firestore.document("project_documents/{docId}")
  .onCreate(async (snap) => {
    const d = snap.data() || {};
    const actorRef = d.uploadedBy || null;
    const actorName = await resolveActorName(actorRef, null);
    await writeActivity({
      projectRef: d.projectRef,
      type: "document_uploaded",
      title: d.title,
      actorRef,
      actorName,
      targetRef: snap.ref,
    });
    return null;
  });
