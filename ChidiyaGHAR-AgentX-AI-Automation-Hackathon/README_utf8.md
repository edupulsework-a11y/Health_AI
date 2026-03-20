# ChidiyaGHAR-AgentX-AI-Automation-Hackathon
# ChidiyaGHAR-Spectrum (Health AI)

A comprehensive **Flutter healthcare application** with advanced video consultation, AI-powered health guidance, and real-time communication features.

---

## 📱 Features

### 🎥 **Dual Video Call System**
- **Stream Video** - Enterprise-grade video calls with custom controls
- **Agora RTC** - Real-time communication with low latency
- Microphone/Camera toggle
- Front/Back camera switching
- Call statistics and monitoring
- Session timer with automatic billing

### 🏥 **Healthcare Features**
- AI-powered health assistant (Google Gemini)
- Professional consultation booking
- PDF receipt generation
- Payment processing integration
- Health data visualization with charts
- Medical record management

### 👤 **User Management**
- **Supabase Authentication** (Email, Google Sign-In)
- Role-based access (User/Professional)
- Profile management
- Permission handling (Camera, Mic, Location, Notifications)

### 📊 **Data & Analytics**
- Real-time health data tracking
- Interactive charts (FL Chart)
- Session history
- Payment records

---

## 🛠️ Tech Stack

### **Frontend**
- **Flutter** `3.11.0-200.1.beta`
- **Dart SDK** `^3.11.0-200.1.beta`
- **Google Fonts** - Custom typography
- **Material Design 3** - Modern UI components

### **State Management**
- **Flutter Riverpod** `^3.2.1` - Reactive state management

### **Backend & Database**
- **Supabase** `^2.12.0` - Backend-as-a-Service
  - PostgreSQL database
  - Real-time subscriptions
  - Row-level security
  - Authentication

### **Video Calling**
- **Stream Video Flutter** `^1.2.4` - Enterprise video SDK
- **Agora RTC Engine** `^6.5.3` - Real-time communication
- **Custom Controls** - Built from scratch to bypass SDK bugs

### **AI & ML**
- **Google Generative AI** `^0.4.7` (Gemini model)

### **Media & Files**
- **Camera** `^0.11.3` - Camera access
- **Image Picker** `^1.2.1` - Gallery/Camera selection
- **File Picker** `^10.3.10` - Document selection
- **PDF** `^3.11.3` - PDF generation
- **Printing** `^5.14.2` - Print/Share PDFs

### **Authentication**
- **Google Sign-In** `^6.1.5`
- Supabase Auth (Email/Password)

### **Utilities**
- **Permission Handler** `^12.0.1` - Runtime permissions
- **Path Provider** `^2.1.5` - File system paths
- **Crypto** `^3.0.7` - Encryption
- **Intl** `^0.20.2` - Internationalization
- **HTTP** `^1.6.0` - API calls
- **Open File** `^3.3.2` - File viewing

### **Data Visualization**
- **FL Chart** `^1.1.1` - Interactive charts

### **Blockchain**
- **web3dart** `^3.0.2` - Web3 integration (optional)

---

## 🚀 Setup Instructions

### Prerequisites
```bash
# Install Flutter SDK 3.11+
# Install Android Studio / Xcode
# Install Git
```

### 1. Clone Repository
```bash
git clone https://github.com/RudrakshRakeshZodage/Nutreva.git
cd ChidiyaGHAR-Spectrum
```

### 2. Install Dependencies
```bash
flutter pub get
```

### 3. Configure API Keys

