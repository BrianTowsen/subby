const admin = require("firebase-admin/app");
admin.initializeApp();

const activityOnSnagCreated = require("./activity_on_snag_created.js");
exports.activityOnSnagCreated = activityOnSnagCreated.activityOnSnagCreated;
const activityOnTaskCreated = require("./activity_on_task_created.js");
exports.activityOnTaskCreated = activityOnTaskCreated.activityOnTaskCreated;
const activityOnDocumentUploaded = require("./activity_on_document_uploaded.js");
exports.activityOnDocumentUploaded =
  activityOnDocumentUploaded.activityOnDocumentUploaded;
const activityOnSnagStatusChanged = require("./activity_on_snag_status_changed.js");
exports.activityOnSnagStatusChanged =
  activityOnSnagStatusChanged.activityOnSnagStatusChanged;
const activityOnTaskCompleted = require("./activity_on_task_completed.js");
exports.activityOnTaskCompleted =
  activityOnTaskCompleted.activityOnTaskCompleted;
