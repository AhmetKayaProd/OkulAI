# Firebase Console Setup Instructions for ChatGPT

## Context
KresAI Flutter app has Firebase SDK integrated. Need to enable 3 services in Firebase Console for the **okulavatar** project.

## Task for ChatGPT
Please go to Firebase Console and enable these services:

### 1. Enable Authentication (Email/Password)
1. Go to: https://console.firebase.google.com/project/okulavatar/authentication
2. Click "Get Started" (if not already enabled)
3. Click "Sign-in method" tab
4. Find "Email/Password" in the providers list
5. Click on it to edit
6. Toggle "Enable" switch to ON
7. Click "Save"

### 2. Create Firestore Database
1. Go to: https://console.firebase.google.com/project/okulavatar/firestore
2. Click "Create database"
3. Select "Start in test mode" (radio button)
   - This allows all read/write for 30 days - perfect for development
4. Click "Next"
5. Select location: **europe-west1 (Belgium)** - closest to Turkey
6. Click "Enable"
7. Wait for database creation (takes ~1 minute)
8. Once created, click "Start collection" to verify:
   - Collection ID: `test`
   - Document ID: Auto-ID
   - Field: `message` (string) = `"Firebase works!"`
   - Click "Save"

### 3. Enable Cloud Storage
1. Go to: https://console.firebase.google.com/project/okulavatar/storage
2. Click "Get started"
3. Select "Start in test mode" (radio button)
   - Allows authenticated uploads for testing
4. Click "Next"
5. Select location: **europe-west1 (Belgium)** - same as Firestore
6. Click "Done"
7. Storage bucket should be created: `okulavatar.firebasestorage.app`

## Verification
After completing all 3 steps, confirm:
- ✅ Authentication shows "Email/Password" as enabled
- ✅ Firestore shows a database in europe-west1 with a `test` collection
- ✅ Storage shows a bucket `okulavatar.firebasestorage.app`

## Important Notes
- Use "Test mode" for both Firestore and Storage (we'll add production rules later)
- Select **europe-west1** for both services (data locality)
- The test mode security rules expire in 30 days - reminder to update before then

## Return Format
Please report back:
1. Status of each step (✅ or ❌)
2. Any errors encountered
3. Screenshots if needed for verification

Thank you!
