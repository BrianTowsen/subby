/* eslint-disable consistent-return */

const functions = require("firebase-functions");
const admin = require("firebase-admin");

if (admin.apps.length === 0) {
  admin.initializeApp();
}

const db = admin.firestore();

const REGION = "us-central1";

// UTC calendar-day key: 'yyyymmdd'. Used to coalesce autosave bursts into
// one feed row per project per day.
function dayKey(date) {
  const y = date.getUTCFullYear();
  const m = (date.getUTCMonth() + 1).toString().padStart(2, "0");
  const d = date.getUTCDate().toString().padStart(2, "0");
  return "" + y + m + d;
}

// The programme (projects/{projectId}/programme/plan) autosaves on a 700ms
// debounce while the owner edits, so an onWrite-per-row approach would flood
// the feed. Instead: skip writes where 'sections' did not change (visibility
// toggles, updatedAt-only merges), and upsert a DETERMINISTIC activity doc
// keyed programme_updated_{projectId}_{yyyymmdd}. Result: at most one "Timeline
// updated" row per project per day, its timestamp bumped to the latest edit.
// No composite index needed - the doc is addressed by ID, never queried.
exports.activityOnProgrammeUpdated = functions
  .region(REGION)
  .firestore.document("projects/{projectId}/programme/{docId}")
  .onWrite(async (change, context) => {
    const after = change.after.exists ? change.after.data() || {} : null;
    if (!after) return null; // deletion -> no feed row
    const before = change.before.exists ? change.before.data() || {} : {};

    const beforeSections = JSON.stringify(before.sections || []);
    const afterSections = JSON.stringify(after.sections || []);
    if (change.before.exists && beforeSections === afterSections) return null;

    const projectRef = change.after.ref.parent.parent;
    if (!projectRef || typeof projectRef.path !== "string") return null;

    const id =
      "programme_updated_" +
      context.params.projectId +
      "_" +
      dayKey(new Date());
    await db.collection("activity").doc(id).set(
      {
        projectRef: projectRef,
        type: "programme_updated",
        title: "", // feed renders the type label alone: "Timeline updated"
        actorRef: null,
        actorName: "",
        targetRef: change.after.ref,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
    return null;
  });
