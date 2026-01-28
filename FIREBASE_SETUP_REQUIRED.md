# Firebase Manual Setup Required

## ⚠️ Action Required

Firebase deployment requires manual project selection. Follow these steps:

### 1. Initialize Firebase Project

```bash
cd c:\Projelerim\kresai
firebase login
firebase use --add
```

**Select your project** from the list (likely "okulavatar" or similar)

**Give it an alias** (e.g., "default")

This will create `.firebaserc` file.

### 2. Deploy Security Rules

```bash
firebase deploy --only firestore:rules
```

**Expected output**:
```
✔ Deploy complete!
```

### 3. Verify in Console

1. Open [Firebase Console](https://console.firebase.google.com)
2. Select your project
3. Go to Firestore Database → Rules
4. Verify rules are active

### Alternative: Manual Upload

If CLI doesn't work:

1. Open Firebase Console
2. Go to Firestore Database → Rules
3. Click "Edit rules"
4. Copy-paste content from `firestore.rules`
5. Click "Publish"

## ✅ What's Already Done

- ✅ `firestore.rules` created
- ✅ `firebase.json` created
- ✅ `firestore.indexes.json` created
- ✅ Deployment guide in `docs/FIRESTORE_RULES_DEPLOYMENT.md`

## 📝 Rules Summary

Current rules allow:
- **Read**: Any authenticated user
- **Write Templates**: Only creator
- **Write Plans**: Any authenticated user

---

**Once deployed, the app will have production-grade Firestore security!**
