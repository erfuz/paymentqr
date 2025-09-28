import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../utils/translations.dart';
import 'settings_screen.dart';
import 'qr_scanner_screen.dart';
import 'wallet_screen.dart';
import 'qr_display_screen.dart';

class PaymentScreen extends StatefulWidget {
  @override
  _PaymentScreenState createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final addressController = TextEditingController();
  final amountController = TextEditingController();
  final noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Set default amount if exists
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<ThemeProvider>();
      if (provider.defaultAmount.isNotEmpty) {
        amountController.text = provider.defaultAmount;
      }
    });
  }

  void generateLink() {
    final provider = context.read<ThemeProvider>();
    final lang = provider.language;
    
    if (addressController.text.isEmpty || amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(Translations.get('address_required', lang))),
      );
      return;
    }
    
    final amount = double.parse(amountController.text) * 1000000;
    final qrData = 'algorand://${addressController.text}'
                   '?amount=${amount.toInt()}'
                   '&note=${noteController.text}';
    
    // Navigate to full screen QR display
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QRDisplayScreen(
          qrData: qrData,
          address: addressController.text,
          amount: amountController.text,
          note: noteController.text.isNotEmpty ? noteController.text : null,
        ),
      ),
    );

    // Auto copy if enabled
    if (provider.autoCopy) {
      Clipboard.setData(ClipboardData(text: qrData));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(Translations.get('link_copied', lang))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ThemeProvider>();
    final lang = provider.language;

    return Scaffold(
      appBar: AppBar(
        title: Text('⚡ ${Translations.get('app_title', lang)}'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.qr_code_scanner),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => QRScannerScreen()),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            // Wallet Connection Button
            Card(
              color: Colors.blue[50],
              child: ListTile(
                leading: Icon(Icons.account_balance_wallet, color: Colors.blue),
                title: Text('Connect Wallet'),
                subtitle: Text('Send payments with Pera Wallet'),
                trailing: Icon(Icons.arrow_forward_ios),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => WalletScreen()),
                  );
                },
              ),
            ),
            SizedBox(height: 20),
            TextField(
              controller: addressController,
              decoration: InputDecoration(
                labelText: Translations.get('wallet_address', lang),
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.account_balance_wallet),
              ),
            ),
            SizedBox(height: 15),
            
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: Translations.get('amount', lang),
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.money),
              ),
            ),
            SizedBox(height: 15),
            
            TextField(
              controller: noteController,
              decoration: InputDecoration(
                labelText: Translations.get('note', lang),
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.note),
              ),
            ),
            SizedBox(height: 20),
            
            ElevatedButton(
              onPressed: generateLink,
              child: Text(
                Translations.get('generate', lang),
                style: TextStyle(fontSize: 16),
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