# OkulAI - Kapsamlı Proje Analizi

## 📋 Proje Özeti

**OkulAI**, anaokulu ve kreş yönetimi için geliştirilmiş yapay zeka destekli bir mobil uygulamadır. Öğretmenler, veliler ve yöneticiler için özel olarak tasarlanmış üç farklı rol sistemi ile eğitim süreçlerini dijitalleştirir ve otomatize eder.

### Temel Teknolojiler
- **Framework:** Flutter (Dart)
- **Backend:** Firebase (Authentication, Firestore, Cloud Storage)
- **AI Engine:** Google Gemini 2.0 Flash
- **State Management:** SharedPreferences (MobX planlanıyor)
- **Design System:** Material 3 + Custom Tokens

---

## 👨‍🏫 ÖĞRETMEN ROLÜ

Öğretmen rolü, sınıf yönetimi ve eğitim içeriği oluşturma konusunda en geniş yetkilere sahip roldür.

### 1. 📚 Ödev Yönetimi (AI Destekli)

#### Ödev Oluşturma
- **AI ile Otomatik Üretim:** Konu, sınıf seviyesi ve zorluk derecesine göre ödev seçenekleri üretir
- **Çoklu Format Desteği:**
  - Çoktan seçmeli
  - Doğru/Yanlış
  - Eşleştirme
  - Boşluk doldurma
  - Kısa/uzun yanıt
  - Çizim
  - Uygulamalı
  - Fotoğraflı çalışma sayfası
- **Özelleştirme Seçenekleri:**
  - Sınıf seviyesi (Kreş, Anaokulu, İlkokul)
  - Zaman penceresi (Günlük, Haftalık, Telafi)
  - Zorluk derecesi (Kolay, Orta, Zor)
  - Tahmini süre
  - Hedef öğrenci seçimi

#### Ödev İnceleme ve Notlandırma
- **AI Destekli Otomatik Değerlendirme:**
  - Fotoğraf tabanlı ödev kontrolü
  - Metin tabanlı yanıt analizi
  - Güven skoru ile doğruluk değerlendirmesi
- **Manuel İnceleme:**
  - Öğretmen override yetkisi
  - Özel geri bildirim ekleme
  - Puan düzeltme
- **Detaylı Raporlama:**
  - Öğrenci bazlı performans analizi
  - Konu bazlı başarı oranları
  - Güçlü ve zayıf yönler

### 2. 📝 Sınav Yönetimi (AI Destekli)

#### Sınav Oluşturma
- **AI ile Soru Üretimi:**
  - Konu bazlı otomatik soru oluşturma
  - Çoklu versiyon desteği (A, B, C)
  - Görsel içerik üretimi (resimli sorular)
- **Soru Tipleri:**
  - Çoktan seçmeli
  - Doğru/Yanlış
  - Eşleştirme
  - Boşluk doldurma
  - Kısa yanıt
  - Dinleme
  - Resimli seçim
  - Çizim kontrolü
- **Sınav Ayarları:**
  - Soru sayısı
  - Süre limiti
  - Zorluk seviyesi
  - Öğretmen stili (oyunlaştırılmış, ciddi, vb.)

#### Sınav Değerlendirme
- **Otomatik Notlandırma:**
  - AI tabanlı yanıt analizi
  - Rubric bazlı puanlama
  - Güven skoru ile kalite kontrolü
- **Öğretmen İncelemesi:**
  - Düşük güvenli yanıtları manuel kontrol
  - Puan düzeltme yetkisi
  - Detaylı geri bildirim
- **Raporlama:**
  - Sınıf geneli başarı analizi
  - Soru bazlı zorluk analizi
  - Öğrenci performans karşılaştırması

### 3. 📅 Günlük Log Yönetimi

#### Öğrenci Takibi
- **Günlük Aktiviteler:**
  - Yemek durumu (Yedi, Kısmen yedi, Yemedi)
  - Uyku durumu (Uyudu, Kısmen uyudu, Uyumadı)
  - Tuvalet durumu
  - Aktivite katılımı
  - Özel notlar
- **Toplu İşlem:**
  - Tüm sınıf için hızlı kayıt
  - Tarih bazlı görüntüleme
  - Geçmiş kayıtlara erişim

### 4. 📸 Paylaşım ve İletişim

#### Feed Yönetimi
- **İçerik Türleri:**
  - Fotoğraf paylaşımı
  - Video paylaşımı
  - Metin duyuruları
  - Etkinlik bildirimleri
- **Gizlilik Kontrolleri:**
  - Veli onayı gerektirme
  - Görünürlük ayarları (Onaylı veliler / Tüm veliler)
  - İçerik moderasyonu

#### Canlı Yayın
- **Sınıf İçi Yayın:**
  - Canlı yayın başlatma/durdurma
  - Veli izin kontrolü
  - Yayın geçmişi

### 5. 👥 Veli Yönetimi

#### Veli Onayları
- **Başvuru İnceleme:**
  - Bekleyen veli kayıtlarını görüntüleme
  - Öğrenci bilgilerini doğrulama
  - Onaylama/Reddetme
