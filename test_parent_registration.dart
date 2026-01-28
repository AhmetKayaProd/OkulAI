// Veli Kayıt Testi
// Bu dosya manuel olarak çalıştırılmalı
// 
// ADIMLAR:
// 1. Veli kodu oluştur: VELI2024
// 2. Kod ile veli kaydı yap
// 3. Kaydı onayla

// İçerik:
/*

📌 VELİ KODU OLUŞTURULDU:
   Kod: VELI2024
   Tip: parent
   Aktif: true
   
👨‍👩‍👧 VELİ KAYDI:
   Veli Adı: Ayşe Yılmaz
   Öğrenci Adı: Can Yılmaz
   Fotoğraf İzni: Evet
   Kullanılan Kod: VELI2024
   Durum: pending → approved
   
✅ SONUÇ:
   - Veli kodu: VELI2024 (aktif)
   - Veli kaydı: Ayşe Yılmaz - Can Yılmaz (onaylı)
   - Sınıf listesine eklendi
   
📱 Veli artık "VELI2024" koduyla giriş yapabilir!

*/

import 'package:kresai/services/registration_store.dart';
import 'package:kresai/models/invite_code.dart';
import 'package:kresai/models/registrations.dart';

Future<void> createParentCodeAndRegistration() async {
  final store = RegistrationStore();
  await store.load();
  
  // 1. Veli kodu oluştur
  final parentCode = InviteCode(
    type: InviteCodeType.parent,
    code: 'VELI2024',
    createdAt: DateTime.now(),
    isActive: true,
  );
  await store.saveParentCode(parentCode);
  
  // 2. Veli kaydı oluştur
  final parentReg = ParentRegistration(
    id: 'parent_ayse_${DateTime.now().millisecondsSinceEpoch}',
    parentName: 'Ayşe Yılmaz',
    studentName: 'Can Yılmaz',
    photoConsent: true,
    codeUsed: 'VELI2024',
    status: RegistrationStatus.approved,
    createdAt: DateTime.now(),
  );
  
  // 3. Kaydı kaydet
  await store.addParentRegistration(parentReg);
  
  print('✅ Veli kodu ve kaydı oluşturuldu!');
}
