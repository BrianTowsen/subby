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
const activityOnQuoteChanged = require("./activity_on_quote_changed.js");
exports.activityOnQuoteChanged = activityOnQuoteChanged.activityOnQuoteChanged;
const activityOnCostPlanUpdated = require("./activity_on_cost_plan_updated.js");
exports.activityOnCostPlanUpdated =
  activityOnCostPlanUpdated.activityOnCostPlanUpdated;
const activityOnProgrammeUpdated = require("./activity_on_programme_updated.js");
exports.activityOnProgrammeUpdated =
  activityOnProgrammeUpdated.activityOnProgrammeUpdated;
const activityOnSiteBookEntry = require("./activity_on_site_book_entry.js");
exports.activityOnSiteBookEntry =
  activityOnSiteBookEntry.activityOnSiteBookEntry;
