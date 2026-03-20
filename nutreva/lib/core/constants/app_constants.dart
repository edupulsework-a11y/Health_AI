// ──────────────────────────────────────────────────────
// NUTREVA — App Constants
// All API keys centralised here
// ──────────────────────────────────────────────────────
class AppConstants {
  AppConstants._();

  static const String appName = 'Nutreva';

  // ── Supabase (Nutreva project) ────────────────────
  static const String supabaseUrl = 'YOUR_SUPABASE_URL';
  static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';

  // ── Google OAuth ──────────────────────────────────
  static const String googleClientId = 'YOUR_GOOGLE_CLIENT_ID';
  static const String googleClientSecret = 'YOUR_GOOGLE_CLIENT_SECRET';

  // ── AI  ───────────────────────────────────────────
  // Gemini (from FINAL project — free tier)
  static const String geminiApiKey = 'YOUR_GEMINI_API_KEY';

  // OpenAI (from FINAL project)
  static const String openAiKey = 'YOUR_OPENAI_API_KEY';

  // Grok / Groq (llama-3.3-70b — AI chat, menstrual advice, food safety)
  static const String grokApiKey = 'YOUR_GROQ_API_KEY';

  // ── Agora (Video Calls) ───────────────────────────
  static const String agoraAppId = 'YOUR_AGORA_APP_ID';
  static const String agoraTempToken = 'YOUR_AGORA_TEMP_TOKEN';

  // ── Stream (Video Calls) ──────────────────────────
  static const String streamApiKey = 'YOUR_STREAM_API_KEY';
  static const String streamApiSecret = 'YOUR_STREAM_API_SECRET';

  // ── ImgBB (Image Upload) ──────────────────────────
  static const String imgBBKey = 'YOUR_IMGBB_API_KEY';

  // ── Firebase (ESP8266 Sensor RTDB) ───────────────
  static const String firebaseApiKey = 'YOUR_FIREBASE_API_KEY';
  static const String firebaseProjectId = 'YOUR_FIREBASE_PROJECT_ID';
  static const String firebaseDatabaseUrl =
      'https://esp82live-default-rtdb.asia-southeast1.firebasedatabase.app';

  // ── Blockchain (MegaETH Testnet) ──────────────────
  static const String megaEthRpcUrl = 'https://rpc.megaeth.com';
  static const String contractAddress = '0x0000000000000000000000000000000000000000'; // update after deploy
  static const int chainId = 6342;

  // ── Nutritionix ───────────────────────────────────
  static const String nutritionApiUrl = 'https://trackapi.nutritionix.com/v2';
  static const String nutritionixAppId = 'YOUR_NUTRITIONIX_APP_ID';
  static const String nutritionixApiKey = 'YOUR_NUTRITIONIX_API_KEY';

  // ── ESP8266 Local ─────────────────────────────────
  static const String espBaseUrl = 'http://192.168.1.100';

  // ── Secure Storage Keys ───────────────────────────
  static const String authTokenKey = 'nutreva_auth_token';
  static const String walletKeyRef = 'nutreva_wallet_key';

  // ── Hive Boxes ────────────────────────────────────
  static const String mealBox = 'meal_logs';
  static const String settingsBox = 'settings';

  // ── App Config ────────────────────────────────────
  static const int bpmAlertThreshold = 120;
  static const int streakGoalDays = 7;
}
