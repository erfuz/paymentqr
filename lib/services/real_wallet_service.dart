import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:walletconnect_flutter_v2/walletconnect_flutter_v2.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../utils/network_config.dart';

class RealWalletService extends ChangeNotifier {
  // WalletConnect Cloud Project ID
  static const String projectId = '8fc205a65be5876a4eea53f1d5e19991'; 
  
  Web3App? _wcClient;
  SessionData? _currentSession;
  String? _connectedAddress;
  double _balance = 0.0;
  bool _isInitialized = false;
  bool _isConnecting = false;
  
  // Getters
  bool get isInitialized => _isInitialized;
  bool get isConnecting => _isConnecting;
  bool get isConnected => _currentSession != null && _connectedAddress != null;
  String? get connectedAddress => _connectedAddress;
  double get balance => _balance;
  SessionData? get session => _currentSession;

  // Initialize WalletConnect
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      _wcClient = await Web3App.createInstance(
        projectId: projectId,
        metadata: const PairingMetadata(
          name: 'Payment QR',
          description: 'Algorand Payment QR Generator',
          url: 'https://paymentqr.app',
          icons: ['https://walletconnect.org/walletconnect-logo.png'],
        ),
      );

      // Check existing sessions
      if (_wcClient!.sessions.getAll().isNotEmpty) {
        _currentSession = _wcClient!.sessions.getAll().first;
        await _onSessionConnected(_currentSession!);
      }

