import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/premium_provider.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  double _defaultTipPercentage = 18.0;
  bool _isDarkMode = false;
  bool _useSystemTheme = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _defaultTipPercentage = prefs.getDouble('default_tip_percentage') ?? 18.0;
      _isDarkMode = prefs.getBool('is_dark_mode') ?? false;
      _useSystemTheme = prefs.getBool('use_system_theme') ?? true;
    });
  }

  Future<void> _saveDefaultTip(double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('default_tip_percentage', value);
    setState(() {
      _defaultTipPercentage = value;
    });
  }

  Future<void> _saveThemeSettings(bool isDark, bool useSystem) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_dark_mode', isDark);
    await prefs.setBool('use_system_theme', useSystem);
    setState(() {
      _isDarkMode = isDark;
      _useSystemTheme = useSystem;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
        children: [
          Consumer<PremiumProvider>(
            builder: (context, premiumProvider, child) {
              if (premiumProvider.isPremium) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Material(
                    color: theme.colorScheme.primaryContainer.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.star_rounded, color: theme.colorScheme.primary, size: 24),
                              const SizedBox(width: 10),
                              Text(
                                'Premium Active',
                                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            premiumProvider.isLifetime
                                ? 'Lifetime Premium'
                                : 'Premium until ${_formatDate(premiumProvider.premiumExpiry)}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Material(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Upgrade to Premium',
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 12),
                        _bullet(theme, 'Unlimited groups'),
                        _bullet(theme, 'Unlimited bill history'),
                        _bullet(theme, 'Priority support'),
                        const SizedBox(height: 18),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => _showPremiumDialog(context),
                            child: const Text('Upgrade Now'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),

          _sectionTitle(theme, 'Preferences'),
          const SizedBox(height: 8),
          Material(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(AppTheme.cardRadius),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              title: const Text('Default Tip Percentage'),
              subtitle: Text('${_defaultTipPercentage.toStringAsFixed(0)}%'),
              trailing: DropdownButton<double>(
                value: _defaultTipPercentage,
                items: AppConstants.defaultTipPercentages
                    .map((p) => DropdownMenuItem(value: p, child: Text('${p.toStringAsFixed(0)}%')))
                    .toList(),
                onChanged: (value) {
                  if (value != null) _saveDefaultTip(value);
                },
              ),
            ),
          ),
          const SizedBox(height: 20),

          _sectionTitle(theme, 'Appearance'),
          const SizedBox(height: 8),
          Material(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(AppTheme.cardRadius),
            child: Column(
              children: [
                SwitchListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                  title: const Text('Use System Theme'),
                  value: _useSystemTheme,
                  onChanged: (value) => _saveThemeSettings(_isDarkMode, value),
                ),
                if (!_useSystemTheme)
                  SwitchListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                    title: const Text('Dark Mode'),
                    value: _isDarkMode,
                    onChanged: (value) => _saveThemeSettings(value, _useSystemTheme),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          _sectionTitle(theme, 'About'),
          const SizedBox(height: 8),
          Material(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(AppTheme.cardRadius),
            child: Column(
              children: [
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  title: const Text('Privacy Policy'),
                  trailing: Icon(Icons.chevron_right_rounded, color: theme.colorScheme.onSurface.withOpacity(0.4)),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Privacy policy coming soon')),
                    );
                  },
                ),
                Divider(height: 1, color: theme.dividerColor),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  title: const Text('Terms of Service'),
                  trailing: Icon(Icons.chevron_right_rounded, color: theme.colorScheme.onSurface.withOpacity(0.4)),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Terms of service coming soon')),
                    );
                  },
                ),
                Divider(height: 1, color: theme.dividerColor),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  title: const Text('Version'),
                  subtitle: const Text('1.0.0'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(ThemeData theme, String title) {
    return Text(
      title,
      style: theme.textTheme.labelLarge?.copyWith(
        fontWeight: FontWeight.w600,
        color: theme.colorScheme.onSurface.withOpacity(0.6),
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _bullet(ThemeData theme, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('• ', style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.w600)),
          Expanded(child: Text(text, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }

  void _showPremiumDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.cardRadius)),
        title: const Text('Upgrade to Premium'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Choose a plan:'),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('Lifetime Premium'),
              subtitle: const Text('\$2.99 one-time payment'),
              trailing: ElevatedButton(
                onPressed: () {
                  // TODO: Implement IAP
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('In-app purchase integration coming soon'),
                    ),
                  );
                },
                child: const Text('Buy'),
              ),
            ),
            ListTile(
              title: const Text('Monthly Premium'),
              subtitle: const Text('\$0.99/month'),
              trailing: ElevatedButton(
                onPressed: () {
                  // TODO: Implement IAP
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('In-app purchase integration coming soon'),
                    ),
                  );
                },
                child: const Text('Subscribe'),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return '${date.month}/${date.day}/${date.year}';
  }
}
