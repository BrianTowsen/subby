const admin = require("firebase-admin/app");
admin.initializeApp();

const activityOnSnagCreated = require("./activity_on_snag_created.js");
exports.activityOnSnagCreated = activityOnSnagCreated.activityOnSnagCreated;