- **Davet Kodu Oluşturma:**
  - Sınıf bazlı davet kodları
  - Kullanım limiti belirleme
  - Kod geçerlilik süresi

### 6. ⚙️ Ayarlar ve Profil

- **Profil Yönetimi:** Ad, email, sınıf bilgisi
- **AI Ayarları:** Gemini API key yapılandırması
- **Bildirim Tercihleri:** Push notification ayarları
- **Program Yükleme:** Haftalık program fotoğraf/metin yükleme

---

## 👨‍👩‍👧 VELİ ROLÜ

Veli rolü, çocuklarının eğitim sürecini takip etmek ve desteklemek için tasarlanmıştır.

### 1. 📚 Ödev Takibi

#### Ödev Görüntüleme
- **Aktif Ödevler:**
  - Yayınlanmış ödev listesi
  - Teslim tarihi bilgisi
  - Durum göstergeleri (Başlanmadı, Devam ediyor, Gönderildi, Notlandırıldı)
- **Ödev Detayları:**
  - Ödev talimatları
  - Gerekli malzemeler
  - Tahmini süre
  - Veli rehberliği notları

#### Ödev Gönderimi
- **Çoklu Gönderim Türü:**
  - Metin yanıtları
  - Fotoğraf yükleme (max 3 fotoğraf)
  - İnteraktif yanıtlar
- **AI Destekli Ön İnceleme:**
  - Gönderim öncesi AI feedback
  - Eksik/hatalı kısımlar için uyarı
  - Geliştirme önerileri
  - Maksimum 3 kez inceleme hakkı
- **Geri Bildirim:**
  - Öğretmen notları
  - Puan bilgisi
  - Güçlü yönler ve gelişim alanları

### 2. 📝 Sınav Takibi

#### Sınav Görüntüleme
- **Üç Kategori:**
  - Bekleyen sınavlar
  - Gönderilen sınavlar
  - Notlandırılmış sınavlar
- **Sınav Bilgileri:**
  - Soru sayısı
  - Süre limiti
  - Konu başlıkları

#### Sınav Katılımı
- **İnteraktif Sınav:**
  - Soru soru ilerleme
  - Otomatik kaydetme (10 saniyede bir)
  - Süre takibi
  - Yanıt değiştirme imkanı
- **Sonuç Görüntüleme:**
  - Toplam puan
  - Soru bazlı doğru/yanlış
  - Öğretmen geri bildirimi
  - Gelişim önerileri (çözüm içermez, sadece ipucu)

### 3. 📅 Günlük Takip

#### Çocuk Durumu
- **Günlük Raporlar:**
  - Yemek durumu
  - Uyku durumu
  - Tuvalet durumu
  - Aktivite katılımı
  - Öğretmen notları
- **Tarih Bazlı Görüntüleme:**
  - Geçmiş kayıtlara erişim
  - Haftalık/aylık özet

### 4. 📸 Feed ve Canlı Yayın

#### İçerik Görüntüleme
- **Feed Akışı:**
  - Fotoğraf/video paylaşımları
  - Duyurular
  - Etkinlik bildirimleri
- **Gizlilik Kontrolü:**
  - Foto/video izni yönetimi
  - İçerik filtreleme

#### Canlı Yayın İzleme
- **Sınıf Yayınları:**
  - Aktif yayınları görüntüleme
  - İzin kontrolü
  - Yayın geçmişi

### 5. ⚙️ Ayarlar ve Profil

- **Profil Yönetimi:** Ad, email, öğrenci bilgisi
- **Foto/Video İzni:** Medya içeriklerini görme izni
- **Bildirim Tercihleri:** Push notification ayarları

---

## 👨‍💼 YÖNETİCİ ROLÜ

Yönetici rolü, okul genelinde kullanıcı yönetimi ve sistem kontrolü için tasarlanmıştır.

### 1. 👥 Kullanıcı Yönetimi

#### Öğretmen Onayları
- **Başvuru İnceleme:**
  - Bekleyen öğretmen kayıtları
  - Kimlik doğrulama
  - Sınıf atama
  - Onaylama/Reddetme

#### Davet Kodu Yönetimi
- **Öğretmen Kodları:**
  - Yeni kod oluşturma
  - Kullanım limiti belirleme
  - Kod geçerlilik süresi
  - Aktif kodları görüntüleme

### 2. 📊 Sistem Yönetimi

- **Kullanıcı Listesi:** Tüm öğretmen ve velileri görüntüleme
- **Okul Ayarları:** Genel sistem konfigürasyonu
- **Raporlama:** Sistem kullanım istatistikleri

---

## 🤖 YAPAY ZEKA ÖZELLİKLERİ

### Google Gemini 2.0 Flash Entegrasyonu

#### 1. Ödev AI Servisi
- **Ödev Üretimi:**
  - Konu ve parametrelere göre 3 farklı ödev seçeneği
  - Format bazlı içerik üretimi
  - Öğrenci talimatları ve veli rehberliği
  - Değerlendirme rubriği
