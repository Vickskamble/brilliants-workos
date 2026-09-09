class AppConstants {
  static const String appName = 'Brilliants Work OS';
  static const String appVersion = '1.0.0';

  // Performance score weights
  static const double taskWeight = 0.35;
  static const double targetWeight = 0.40;
  static const double onTimeWeight = 0.25;

  // Performance bands
  static const double excellentThreshold = 85;
  static const double goodThreshold = 70;
  static const double averageThreshold = 50;

  // Escalation thresholds (days)
  static const int escalationManagerDays = 2;
  static const int escalationAdminDays = 3;

  // Task status order for sorting
  static const Map<String, int> priorityOrder = {
    'URGENT': 0,
    'HIGH': 1,
    'MEDIUM': 2,
    'LOW': 3,
  };
}
