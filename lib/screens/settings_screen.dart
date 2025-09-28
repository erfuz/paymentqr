import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../utils/translations.dart';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late String selectedLanguage;
  late String selectedQrSize;
  late bool autoCopy;
  late TextEditingController defaultAmountController;

  @override
  void initState() {
    super.initState();
    final provider = context.read<ThemeProvider>();
    selectedLanguage = provider.language;
    autoCopy = provider.autoCopy;
    defaultAmountController = TextEditingController(text: provider.defaultAmount);
    
    // Determine QR size string
    if (provider.qrSize == 200) {
      selectedQrSize = 'small';
    } else if (provider.qrSize == 250) {
      selectedQrSize = 'medium';
    } else {
      selectedQrSize = 'large';
    }
  }

  @override
  void dispose() {
    defaultAmountController.dispose();
    super.dispose();
  }

  double getQrSizeValue(String size) {
    switch (size) {
      case 'small':
        return 200;
      case 'large':
        return 300;
      default:
        return 250; // medium
    }
  }

  void saveSettings() async {
    final provider = context.read<ThemeProvider>();
    
    // Save all settings
    await provider.setLanguage(selectedLanguage);
    await provider.setQrSize(getQrSizeValue(selectedQrSize));
    await provider.setAutoCopy(autoCopy);
    await provider.setDefaultAmount(defaultAmountController.text);
    
    // Show confirmation
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(Translations.get('settings_saved', provider.language)),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ThemeProvider>();
    final isDark = provider.themeMode == ThemeMode.dark;
    final lang = provider.language;

    return Scaffold(
      appBar: AppBar(
        title: Text(Translations.get('settings', lang)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Theme Section
            Card(
              child: Padding(
                padding: EdgeInsets.all(15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      Translations.get('theme', lang),
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 10),
                    SwitchListTile(
                      title: Text(
                        isDark 
                          ? Translations.get('dark_mode', lang)
                          : Translations.get('light_mode', lang)
                      ),
                      secondary: Icon(
                        isDark ? Icons.dark_mode : Icons.light_mode
                      ),
                      value: isDark,
                      onChanged: (value) {
                        provider.toggleTheme();
                      },
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 15),

            // Language Section
            Card(
              child: Padding(
                padding: EdgeInsets.all(15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      Translations.get('language', lang),
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 10),
                    RadioListTile<String>(
                      title: Text('English 🇬🇧'),
                      value: 'en',
                      groupValue: selectedLanguage,
                      onChanged: (value) {
                        setState(() {
                          selectedLanguage = value!;
                        });
                      },
                    ),
                    RadioListTile<String>(
                      title: Text('Türkçe 🇹🇷'),
                      value: 'tr',
                      groupValue: selectedLanguage,
                      onChanged: (value) {
                        setState(() {
                          selectedLanguage = value!;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 15),

            // QR Size Section
            Card(
              child: Padding(
                padding: EdgeInsets.all(15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      Translations.get('qr_size', lang),
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 10),
                    SegmentedButton<String>(
                      segments: [
                        ButtonSegment(
                          value: 'small',
                          label: Text(Translations.get('small', lang)),
                          icon: Icon(Icons.qr_code, size: 16),
                        ),
                        ButtonSegment(
                          value: 'medium',
                          label: Text(Translations.get('medium', lang)),
                          icon: Icon(Icons.qr_code, size: 20),
                        ),
                        ButtonSegment(
                          value: 'large',
                          label: Text(Translations.get('large', lang)),
                          icon: Icon(Icons.qr_code, size: 24),
                        ),
                      ],
                      selected: {selectedQrSize},
                      onSelectionChanged: (Set<String> newSelection) {
                        setState(() {
                          selectedQrSize = newSelection.first;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 15),

            // Auto Copy Section
            Card(
              child: Padding(
                padding: EdgeInsets.all(15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SwitchListTile(
                      title: Text(Translations.get('auto_copy', lang)),
                      subtitle: Text(
                        Translations.get('auto_copy_desc', lang),
                        style: TextStyle(fontSize: 12),
                      ),
                      secondary: Icon(Icons.copy),
                      value: autoCopy,
                      onChanged: (value) {
                        setState(() {
                          autoCopy = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 15),

            // Default Amount Section
            Card(
              child: Padding(
                padding: EdgeInsets.all(15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      Translations.get('default_amount', lang),
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 10),
                    TextField(
                      controller: defaultAmountController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: '0.0',
                        suffixText: 'ALGO',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 15),

            // Version Info
            Card(
              child: Padding(
                padding: EdgeInsets.all(15),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      Translations.get('version', lang),
                      style: TextStyle(fontSize: 16),
                    ),
                    Text(
                      '1.0.0',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 30),

            // Save Button
            ElevatedButton(
              onPressed: saveSettings,
              child: Text(
                Translations.get('save', lang),
                style: TextStyle(fontSize: 18),
              ),
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 50),
                backgroundColor: Colors.green,
              ),
            ),
          ],
        ),
      ),
    );
  }
}