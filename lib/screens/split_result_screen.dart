import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/bill.dart';
import '../providers/bill_provider.dart';
import '../providers/premium_provider.dart';
import '../utils/app_theme.dart';
import '../widgets/calculation_summary.dart';

class SplitResultScreen extends StatefulWidget {
  final Bill bill;

  const SplitResultScreen({
    super.key,
    required this.bill,
  });

  @override
  State<SplitResultScreen> createState() => _SplitResultScreenState();
}

class _SplitResultScreenState extends State<SplitResultScreen> {
  Future<void> _saveBill() async {
    final billProvider = Provider.of<BillProvider>(context, listen: false);
    final premiumProvider = Provider.of<PremiumProvider>(context, listen: false);

    // Check if user can save more bills
    final allBills = await billProvider.loadAllBills();
    if (!premiumProvider.canSaveBill(allBills.length) &&
        !allBills.any((b) => b.id == widget.bill.id)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Free tier limit reached. Upgrade to Premium for unlimited history.',
            ),
            duration: Duration(seconds: 3),
          ),
        );
      }
      return;
    }

    final success = await billProvider.saveBillToHistory(widget.bill);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Bill saved to history' : 'Failed to save bill'),
        ),
      );
    }
  }

  void _updatePaidStatus(String personName, bool paid) {
    final billProvider = Provider.of<BillProvider>(context, listen: false);
    billProvider.updateBillPaidStatus(widget.bill.id, personName, paid);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Bill at ${widget.bill.restaurantName}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // TODO: Implement share functionality
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Share feature coming soon')),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: CalculationSummary(
              bill: widget.bill,
              onPaidStatusChanged: _updatePaidStatus,
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).shadowColor.withOpacity(0.08),
                  blurRadius: 12,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Back'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () {
                        _saveBill();
                        Navigator.popUntil(context, (route) => route.isFirst);
                      },
                      child: const Text('Save & Finish'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
