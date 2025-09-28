import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/theme_provider.dart';
import '../utils/translations.dart';
import '../utils/network_config.dart';
import 'settings_screen.dart';
import 'qr_scanner_screen.dart';
import 'wallet_screen.dart';
import 'qr_display_screen.dart';

class PaymentScreen extends StatefulWidget {
  @override
  _PaymentScreenState createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  // Test address for easy testing
  static const String TEST_ADDRESS = '6QG2OFG26NAWHM26LBKR3XO3TIO3V2MFP55MHRC5Q5UKF7BXOYCJ6P7IMM';
  
  final addressController = TextEditingController();
  final amountController = TextEditingController();
  final noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Set default amount if exists
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = context.read<ThemeProvider>();
      if (provider.defaultAmount.isNotEmpty) {
        amountController.text = provider.defaultAmount;
      }
      
      // Load saved address or use test address for TestNet
      final prefs = await SharedPreferences.getInstance();
      final savedAddress = prefs.getString('saved_wallet_address');
      if (savedAddress != null && savedAddress.isNotEmpty) {
        addressController.text = savedAddress;
      } else if (NetworkConfig.USE_TESTNET) {
        // Pre-fill test address for easy testing
        addressController.text = TEST_ADDRESS;
      }
    });
  }

  Future<void> openTestnetFaucet() async {
    final url = Uri.parse(NetworkConfig.TESTNET_FAUCET_URL);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  void generateLink() {
    final provider = context.read<ThemeProvider>();
    final lang = provider.language;
    
    if (addressController.text.isEmpty || amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(Translations.get('fill_all_fields', lang)),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    double amount;
    try {
      amount = double.parse(amountController.text);
      if (amount <= 0) {
        throw FormatException('Amount must be positive');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(Translations.get('invalid_amount', lang)),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Convert to microAlgos
    final microAlgos = (amount * 1000000).toInt();
    
    // Create Algorand URI
    final algorandUri = 'algorand://${addressController.text}?amount=$microAlgos${noteController.text.isNotEmpty ? '&note=${Uri.encodeComponent(noteController.text)}' : ''}';
    
    // Navigate to QR Display Screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QRDisplayScreen(
          qrData: algorandUri,
          address: addressController.text,
          amount: amountController.text,
          note: noteController.text.isNotEmpty ? noteController.text : null,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final lang = themeProvider.language;

    return Scaffold(
      appBar: AppBar(
        title: Text(Translations.get('app_title', lang)),
        actions: [
          // TestNet indicator
          if (NetworkConfig.USE_TESTNET)
            Container(
              margin: EdgeInsets.only(right: 8),
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'TESTNET',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
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
            icon: Icon(Icons.account_balance_wallet),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => WalletScreen()),
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
            // TestNet Faucet Card (only on TestNet)
            if (NetworkConfig.USE_TESTNET) ...[
              Card(
                color: Colors.blue[50],
                child: ListTile(
                  leading: Icon(Icons.water_drop, color: Colors.blue, size: 30),
                  title: Text(
                    'Get Test ALGO',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text('Get free TestNet ALGO for testing'),
                  trailing: Icon(Icons.open_in_new),
                  onTap: openTestnetFaucet,
                ),
              ),
              SizedBox(height: 10),
              // Test Address Info
              Card(
                color: Colors.green[50],
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.green),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Test address pre-filled for easy testing',
                          style: TextStyle(fontSize: 12, color: Colors.green[800]),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20),
            ],

            // Address Input
            TextField(
              controller: addressController,
              decoration: InputDecoration(
                labelText: Translations.get('wallet_address', lang),
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.account_balance_wallet),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.paste),
                      onPressed: () async {
                        final data = await Clipboard.getData('text/plain');
                        if (data != null) {
                          addressController.text = data.text ?? '';
                        }
                      },
                      tooltip: 'Paste',
                    ),
                    if (NetworkConfig.USE_TESTNET)
                      IconButton(
                        icon: Icon(Icons.refresh, color: Colors.orange),
                        onPressed: () {
                          addressController.text = TEST_ADDRESS;
                        },
                        tooltip: 'Use Test Address',
                      ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),

            // Amount Input
            TextField(
              controller: amountController,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: Translations.get('amount_algo', lang),
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.attach_money),
                hintText: '0.5',
              ),
            ),
            SizedBox(height: 20),

            // Note Input
            TextField(
              controller: noteController,
              decoration: InputDecoration(
                labelText: Translations.get('note_optional', lang),
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.note),
                hintText: Translations.get('note_hint', lang),
              ),
            ),
            SizedBox(height: 30),

            // Generate Button
            Container(
              width: double.infinity,
              height: 55,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green, Colors.green.shade700],
                ),
                borderRadius: BorderRadius.circular(30),
              ),
              child: ElevatedButton.icon(
                onPressed: generateLink,
                icon: Icon(Icons.qr_code, color: Colors.white, size: 28),
                label: Text(
                  Translations.get('generate_qr', lang),
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                ),
              ),
            ),

            // Quick Fill Buttons (for testing)
            if (NetworkConfig.USE_TESTNET) ...[
              SizedBox(height: 20),
              Text('Quick Test:', style: TextStyle(fontSize: 12, color: Colors.grey)),
              SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      amountController.text = '0.1';
                      noteController.text = 'Test Payment';
                    },
                    child: Text('0.1 ALGO'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[300],
                      foregroundColor: Colors.black,
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      amountController.text = '1';
                      noteController.text = 'Test Payment';
                    },
                    child: Text('1 ALGO'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[300],
                      foregroundColor: Colors.black,
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      amountController.text = '5';
                      noteController.text = 'Test Payment';
                    },
                    child: Text('5 ALGO'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[300],
                      foregroundColor: Colors.black,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}