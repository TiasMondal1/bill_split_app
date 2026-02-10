import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/bill_provider.dart';
import '../utils/app_theme.dart';
import '../widgets/bill_card.dart';
import 'bill_entry_screen.dart';
import 'groups_screen.dart';
import 'history_screen.dart';
import 'settings_screen.dart';
import 'receipt_scanner_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bill Splitter'),
      ),
      body: _buildCurrentScreen(),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const BillEntryScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.add_rounded),
              label: const Text('New Bill'),
            )
          : null,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: theme.shadowColor.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(icon: Icons.home_rounded, label: 'Home', index: 0, current: _currentIndex, onTap: () => setState(() => _currentIndex = 0)),
                _NavItem(icon: Icons.group_rounded, label: 'Groups', index: 1, current: _currentIndex, onTap: () => setState(() => _currentIndex = 1)),
                _NavItem(icon: Icons.history_rounded, label: 'History', index: 2, current: _currentIndex, onTap: () => setState(() => _currentIndex = 2)),
                _NavItem(icon: Icons.settings_rounded, label: 'Settings', index: 3, current: _currentIndex, onTap: () => setState(() => _currentIndex = 3)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentScreen() {
    switch (_currentIndex) {
      case 0:
        return _buildHomeContent();
      case 1:
        return const GroupsScreen();
      case 2:
        return const HistoryScreen();
      case 3:
        return const SettingsScreen();
      default:
        return _buildHomeContent();
    }
  }

  Widget _buildHomeContent() {
    final theme = Theme.of(context);
    return Consumer<BillProvider>(
      builder: (context, billProvider, child) {
        return RefreshIndicator(
          onRefresh: () => billProvider.loadRecentBills(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Scan Receipt Card
                Material(
                  color: theme.colorScheme.primaryContainer.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ReceiptScannerScreen(),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(
                              Icons.document_scanner_rounded,
                              size: 28,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Scan Receipt',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Use OCR to extract items from a photo',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurface.withOpacity(0.65),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.arrow_forward_ios_rounded, size: 14, color: theme.colorScheme.onSurface.withOpacity(0.4)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  'Recent Bills',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 12),
                if (billProvider.isLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (billProvider.recentBills.isEmpty)
                  _EmptyState(
                    icon: Icons.receipt_long_rounded,
                    title: 'No bills yet',
                    subtitle: 'Create your first bill or scan a receipt to get started.',
                  )
                else
                  ...billProvider.recentBills.map((bill) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: BillCard(
                          bill: bill,
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              '/bill-details',
                              arguments: bill.id,
                            );
                          },
                        ),
                      )),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final int index;
  final int current;
  final VoidCallback onTap;

  const _NavItem({required this.icon, required this.label, required this.index, required this.current, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selected = index == current;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 24, color: selected ? theme.colorScheme.primary : theme.colorScheme.onSurface.withOpacity(0.5)),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                color: selected ? theme.colorScheme.primary : theme.colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyState({required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
      ),
      child: Column(
        children: [
          Icon(icon, size: 48, color: theme.colorScheme.onSurface.withOpacity(0.35)),
          const SizedBox(height: 16),
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.55),
            ),
          ),
        ],
      ),
    );
  }
}