      // Register event handlers
      _wcClient!.onSessionConnect.subscribe(_handleSessionConnect);
      _wcClient!.onSessionDelete.subscribe(_handleSessionDelete);
      _wcClient!.onSessionEvent.subscribe(_handleSessionEvent);
      _wcClient!.onSessionExpire.subscribe(_handleSessionExpire);

      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      print('WalletConnect init error: $e');
      throw e;
    }
  }

  // Connect to Pera Wallet
  Future<void> connectWallet(BuildContext context) async {
    if (!_isInitialized) await initialize();
    if (_isConnecting) return;
    
    _isConnecting = true;
    notifyListeners();
    
    try {
      // Create connection request
      final ConnectResponse connectResponse = await _wcClient!.connect(
        requiredNamespaces: {
          'algorand': RequiredNamespace(
            chains: [NetworkConfig.currentChainId],
            methods: ['algo_signTxn'],
            events: [],
          ),
        },
      );

      final uri = connectResponse.uri;
      if (uri == null) throw Exception('Failed to create connection URI');
      
      print('WalletConnect URI: ${uri.toString()}');
      print('Using chain: ${NetworkConfig.currentChainId}');

      // Show QR Code Dialog
      final confirmed = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                Icon(Icons.wallet, color: Colors.green),
                SizedBox(width: 10),
                Text('Connect Pera Wallet (${NetworkConfig.networkName})'),
              ],
            ),
            content: Container(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                // QR Code
                Container(
                  padding: EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.grey.shade300, width: 2),
                  ),
                  child: QrImageView(
                    data: uri.toString(),
                    size: 250,
                    backgroundColor: Colors.white,
                  ),
                ),
                SizedBox(height: 20),
                
                // Deep Link Button
                ElevatedButton.icon(
                  onPressed: () async {
                    final wcUri = Uri.encodeComponent(uri.toString());
                    final peraUri = 'pera://wc?uri=$wcUri';
                    
                    try {
                      if (await canLaunchUrl(Uri.parse(peraUri))) {
                        await launchUrl(
                          Uri.parse(peraUri),
                          mode: LaunchMode.externalApplication,
                        );
                      }
                    } catch (e) {
                      print('Failed to open Pera: $e');
                    }
                  },
                  icon: Icon(Icons.open_in_new),
                  label: Text('Open Pera Wallet'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    minimumSize: Size(double.infinity, 45),
                  ),
                ),
                SizedBox(height: 10),
                
                Text(
                  'Scan with Pera Wallet or click the button above',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(false);
                },
                child: Text('Cancel'),
              ),
            ],
          );
        },
      );

      if (confirmed == false) {
        _isConnecting = false;
        notifyListeners();
        return;
      }

      // Wait for session approval with longer timeout
      final session = await connectResponse.session.future.timeout(
        Duration(minutes: 10), // Increased timeout
        onTimeout: () => throw TimeoutException('Connection timeout - Please try again'),
      );

      await _onSessionConnected(session);
      
    } catch (e) {
      print('Connection error: $e');
      _isConnecting = false;
      notifyListeners();
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Connection failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Handle successful connection
  Future<void> _onSessionConnected(SessionData session) async {
    _currentSession = session;
    
    // Extract address from session
    final accounts = session.namespaces['algorand']?.accounts ?? [];
    if (accounts.isNotEmpty) {
      // Format: algorand:CHAIN_ID:ADDRESS
      final parts = accounts.first.split(':');
      _connectedAddress = parts.last;
    }
    
    _isConnecting = false;
    notifyListeners();
    
    // Fetch balance (would need Algorand SDK for real implementation)
    await fetchBalance();
  }

  // Disconnect wallet
  Future<void> disconnect() async {
    if (_currentSession == null) return;
    
    try {
      await _wcClient?.disconnectSession(
        topic: _currentSession!.topic,
        reason: Errors.getSdkError(Errors.USER_DISCONNECTED),
      );
    } catch (e) {
      print('Disconnect error: $e');
    }
    
    _currentSession = null;
    _connectedAddress = null;
    _balance = 0.0;
    notifyListeners();
  }

  // Send transaction
  Future<Map<String, dynamic>?> sendTransaction({
    required BuildContext context,
    required String toAddress,
    required double amount,
    String? note,
  }) async {
    if (!isConnected || _currentSession == null) {
      throw Exception('Wallet not connected');
    }

    try {
      // Create Algorand transaction structure
      final transaction = {
        'txn': {
          'type': 'pay',
          'from': _connectedAddress,
          'to': toAddress,
          'amount': (amount * 1000000).toInt(),
          'fee': 1000,
          'firstRound': 1000,
          'lastRound': 2000,
          'genesisID': NetworkConfig.genesisId,
          'genesisHash': NetworkConfig.genesisHash,
        },
      };

      if (note != null && note.isNotEmpty) {
        transaction['txn']!['note'] = base64Encode(utf8.encode(note));
      }

      // Request signature
      final result = await _wcClient!.request(
        topic: _currentSession!.topic,
        chainId: NetworkConfig.currentChainId,
        request: SessionRequestParams(
          method: 'algo_signTxn',
          params: [[transaction]],
        ),
      );

      return {
        'success': true,
        'txId': result?.toString() ?? 'pending',
      };
      
    } catch (e) {
      print('Transaction error: $e');
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Transaction failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      
      return null;
    }
  }

  // Fetch balance (simplified - real implementation needs Algorand SDK)
  Future<void> fetchBalance() async {
    if (!isConnected) return;
    
    // Mock balance for demo
    // In production, use Algorand SDK to fetch real balance
    _balance = 10.5; // Mock balance
    notifyListeners();
  }

  // Event handlers
  void _handleSessionConnect(SessionConnect? event) {
    if (event != null) {
      _onSessionConnected(event.session);
    }
  }

  void _handleSessionDelete(SessionDelete? event) {
    _currentSession = null;
    _connectedAddress = null;
    _balance = 0.0;
    notifyListeners();
  }

  void _handleSessionEvent(SessionEvent? event) {
    print('Session event: ${event?.name}');
  }

  void _handleSessionExpire(SessionExpire? event) {
    _currentSession = null;
    _connectedAddress = null;
    _balance = 0.0;
    notifyListeners();
  }

  @override
  void dispose() {
    _wcClient?.onSessionConnect.unsubscribeAll();
    _wcClient?.onSessionDelete.unsubscribeAll();
    _wcClient?.onSessionEvent.unsubscribeAll();
    _wcClient?.onSessionExpire.unsubscribeAll();
    super.dispose();
  }
}

class TimeoutException implements Exception {
  final String message;
  TimeoutException(this.message);
  
  @override
  String toString() => message;
}