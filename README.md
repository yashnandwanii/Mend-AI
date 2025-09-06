# Mend AI - Couples Therapist App

A Flutter-based AI couples therapy app that helps partners communicate better through voice-guided conversations, real-time AI moderation, and relationship insights.

## Features

### 🎯 Core Features
- **Voice-Based Communication**: Real-time voice chat between partners with AI moderation
- **AI Guidance**: Intelligent conversation prompts and guided questions
- **Communication Scoring**: Track progress in empathy, listening, clarity, respect, responsiveness, and open-mindedness
- **Interruption Detection**: Screen flashes red with TTS reminders when interruptions occur
- **Post-Session Reflection**: Gratitude exercises and relationship insights
- **Partner Connection**: Invite system with unique codes for partner pairing

### 📊 Analytics & Insights
- **Progress Dashboard**: Visual charts showing communication improvement over time
- **Session History**: Complete record of all conversation sessions
- **Reflection Tracking**: Save and review post-session reflections
- **Bonding Activities**: AI-suggested activities to strengthen relationships

### 🎨 User Experience
- **Color-Coded Interface**: Different background colors for each partner
- **Animated UI**: Smooth transitions and engaging animations
- **Waveform Visualization**: Real-time audio visualization during conversations
- **Celebration Animations**: Positive reinforcement after successful sessions

## Tech Stack

### Frontend
- **Flutter**: Cross-platform mobile development
- **Riverpod**: State management
- **Go Router**: Navigation and routing
- **Lottie**: Animations
- **FL Chart**: Data visualization

### Backend
- **Firebase Auth**: User authentication
- **Cloud Firestore**: Real-time database
- **Firebase Storage**: File storage

### AI Services (Placeholder Integration)
- **Speech-to-Text**: Vosk (offline) or cloud services
- **Text-to-Speech**: Flutter TTS plugin
- **Emotion Detection**: Hugging Face emotion classifiers
- **Conversation Analysis**: Custom scoring algorithms
- **AI Guidance**: Flan-T5 or similar language models

## Setup Instructions

### Prerequisites
- Flutter SDK (3.9.0 or higher)
- Firebase project
- Android Studio / VS Code
- Git

### 1. Clone the Repository
```bash
git clone <repository-url>
cd mend_ai
```

### 2. Install Dependencies
```bash
flutter pub get
```

### 3. Firebase Setup
1. Create a new Firebase project at https://console.firebase.google.com/
2. Enable Authentication, Firestore, and Storage
3. Run the Firebase CLI configuration:
```bash
npm install -g firebase-tools
dart pub global activate flutterfire_cli
flutterfire configure
```
4. Replace the placeholder Firebase configuration in `lib/config/firebase_options.dart` with your actual config

### 4. Configure Firebase Authentication
- Enable Anonymous authentication in Firebase Console
- Optionally enable Email/Password authentication

### 5. Setup Firestore Database
Create the following collections in Firestore:
- `users` - User profiles and preferences
- `relationships` - Partner connections and invite codes
- `sessions` - Conversation session data
- `reflections` - Post-session reflection data

### 6. Add Assets
Place the following assets in the respective directories:
- `assets/animations/celebration.json` - Lottie celebration animation
- `assets/fonts/` - Poppins font family files
- App icons and images in `assets/images/`

### 7. Run the App
```bash
# Run on Android
flutter run

# Run on iOS (macOS required)
flutter run -d ios

# Build for release
flutter build apk --release  # Android
flutter build ios --release  # iOS
```

## Project Structure

```
lib/
├── config/           # App configuration
│   ├── app_router.dart
│   ├── app_theme.dart
│   └── firebase_options.dart
├── models/           # Data models
│   ├── user_model.dart
│   ├── relationship_model.dart
│   ├── session_model.dart
│   └── reflection_model.dart
├── providers/        # Riverpod state providers
│   ├── auth_provider.dart
│   ├── relationship_provider.dart
│   └── voice_provider.dart
├── screens/          # UI screens
│   ├── splash_screen.dart
│   ├── welcome_screen.dart
│   ├── onboarding_screen.dart
│   ├── partner_invite_screen.dart
│   ├── home_screen.dart
│   ├── voice_chat_screen.dart
│   ├── post_resolution_screen.dart
│   ├── insights_screen.dart
│   └── profile_screen.dart
├── services/         # Business logic services
│   ├── firebase_auth_service.dart
│   ├── firebase_database_service.dart
│   ├── ai_service.dart
│   ├── voice_service.dart
│   └── permission_service.dart
├── widgets/          # Reusable UI components
│   ├── animated_button.dart
│   └── loading_widget.dart
└── main.dart         # App entry point
```

## AI Integration Setup

### Speech-to-Text (Vosk)
1. Download Vosk models from https://alphacephei.com/vosk/models
2. Add model files to `assets/vosk_models/`
3. Update `ai_service.dart` to use actual Vosk integration

### Emotion Detection (Hugging Face)
1. Sign up for Hugging Face API access
2. Get API token and add to environment variables
3. Update emotion detection calls in `ai_service.dart`

### Text-to-Speech
The app uses Flutter's built-in TTS which works out of the box on both platforms.

## Development Guidelines

### State Management
- Use Riverpod for all state management
- Keep providers focused and single-purpose
- Use AsyncValue for async operations

### Navigation
- Use Go Router for type-safe navigation
- Define all routes in `app_router.dart`
- Use context.go() for navigation

### UI/UX
- Follow Material Design 3 guidelines
- Use consistent spacing and colors from `app_theme.dart`
- Implement accessibility features

### Data Flow
1. User interactions trigger provider methods
2. Providers update Firebase through services
3. Firebase changes trigger provider updates
4. UI rebuilds automatically with new data

## Testing

### Unit Tests
```bash
flutter test
```

### Integration Tests
```bash
flutter drive --target=test_driver/app.dart
```

### Firebase Emulators (Optional)
```bash
firebase emulators:start
```

## Deployment

### Android
1. Generate signing key
2. Configure `android/app/build.gradle`
3. Build release APK: `flutter build apk --release`

### iOS
1. Configure Xcode project
2. Set up App Store Connect
3. Build for App Store: `flutter build ios --release`

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For issues and questions:
- Create an issue on GitHub
- Contact: support@mendai.app

---

Built with ❤️ using Flutter and Firebase
