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

// Site book entries are top-level docs carrying projectRef + authorRef +
// authorName (denormalized at write time in SiteBookPageView). Private
// entries never reach the shared project feed.
exports.activityOnSiteBookEntry = functions
  .region(REGION)
  .firestore.document("site_book_entries/{entryId}")
  .onCreate(async (snap) => {
    const d = snap.data() || {};
    if ((d.visibility || "shared").toString() === "private") return null;
    const actorRef = d.authorRef || null;
    const actorName = await resolveActorName(actorRef, d.authorName);
    const note = (d.note || "").toString().trim();
    const title = note.length > 60 ? note.slice(0, 57) + "\u2026" : note;
    await writeActivity({
      projectRef: d.projectRef,
      type: "site_note_added",
      title: title,
      actorRef: actorRef,
      actorName: actorName,
      targetRef: snap.ref,
    });
    return null;
  });
