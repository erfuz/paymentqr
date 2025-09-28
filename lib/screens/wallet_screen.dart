import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/real_wallet_service.dart';
import '../providers/theme_provider.dart';
import '../utils/translations.dart';
import '../utils/network_config.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class WalletScreen extends StatefulWidget {
  @override
  _WalletScreenState createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final TextEditingController toAddressController = TextEditingController();
  final TextEditingController amountController = TextEditingController();
  final TextEditingController noteController = TextEditingController();
  bool isSending = false;

  @override
  void initState() {
    super.initState();
    // Initialize WalletConnect when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RealWalletService>().initialize().catchError((e) {
        print('Failed to initialize WalletConnect: $e');
      });
    });
  }

  Future<void> sendPayment() async {
    if (toAddressController.text.isEmpty || amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Address and amount required!')),
      );
      return;
    }

    setState(() {
      isSending = true;
    });

    try {
      final walletService = context.read<RealWalletService>();
      final result = await walletService.sendTransaction(
        context: context,
        toAddress: toAddressController.text,
        amount: double.parse(amountController.text),
        note: noteController.text.isEmpty ? null : noteController.text,
      );

      if (result != null && result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Transaction sent! ID: ${result['txId']}'),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: 'Copy',
              onPressed: () {
                Clipboard.setData(ClipboardData(text: result['txId']));
              },
            ),
          ),
        );

        // Clear form after successful transaction
        toAddressController.clear();
        amountController.clear();
        noteController.clear();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Transaction failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        isSending = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final walletService = context.watch<RealWalletService>();
    final themeProvider = context.watch<ThemeProvider>();
    final lang = themeProvider.language;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text('💳 Wallet'),
            SizedBox(width: 10),
            if (NetworkConfig.USE_TESTNET)
              Container(
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
          ],
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            // Connection Status Card
            Card(
              color: walletService.isConnected ? Colors.green[50] : Colors.orange[50],
              child: Padding(
                padding: EdgeInsets.all(15),
                child: Column(
                  children: [
                    Icon(
                      walletService.isConnected ? Icons.check_circle : Icons.account_balance_wallet,
                      size: 50,
                      color: walletService.isConnected ? Colors.green : Colors.orange,
                    ),
                    SizedBox(height: 10),
                    Text(
                      walletService.isConnected ? 'Wallet Connected' : 'No Wallet Connected',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: walletService.isConnected ? Colors.green[800] : Colors.orange[800],
                      ),
                    ),
                    if (walletService.isConnected) ...[
                      SizedBox(height: 10),
                      Text(
                        'Address: ${walletService.connectedAddress?.substring(0, 10)}...${walletService.connectedAddress?.substring(walletService.connectedAddress!.length - 10)}',
                        style: TextStyle(fontSize: 12),
                      ),
                      if (walletService.balance > 0) ...[
                        SizedBox(height: 5),
                        Text(
                          'Balance: ${walletService.balance.toStringAsFixed(2)} ALGO',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                    SizedBox(height: 15),
                    ElevatedButton.icon(
                      icon: Icon(
                        walletService.isConnected 
                          ? Icons.logout 
                          : walletService.isConnecting ? Icons.hourglass_empty : Icons.link,
                      ),
                      label: Text(
                        walletService.isConnected 
                          ? 'Disconnect' 
                          : walletService.isConnecting ? 'Connecting...' : 'Connect Pera Wallet',
                        style: TextStyle(fontSize: 16),
                      ),
                      onPressed: walletService.isConnecting ? null : () async {
                        if (walletService.isConnected) {
                          await walletService.disconnect();
                        } else {
                          try {
                            await walletService.connectWallet(context);
                          } catch (e) {
                            // Error handling is done in the service
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: walletService.isConnected ? Colors.red : Colors.green,
                        minimumSize: Size(double.infinity, 45),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Send Payment Section
            if (walletService.isConnected) ...[
              SizedBox(height: 30),
              Card(
                child: Padding(
                  padding: EdgeInsets.all(15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '📤 Send Payment',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 20),
                      TextField(
                        controller: toAddressController,
                        decoration: InputDecoration(
                          labelText: 'Recipient Address',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person),
                        ),
                      ),
                      SizedBox(height: 15),
                      TextField(
                        controller: amountController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Amount (ALGO)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.money),
                        ),
                      ),
                      SizedBox(height: 15),
                      TextField(
                        controller: noteController,
                        decoration: InputDecoration(
                          labelText: 'Note (optional)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.note),
                        ),
                      ),
                      SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: isSending ? null : sendPayment,
                        child: isSending
                          ? CircularProgressIndicator(color: Colors.white)
                          : Text('SEND PAYMENT', style: TextStyle(fontSize: 16)),
                        style: ElevatedButton.styleFrom(
                          minimumSize: Size(double.infinity, 50),
                          backgroundColor: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            // Instructions when not connected
            if (!walletService.isConnected) ...[
              SizedBox(height: 30),
              
              // Get Test ALGO button for Testnet
              if (NetworkConfig.USE_TESTNET) ...[
                Card(
                  color: Colors.green[50],
                  child: ListTile(
                    leading: Icon(Icons.savings, color: Colors.green, size: 30),
                    title: Text(
                      'Get Free Test ALGO',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text('Get testnet tokens for testing'),
                    trailing: Icon(Icons.open_in_new),
                    onTap: () async {
                      final url = Uri.parse(NetworkConfig.TESTNET_FAUCET_URL);
                      if (await canLaunchUrl(url)) {
                        await launchUrl(url, mode: LaunchMode.externalApplication);
                      }
                    },
                  ),
                ),
                SizedBox(height: 20),
              ],
              
              Card(
                color: Colors.blue[50],
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Icon(Icons.info_outline, size: 40, color: Colors.blue),
                      SizedBox(height: 15),
                      Text(
                        'How to Connect:',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[800],
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        '1. Click "Connect Pera Wallet"\n'
                        '2. Scan the QR code with Pera Wallet\n'
                        '3. Or click "Open Pera Wallet" button\n'
                        '4. Approve the connection in Pera\n'
                        '5. Start sending payments!',
                        style: TextStyle(fontSize: 14),
                        textAlign: TextAlign.left,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    toAddressController.dispose();
    amountController.dispose();
    noteController.dispose();
    super.dispose();
  }
}