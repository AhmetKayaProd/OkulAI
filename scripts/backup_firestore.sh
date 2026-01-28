#!/bin/bash
# Firestore Backup Script
# Automatically exports Firestore data to Cloud Storage

PROJECT_ID="okulai-dev"
BUCKET="gs://okulai-dev-backups"
DATE=$(date +%Y%m%d_%H%M%S)

echo "🔄 Starting Firestore backup: $DATE"

# Export Firestore data
gcloud firestore export $BUCKET/firestore-backup-$DATE \
  --project=$PROJECT_ID \
  --async

echo "✅ Backup initiated: $BUCKET/firestore-backup-$DATE"
echo "📊 Check status: gcloud firestore operations list --project=$PROJECT_ID"
echo ""
echo "💡 To restore this backup, run:"
echo "   ./restore_firestore.sh $BUCKET/firestore-backup-$DATE"