- **Ödev Değerlendirme:**
  - Fotoğraf tabanlı ödev kontrolü
  - Metin analizi
  - Güven skoru hesaplama
  - Detaylı geri bildirim üretimi

#### 2. Sınav AI Servisi
- **Sınav Üretimi:**
  - Konu bazlı soru oluşturma
  - Çoklu versiyon desteği
  - Görsel içerik üretimi
  - Rubric oluşturma
- **Sınav Değerlendirme:**
  - Otomatik yanıt analizi
  - Güven skoru ile kalite kontrolü
  - Öğrenci bazlı feedback

#### 3. Program Parsing
- **Görsel İşleme:**
  - Haftalık program fotoğraflarını OCR
  - Yapılandırılmış veri çıkarımı
  - Günlük plan önerisi

---

## 📊 VERİ MODELLERİ

### Temel Modeller

1. **Homework (Ödev)**
   - Ödev bilgileri, format, talimatlar
   - Değerlendirme rubriği
   - Hedef öğrenciler
   - Durum (Taslak, Yayınlandı, Kapatıldı)

2. **HomeworkSubmission (Ödev Gönderimi)**
   - Öğrenci yanıtları (metin/fotoğraf)
   - AI inceleme sonuçları
   - Öğretmen notları ve puanı
   - Gönderim durumu

3. **Exam (Sınav)**
   - Sınav bilgileri, sorular
   - Soru tipleri ve rubric
   - Süre ve zorluk ayarları

4. **ExamSubmission (Sınav Gönderimi)**
   - Öğrenci yanıtları
   - Otomatik notlandırma sonuçları
   - Soru bazlı değerlendirme
   - Durum (Devam ediyor, Gönderildi, Notlandı)

5. **DailyLogItem (Günlük Kayıt)**
   - Öğrenci günlük durumu
   - Aktivite tipleri (Yemek, Uyku, Tuvalet, Aktivite)
   - Durum (Tamamlandı, Kısmi, Atlandı)

6. **FeedItem (Paylaşım)**
   - İçerik tipi (Fotoğraf, Video, Metin, Etkinlik)
   - Medya URL'leri
   - Görünürlük ve izin ayarları

7. **LiveSession (Canlı Yayın)**
   - Yayın durumu (Canlı, Bitti)
   - Başlangıç/bitiş zamanları
   - İzin gereksinimleri

8. **InviteCode (Davet Kodu)**
   - Kod tipi (Öğretmen/Veli)
   - Kullanım limiti
   - Geçerlilik süresi
   - Okul ve sınıf bilgisi

---

## 🔐 GÜVENLİK ve YETKİLENDİRME

### Firebase Authentication
- Email/Password authentication
- Rol bazlı yetkilendirme (Teacher, Parent, Admin)
- Secure session management

### Veri Gizliliği
- Veli foto/video izin sistemi
- Sınıf bazlı veri izolasyonu
- Öğrenci bilgilerinin korunması

---

## 📱 KULLANICI AKIŞLARI

### İlk Kurulum Akışı

1. **Hesap Oluşturma:** Email ve şifre ile kayıt
2. **Rol Seçimi:** Teacher veya Parent
3. **Davet Kodu Girişi:** Okul/sınıf bağlantısı
4. **Onay Bekleme:** Admin/Teacher onayı
5. **Profil Tamamlama:** Ek bilgiler

### Öğretmen Günlük Akışı

1. Ana sayfada günün özetini görüntüleme
2. Günlük log girişi (yemek, uyku, aktivite)
3. Ödev/sınav oluşturma (AI desteği ile)
4. Gönderilen ödev/sınavları inceleme
5. Feed'e içerik paylaşımı
6. Veli onaylarını kontrol

### Veli Günlük Akışı

1. Ana sayfada çocuğun durumunu görüntüleme
2. Günlük raporu inceleme
3. Aktif ödevleri kontrol ve gönderim
4. Sınavlara katılım
5. Feed'i takip etme
6. Canlı yayın izleme (izin varsa)

---

## 🚀 GELECEK ÖZELLİKLER

### Planlanan Geliştirmeler
- Cloud Functions entegrasyonu
- Firestore real-time sync
- Push notifications (FCM)
- MobX state management
- Çoklu dil desteği
- Dark mode

### Potansiyel Yeni Özellikler
- Veli-öğretmen mesajlaşma
- Devam/devamsızlık takibi
- Mali yönetim (ücret takibi)
- Etkinlik takvimi
- Sağlık kayıtları
- Gelişim raporları

---

## 📈 PROJE İSTATİSTİKLERİ

- **Toplam Ekran:** 50+ ekran
- **Model Sayısı:** 22 veri modeli
- **Öğretmen Ekranı:** 24 ekran
- **Veli Ekranı:** 14 ekran
- **Yönetici Ekranı:** 4 ekran
- **AI Servis:** 3 ana AI servisi (Ödev, Sınav, Program)

---

**Rapor Tarihi:** 28 Ocak 2026  
**Proje Durumu:** Aktif Geliştirme  
**Teknoloji Stack:** Flutter + Firebase + Google Gemini AI
