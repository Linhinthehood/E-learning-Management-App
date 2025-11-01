/// App-wide constants
class AppConstants {
  // API endpoints (if using REST API)
  static const String baseUrl = 'https://your-api.com/api';
  static const String loginEndpoint = '/auth/login';
  static const String logoutEndpoint = '/auth/logout';

  // Route names
  static const String loginRoute = '/login';
  static const String dashboardRoute = '/dashboard';
  static const String courseRoute = '/course';

  // Storage keys
  static const String userCacheKey = 'cached_user';
  static const String tokenKey = 'auth_token';

  // Instructor credentials (as per requirement)
  static const String instructorEmail = 'admin';
  static const String instructorPassword = 'admin';
}
