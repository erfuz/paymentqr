class Translations {
  static Map<String, Map<String, String>> labels = {
    'en': {
      // Main Screen
      'app_title': 'Payment QR',
      'wallet_address': 'Wallet Address',
      'amount': 'Amount (ALGO)',
      'note': 'Note (optional)',
      'generate': 'GENERATE QR',
      'copy': 'COPY',
      'share': 'SHARE',
      'address_required': 'Address and Amount required!',
      'link_copied': 'Link copied!',
      
      // Settings Screen
      'settings': 'Settings',
      'theme': 'Theme',
      'dark_mode': 'Dark Mode',
      'light_mode': 'Light Mode',
      'language': 'Language',
      'english': 'English',
      'turkish': 'Türkçe',
      'qr_size': 'QR Code Size',
      'small': 'Small',
      'medium': 'Medium',
      'large': 'Large',
      'auto_copy': 'Auto Copy',
      'auto_copy_desc': 'Automatically copy link after generating QR',
      'default_amount': 'Default Amount',
      'version': 'Version',
      'save': 'Save',
      'settings_saved': 'Settings saved!',
    },
    'tr': {
      // Ana Ekran
      'app_title': 'Ödeme QR',
      'wallet_address': 'Cüzdan Adresi',
      'amount': 'Miktar (ALGO)',
      'note': 'Not (opsiyonel)',
      'generate': 'QR OLUŞTUR',
      'copy': 'KOPYALA',
      'share': 'PAYLAŞ',
      'address_required': 'Adres ve Miktar gerekli!',
      'link_copied': 'Link kopyalandı!',
      
      // Ayarlar Ekranı
      'settings': 'Ayarlar',
      'theme': 'Tema',
      'dark_mode': 'Karanlık Mod',
      'light_mode': 'Aydınlık Mod',
      'language': 'Dil',
      'english': 'English',
      'turkish': 'Türkçe',
      'qr_size': 'QR Kod Boyutu',
      'small': 'Küçük',
      'medium': 'Orta',
      'large': 'Büyük',
      'auto_copy': 'Otomatik Kopyala',
      'auto_copy_desc': 'QR oluşturduktan sonra linki otomatik kopyala',
      'default_amount': 'Varsayılan Miktar',
      'version': 'Versiyon',
      'save': 'Kaydet',
      'settings_saved': 'Ayarlar kaydedildi!',
    }
  };

  static String get(String key, String language) {
    return labels[language]?[key] ?? labels['en']?[key] ?? key;
  }
}