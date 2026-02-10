import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/bill_provider.dart';
import '../providers/premium_provider.dart';
import '../utils/app_theme.dart';
import '../widgets/bill_card.dart';
import 'split_result_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final billProvider = Provider.of<BillProvider>(context, listen: false);
      billProvider.loadAllBills();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bill History'),
        actions: [
          Consumer<BillProvider>(
            builder: (context, billProvider, child) {
              return IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () => _clearHistory(context, billProvider),
                tooltip: 'Clear History',
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Consumer2<BillProvider, PremiumProvider>(
              builder: (context, billProvider, premiumProvider, child) {
                if (billProvider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (billProvider.recentBills.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.history_rounded, size: 56, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.25)),
                          const SizedBox(height: 16),
                          Text(
                            'No bills in history',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Saved bills will appear here',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                // Show limit warning for free users
                if (!premiumProvider.isPremium) {
                  final billCount = billProvider.recentBills.length;
                  if (billCount >= 10) {
                    return Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                          child: Material(
                            color: Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.4),
                            borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Row(
                                children: [
                                  Icon(Icons.info_outline_rounded, color: Theme.of(context).colorScheme.secondary, size: 22),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'Showing last 10 bills. Upgrade to Premium for unlimited history.',
                                      style: Theme.of(context).textTheme.bodySmall,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Expanded(child: _buildBillList(billProvider)),
                      ],
                    );
                  }
                }

                return _buildBillList(billProvider);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBillList(BillProvider billProvider) {
    return RefreshIndicator(
      onRefresh: () => billProvider.loadAllBills(),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        itemCount: billProvider.recentBills.length,
        itemBuilder: (context, index) {
          final bill = billProvider.recentBills[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: BillCard(
              bill: bill,
              onTap: () async {
                final fullBill = await billProvider.getBillById(bill.id);
                if (fullBill != null && mounted) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SplitResultScreen(bill: fullBill),
                    ),
                  );
                }
              },
            ),
          );
        },
      ),
    );
  }

  void _clearHistory(BuildContext context, BillProvider billProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.cardRadius)),
        title: const Text('Clear History'),
        content: const Text(
          'Are you sure you want to delete all bill history? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              billProvider.clearAllBills();
              Navigator.pop(context);
            },
            child: Text('Clear', style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        ],
      ),
    );
  }
}
