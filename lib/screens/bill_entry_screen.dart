import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/bill_item.dart';
import '../models/person.dart';
import '../providers/bill_provider.dart';
import '../providers/group_provider.dart';
import '../services/calculation_service.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import '../widgets/item_tile.dart';
import '../widgets/person_chip.dart';
import 'split_result_screen.dart';

class BillEntryScreen extends StatefulWidget {
  const BillEntryScreen({super.key});

  @override
  State<BillEntryScreen> createState() => _BillEntryScreenState();
}

class _BillEntryScreenState extends State<BillEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _restaurantController = TextEditingController();
  final _taxRateController = TextEditingController();
  final _tipRateController = TextEditingController();

  List<Person> _people = [];
  List<BillItem> _items = [];
  String? _selectedGroupId;
  bool _taxIsPercentage = true;
  bool _tipIsPercentage = true;

  @override
  void initState() {
    super.initState();
    _loadGroups();
  }

  void _loadGroups() {
    final groupProvider = Provider.of<GroupProvider>(context, listen: false);
    groupProvider.loadGroups();
  }

  @override
  void dispose() {
    _restaurantController.dispose();
    _taxRateController.dispose();
    _tipRateController.dispose();
    super.dispose();
  }

  void _addPerson() {
    showDialog(
      context: context,
      builder: (context) {
        final nameController = TextEditingController();
        return AlertDialog(
          title: const Text('Add Person'),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: 'Name',
              hintText: 'Enter person name',
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (nameController.text.trim().isNotEmpty) {
                  final colorValue = Helpers.getColorForPerson(
                    nameController.text.trim(),
                    AppConstants.personColors,
                  );
                  setState(() {
                    _people.add(Person(
                      name: nameController.text.trim(),
                      colorValue: colorValue,
                    ));
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _removePerson(Person person) {
    setState(() {
      _people.remove(person);
      // Remove person from all items
      _items = _items.map((item) {
        return item.copyWith(
          assignedPeople: item.assignedPeople
              .where((p) => p != person.name)
              .toList(),
        );
      }).toList();
    });
  }

  void _addItem() {
    showDialog(
      context: context,
      builder: (context) {
        final nameController = TextEditingController();
        final priceController = TextEditingController();
        final quantityController = TextEditingController(text: '1');
        final selectedPeople = <String>{};

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Add Item'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Item Name',
                        hintText: 'e.g., Pizza',
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: priceController,
                      decoration: const InputDecoration(
                        labelText: 'Price',
                        hintText: '0.00',
                      ),
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: quantityController,
                      decoration: const InputDecoration(
                        labelText: 'Quantity',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    const Text('Shared by:'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: _people.map((person) {
                        final isSelected = selectedPeople.contains(person.name);
                        return FilterChip(
                          label: Text(person.name),
                          selected: isSelected,
                          onSelected: (selected) {
                            setDialogState(() {
                              if (selected) {
                                selectedPeople.add(person.name);
                              } else {
                                selectedPeople.remove(person.name);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    final name = nameController.text.trim();
                    final price = double.tryParse(priceController.text);
                    final quantity = int.tryParse(quantityController.text) ?? 1;

                    if (name.isNotEmpty && price != null && price > 0) {
                      setState(() {
                        _items.add(BillItem(
                          id: const Uuid().v4(),
                          name: name,
                          price: price,
                          quantity: quantity,
                          assignedPeople: selectedPeople.toList(),
                        ));
                      });
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _editItem(BillItem item) {
    final index = _items.indexWhere((i) => i.id == item.id);
    if (index == -1) return;

    showDialog(
      context: context,
      builder: (context) {
        final nameController = TextEditingController(text: item.name);
        final priceController = TextEditingController(text: item.price.toString());
        final quantityController = TextEditingController(text: item.quantity.toString());
        final selectedPeople = Set<String>.from(item.assignedPeople);

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Edit Item'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Item Name'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: priceController,
                      decoration: const InputDecoration(labelText: 'Price'),
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: quantityController,
                      decoration: const InputDecoration(labelText: 'Quantity'),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    const Text('Shared by:'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: _people.map((person) {
                        final isSelected = selectedPeople.contains(person.name);
                        return FilterChip(
                          label: Text(person.name),
                          selected: isSelected,
                          onSelected: (selected) {
                            setDialogState(() {
                              if (selected) {
                                selectedPeople.add(person.name);
                              } else {
                                selectedPeople.remove(person.name);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    final name = nameController.text.trim();
                    final price = double.tryParse(priceController.text);
                    final quantity = int.tryParse(quantityController.text) ?? 1;

                    if (name.isNotEmpty && price != null && price > 0) {
                      setState(() {
                        _items[index] = BillItem(
                          id: item.id,
                          name: name,
                          price: price,
                          quantity: quantity,
                          assignedPeople: selectedPeople.toList(),
                        );
                      });
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _assignAllEqually() {
    if (_people.isEmpty || _items.isEmpty) return;

    setState(() {
      _items = _items.map((item) {
        return item.copyWith(assignedPeople: _people.map((p) => p.name).toList());
      }).toList();
    });
  }

  void _calculateSplit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one item')),
      );
      return;
    }

    // Check if all items have at least one person assigned
    final itemsWithoutPeople = _items.where((item) => item.assignedPeople.isEmpty).toList();
    if (itemsWithoutPeople.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All items must be assigned to at least one person')),
      );
      return;
    }

    final taxRate = double.tryParse(_taxRateController.text) ?? 0.0;
    final tipRate = double.tryParse(_tipRateController.text) ?? 0.0;

    final billProvider = Provider.of<BillProvider>(context, listen: false);

    try {
      final bill = await billProvider.calculateBill(
        restaurantName: _restaurantController.text.trim(),
        items: _items,
        taxRate: taxRate,
        taxIsPercentage: _taxIsPercentage,
        tipRate: tipRate,
        tipIsPercentage: _tipIsPercentage,
        groupId: _selectedGroupId,
      );

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => SplitResultScreen(bill: bill),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final subtotal = CalculationService.calculateSubtotal(_items);
    final taxRate = double.tryParse(_taxRateController.text) ?? 0.0;
    final tipRate = double.tryParse(_tipRateController.text) ?? 0.0;
    final tax = CalculationService.calculateTax(
      subtotal: subtotal,
      taxRate: taxRate,
      isPercentage: _taxIsPercentage,
    );
    final tip = CalculationService.calculateTip(
      subtotal: subtotal,
      tipRate: tipRate,
      isPercentage: _tipIsPercentage,
    );
    final total = CalculationService.calculateTotal(
      subtotal: subtotal,
      tax: tax,
      tip: tip,
    );

    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Bill'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check_rounded),
            onPressed: _calculateSplit,
            tooltip: 'Calculate Split',
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
          children: [
            TextFormField(
              controller: _restaurantController,
              decoration: const InputDecoration(
                labelText: 'Restaurant Name',
                hintText: 'e.g., Local Bistro',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter restaurant name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Group Selection
            Consumer<GroupProvider>(
              builder: (context, groupProvider, child) {
                if (groupProvider.groups.isEmpty) {
                  return const SizedBox.shrink();
                }
                return DropdownButtonFormField<String>(
                  value: _selectedGroupId,
                  decoration: const InputDecoration(
                    labelText: 'Group (Optional)',
                  ),
                  items: [
                    const DropdownMenuItem<String>(
                      value: null,
                      child: Text('None'),
                    ),
                    ...groupProvider.groups.map((group) {
                      return DropdownMenuItem<String>(
                        value: group.id,
                        child: Text(group.name),
                      );
                    }),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedGroupId = value;
                      if (value != null) {
                        final group = groupProvider.getGroupById(value);
                        if (group != null) {
                          _people = group.members.map((name) {
                            return Person(
                              name: name,
                              colorValue: Helpers.getColorForPerson(
                                name,
                                AppConstants.personColors,
                              ),
                            );
                          }).toList();
                        }
                      }
                    });
                  },
                );
              },
            ),
            const SizedBox(height: 24),

            _sectionTitle(theme, 'People'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ..._people.map((person) => PersonChip(
                      person: person,
                      showDelete: true,
                      onTap: () => _removePerson(person),
                    )),
                ActionChip(
                  avatar: const Icon(Icons.add, size: 18),
                  label: const Text('Add Person'),
                  onPressed: _addPerson,
                ),
              ],
            ),
            const SizedBox(height: 24),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _sectionTitle(theme, 'Items'),
                if (_items.isNotEmpty && _people.isNotEmpty)
                  TextButton.icon(
                    onPressed: _assignAllEqually,
                    icon: const Icon(Icons.auto_awesome_rounded, size: 18),
                    label: const Text('Assign All Equally'),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            if (_items.isEmpty)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                ),
                child: Center(
                  child: Text(
                    'No items yet. Tap Add Item below.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ),
              )
            else
              ..._items.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Material(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                      child: ItemTile(
                        item: item,
                        onTap: () => _editItem(item),
                        onDelete: () {
                          setState(() {
                            _items.remove(item);
                          });
                        },
                      ),
                    ),
                  )),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _addItem,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add Item'),
            ),
            const SizedBox(height: 24),

            _sectionTitle(theme, 'Tax & Tip'),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _taxRateController,
                    decoration: const InputDecoration(labelText: 'Tax'),
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
                const SizedBox(width: 8),
                ToggleButtons(
                  isSelected: [_taxIsPercentage, !_taxIsPercentage],
                  onPressed: (index) {
                    setState(() {
                      _taxIsPercentage = index == 0;
                    });
                  },
                  children: const [Text('%'), Text('\$')],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _tipRateController,
                    decoration: const InputDecoration(labelText: 'Tip'),
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
                const SizedBox(width: 8),
                ToggleButtons(
                  isSelected: [_tipIsPercentage, !_tipIsPercentage],
                  onPressed: (index) {
                    setState(() {
                      _tipIsPercentage = index == 0;
                    });
                  },
                  children: const [Text('%'), Text('\$')],
                ),
              ],
            ),
            const SizedBox(height: 24),

            Material(
              color: theme.colorScheme.primaryContainer.withOpacity(0.4),
              borderRadius: BorderRadius.circular(AppTheme.cardRadius),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: [
                    _buildSummaryRow(theme, 'Subtotal', subtotal),
                    Divider(height: 24, color: theme.dividerColor),
                    _buildSummaryRow(theme, 'Tax', tax),
                    _buildSummaryRow(theme, 'Tip', tip),
                    Divider(height: 24, color: theme.dividerColor),
                    _buildSummaryRow(theme, 'Total', total, isTotal: true),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),

            ElevatedButton(
              onPressed: _calculateSplit,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Calculate Split'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(ThemeData theme, String title) {
    return Text(
      title,
      style: theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
      ),
    );
  }

  Widget _buildSummaryRow(ThemeData theme, String label, double amount, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontSize: isTotal ? 18 : 15,
              fontWeight: isTotal ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
          Text(
            Helpers.formatCurrency(amount),
            style: theme.textTheme.bodyLarge?.copyWith(
              fontSize: isTotal ? 18 : 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
