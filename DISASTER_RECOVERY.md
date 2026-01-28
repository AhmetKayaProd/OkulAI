# Firestore Disaster Recovery - Setup Guide

## Overview
This guide covers the disaster recovery setup for KresAI's Firestore database.

## Phase 1: Implemented ✅

### 1. Rate Limiting
**File**: `lib/services/firestore_rate_limiter.dart`

**Purpose**: Prevents quota overruns by limiting write operations.

**Configuration**:
- Max 100 writes per minute per collection
- Automatic throttling when limit exceeded

**Usage**: Automatically integrated into all store write operations.

### 2. Retry Logic
**File**: `lib/services/firestore_retry_helper.dart`

**Purpose**: Handles transient network failures with exponential backoff.

**Configuration**:
- Max 3 retries
- Exponential backoff: 1s, 2s, 4s

**Usage**: Wraps all Firestore write operations.

### 3. Monitoring
**File**: `lib/services/firebase_monitoring.dart`

**Purpose**: Detects anomalies and alerts on high error/write rates.

**Configuration**:
- Alert threshold: 1000 writes/hour
- Error threshold: 50 errors/hour

**Usage**: Automatically tracks all Firestore operations.

### 4. Backup Scripts
**Files**: 
- `scripts/backup_firestore.sh` - Daily backup
- `scripts/restore_firestore.sh` - Disaster recovery

**Setup**:
```bash
# 1. Create Cloud Storage bucket
gsutil mb -p okulai-dev -l us-central1 gs://okulai-dev-backups

# 2. Set retention policy (30 days)
gsutil lifecycle set lifecycle.json gs://okulai-dev-backups

# 3. Run manual backup
cd scripts
chmod +x backup_firestore.sh restore_firestore.sh
./backup_firestore.sh

# 4. Schedule daily backups (Cloud Scheduler)
gcloud scheduler jobs create http firestore-daily-backup \
  --schedule="0 2 * * *" \
  --uri="https://firestore.googleapis.com/v1/projects/okulai-dev/databases/(default):exportDocuments" \
  --message-body='{"outputUriPrefix":"gs://okulai-dev-backups/scheduled-backup"}' \
  --oauth-service-account-email=firebase-adminsdk@okulai-dev.iam.gserviceaccount.com
```

---

## Phase 2: Pending ⏳

### Security Rules (Requires Firebase Auth)

**Current State**: `allow read, write: if true;` (demo mode)

**Target State**: Role-based access control

**Blocker**: Firebase Authentication not configured

**Next Steps**:
1. Configure Firebase Authentication
2. Update security rules (see `disaster_recovery_plan.md`)
3. Test thoroughly on staging
4. Deploy to production

---

## Testing

### Rate Limiting Test
```dart
// Simulate high write volume
for (int i = 0; i < 150; i++) {
  await announcementStore.createAnnouncement(testAnnouncement);
}
// Expected: First 100 succeed, rest throttled
```

### Retry Logic Test
```dart
// Simulate network failure (disconnect WiFi)
await announcementStore.createAnnouncement(testAnnouncement);
// Expected: Retries 3 times with exponential backoff
```

### Monitoring Test
```dart
// Check stats
final stats = FirebaseMonitoring().getStats();
print(stats); // {writes: X, reads: Y, errors: Z}
```

### Backup/Restore Test
```bash
# 1. Backup current data
./scripts/backup_firestore.sh

# 2. Delete some data (test environment only!)
# ... delete via Firebase Console ...

# 3. Restore from backup
./scripts/restore_firestore.sh gs://okulai-dev-backups/firestore-backup-YYYYMMDD_HHMMSS
```

---

## Monitoring Dashboard

### Firebase Console
1. Go to Firebase Console → Firestore
2. Check "Usage" tab for quota monitoring
3. Set up budget alerts

### Client-Side Stats
```dart
// Get current stats
final monitoring = FirebaseMonitoring();
final stats = monitoring.getStats();

print('Writes: ${stats['writes']}');
print('Reads: ${stats['reads']}');
print('Errors: ${stats['errors']}');
```

---

## Disaster Recovery Procedures

### Scenario 1: Data Accidentally Deleted
```bash
# 1. List available backups
gsutil ls gs://okulai-dev-backups/

# 2. Restore from most recent backup
./scripts/restore_firestore.sh gs://okulai-dev-backups/firestore-backup-LATEST

# 3. Verify data restored
# Check Firebase Console
```

### Scenario 2: Quota Exceeded
```bash
# 1. Check rate limiter stats
# Look for "RATE LIMIT" messages in console

# 2. Identify problematic code
# Check which collection is hitting limits

# 3. Fix the bug
# Update code to reduce write frequency

# 4. Deploy fix
flutter run -d chrome
```

### Scenario 3: Security Rules Broken
```bash
# 1. Rollback rules in Firebase Console
# Go to Firestore → Rules → History → Restore previous version

# 2. Fix rules locally
# Update firestore.rules

# 3. Test with emulator
firebase emulators:start

# 4. Deploy fixed rules
firebase deploy --only firestore:rules
```

---

## Cost Monitoring

### Firestore Costs
- Reads: $0.06 per 100K documents
- Writes: $0.18 per 100K documents
- Deletes: $0.02 per 100K documents
- Storage: $0.18/GB/month

### Backup Costs
- Cloud Storage: $0.026/GB/month
- Export operation: $0.10 per GB

### Budget Alerts
Set up in Firebase Console → Project Settings → Budget & Alerts

Recommended limits:
- Daily: $5
- Monthly: $100

---

## Next Steps

1. ✅ Apply disaster recovery features to remaining stores
2. ⏳ Configure Firebase Authentication
3. ⏳ Deploy production security rules
4. ⏳ Set up Cloud Scheduler for automated backups
5. ⏳ Configure budget alerts
6. ⏳ Create monitoring dashboard
