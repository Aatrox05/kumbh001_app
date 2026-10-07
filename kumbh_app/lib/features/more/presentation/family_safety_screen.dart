import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kumbh_app/app/providers.dart';

class FamilySafetyScreen extends ConsumerStatefulWidget {
  const FamilySafetyScreen({super.key});

  @override
  ConsumerState<FamilySafetyScreen> createState() => _FamilySafetyScreenState();
}

class _FamilySafetyScreenState extends ConsumerState<FamilySafetyScreen> {
  @override
  Widget build(BuildContext context) {
    final members = ref.watch(contactsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFFF6E9),
      appBar: AppBar(
        title: const Text('Family Safety'),
        backgroundColor: const Color(0xFFFF7A00),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(left: 16, right: 16, bottom: 100),
          children: [
            const SizedBox(height: 12),
            const Row(
              children: [
                CircleAvatar(backgroundColor: Color(0xFFFF7A00), child: Icon(Icons.group, color: Colors.white)),
                SizedBox(width: 8),
                CircleAvatar(backgroundColor: Color(0xFFFF7A00), child: Icon(Icons.person, color: Colors.white)),
                SizedBox(width: 8),
                CircleAvatar(backgroundColor: Color(0xFFFF7A00), child: Icon(Icons.person_outline, color: Colors.white)),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Trusted Contacts',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
              ),
              child: members.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(20.0),
                      child: Center(
                        child: Text(
                          'No family safety contacts added.\nAdd trusted contacts who will receive emergency distress alerts.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.black54),
                        ),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: members.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final m = members[index];
                        return ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: Color(0xFFEEEEEE),
                            child: Icon(Icons.person, color: Colors.grey),
                          ),
                          title: Text(m.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text(m.phone),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                            onPressed: () async {
                              if (m.id != null) {
                                await ref.read(contactsProvider.notifier).deleteContact(m.id!);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Contact deleted')),
                                  );
                                }
                              }
                            },
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF7A00),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  elevation: 4,
                ),
                onPressed: _addMemberDialog,
                child: const Text('ADD member', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addMemberDialog() {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('Add member'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(decoration: const InputDecoration(labelText: 'Name'), controller: nameController),
              TextField(decoration: const InputDecoration(labelText: 'Phone'), controller: phoneController, keyboardType: TextInputType.phone),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final name = nameController.text.trim();
                final phone = phoneController.text.trim();
                if (name.isNotEmpty && phone.isNotEmpty) {
                  await ref.read(contactsProvider.notifier).addContact(name, phone);
                  if (mounted) {
                    Navigator.pop(context);
                  }
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }
}
