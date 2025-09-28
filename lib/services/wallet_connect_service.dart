import 'package:flutter/material.dart';
import 'package:walletconnect_flutter_v2/walletconnect_flutter_v2.dart';
import 'package:url_launcher/url_launcher.dart';

class WalletConnectService extends ChangeNotifier {
  static const String projectId = 'YOUR_PROJECT_ID'; // WalletConnect Cloud'dan alınacak
  static const String appName = 'Payment QR';
  static const String appDescription = 'Algorand Payment QR Generator';
  static const String appUrl = 'https://paymentqr.app';
  static const String appIcon = 'https://paymentqr.app/icon.png';

  Web3App? _wcClient;
  SessionData? _session;
  String? _connectedAddress;
  double? _balance;
  
  Web3App? get wcClient => _wcClient;
  SessionData? get session => _session;
  String? get connectedAddress => _connectedAddress;
  double? get balance => _balance;
  bool get isConnected => _session != null && _connectedAddress != null;

  // Initialize WalletConnect
  Future<void> initialize() async {
    _wcClient = await Web3App.createInstance(
      projectId: projectId,
      metadata: const PairingMetadata(
        name: appName,
        description: appDescription,
        url: appUrl,
        icons: [appIcon],
      ),
    );

    // Check for existing sessions
    final sessions = _wcClient!.sessions.getAll();
    if (sessions.isNotEmpty) {
      _session = sessions.first;
      _connectedAddress = _session!.namespaces['algorand']?.accounts.first.split(':').last;
      notifyListeners();
    }

    // Listen for session events
    _wcClient!.onSessionConnect.subscribe(_onSessionConnect);
    _wcClient!.onSessionUpdate.subscribe(_onSessionUpdate);
    _wcClient!.onSessionDelete.subscribe(_onSessionDelete);
  }

  // Connect to Pera Wallet
  Future<void> connect(BuildContext context) async {
    if (_wcClient == null) await initialize();

    try {
      // Create connection
      final ConnectResponse resp = await _wcClient!.connect(
        requiredNamespaces: {
          'algorand': RequiredNamespace(
            chains: ['algorand:mainnet'], // or 'algorand:testnet'
            methods: [
              'algo_signTxn',
              'algo_sendTransaction',
            ],
            events: [],
          ),
        },
      );

      final Uri? uri = resp.uri;
      if (uri != null) {
        // Show QR code dialog
        await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Connect Pera Wallet'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 250,
                    height: 250,
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        'QR Code Here\n\n${uri.toString()}',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 10, color: Colors.black),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton.icon(
                    icon: Icon(Icons.wallet),
                    label: Text('Open Pera Wallet'),
                    onPressed: () async {
                      // Deep link to Pera
                      final wcUri = 'wc:${uri.toString().split('wc:').last}';
                      final peraUri = 'pera-wallet://wc?uri=${Uri.encodeComponent(wcUri)}';
                      
                      try {
                        await launchUrl(Uri.parse(peraUri));
                      } catch (e) {
                        // Try web version
                        await launchUrl(
                          Uri.parse('https://wallet.perawallet.app/wc?uri=${Uri.encodeComponent(wcUri)}'),
                          mode: LaunchMode.externalApplication,
                        );
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
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Cancel'),
                ),
              ],
            );
          },
        );

        // Wait for connection
        final session = await resp.session.future;
        _onSessionConnect(SessionConnect(session));
      }
    } catch (e) {
      print('Connection error: $e');
      throw e;
    }
  }

  // Disconnect wallet
  Future<void> disconnect() async {
    if (_session != null) {
      await _wcClient?.disconnectSession(
        topic: _session!.topic,
        reason: Errors.getSdkError(Errors.USER_DISCONNECTED),
      );
    }
    _session = null;
    _connectedAddress = null;
    _balance = null;
    notifyListeners();
  }

  // Send transaction
  Future<String?> sendTransaction({
    required String toAddress,
    required double amount,
    String? note,
  }) async {
    if (!isConnected || _session == null) {
      throw Exception('Wallet not connected');
    }

    try {
      // Create transaction object
      final transaction = {
        'from': _connectedAddress,
        'to': toAddress,
        'amount': (amount * 1000000).toInt(), // Convert to microAlgos
        'note': note ?? '',
        'type': 'pay',
      };

      // Request signature from Pera
      final result = await _wcClient!.request(
        topic: _session!.topic,
        chainId: 'algorand:mainnet',
        request: SessionRequestParams(
          method: 'algo_sendTransaction',
          params: [transaction],
        ),
      );

      return result as String?; // Transaction ID
    } catch (e) {
      print('Transaction error: $e');
      throw e;
    }
  }

  // Get account balance (simplified - needs Algorand SDK for real implementation)
  Future<void> fetchBalance() async {
    if (!isConnected) return;
    
    // This would need actual Algorand API call
    // For now, just mock it
    _balance = 100.0; // Mock balance
    notifyListeners();
  }

  // Event handlers
  void _onSessionConnect(SessionConnect? args) {
    if (args != null) {
      _session = args.session;
      _connectedAddress = args.session.namespaces['algorand']?.accounts.first.split(':').last;
      print('Connected to: $_connectedAddress');
      notifyListeners();
      fetchBalance();
    }
  }

  void _onSessionUpdate(SessionUpdate? args) {
    if (args != null) {
      // SessionUpdate doesn't have session property in new version
      // Just notify listeners for any updates
      notifyListeners();
    }
  }

  void _onSessionDelete(SessionDelete? args) {
    _session = null;
    _connectedAddress = null;
    _balance = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _wcClient?.onSessionConnect.unsubscribeAll();
    _wcClient?.onSessionUpdate.unsubscribeAll();
    _wcClient?.onSessionDelete.unsubscribeAll();
    super.dispose();
  }
}