import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kumbh_app/app/providers.dart';
import '../data/lost_found_report_model.dart';

class LostFoundScreen extends ConsumerStatefulWidget {
  const LostFoundScreen({super.key});

  @override
  ConsumerState<LostFoundScreen> createState() => _LostFoundScreenState();
}

class _LostFoundScreenState extends ConsumerState<LostFoundScreen> {
  int tabIndex = 0;
  final _formKey = GlobalKey<FormState>();

  final nameController = TextEditingController();
  final ageController = TextEditingController();
  String gender = 'select';
  final locationController = TextEditingController();
  final contactController = TextEditingController();
  final descController = TextEditingController();

  XFile? _pickedImage;
  String? _storedBase64;
  bool _uploading = false;

  @override
  void dispose() {
    nameController.dispose();
    ageController.dispose();
    locationController.dispose();
    contactController.dispose();
    descController.dispose();
    super.dispose();
  }

  void _clearForm() {
    nameController.clear();
    ageController.clear();
    locationController.clear();
    contactController.clear();
    descController.clear();
    setState(() {
      gender = 'select';
      _pickedImage = null;
      _storedBase64 = null;
      _uploading = false;
    });
  }

  Future<void> _showImagePickerOptions() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Upload Photo',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF6E9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Text('📷', style: TextStyle(fontSize: 24)),
                    ),
                  ),
                  title: const Text(
                    'Take Photo',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text('Open camera to capture a new photo'),
                  onTap: () async {
                    Navigator.of(context).pop();
                    await _pickImage(ImageSource.camera);
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF6E9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Text('🖼', style: TextStyle(fontSize: 24)),
                    ),
                  ),
                  title: const Text(
                    'Choose from Gallery',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text('Select an existing photo from gallery'),
                  onTap: () async {
                    Navigator.of(context).pop();
                    await _pickImage(ImageSource.gallery);
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(
        source: source,
        imageQuality: 85,
      );

      if (image == null) return;

      final int fileSize = await image.length();
      const int maxSize = 10 * 1024 * 1024;

      if (fileSize > maxSize) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Image file is too large. Max 10MB.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      setState(() {
        _pickedImage = image;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Permission required to access photos. Please enable in your device settings.',
            ),
          ),
        );
      }
    }
  }

  Future<void> _replaceImage() async {
    await _showImagePickerOptions();
  }

  void _deleteImage() {
    setState(() {
      _pickedImage = null;
      _storedBase64 = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final reports = ref.watch(lostFoundNotifierProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFFF6E9),
      appBar: AppBar(
        title: const Text('Lost & Found'),
        backgroundColor: const Color(0xFFFF7A00),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(left: 16, right: 16, bottom: 100),
          children: [
            const SizedBox(height: 12),
            _SegmentedTabs(
              index: tabIndex,
              onChanged: (i) => setState(() => tabIndex = i),
            ),
            const SizedBox(height: 16),
            _ReportCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tabIndex == 0 ? 'Report Lost Person' : 'Report Found/Safe Person',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        _TextField(controller: nameController, label: 'Full Name', hint: 'Enter full name'),
                        Row(
                          children: [
                            Expanded(
                              child: _TextField(
                                controller: ageController,
                                label: 'Age',
                                hint: 'Age',
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _Dropdown(
                                label: 'Gender',
                                value: gender,
                                items: const ['select', 'Male', 'Female', 'Other'],
                                onChanged: (v) => setState(() => gender = v ?? 'select'),
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: _TextField(
                                controller: locationController,
                                label: 'Last Seen Location',
                                hint: 'Last seen location',
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _TextField(
                                controller: contactController,
                                label: 'Contact Number',
                                hint: 'Enter contact',
                                keyboardType: TextInputType.phone,
                              ),
                            ),
                          ],
                        ),
                        _TextField(
                          controller: descController,
                          label: 'Description',
                          hint: 'Enter any information related to this person...',
                          maxLines: 3,
                        ),
                        const SizedBox(height: 8),
                        _UploadRow(
                          pickedImage: _pickedImage,
                          uploading: _uploading,
                          onPick: _showImagePickerOptions,
                          onReplace: _replaceImage,
                          onDelete: _deleteImage,
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 48,
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFF5722),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              elevation: 4,
                            ),
                            onPressed: () async {
                              final name = nameController.text.trim();
                              final ageText = ageController.text.trim();
                              final loc = locationController.text.trim();
                              final contact = contactController.text.trim();
                              final desc = descController.text.trim();

                              if (name.isEmpty || ageText.isEmpty || contact.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Please fill all required fields')),
                                );
                                return;
                              }

                              String? imageBase64;
                              if (_pickedImage != null) {
                                setState(() {
                                  _uploading = true;
                                });
                                try {
                                  final bytes = await _pickedImage!.readAsBytes();
                                  imageBase64 = base64.encode(bytes);
                                  _storedBase64 = imageBase64;
                                } catch (e) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Failed to process image')),
                                    );
                                  }
                                } finally {
                                  if (mounted) {
                                    setState(() {
                                      _uploading = false;
                                    });
                                  }
                                }
                              }

                              final report = LostFoundReport(
                                name: name,
                                age: int.tryParse(ageText) ?? 0,
                                gender: gender,
                                location: loc,
                                contact: contact,
                                description: desc,
                                isLost: tabIndex == 0,
                                imageBase64: imageBase64,
                              );

                              final messenger = ScaffoldMessenger.of(context);
                              await ref.read(lostFoundNotifierProvider.notifier).addReport(report);
                              _clearForm();

                              messenger.showSnackBar(
                                const SnackBar(
                                  content: Text('Report saved offline and queued for synchronization'),
                                ),
                              );
                            },
                            child: _uploading
                                ? const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                        ),
                                      ),
                                      SizedBox(width: 12),
                                      Text(
                                        'Processing...',
                                        style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white),
                                      ),
                                    ],
                                  )
                                : const Text(
                                    'Submit Report',
                                    style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            if (reports.isNotEmpty) ...[
              const Text(
                'My Submissions',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: reports.length,
                itemBuilder: (context, index) {
                  final r = reports[index];
                  return Card(
                    color: Colors.white,
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: r.imageBase64 != null && r.imageBase64!.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: Container(
                                width: 48,
                                height: 48,
                                color: const Color(0xFFFFF6E9),
                                child: const Icon(
                                  Icons.image,
                                  color: Color(0xFFFF7A00),
                                  size: 24,
                                ),
                              ),
                            )
                          : null,
                      title: Text(r.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text('${r.isLost ? "Lost" : "Found/Safe"} · ${r.location}'),
                      trailing: Icon(
                        r.synced ? Icons.cloud_done : Icons.cloud_off,
                        color: r.synced ? Colors.green : Colors.orange,
                      ),
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _UploadRow extends StatelessWidget {
  final XFile? pickedImage;
  final bool uploading;
  final VoidCallback onPick;
  final VoidCallback onReplace;
  final VoidCallback onDelete;

  const _UploadRow({
    required this.pickedImage,
    required this.uploading,
    required this.onPick,
    required this.onReplace,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (pickedImage != null) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(
              File(pickedImage!.path),
              width: 120,
              height: 120,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                const Text(
                  'Photo selected',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  pickedImage!.name,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: uploading ? null : onReplace,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFFF7A00)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                        icon: const Icon(
                          Icons.refresh,
                          size: 18,
                          color: Color(0xFFFF7A00),
                        ),
                        label: const Text(
                          'Replace',
                          style: TextStyle(
                            color: Color(0xFFFF7A00),
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: uploading ? null : onDelete,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.red),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                        icon: const Icon(
                          Icons.delete_outline,
                          size: 18,
                          color: Colors.red,
                        ),
                        label: const Text(
                          'Delete',
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      );
    }

    return InkWell(
      onTap: uploading ? null : onPick,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: const Color(0xFFFF7A00),
            style: BorderStyle.solid,
          ),
          color: const Color(0xFFFF7A00).withValues(alpha: 0.04),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.upload, color: Color(0xFFFF7A00)),
            const SizedBox(width: 8),
            Text(
              uploading ? 'Processing image...' : 'Upload Photo',
              style: const TextStyle(
                color: Color(0xFFFF7A00),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SegmentedTabs extends StatelessWidget {
  final int index;
  final ValueChanged<int> onChanged;
  const _SegmentedTabs({required this.index, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () => onChanged(0),
              borderRadius: BorderRadius.circular(24),
              child: Container(
                decoration: BoxDecoration(
                  color: index == 0 ? const Color(0xFFFF7A00).withValues(alpha: 0.08) : Colors.transparent,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Center(
                  child: Text(
                    'Report lost',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: index == 0 ? const Color(0xFFFF7A00) : Colors.black54,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: InkWell(
              onTap: () => onChanged(1),
              borderRadius: BorderRadius.circular(24),
              child: Container(
                decoration: BoxDecoration(
                  color: index == 1 ? const Color(0xFFFF7A00).withValues(alpha: 0.08) : Colors.transparent,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Center(
                  child: Text(
                    'Safe/Found',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: index == 1 ? const Color(0xFFFF7A00) : Colors.black54,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final Widget child;
  const _ReportCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8)],
        border: Border.all(color: Colors.black12),
      ),
      child: child,
    );
  }
}

class _TextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final TextInputType? keyboardType;
  final int maxLines;
  const _TextField({
    required this.controller,
    required this.label,
    required this.hint,
    this.keyboardType,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            decoration: InputDecoration(
              hintText: hint,
              filled: true,
              fillColor: const Color(0xFFF9F9F9),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.black26),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.black26),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Dropdown extends StatelessWidget {
  final String label;
  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;
  const _Dropdown({required this.label, required this.value, required this.items, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF9F9F9),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.black26),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              items: items
                  .map((e) => DropdownMenuItem<String>(
                        value: e,
                        child: Text(e),
                      ))
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}
