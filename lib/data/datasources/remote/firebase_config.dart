/// Firebase Configuration
/// Your actual Firebase project credentials
class FirebaseConfig {
  static const String apiKey = "AIzaSyBLimiaIgCPelv2YYp4fKHvG8PzXJ1RuBo";
  static const String authDomain =
      "e-learning-management-ap-351a8.firebaseapp.com";
  static const String projectId = "e-learning-management-ap-351a8";
  static const String storageBucket =
      "e-learning-management-ap-351a8.firebasestorage.app";
  static const String messagingSenderId = "749862035515";
  static const String appId = "1:749862035515:web:46affdd8d4a1e62a64bc1e";
  static const String measurementId = "G-EHNGKWX2BB";

  // For web platform
  static Map<String, String> get webConfig => {
    'apiKey': apiKey,
    'authDomain': authDomain,
    'projectId': projectId,
    'storageBucket': storageBucket,
    'messagingSenderId': messagingSenderId,
    'appId': appId,
    'measurementId': measurementId,
  };
}
