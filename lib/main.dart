import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'providers/bill_provider.dart';
import 'providers/group_provider.dart';
import 'providers/premium_provider.dart';
import 'screens/home_screen.dart';
import 'screens/split_result_screen.dart';
import 'utils/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const BillSplitApp());
}

class BillSplitApp extends StatefulWidget {
  const BillSplitApp({super.key});

  @override
  State<BillSplitApp> createState() => _BillSplitAppState();
}

class _BillSplitAppState extends State<BillSplitApp> {
  ThemeMode _themeMode = ThemeMode.system;
  bool _isDarkMode = false;

  @override
  void initState() {
    super.initState();
    _loadThemeSettings();
  }

  Future<void> _loadThemeSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final useSystemTheme = prefs.getBool('use_system_theme') ?? true;
    final isDarkMode = prefs.getBool('is_dark_mode') ?? false;

    setState(() {
      if (useSystemTheme) {
        _themeMode = ThemeMode.system;
      } else {
        _themeMode = isDarkMode ? ThemeMode.dark : ThemeMode.light;
      }
      _isDarkMode = isDarkMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PremiumProvider()),
        ChangeNotifierProxyProvider<PremiumProvider, GroupProvider>(
          create: (_) => GroupProvider(Provider.of<PremiumProvider>(_, listen: false)),
          update: (_, premiumProvider, __) => GroupProvider(premiumProvider),
        ),
        ChangeNotifierProxyProvider<PremiumProvider, BillProvider>(
          create: (_) => BillProvider(Provider.of<PremiumProvider>(_, listen: false)),
          update: (_, premiumProvider, __) => BillProvider(premiumProvider),
        ),
      ],
      child: MaterialApp(
        title: 'Bill Splitter',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: _themeMode,
        home: const HomeScreen(),
        routes: {
          '/home': (context) => const HomeScreen(),
          '/bill-details': (context) {
            final billId = ModalRoute.of(context)!.settings.arguments as String;
            return FutureBuilder(
              future: Provider.of<BillProvider>(context, listen: false).getBillById(billId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                }
                final bill = snapshot.data;
                if (bill == null) {
                  return Scaffold(
                    appBar: AppBar(title: const Text('Bill Not Found')),
                    body: const Center(child: Text('Bill not found')),
                  );
                }
                return SplitResultScreen(bill: bill);
              },
            );
          },
        },
      ),
    );
  }
}
