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

// Quote docs live at projects/{projectId}/quotes/{listingId} and carry no
// projectRef field - the project is the grandparent of the quote doc.
// Lifecycle: invited -> submitted -> accepted | declined. Only status
// transitions produce feed rows; merge writes that touch other fields
// (updatedAt, amounts re-saved with same status) are ignored.
exports.activityOnQuoteChanged = functions
  .region(REGION)
  .firestore.document("projects/{projectId}/quotes/{quoteId}")
  .onWrite(async (change, context) => {
    const after = change.after.exists ? change.after.data() || {} : null;
    if (!after) return null; // deletion -> no feed row
    const before = change.before.exists ? change.before.data() || {} : {};

    const beforeStatus = (before.status || "").toString();
    const afterStatus = (after.status || "").toString();
    if (change.before.exists && beforeStatus === afterStatus) return null;

    const projectRef = change.after.ref.parent.parent;
    const listingName = (after.listingName || "Trade").toString().trim();

    let type = null;
    let actorRef = null;
    let actorName = "";
    switch (afterStatus) {
      case "invited":
        type = "quote_requested";
        break;
      case "submitted":
        type = "quote_submitted";
        actorRef = after.providerRef || null;
        actorName = await resolveActorName(actorRef, "");
        break;
      case "accepted":
        type = "quote_accepted";
        break;
      case "declined":
        type = "quote_declined";
        break;
      default:
        return null;
    }

    await writeActivity({
      projectRef: projectRef,
      type: type,
      title: listingName,
      actorRef: actorRef,
      actorName: actorName,
      targetRef: change.after.ref,
    });
    return null;
  });
