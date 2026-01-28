# KresAI V1 Test Scenarios

## SCENARIO 1: Admin Teacher Approve/Reject

### Approve Flow
1. Admin generates teacher code
2. Teacher enters code and fills registration form
3. Admin sees pending teacher in "Öğretmen Onayları"
4. Admin approves teacher
5. **Expected**: 
   - Teacher receives approval notification
   - Teacher can access TeacherShell
   - Activity log shows "Öğretmen onaylandı" event

### Reject Flow
1. Follow steps 1-3 above
2. Admin rejects teacher
3. **Expected**:
   - Teacher receives rejection notification
   - Teacher sees RejectedScreen (terminal)
   - Activity log shows "Öğretmen reddedildi" event

---

## SCENARIO 2: Teacher Parent Approve/Reject

### Approve Flow
1. Teacher generates parent code
2. Parent enters code and fills registration
3. Teacher sees pending parent in "Veli Onayları"
4. Teacher adds to roster and approves
5. **Expected**:
   - Parent receives approval notification
   - Parent can access ParentShell
   - Parent appears in class roster
   - Activity log shows "Veli onaylandı" event

### Reject Flow
1. Follow steps 1-3 above
2. Teacher rejects parent
3. **Expected**:
   - Parent receives rejection notification
   - Parent sees RejectedScreen (terminal)
   - Activity log shows "Veli reddedildi" event

---

## SCENARIO 3: Parent Consent Toggle

### Consent Off
1. Parent opens Settings (⚙️ icon in AppBar)
2. Toggle "Foto/Video İzni" OFF
3. Navigate to Feed tab
4. **Expected**:
   - Photo/Video feed items show "İzin gerekli" placeholder
   - Text/Activity items visible normally

5. Navigate to Live tab
6. If live active:
   **Expected**: "Canlı için izin gerekli" screen shown

### Consent On
1. Return to Settings
2. Toggle "Foto/Video İzni" ON
3. Navigate to Feed/Live
4. **Expected**:
   - All feed items visible
   - Live session accessible

---

## SCENARIO 4: Teacher Share Feed → Parent Views

1. Teacher navigates to Feed tab → "Paylaş" button
2. Select type (Text/Activity/Photo/Video)
3. Write content and submit
4. **Expected**:
   - Feed appears in TeacherFeedScreen
   - Activity log shows "Feed paylaşıldı" event

5. Parent (approved, consent ON) opens Feed tab
6. **Expected**:
   - Shared feed item visible
   - If requiresConsent=true and consent=false → placeholder shown

---

## SCENARIO 5: Teacher Daily Log → Parent Home Summary

1. Teacher navigates to "Ana Sayfa" tab
2. Teacher opens "Günlük Girişi" progress card
3. Select a child, tap meal/nap/toilet/activity button
4. Choose status (Done/Partial/Skipped) and add details
5. Save
6. **Expected**:
   - Log saved successfully
   - Teacher profile shows updated progress (X/N)
   - Activity log shows "Günlük güncellendi" event

7. Parent (of that child) opens "Ana Sayfa"
8. **Expected**:
   - "Bugünkü Özet" card shows meal/nap/toilet/activity with correct status+details

---

## SCENARIO 6: Live Start/End → Parent Home Card

### Start Live
1. Teacher navigates to "Canlı" tab
2. Enter optional title
3. Click "Canlı Yayın Başlat"
4. **Expected**:
   - Session starts, CANLI badge appears
   - Activity log shows "Canlı başlatıldı" event

5. Parent opens "Ana Sayfa"
6. **Expected**:
   - Live card appears with "CANLI YAYIN" + "İzle" button
   - If consent=false → "İzin gerekli" message

### End Live
1. Teacher clicks "Canlıyı Bitir"
2. **Expected**:
   - Session ends
   - Activity log shows "Canlı sonlandı" event

3. Parent refreshes "Ana Sayfa"
4. **Expected**:
   - Live card disappears

---

## SCENARIO 7: Restart Persistence

1. Perform multiple actions:
   - Teacher approve parent
   - Share feed
   - Log daily entry
   - Start live session

2. Restart app (hot reload or full restart)

3. **Expected**:
   - All registrations persist (approved states)
   - Feed items visible
   - Daily logs visible
   - Live session state persists (active/ended)
   - Activity log entries persist
   - Notifications persist

---

## SCENARIO 8: Activity Log Dashboard

### Admin View
1. Admin dashboard shows system snapshot
2. **Expected**: Recent activity events visible (if implemented)

### Teacher View
1. Teacher opens "Ana Sayfa"
2. **Expected**:
   - Pending parents count
   - Live status
   - Today's log progress
   - Latest feed items

### Parent View
1. Parent opens "Ana Sayfa"
2. **Expected**:
   - Live card (if active)
   - Today's summary (meal/nap/toilet/activity)
   - Latest 3 feed items

---

## Additional Edge Cases

### Duplicate Prevention
- Teacher: Try sharing same feed twice → Should show "Bu paylaşım zaten mevcut"
- Teacher: Try starting live when already active → Should return existing session (NO-OP)
- Daily: Same child+date+type → Should overwrite (upsert)

### Class Binding
- Teacher: Cannot see/edit other teacher's class data
- Parent: Cannot see roster outside their child's class

### Double-Tap Protection
- All approve/reject buttons disabled during processing
- Live start/end buttons disabled during processing
- Share feed button disabled during processing

---

## Manual Test Checklist

- [ ] Admin approve teacher → notification + activity log
- [ ] Admin reject teacher → notification + rejected screen
- [ ] Teacher approve parent → notification + roster + activity log
- [ ] Teacher reject parent → notification + rejected screen
- [ ] Parent consent OFF → feed/live blocked
- [ ] Parent consent ON → feed/live accessible
- [ ] Teacher share feed → parent görür
- [ ] Teacher daily log → parent home summary
- [ ] Live start → parent home card + activity log
- [ ] Live end → parent home card disappears + activity log
- [ ] Restart → tüm data persist
- [ ] Activity log dashboard → events görünür
- [ ] Duplicate guards çalışıyor
- [ ] Double-tap protection aktif
