class AppConstants {
  // Free tier limits
  static const int maxFreeGroups = 2;
  static const int maxFreeGroupMembers = 5;
  static const int maxFreeBillHistory = 10;

  // Premium product IDs
  static const String premiumLifetimeId = 'premium_lifetime';
  static const String premiumMonthlyId = 'premium_monthly';

  // Colors
  static const int primaryColor = 0xFF009688; // Teal
  static const int secondaryColor = 0xFFFF5722; // Deep Orange

  // Person colors (Material Design palette)
  static const List<int> personColors = [
    0xFF2196F3, // Blue
    0xFF9C27B0, // Purple
    0xFF4CAF50, // Green
    0xFFFF9800, // Orange
    0xFFE91E63, // Pink
    0xFF00BCD4, // Cyan
    0xFFFFEB3B, // Yellow
    0xFF795548, // Brown
  ];

  // Default tip percentages
  static const List<double> defaultTipPercentages = [15.0, 18.0, 20.0];
}
