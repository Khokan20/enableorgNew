"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.deleteUser = void 0;
const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();
exports.deleteUser = functions.firestore.document("/User/{uid}")
    .onDelete(async (snapshot, context) => {
    const userId = context.params.uid;
    try {
        await admin.auth().deleteUser(userId);
        console.log('User deleted from Authentication:', userId);
    }
    catch (error) {
        console.error('Error deleting user from Authentication:', error);
    }
});
//# sourceMappingURL=index.js.map