---
description: Run KresAI on Chrome with fixed port
---

# KresAI Web Development Workflow

## Sabit Port ile Çalıştırma

Flutter web uygulamasını **sabit 5555 portunda** çalıştırmak için:

```bash
flutter run -d chrome --web-port=5555
```

## Localhost URL
Uygulama çalıştığında:
- **URL**: http://localhost:5555
- **Browser Agent için**: Bu URL'yi kullan

## Hot Reload
Kod değişikliklerinden sonra:
- Terminal'de `r` tuşuna bas

## Yeniden Başlat
- Terminal'de `R` tuşuna bas (büyük harf)

## Durdurma
- Terminal'de `q` tuşuna bas

## Not
- Port 5555 kullanılıyorsa, başka bir port dene (örn: 5556, 5557)
- Bu workflow dosyası sayesinde her zaman aynı portu kullanacağız
