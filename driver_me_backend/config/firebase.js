const admin = require('firebase-admin');

// Check if serviceAccountKey.json exists
let serviceAccount;
try {
  serviceAccount = require('./serviceAccountKey.json');
} catch (error) {
  console.error('❌ serviceAccountKey.json not found in config folder');
  console.error('Please download from Firebase Console and place in config/');
  process.exit(1);
}

// Initialize Firebase Admin
if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
    projectId: process.env.FIREBASE_PROJECT_ID || serviceAccount.project_id
  });
}

const db = admin.firestore();
const auth = admin.auth();

// Test Firebase connection
db.collection('test').doc('connection').set({
  status: 'connected',
  timestamp: admin.firestore.FieldValue.serverTimestamp()
}).then(() => {
  console.log('✅ Firebase connected successfully');
}).catch((error) => {
  console.error('❌ Firebase connection failed:', error.message);
});

module.exports = { admin, db, auth };