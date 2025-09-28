// Network configuration for Algorand
class NetworkConfig {
  static const bool USE_TESTNET = true; // Set to false for mainnet
  
  // Chain IDs - Alternative formats
  static const String MAINNET_CHAIN_ID = 'algorand:wGHE2Pwdvd7S12BL5FaOP20EGYesN73k';
  static const String TESTNET_CHAIN_ID = 'algorand:testnet-v1.0'; // Simplified format
  
  // Genesis IDs
  static const String MAINNET_GENESIS_ID = 'mainnet-v1.0';
  static const String TESTNET_GENESIS_ID = 'testnet-v1.0';
  
  // Genesis Hashes
  static const String MAINNET_GENESIS_HASH = 'wGHE2Pwdvd7S12BL5FaOP20EGYesN73k';
  static const String TESTNET_GENESIS_HASH = 'SGO1GKSzyE7IEPItTxCByw9x8FmnrCDexi9/cOUJOiI=';
  
  // Current network settings
  static String get currentChainId => USE_TESTNET ? TESTNET_CHAIN_ID : MAINNET_CHAIN_ID;
  static String get genesisId => USE_TESTNET ? TESTNET_GENESIS_ID : MAINNET_GENESIS_ID;
  static String get genesisHash => USE_TESTNET ? TESTNET_GENESIS_HASH : MAINNET_GENESIS_HASH;
  static String get networkName => USE_TESTNET ? 'Testnet' : 'Mainnet';
  
  // Testnet faucet URL
  static const String TESTNET_FAUCET_URL = 'https://bank.testnet.algorand.network';
}