#!/bin/bash
# Firestore Restore Script
# Restores Firestore data from a Cloud Storage backup

PROJECT_ID="okulai-dev"
BACKUP_PATH=$1

if [ -z "$BACKUP_PATH" ]; then
  echo "❌ Error: Backup path required"
  echo ""
  echo "Usage: ./restore_firestore.sh gs://bucket/path/to/backup"
  echo ""
  echo "Example:"
  echo "  ./restore_firestore.sh gs://okulai-dev-backups/firestore-backup-20240128_100000"
  exit 1
fi

echo "⚠️  WARNING: This will overwrite current Firestore data!"
echo "📦 Backup: $BACKUP_PATH"
echo "🎯 Project: $PROJECT_ID"
echo ""
read -p "Continue? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
  echo "❌ Restore cancelled"
  exit 0
fi

echo ""
echo "🔄 Starting Firestore restore from: $BACKUP_PATH"

# Import Firestore data
gcloud firestore import $BACKUP_PATH \
  --project=$PROJECT_ID \
  --async

echo ""
echo "✅ Restore initiated"
echo "📊 Check status: gcloud firestore operations list --project=$PROJECT_ID"
