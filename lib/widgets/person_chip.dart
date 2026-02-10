import 'package:flutter/material.dart';
import '../models/person.dart';
import '../utils/app_theme.dart';

class PersonChip extends StatelessWidget {
  final Person person;
  final VoidCallback? onTap;
  final bool isSelected;
  final bool showDelete;

  const PersonChip({
    super.key,
    required this.person,
    this.onTap,
    this.isSelected = false,
    this.showDelete = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = Color(person.colorValue);

    return Material(
      color: isSelected ? color.withOpacity(0.2) : theme.colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: color,
                child: Text(
                  person.name.isNotEmpty ? person.name[0].toUpperCase() : '?',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                person.name,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
