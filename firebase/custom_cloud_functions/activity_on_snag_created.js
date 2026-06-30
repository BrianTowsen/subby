/* eslint-disable consistent-return */

/**
 * Subby — Activity Log (server-side, trigger-driven).
 *
 * Five Firestore triggers append high-signal events to a top-level `activity`
 * collection. Writes run in the Admin SDK (rules bypassed), so the collection
 * can be locked read-only to clients and the log can never be forged or skipped.
 *
 * Event doc: projectRef, type, title, actorRef, actorName, createdAt.
 * Triggers map to existing top-level collections (snags / tasks /
 * project_documents), all of which already carry `projectRef`.
 *
 * onCreate reads the doc's own creator (createdBy / uploadedBy). onUpdate reads
 * the actor stamp (updatedBy / updatedByName) the snag/task detail widgets now
 * write on every status change, falling back to the creator. Names are resolved
 * from the user doc only when no denormalised name was stored.
 */

const functions = require("firebase-functions");
const admin = require("firebase-admin");

if (admin.apps.length === 0) {
  admin.initializeApp();
}

const db = admin.firestore();

// ⚠️ Set to your Firestore location (Clutch Putt uses us-central1 — change if
// Subby's database is in a different region).
const REGION = "us-central1";

/* ----------------- HELPERS ----------------- */
async function resolveActorName(actorRef, fallbackName) {
  const n = (fallbackName || "").toString().trim();
  if (n) return n;
  if (!actorRef || typeof actorRef.get !== "function") return "";
  try {
    const snap = await actorRef.get();
    const d = snap.exists ? snap.data() || {} : {};
    return (d.display_name || d.displayName || "").toString().trim();
  } catch (_) {
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

async function writeActivity({ projectRef, type, title, actorRef, actorName }) {
  if (!projectRef || typeof projectRef.path !== "string") return;
  await db.collection("activity").add({
    projectRef,
    type,
    title: (title || "").toString().trim() || "Untitled",
    actorRef: actorRef || null,
    actorName: (actorName || "").toString().trim(),
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

/* ----------------- 1) Snag recorded ----------------- */
exports.activityOnSnagCreated = functions
  .region(REGION)
  .firestore.document("snags/{snagId}")
  .onCreate(async (snap) => {
    const d = snap.data() || {};
    const actorRef = d.createdBy || null;
    const actorName = await resolveActorName(actorRef, d.createdByName);
    await writeActivity({
      projectRef: d.projectRef,
      type: "snag_recorded",
      title: d.title,
      actorRef,
      actorName,
    });
    return null;
  });

/* ----------------- 2) Snag status changed ----------------- */
exports.activityOnSnagStatusChanged = functions
  .region(REGION)
  .firestore.document("snags/{snagId}")
  .onUpdate(async (change) => {
    const before = change.before.data() || {};
    const after = change.after.data() || {};
    if ((before.status || "") === (after.status || "")) return null;
    const actor = await pickUpdateActor(after);
    await writeActivity({
      projectRef: after.projectRef,
      type: "snag_status",
      title: `${(after.title || "Snag").toString().trim()} \u2014 ${snagStatusLabel(after.status)}`,
      actorRef: actor.ref,
      actorName: actor.name,
    });
    return null;
  });

/* ----------------- 3) Task added ----------------- */
exports.activityOnTaskCreated = functions
  .region(REGION)
  .firestore.document("tasks/{taskId}")
  .onCreate(async (snap) => {
    const d = snap.data() || {};
    const actorRef = d.createdBy || null;
    const actorName = await resolveActorName(actorRef, d.createdByName);
    await writeActivity({
      projectRef: d.projectRef,
      type: "task_added",
      title: d.title,
      actorRef,
      actorName,
    });
    return null;
  });

/* ----------------- 4) Task completed (status -> done) ----------------- */
exports.activityOnTaskCompleted = functions
  .region(REGION)
  .firestore.document("tasks/{taskId}")
  .onUpdate(async (change) => {
    const before = change.before.data() || {};
    const after = change.after.data() || {};
    if (after.status !== "done" || before.status === "done") return null;
    const actor = await pickUpdateActor(after);
    await writeActivity({
      projectRef: after.projectRef,
      type: "task_completed",
      title: after.title,
      actorRef: actor.ref,
      actorName: actor.name,
    });
    return null;
  });

/* ----------------- 5) Document uploaded ----------------- */
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
    });
    return null;
  });
