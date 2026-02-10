import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/group.dart';
import '../providers/group_provider.dart';
import '../providers/premium_provider.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';

class GroupsScreen extends StatelessWidget {
  const GroupsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Groups'),
      ),
      body: Consumer2<GroupProvider, PremiumProvider>(
        builder: (context, groupProvider, premiumProvider, child) {
          if (groupProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final canCreateMore = premiumProvider.canCreateGroup(groupProvider.groups.length);

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
            children: [
              if (!premiumProvider.isPremium)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
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
                              'Free: ${groupProvider.groups.length}/${AppConstants.maxFreeGroups} groups',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              if (groupProvider.groups.isEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.group_rounded, size: 48, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.35)),
                      const SizedBox(height: 16),
                      Text(
                        'No groups yet',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Create a group to quickly load people when splitting bills.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.55),
                        ),
                      ),
                    ],
                  ),
                )
              else
                ...groupProvider.groups.map((group) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Material(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          title: Text(group.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text('${group.members.length} members', style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_rounded),
                                onPressed: () => _editGroup(context, group),
                              ),
                              IconButton(
                                icon: Icon(Icons.delete_outline_rounded, color: Theme.of(context).colorScheme.error),
                                onPressed: () => _deleteGroup(context, groupProvider, group.id),
                              ),
                            ],
                          ),
                          onTap: () => _viewGroup(context, group),
                        ),
                      ),
                    )),
            ],
          );
        },
      ),
      floatingActionButton: Consumer2<GroupProvider, PremiumProvider>(
        builder: (context, groupProvider, premiumProvider, child) {
          final canCreateMore = premiumProvider.canCreateGroup(groupProvider.groups.length);
          return FloatingActionButton.extended(
            onPressed: canCreateMore ? () => _createGroup(context) : null,
            tooltip: canCreateMore ? 'Create Group' : 'Upgrade to Premium for more groups',
            icon: const Icon(Icons.add_rounded),
            label: const Text('New Group'),
          );
        },
      ),
    );
  }

  void _createGroup(BuildContext context) {
    final nameController = TextEditingController();
    final members = <String>[];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Create Group'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Group Name',
                        hintText: 'e.g., Office Lunch Crew',
                      ),
                      autofocus: true,
                    ),
                    const SizedBox(height: 16),
                    const Text('Members:'),
                    const SizedBox(height: 8),
                    ...members.map((member) => ListTile(
                          title: Text(member),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () {
                              setDialogState(() {
                                members.remove(member);
                              });
                            },
                          ),
                        )),
                    TextButton.icon(
                      onPressed: () {
                        final memberController = TextEditingController();
                        showDialog(
                          context: context,
                          builder: (innerContext) => AlertDialog(
                            title: const Text('Add Member'),
                            content: TextField(
                              controller: memberController,
                              decoration: const InputDecoration(
                                labelText: 'Member Name',
                              ),
                              autofocus: true,
                              onSubmitted: (_) {
                                if (memberController.text.trim().isNotEmpty) {
                                  setDialogState(() {
                                    members.add(memberController.text.trim());
                                  });
                                  Navigator.pop(innerContext);
                                }
                              },
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(innerContext),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () {
                                  if (memberController.text.trim().isNotEmpty) {
                                    setDialogState(() {
                                      members.add(memberController.text.trim());
                                    });
                                    Navigator.pop(innerContext);
                                  }
                                },
                                child: const Text('Add'),
                              ),
                            ],
                          ),
                        );
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Add Member'),
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
                  onPressed: () async {
                    if (nameController.text.trim().isNotEmpty) {
                      final groupProvider = Provider.of<GroupProvider>(context, listen: false);
                      final premiumProvider = Provider.of<PremiumProvider>(context, listen: false);

                      if (!premiumProvider.canCreateGroup(groupProvider.groups.length)) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Group limit reached. Upgrade to Premium.'),
                            ),
                          );
                        }
                        return;
                      }

                      if (members.any((m) => !premiumProvider.canAddMemberToGroup(members.length))) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Member limit reached. Upgrade to Premium.'),
                            ),
                          );
                        }
                        return;
                      }

                      final success = await groupProvider.createGroup(
                        nameController.text.trim(),
                        members,
                      );

                      if (context.mounted) {
                        Navigator.pop(context);
                        if (!success) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Failed to create group. Check limits.'),
                            ),
                          );
                        }
                      }
                    }
                  },
                  child: const Text('Create'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _editGroup(BuildContext context, Group group) {
    final nameController = TextEditingController(text: group.name);
    final members = List<String>.from(group.members);

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Edit Group'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Group Name'),
                    ),
                    const SizedBox(height: 16),
                    const Text('Members:'),
                    const SizedBox(height: 8),
                    ...members.map((member) => ListTile(
                          title: Text(member),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () {
                              setDialogState(() {
                                members.remove(member);
                              });
                            },
                          ),
                        )),
                    TextButton.icon(
                      onPressed: () {
                        final memberController = TextEditingController();
                        showDialog(
                          context: context,
                          builder: (innerContext) => AlertDialog(
                            title: const Text('Add Member'),
                            content: TextField(
                              controller: memberController,
                              decoration: const InputDecoration(labelText: 'Member Name'),
                              autofocus: true,
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(innerContext),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () {
                                  if (memberController.text.trim().isNotEmpty) {
                                    setDialogState(() {
                                      members.add(memberController.text.trim());
                                    });
                                    Navigator.pop(innerContext);
                                  }
                                },
                                child: const Text('Add'),
                              ),
                            ],
                          ),
                        );
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Add Member'),
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
                  onPressed: () async {
                    if (nameController.text.trim().isNotEmpty) {
                      final groupProvider = Provider.of<GroupProvider>(context, listen: false);
                      final premiumProvider = Provider.of<PremiumProvider>(context, listen: false);

                      if (!premiumProvider.isPremium &&
                          members.length > AppConstants.maxFreeGroupMembers) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Member limit reached. Upgrade to Premium.'),
                            ),
                          );
                        }
                        return;
                      }

                      final updatedGroup = group.copyWith(
                        name: nameController.text.trim(),
                        members: members,
                      );

                      final success = await groupProvider.updateGroup(updatedGroup);

                      if (context.mounted) {
                        Navigator.pop(context);
                        if (!success) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Failed to update group')),
                          );
                        }
                      }
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

  void _viewGroup(BuildContext context, Group group) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(group.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Members (${group.members.length}):'),
            const SizedBox(height: 8),
            ...group.members.map((member) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text('• $member'),
                )),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _deleteGroup(BuildContext context, GroupProvider groupProvider, String groupId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Group'),
        content: const Text('Are you sure you want to delete this group?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              groupProvider.deleteGroup(groupId);
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
