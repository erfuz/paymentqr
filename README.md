# Payment QR - Algorand Payment System

## 📱 About
Payment QR is a mobile application that simplifies receiving Algorand blockchain payments through QR codes. Users can quickly and securely transfer ALGO by simply creating or scanning QR codes.

## 🎯 Purpose
Making Algorand payments accessible to everyone. Instead of dealing with complex wallet addresses, receive or send payments in seconds using QR codes.

## ✨ Features
- **QR Code Generation**: Create payment QR codes with wallet address, amount, and optional notes
- **QR Code Scanner**: Scan QR codes to auto-fill payment information
- **Deep Link Integration**: Direct connection with Pera Wallet
- **TestNet Support**: Safe testing with free test tokens
- **Multi-language**: Turkish and English language support
- **Theme Selection**: Dark/Light mode

## 🛠️ Tech Stack
- **Flutter**: Cross-platform mobile development
- **Dart**: Programming language
- **Algorand Blockchain**: Payment infrastructure
- **Pera Wallet**: Wallet integration
- **Provider**: State management
- **QR Flutter**: QR code generation

## 📲 How to Use
1. Open the app
2. Enter wallet address (pre-filled for TestNet)
3. Set payment amount
4. Generate QR code
5. Recipient scans with Pera Wallet and confirms payment

## 🚀 Installation
```bash
git clone https://github.com/erfuz/paymentqr.git
cd payment_qr
flutter pub get
flutter run
```

## 🧪 Testing on TestNet
1. Switch Pera Wallet to TestNet (Settings → Developer → Node → TestNet)
2. Get test ALGO from [Algorand TestNet Faucet](https://bank.testnet.algorand.network/)
3. Make test payments in the app

## 📋 Requirements
- Flutter SDK (>=3.0.0)
- Dart SDK (>=3.0.0)
- Android Studio / VS Code
- Android/iOS device or emulator

## 🤝 Use Cases
- **Merchants**: Accept ALGO payments in stores
- **Peer-to-Peer**: Send money to friends
- **Events**: Quick payment collection
- **Services**: Invoice payments via QR

## 📄 License
MIT License

## 👥 Contributors
Developed for Algorand Hackathon 2025