Create/Update `lib/core/api_keys.dart`:
```dart
class ApiKeys {
  // Supabase Configuration
  static const String supabaseUrl = "YOUR_SUPABASE_PROJECT_URL";
  static const String supabaseAnonKey = "YOUR_SUPABASE_ANON_KEY";
  
  // Agora RTC
  static const String agoraAppId = "YOUR_AGORA_APP_ID";
  static const String agoraSecret = "YOUR_AGORA_SECRET";
  static const String agoraTempToken = "YOUR_AGORA_TOKEN"; // For testing
  
  // Stream Video
  static const String streamApiKey = "YOUR_STREAM_API_KEY";
  static const String streamApiSecret = "YOUR_STREAM_SECRET";
  
  // AI Services
  static const String geminiKey = "YOUR_GEMINI_API_KEY";
  static const String grokKey = "YOUR_GROK_API_KEY";     // Optional: For Grok AI
  static const String openAiKey = "YOUR_OPENAI_KEY";     // Optional
  
  // Image Upload
  static const String imgBBKey = "YOUR_IMGBB_KEY";
}
```

#### 🔑 How to Get API Keys:

**Supabase** (Required):
1. Go to [supabase.com](https://supabase.com)
2. Create a new project
3. Navigate to **Settings** → **API**
4. Copy:
   - **Project URL** → `supabaseUrl`
   - **anon/public** key → `supabaseAnonKey`

**Agora** (Required for video calls):
1. Go to [console.agora.io](https://console.agora.io)
2. Create a project
3. Copy **App ID** → `agoraAppId`
4. Enable **App Certificate** in settings
5. Copy **Primary Certificate** → `agoraSecret`
6. Generate temp token for testing → `agoraTempToken`

**Stream Video** (Required for video calls):
1. Go to [getstream.io](https://getstream.io)
2. Create a video app
3. Copy **API Key** → `streamApiKey`
4. Copy **API Secret** → `streamApiSecret`

**Google Gemini** (Required for AI):
1. Go to [makersuite.google.com](https://makersuite.google.com/app/apikey)
2. Create API key → `geminiKey`

**Grok AI** (Optional):
1. Go to [x.ai](https://x.ai) or Grok API platform
2. Generate API key → `grokKey`

**ImgBB** (Optional - for image hosting):
1. Go to [imgbb.com](https://imgbb.com)
2. Sign up and get API key → `imgBBKey`


```bash
# Android
flutter run

# iOS
flutter run -d ios

# Web
flutter run -d chrome
```

---

## 📂 Project Structure

```
lib/
├── core/
│   ├── api_keys.dart           # API configuration
│   └── constants.dart          # App constants
├── features/
│   ├── professional/
│   │   ├── screens/
│   │   │   ├── demo_call_screen.dart      # Stream Video UI
│   │   │   └── agora_call_screen.dart     # Agora Video UI
│   │   └── widgets/
│   │       └── unified_consultation_modal.dart
│   └── user/
├── services/
│   ├── stream_service.dart     # Stream Video logic
│   ├── payment_service.dart    # Payment processing
│   ├── pdf_service.dart        # PDF generation
│   └── health_service.dart     # Health data
└── main.dart
```

---

## 🔐 Permissions Required

### Android (`AndroidManifest.xml`)
- Camera
- Microphone
- Internet
- Bluetooth (for audio routing)
- Storage (for PDFs)

### iOS (`Info.plist`)
- Camera Usage Description
- Microphone Usage Description
- Photo Library Usage
- Bluetooth Peripheral Usage

---

## ❓ Top 10 Technical Questions & Answers

### 1. **Q: Why are there two video calling systems (Stream & Agora)?**
**A:** We implemented both for flexibility and redundancy:
- **Stream Video**: Better for group calls, enterprise features, built-in UI
- **Agora**: Lower latency, better for 1-on-1 calls, more control
- Users can choose based on their needs and network conditions

---

### 2. **Q: How did you fix the Stream Video `BoxConstraints` crash?**

**A:** The Stream Video Flutter SDK v1.2.4 has a critical bug where `CallControlOption` widgets receive **infinite width constraints**, causing crashes. Here's the complete fix:

#### **The Problem:**
```
Error: BoxConstraints forces an infinite width (w=Infinity, 52.0<=h<=56.0)
Location: stream_video_flutter-1.2.4/lib/src/call_controls/call_control_option.dart:59:12
Result: RenderBox was not laid out → App Crash
```

#### **❌ BEFORE (Crashing Code):**
```dart
// demo_call_screen.dart - OLD IMPLEMENTATION
return Scaffold(
  body: Theme(
    data: theme.copyWith(
      extensions: [stream.StreamVideoTheme.dark()],  // ❌ Theme wrapper
    ),
    child: Stack(
      children: [
        stream.StreamCallContainer(                   // ❌ Buggy container
          call: _call,
          callContentWidgetBuilder: (context, call) {
            return stream.StreamCallContent(          // ❌ Buggy content
              callControlsWidgetBuilder: (context, call) {
                return stream.StreamCallControls(     // ❌ Buggy controls
                  options: [
                    stream.CallControlOption(         // ❌ CRASH HERE!
                      icon: Icon(Icons.info),         // Receives w=Infinity
                      onPressed: () => showStats(),
                    ),
                    stream.ToggleMicrophoneOption(...),
                    stream.ToggleCameraOption(...),
                  ],
                );
              },
            );
          },
        ),
      ],
    ),
  ),
);
```

#### **✅ AFTER (Working Code):**
```dart
// demo_call_screen.dart - FIXED IMPLEMENTATION
return Scaffold(
  backgroundColor: Colors.black,
  body: Stack(                                        // ✅ Simple Stack
    fit: StackFit.expand,
    children: [
      // Video rendering only (using SDK)
      Positioned.fill(
        child: stream.StreamCallParticipants(         // ✅ Direct video widget
          call: _call,
        ),
      ),
      
      // Custom control bar (bypassing buggy SDK widgets)
      Positioned(
        left: 0, right: 0, bottom: 40,
        child: _buildCustomControls(),                // ✅ Our custom UI
      ),
    ],
  ),
);

// Custom control builder with FIXED dimensions
Widget _buildCustomControls() {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildControlButton(
          icon: _isMicEnabled ? Icons.mic : Icons.mic_off,
          label: 'Mic',
          onPressed: _toggleMicrophone,
        ),
        _buildControlButton(
          icon: _isCameraEnabled ? Icons.videocam : Icons.videocam_off,
          label: 'Camera',
          onPressed: _toggleCamera,
        ),
        // ... more buttons
      ],
    ),
  );
}

// Individual button with FIXED width/height (no infinite constraints!)
Widget _buildControlButton({...}) {
  return Column(
    children: [
      Container(
        width: 60,   // ✅ FIXED width (solves the crash)
        height: 60,  // ✅ FIXED height
        decoration: BoxDecoration(
          color: buttonColor.withOpacity(0.9),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 28),
      ),
      Text(label),
    ],
  );
}

// Manual state management
bool _isCameraEnabled = true;
bool _isMicEnabled = true;

Future<void> _toggleMicrophone() async {
  await _call.setMicrophoneEnabled(enabled: !_isMicEnabled);
  setState(() => _isMicEnabled = !_isMicEnabled);
}
```

#### **📊 Key Differences:**

| Component | Before (Crashed) | After (Fixed) |
|-----------|------------------|---------------|
| **UI Framework** | SDK widgets (`StreamCallContainer`, `StreamCallContent`) | Custom Flutter widgets |
| **Control Buttons** | `CallControlOption` (buggy) | Custom `_buildControlButton` |
| **Width Constraints** | Infinite (`w=Infinity`) ❌ | Fixed (`60px`) ✅ |
| **Video Rendering** | `StreamCallContent` | `StreamCallParticipants` |
| **State Management** | SDK internal | Manual with `setState` |
| **Theme Wrapper** | `StreamVideoTheme.dark()` | Not needed |
| **Lines of Code** | ~60 lines | ~150 lines (but stable) |
| **Result** | **Crashes** ❌ | **Works perfectly** ✅ |

#### **Why This Works:**
1. **Bypassed buggy SDK UI** - Only use SDK for video rendering and core functions
2. **Fixed dimensions** - All buttons have explicit width/height (60x60)
3. **Manual control** - Direct calls to `_call.setMicrophoneEnabled()`, etc.
4. **Simpler stack** - No complex widget nesting that causes constraint issues

**Code Location:** `lib/features/professional/screens/demo_call_screen.dart`



---

### 3. **Q: How does Agora token authentication work?**
**A:** Agora uses temporary tokens for security:
1. Generate token on [Agora Console](https://console.agora.io) for specific channel
2. Token includes: App ID, Channel Name, UID, expiration time
3. Token must match exactly with the channel name in the app
4. Update `agoraTempToken` in `api_keys.dart`

**Note:** For production, implement server-side token generation with automatic refresh.

---

### 4. **Q: Why use Supabase instead of Firebase?**
**A:** Supabase offers:
- Open-source alternative to Firebase
- PostgreSQL (vs Firebase's NoSQL) - better for relational health data
- Row-level security for HIPAA compliance
- Better pricing at scale
- Real-time subscriptions
- Built-in authentication with multiple providers

---

### 5. **Q: How is the session timer implemented?**
**A:** Using a `Timer` that:
```dart
Timer.periodic(const Duration(seconds: 1), (timer) {
  setState(() => _secondsRemaining--);
  if (_secondsRemaining <= 0) {
    _endCall(); // Auto-end and charge
  }
});
```
- Starts on call join
- Decrements every second
- Auto-ends at 0
- Triggers payment processing
- Generates PDF receipt

---

### 6. **Q: How do you handle permissions across platforms?**
**A:** Using `permission_handler` package:
```dart
await StreamService.requestPermissions();
```
This requests:
- Camera (video calls)
- Microphone (audio)
- Bluetooth (audio routing)
- Notifications (call alerts)

Platform-specific configurations in `AndroidManifest.xml` and `Info.plist`.

---

### 7. **Q: Why did you remove the digit-only filter from the channel input?**
**A:** The original filter (`FilteringTextInputFormatter.digitsOnly`) only allowed numeric input. We needed to support:
- Alphanumeric channel names (e.g., "test", "call-123")
- Agora's channel naming conventions
- More flexible testing

**Fix:** Removed input formatters, validated non-empty input instead.

---

### 8. **Q: How does AI health guidance work?**
**A:** Powered by Google Gemini:
1. User submits health query
2. App sends to Gemini API with context (medical history, symptoms)
3. Gemini generates personalized advice
4. Response displayed in chat interface
5. Conversation history maintained for follow-up

**Security:** All health data encrypted, HIPAA-compliant storage.

---

### 9. **Q: What's the payment processing flow?**
**A:**
```
Call Start → Timer Begins → Call End → Calculate Duration
    ↓
Calculate Cost (e.g., $2/min)
    ↓
Process Payment (via payment_service.dart)
    ↓
Generate PDF Receipt (with session details)
    ↓
Show Summary Dialog
```

**Integrations:** Ready for Stripe, PayPal, or Razorpay.

---

### 10. **Q: How do you handle network issues during calls?**
**A:** Multi-layer approach:
- **Stream Video**: Automatic reconnection, adaptive bitrate
- **Agora**: Built-in network quality monitoring
- **Error Handling**:
  ```dart
  try {
    await _call.join();
  } catch (e) {
    // Show error, offer retry or fallback to Agora
  }
  ```
- **Fallback**: If Stream fails, suggest Agora (and vice versa)
- **Monitoring**: Track connection state, display warnings for poor network

---

## 🐛 Known Issues

1. **Stream Video SDK Bug**: Fixed with custom controls (see Q&A #2)
2. **Agora Token Expiry**: Manual refresh required (implement server-side generation)
3. **iOS Background Permissions**: Requires additional configuration for background calls

---

## 🙏 Acknowledgments

- **Stream.io** - Video SDK
- **Agora** - RTC Engine
- **Supabase** - Backend infrastructure
- **Google** - Gemini AI, Fonts, Sign-In
- **Flutter Team** - Amazing framework

---

**Built with ❤️ using Flutter**
