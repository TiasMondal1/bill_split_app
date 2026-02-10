import 'package:flutter/material.dart';
import '../models/bill.dart';
import '../models/person.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import '../utils/app_theme.dart';
import 'person_chip.dart';

class CalculationSummary extends StatelessWidget {
  final Bill bill;
  final Function(String, bool)? onPaidStatusChanged;

  const CalculationSummary({
    super.key,
    required this.bill,
    this.onPaidStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final people = bill.allPeople;

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      itemCount: people.length,
      itemBuilder: (context, index) {
        final personName = people[index];
        final total = bill.personTotals[personName] ?? 0.0;
        final isPaid = bill.paidStatus[personName] ?? false;
        final colorValue = Helpers.getColorForPerson(personName, AppConstants.personColors);
        final personItems = bill.items
            .where((item) => item.assignedPeople.contains(personName))
            .toList();

        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Material(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(AppTheme.cardRadius),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      PersonChip(
                        person: Person(name: personName, colorValue: colorValue),
                      ),
                      const Spacer(),
                      if (onPaidStatusChanged != null)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Paid',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface.withOpacity(0.7),
                              ),
                            ),
                            Checkbox(
                              value: isPaid,
                              onChanged: (value) => onPaidStatusChanged!(personName, value ?? false),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                  if (personItems.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Items',
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 6),
                    ...personItems.map((item) => Padding(
                          padding: const EdgeInsets.only(left: 4, bottom: 2),
                          child: Text(
                            '• ${item.name} (${Helpers.formatCurrency(item.totalPrice / item.assignedPeople.length)})',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(0.65),
                            ),
                          ),
                        )),
                    const SizedBox(height: 10),
                  ],
                  Divider(height: 20, color: theme.dividerColor),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        Helpers.formatCurrency(total),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
