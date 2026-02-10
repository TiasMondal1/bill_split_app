import 'package:flutter/material.dart';
import '../models/bill_item.dart';
import '../utils/helpers.dart';
import '../utils/app_theme.dart';

class ItemTile extends StatelessWidget {
  final BillItem item;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const ItemTile({
    super.key,
    required this.item,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      item.name,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.assignedPeople.isEmpty
                          ? 'No one assigned'
                          : 'Split ${item.assignedPeople.length} way${item.assignedPeople.length > 1 ? 's' : ''}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: item.assignedPeople.isEmpty
                            ? theme.colorScheme.error
                            : theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                Helpers.formatCurrency(item.totalPrice),
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (onDelete != null) ...[
                const SizedBox(width: 4),
                IconButton(
                  icon: Icon(Icons.delete_outline_rounded, size: 20, color: theme.colorScheme.error),
                  onPressed: onDelete,
                  style: IconButton.styleFrom(
                    minimumSize: const Size(40, 40),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
