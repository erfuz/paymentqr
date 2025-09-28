import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../utils/translations.dart';

class QRScannerScreen extends StatefulWidget {
  @override
  _QRScannerScreenState createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  MobileScannerController cameraController = MobileScannerController();
  bool isScanned = false;

  void _handleQRCode(String code) async {
    if (isScanned) return; // Prevent multiple scans
    isScanned = true;

    // Check if it's an Algorand URI
    if (code.startsWith('algorand://')) {
      // Show confirmation dialog
      showDialog(
        context: context,
        builder: (BuildContext context) {
          // Parse the URI
          Uri uri = Uri.parse(code);
          String address = uri.host;
          String? amountStr = uri.queryParameters['amount'];
          String? note = uri.queryParameters['note'];
          
          double? amount;
          if (amountStr != null) {
            amount = double.tryParse(amountStr);
            if (amount != null) {
              amount = amount / 1000000; // Convert from microAlgos to Algos
            }
          }

          return AlertDialog(
            title: Text('⚡ Payment Request'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('To: ${address.substring(0, 10)}...'),
                if (amount != null) Text('Amount: $amount ALGO'),
                if (note != null && note.isNotEmpty) Text('Note: $note'),
                SizedBox(height: 20),
                Text('Open with Pera Wallet?', 
                  style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  setState(() {
                    isScanned = false;
                  });
                },
                child: Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  // Try to open in Pera Wallet
                  final peraUri = code.replaceFirst('algorand://', 'pera://');
                  
                  try {
                    // First try Pera Wallet
                    if (await canLaunchUrl(Uri.parse(peraUri))) {
                      await launchUrl(Uri.parse(peraUri));
                    } 
                    // Then try generic Algorand URI
                    else if (await canLaunchUrl(Uri.parse(code))) {
                      await launchUrl(Uri.parse(code));
                    } 
                    else {
                      // Show error
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Pera Wallet not installed'),
                          action: SnackBarAction(
                            label: 'Install',
                            onPressed: () {
                              // Open app store
                              launchUrl(Uri.parse(
                                Theme.of(context).platform == TargetPlatform.iOS
                                  ? 'https://apps.apple.com/app/pera-algo-wallet/id1459898525'
                                  : 'https://play.google.com/store/apps/details?id=com.algorand.android'
                              ));
                            },
                          ),
                        ),
                      );
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error opening wallet: $e')),
                    );
                  }
                  
                  Navigator.of(context).pop();
                },
                child: Text('Open Pera'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                ),
              ),
            ],
          );
        },
      );
    } else {
      // Not an Algorand QR code
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Invalid QR Code: Not an Algorand payment'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        isScanned = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ThemeProvider>();
    final lang = provider.language;

    return Scaffold(
      appBar: AppBar(
        title: Text('📸 Scan QR'),
        actions: [
          IconButton(
            icon: Icon(cameraController.torchEnabled ? Icons.flash_on : Icons.flash_off),
            onPressed: () => cameraController.toggleTorch(),
          ),
          IconButton(
            icon: Icon(Icons.flip_camera_ios),
            onPressed: () => cameraController.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: cameraController,
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                if (barcode.rawValue != null) {
                  debugPrint('QR Code found: ${barcode.rawValue}');
                  _handleQRCode(barcode.rawValue!);
                  break;
                }
              }
            },
          ),
          // Scanning overlay
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.green, width: 3),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          // Instructions
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.all(20),
              color: Colors.black54,
              child: Text(
                'Point camera at Algorand QR code',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }
}