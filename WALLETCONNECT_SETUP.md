# WalletConnect Setup Guide

## 🔑 Project ID Alma (5 dakika)

1. **WalletConnect Cloud'a Git:**
   - https://cloud.walletconnect.com/sign-up

2. **Ücretsiz Hesap Oluştur:**
   - Email ile kayıt ol
   - Email'i doğrula

3. **Yeni Proje Oluştur:**
   - "New Project" tıkla
   - Project Name: `Payment QR`
   - Project Type: `App`
   - Platform: `Flutter`

4. **Project ID'yi Kopyala:**
   - Dashboard'da 32 karakterlik ID görünür
   - Örnek: `a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6`

5. **Kodu Güncelle:**
   ```dart
   // lib/services/wallet_connect_service.dart
   static const String projectId = 'YOUR_PROJECT_ID_HERE';
   ```

## 🎯 Test için Alternatif

Eğer hemen test etmek istersen, bu demo ID'yi kullan:
```dart
static const String projectId = '2d4f2c8e3b5a7f9d1e6c8b3a5d7f2e4c';
```
(Not: Bu gerçek değil, sadece örnek. Gerçek ID almanız gerekiyor)

## 📱 Testnet Ayarı

WalletConnect servisinde mainnet'i testnet yap:
```dart
// lib/services/wallet_connect_service.dart
// Değiştir:
'algorand:mainnet' → 'algorand:testnet'
```

## ✅ Hazır!

Project ID'yi aldıktan sonra:
1. Koda yapıştır
2. `flutter pub get`
3. `flutter run`
4. Test et!