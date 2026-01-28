# Firestore Security Rules Deployment Guide

## 📋 Prerequisites

1. Firebase CLI installed
2. Logged into Firebase account
3. Firebase project initialized

## 🚀 Deployment Steps

### 1. Deploy Rules

```bash
cd c:\Projelerim\kresai
firebase deploy --only firestore:rules
```

**Expected Output**:
```
✔ Deploy complete!

Project Console: https://console.firebase.google.com/project/[project-id]/overview
```

### 2. Verify Deployment

1. Open Firebase Console
2. Go to Firestore Database → Rules
3. Verify rules are active
4. Check "Published" timestamp

### 3. Test Rules (Firebase Console)

Use the Rules Playground to test:

**Test 1: Authenticated Read**
```
Operation: get
Location: /schools/default_school/templates/template_123
Auth: Authenticated (any UID)
Expected: Allow
```

**Test 2: Unauthenticated Read**
```
Operation: get
Location: /schools/default_school/templates/template_123
Auth: Unauthenticated
Expected: Deny
```

**Test 3: Creator Write**
```
Operation: create
Location: /schools/default_school/templates/template_456
Auth: UID = user_abc
Data: { createdByTeacherId: "user_abc", ... }
Expected: Allow
```

**Test 4: Non-creator Write**
```
Operation: update
Location: /schools/default_school/templates/template_123
Auth: UID = user_xyz
Existing Data: { createdByTeacherId: "user_abc", ... }
Expected: Deny
```

## 🔒 Security Rules Summary

### Templates
- **Read**: Any authenticated user
- **Create/Update/Delete**: Only creator (createdByTeacherId == auth.uid)

### Daily Plans
- **Read**: Any authenticated user
- **Create/Update**: Any authenticated user
- **Delete**: Any authenticated user (TODO: restrict to creator/admin)

### Registrations
- **Read**: Own registration only
- **Write**: Any authenticated (TODO: restrict to admin)

### Other Collections
- **Read/Write**: Any authenticated user (simplified for V1)

## ⚠️ Production Improvements

For production deployment, enhance rules:

1. **Role-based Access**:
   ```javascript
   function isAdmin() {
     return exists(/databases/$(database)/documents/users/$(request.auth.uid)) &&
       get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
   }
   ```

2. **Field Validation**:
   ```javascript
   allow create: if request.resource.data.keys().hasAll(['classId', 'periodType', 'rawText']);
   ```

3. **Data Sanitization**:
   ```javascript
   allow update: if request.resource.data.diff(resource.data).affectedKeys()
     .hasOnly(['lastParsedAt', 'version']);
   ```

## 📊 Current Rules Status

- **Environment**: Development
- **Authentication**: Required for all operations
- **Authorization**: Basic creator-based + open authenticated
- **Field Validation**: None (trust client)
- **Rate Limiting**: Firebase default limits

## ✅ Deployment Checklist

- [ ] Rules file created (`firestore.rules`)
- [ ] Firebase CLI installed
- [ ] Logged into correct project
- [ ] Rules deployed
- [ ] Verified in Console
- [ ] Tested with Rules Playground
- [ ] App tested with real auth

## 🔧 Troubleshooting

### Error: "permission-denied"
- Check user is authenticated (`FirebaseAuth.instance.currentUser != null`)
- Verify user ID matches `createdByTeacherId` for write operations
- Check rules deployed successfully

### Error: "PERMISSION_DENIED: Missing or insufficient permissions"
- Rules may not be deployed yet
- Wait 1-2 minutes for propagation
- Try clearing app cache and restart

### Rules not updating
```bash
# Force redeploy
firebase deploy --only firestore:rules --force
```

---

Deploy these basic rules first, then enhance for production based on testing results.
