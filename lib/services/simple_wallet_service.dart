import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class SimpleWalletService extends ChangeNotifier {
  String? _connectedAddress;
  bool _isConnected = false;
  
  String? get connectedAddress => _connectedAddress;
  bool get isConnected => _isConnected;

  // Simulate wallet connection
  Future<void> connectWallet(BuildContext context) async {
    // For demo purposes, we'll use a simple deep link approach
    // In production, you'd use full WalletConnect implementation
    
    try {
      // Show connection dialog
      final result = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('🔗 Connect Pera Wallet'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.qr_code, size: 100, color: Colors.blue),
                SizedBox(height: 20),
                Text(
                  'To connect your wallet:\n\n'
                  '1. Open Pera Wallet\n'
                  '2. Go to Settings → WalletConnect\n'
                  '3. Scan QR or paste link\n'
                  '4. Approve connection',
                  textAlign: TextAlign.left,
                ),
                SizedBox(height: 20),
                ElevatedButton.icon(
                  icon: Icon(Icons.open_in_new),
                  label: Text('Open Pera Wallet'),
                  onPressed: () async {
                    // Try to open Pera Wallet
                    final peraUrl = 'pera-wallet://';
                    if (await canLaunchUrl(Uri.parse(peraUrl))) {
                      await launchUrl(Uri.parse(peraUrl));
                    } else {
                      // Open app store
                      final storeUrl = Theme.of(context).platform == TargetPlatform.iOS
                        ? 'https://apps.apple.com/app/pera-algo-wallet/id1459898525'
                        : 'https://play.google.com/store/apps/details?id=com.algorand.android';
                      await launchUrl(Uri.parse(storeUrl));
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text('Simulate Connected'),
              ),
            ],
          );
        },
      );

      if (result == true) {
        // Simulate successful connection
        _isConnected = true;
        _connectedAddress = 'DEMO7S5QTQJLX3ZWWOPK2BETQEM5CVMWSXRAL2ENKVLGOBX7PQ3UQDEMO';
        notifyListeners();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Wallet connected successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Connection error: $e');
    }
  }

  // Disconnect wallet
  void disconnect() {
    _isConnected = false;
    _connectedAddress = null;
    notifyListeners();
  }

  // Send transaction using deep link
  Future<void> sendTransaction({
    required BuildContext context,
    required String toAddress,
    required double amount,
    String? note,
  }) async {
    if (!_isConnected) {
      throw Exception('Wallet not connected');
    }

    try {
      // Create Algorand URI
      final amountInMicroAlgos = (amount * 1000000).toInt();
      final algorandUri = 'algorand://$toAddress?amount=$amountInMicroAlgos&note=${note ?? ''}';
      
      // Convert to Pera URI
      final peraUri = algorandUri.replaceFirst('algorand://', 'pera://');
      
      // Show confirmation dialog
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('📤 Confirm Payment'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('To: ${toAddress.substring(0, 10)}...'),
                Text('Amount: $amount ALGO'),
                if (note != null && note.isNotEmpty) Text('Note: $note'),
                SizedBox(height: 20),
                Text(
                  'This will open Pera Wallet for you to approve the transaction.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text('Continue'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                ),
              ),
            ],
          );
        },
      );

      if (confirmed == true) {
        // Try to open in Pera Wallet
        if (await canLaunchUrl(Uri.parse(peraUri))) {
          await launchUrl(Uri.parse(peraUri));
          
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Opening Pera Wallet...'),
              backgroundColor: Colors.blue,
            ),
          );
        } else if (await canLaunchUrl(Uri.parse(algorandUri))) {
          // Fallback to generic Algorand URI
          await launchUrl(Uri.parse(algorandUri));
        } else {
          throw Exception('Could not open wallet app');
        }
      }
    } catch (e) {
      print('Transaction error: $e');
      throw e;
    }
  }
}