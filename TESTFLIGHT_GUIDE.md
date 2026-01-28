# OkulAI - TestFlight Otomatik Dağıtım Kurulum Rehberi

Merhaba! OkulAI uygulamasını TestFlight'a otomatik olarak göndermek için gerekli tüm altyapıyı (GitHub Actions, Fastlane) projenize ekledim. Süreci tamamlamak için aşağıdaki adımları dikkatlice takip etmeniz yeterlidir.

## 1. Adım: Sertifika Deposu Oluşturma

Kod imzalama sertifikaları ve provisioning profillerini güvenli bir şekilde saklamak için yeni bir **özel (private)** GitHub deposu oluşturmanız gerekiyor.

1.  **Yeni Depo Oluşturun:**
    *   GitHub hesabınıza gidin ve [yeni bir depo oluşturun](https://github.com/new).
    *   **Repository name:** `OkulAI-certificates` (Bu ismin tam olarak aynı olması kritik öneme sahiptir).
    *   **Description (isteğe bağlı):** `OkulAI iOS code signing certificates`
    *   **Private** seçeneğini işaretleyin. Bu depo **kesinlikle** özel olmalıdır.
    *   "Create repository" butonuna tıklayın.

## 2. Adım: App Store Connect API Anahtarı Oluşturma

GitHub Actions'ın App Store Connect'e bağlanabilmesi için bir API anahtarı oluşturacağız.

1.  **App Store Connect'e Gidin:**
    *   [App Store Connect > Users and Access > Integrations](https://appstoreconnect.apple.com/access/integrations/api) sayfasına gidin.
2.  **Yeni Anahtar Oluşturun:**
    *   "Keys" sekmesinin yanındaki mavi **(+)** butonuna tıklayın.
    *   **Name:** `OkulAI TestFlight Key`
    *   **Access:** `Admin` seçin.
    *   "Generate" butonuna tıklayın.
3.  **Anahtarı İndirin ve Bilgileri Kaydedin:**
    *   **ÖNEMLİ:** Anahtar oluşturulduğunda **"Download API Key"** linkine tıklayarak `.p8` uzantılı dosyayı hemen indirin. Bu dosya sadece bir kez indirilebilir. Güvenli bir yerde saklayın.
    *   Aşağıdaki üç bilgiyi bir metin editörüne kopyalayın:
        *   **Issuer ID:** Sayfanın üst kısmında yer alan uzun bir kod (ör: `3d6c551b-....`).
        *   **Key ID:** Yeni oluşturduğunuz anahtarın `KEY ID` sütunundaki değeri.
        *   **API Key Dosyası:** İndirdiğiniz `AuthKey_XXXX.p8` dosyası.

## 3. Adım: GitHub Depo Sırlarını (Secrets) Ayarlama

GitHub Actions'ın güvenli bir şekilde çalışabilmesi için yukarıda edindiğiniz bilgileri `OkulAI` deposunun sırlarına ekleyeceğiz.

1.  **GitHub Deponuza Gidin:**
    *   `AhmetKayaProd/OkulAI` deposunu açın.
    *   **Settings > Secrets and variables > Actions** menüsüne gidin.
2.  **Yeni Sırlar Ekleyin:**
    *   "New repository secret" butonuna tıklayarak aşağıdaki 5 sırrı teker teker oluşturun:

| Secret Adı                      | Değeri                                                                                                                                                                                          |
| :------------------------------ | :---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `APP_STORE_CONNECT_ISSUER_ID`   | 2. Adım'da kaydettiğiniz **Issuer ID** değeri.                                                                                                                                                  |
| `APP_STORE_CONNECT_KEY_ID`      | 2. Adım'da kaydettiğiniz **Key ID** değeri.                                                                                                                                                     |
| `APP_STORE_CONNECT_API_KEY`     | 2. Adım'da indirdiğiniz `.p8` dosyasının içeriği. Dosyayı bir metin editörüyle açın, **tüm içeriğini** (`-----BEGIN PRIVATE KEY-----` ve `-----END PRIVATE KEY-----` dahil) kopyalayıp buraya yapıştırın. |
| `MATCH_PASSWORD`                | Sertifika deposunu şifrelemek için **sizin belirleyeceğiniz** bir parola. Karmaşık ve güvenli bir parola seçin.                                                                                    |
| `MATCH_GIT_BASIC_AUTHORIZATION` | Sertifika deposuna erişim için kullanılacak **GitHub Personal Access Token**. [Buradan](https://github.com/settings/tokens?type=beta) "Fine-grained personal access token" oluşturun. `OkulAI-certificates` deposu için **Read and Write** yetkisi vermeniz yeterlidir. Oluşturduğunuz token'ı buraya yapıştırın. |

## 4. Adım: İlk Dağıtımı Başlatma

Tüm sırlar eklendikten sonra GitHub Actions otomatik olarak çalışmaya başlayacaktır. `main` branch'ine bir commit push edildiğinde yeni bir build alınıp TestFlight'a gönderilir.

İlk dağıtımı manuel olarak tetiklemek için:

1.  `OkulAI` deposunda **Actions** sekmesine gidin.
2.  Sol menüden **iOS TestFlight Deployment** workflow'unu seçin.
3.  **"Run workflow"** butonuna tıklayın ve `main` branch'ini seçerek çalıştırın.

İlk çalıştırmada `match` komutu sertifikaları oluşturup `OkulAI-certificates` deposuna push edecektir. Süreç tamamlandığında uygulamanız App Store Connect'te "TestFlight" sekmesi altında görünecektir.

Herhangi bir sorun yaşarsanız Actions loglarını kontrol edebilirsiniz.

Başarılar!
