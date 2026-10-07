import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/providers.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _formKey = GlobalKey<FormState>();

  final _originController = TextEditingController();
  final _destinationController = TextEditingController(text: 'Nashik');
  final _daysController = TextEditingController(text: '1');
  final _travelersController = TextEditingController(text: '1');
  final _accessibilityController = TextEditingController();
  final _startDateController = TextEditingController();
  final _endDateController = TextEditingController();

  String _transportation = 'Train';
  String _budget = 'Medium';
  String _accommodation = 'No Preference';
  bool _includeReturn = false;
  bool _useDateRange = false;

  final List<String> _selectedInterests = [];

  final List<String> _interests = [
    'Spiritual Sites',
    'Temples',
    'Ghats',
    'Food',
    'Culture',
    'Shopping',
  ];

  final List<String> _transportationOptions = [
    'Train',
    'Bus',
    'Car',
    'Flight',
    'Walk/Public Mix',
  ];

  final List<String> _budgetOptions = [
    'Low',
    'Medium',
    'High',
  ];

  final List<String> _accommodationOptions = [
    'Hotel',
    'Asram',
    'Guest House',
    'No Preference',
  ];

  bool _isLoading = false;
  bool _hasPlan = false;
  bool _hasError = false;
  String _errorMessage = '';
  Map<String, dynamic> _planData = {};
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void dispose() {
    _originController.dispose();
    _destinationController.dispose();
    _daysController.dispose();
    _travelersController.dispose();
    _accessibilityController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    super.dispose();
  }

  Future<void> _selectStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFEA7A1A),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _startDate = picked;
        _startDateController.text =
            '${picked.day}/${picked.month}/${picked.year}';
      });
    }
  }

  Future<void> _selectEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: _startDate ?? DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFEA7A1A),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _endDate = picked;
        _endDateController.text =
            '${picked.day}/${picked.month}/${picked.year}';
      });
    }
  }

  void _toggleInterest(String interest) {
    setState(() {
      if (_selectedInterests.contains(interest)) {
        _selectedInterests.remove(interest);
      } else {
        _selectedInterests.add(interest);
      }
    });
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = '';
    });

    final formData = <String, dynamic>{
      'origin': _originController.text.trim(),
      'destination': _destinationController.text.trim(),
      'travelers': int.tryParse(_travelersController.text) ?? 1,
      'transportation': _transportation,
      'budget': _budget,
      'accommodation': _accommodation,
      'interests': _selectedInterests,
      'accessibility': _accessibilityController.text.trim(),
      'includeReturn': _includeReturn,
    };

    if (_useDateRange) {
      formData['startDate'] = _startDate?.toIso8601String();
      formData['endDate'] = _endDate?.toIso8601String();
    } else {
      formData['days'] = int.tryParse(_daysController.text) ?? 1;
    }

    try {
      final dioClient = ref.read(dioClientProvider);
      final response = await dioClient.postAIPlan(formData);

      if (response.statusCode == 200 &&
          response.data != null &&
          response.data['success'] == true) {
        setState(() {
          _planData = {
            'answer': response.data['answer'] ?? '',
            'planDetails': response.data['data']?['planDetails'] ?? formData,
          };
          _hasPlan = true;
        });
      } else {
        setState(() {
          _hasError = true;
          _errorMessage =
              'Plan generation unavailable. Please try again later.';
        });
      }
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Plan generation unavailable. Please try again later.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _startOver() {
    setState(() {
      _hasPlan = false;
      _hasError = false;
      _errorMessage = '';
      _planData = {};
    });
  }

  List<Map<String, dynamic>> _parseItineraryDays(String text) {
    final days = <Map<String, dynamic>>[];
    final lines = text.split('\n');
    String currentDay = '';
    String currentContent = '';
    int dayIndex = 0;

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;

      final dayMatch =
          RegExp(r'(Day\s*\d+|DAY\s*\d+|दिन\s*\d+)', caseSensitive: false)
              .firstMatch(trimmed);
      if (dayMatch != null) {
        if (currentDay.isNotEmpty) {
          days.add({
            'title': currentDay,
            'content': currentContent.trim(),
            'index': dayIndex++,
          });
        }
        currentDay = trimmed;
        currentContent = '';
      } else {
        currentContent += '$trimmed\n';
      }
    }

    if (currentDay.isNotEmpty && currentContent.trim().isNotEmpty) {
      days.add({
        'title': currentDay,
        'content': currentContent.trim(),
        'index': dayIndex++,
      });
    }

    if (days.isEmpty && text.trim().isNotEmpty) {
      days.add({
        'title': 'Itinerary',
        'content': text.trim(),
        'index': 0,
      });
    }

    return days;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Plan My Visit'),
        backgroundColor: const Color(0xFFEA7A1A),
        foregroundColor: Colors.white,
        actions: [
          if (_hasPlan)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _startOver,
              tooltip: 'Start Over',
            ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? _buildLoading()
            : _hasPlan
                ? _buildItinerary()
                : _buildForm(),
      ),
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 60,
            height: 60,
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFEA7A1A)),
              strokeWidth: 5,
            ),
          ),
          SizedBox(height: 24),
          Text(
            'Generating your personalized plan...',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'This may take a moment',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: const Color(0xFFEA7A1A).withValues(alpha: 0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Color(0xFFEA7A1A)),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Fill in your trip details and let AI plan your perfect Kumbh Mela visit.',
                      style: TextStyle(fontSize: 14, color: Colors.black87),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _buildSectionTitle('Trip Details'),
            const SizedBox(height: 12),
            TextFormField(
              controller: _originController,
              decoration: const InputDecoration(
                labelText: 'Traveling from (City/Town)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_on_outlined),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter your origin';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _destinationController,
              decoration: const InputDecoration(
                labelText: 'Destination (e.g. Nashik)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.place_outlined),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a destination';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Use date range instead of days'),
              subtitle: Text(
                _useDateRange
                    ? 'Pick start and end dates'
                    : 'Specify number of days',
                style: const TextStyle(fontSize: 12),
              ),
              value: _useDateRange,
              onChanged: (value) {
                setState(() {
                  _useDateRange = value;
                });
              },
              activeColor: const Color(0xFFEA7A1A),
              contentPadding: const EdgeInsets.symmetric(horizontal: 0),
            ),
            if (_useDateRange) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _startDateController,
                      readOnly: true,
                      onTap: _selectStartDate,
                      decoration: const InputDecoration(
                        labelText: 'Start Date',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.calendar_today),
                      ),
                      validator: (value) {
                        if (_useDateRange && (value == null || value.isEmpty)) {
                          return 'Pick start date';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _endDateController,
                      readOnly: true,
                      onTap: _selectEndDate,
                      decoration: const InputDecoration(
                        labelText: 'End Date',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.calendar_today),
                      ),
                      validator: (value) {
                        if (_useDateRange && (value == null || value.isEmpty)) {
                          return 'Pick end date';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
            ] else ...[
              const SizedBox(height: 8),
              TextFormField(
                controller: _daysController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Number of days',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.date_range),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Enter number of days';
                  }
                  final n = int.tryParse(value);
                  if (n == null || n <= 0) {
                    return 'Enter a valid number';
                  }
                  return null;
                },
              ),
            ],
            const SizedBox(height: 16),
            TextFormField(
              controller: _travelersController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Number of travelers',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.people_outline),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Enter traveler count';
                }
                final n = int.tryParse(value);
                if (n == null || n <= 0) {
                  return 'Enter a valid number';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            _buildSectionTitle('Preferences'),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _transportation,
              decoration: const InputDecoration(
                labelText: 'Transportation',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.directions_transit),
              ),
              items: _transportationOptions
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _transportation = value!;
                });
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _budget,
              decoration: const InputDecoration(
                labelText: 'Budget',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.account_balance_wallet_outlined),
              ),
              items: _budgetOptions
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _budget = value!;
                });
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _accommodation,
              decoration: const InputDecoration(
                labelText: 'Accommodation',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.hotel_outlined),
              ),
              items: _accommodationOptions
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _accommodation = value!;
                });
              },
            ),
            const SizedBox(height: 24),
            _buildSectionTitle('Interests'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _interests.map((interest) {
                final isSelected = _selectedInterests.contains(interest);
                return FilterChip(
                  label: Text(interest),
                  selected: isSelected,
                  onSelected: (_) => _toggleInterest(interest),
                  selectedColor: const Color(0xFFFFE0B2),
                  checkmarkColor: const Color(0xFFEA7A1A),
                  side: BorderSide(
                    color: isSelected
                        ? const Color(0xFFEA7A1A)
                        : Colors.grey.shade400,
                  ),
                  labelStyle: TextStyle(
                    color:
                        isSelected ? const Color(0xFFEA7A1A) : Colors.black87,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            _buildSectionTitle('Additional Details'),
            const SizedBox(height: 12),
            TextFormField(
              controller: _accessibilityController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Accessibility requirements (optional)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.accessibility_new),
                hintText: 'e.g. Wheelchair access, elderly assistance',
              ),
            ),
            const SizedBox(height: 16),
            CheckboxListTile(
              title: const Text('Include return planning'),
              subtitle: const Text(
                'Plan your return journey as well',
                style: TextStyle(fontSize: 12),
              ),
              value: _includeReturn,
              onChanged: (value) {
                setState(() {
                  _includeReturn = value ?? false;
                });
              },
              activeColor: const Color(0xFFEA7A1A),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: const EdgeInsets.symmetric(horizontal: 0),
            ),
            if (_hasError) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade300),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage,
                        style: const TextStyle(color: Colors.red, fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEA7A1A),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: const Text(
                  'Generate Plan',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildItinerary() {
    final answer = _planData['answer'] ?? '';
    final days = _parseItineraryDays(answer);
    final unavailableKeywords = [
      'unavailable',
      'not available',
      'not yet available',
      'cannot confirm',
      'no information',
      'please confirm',
      'verify',
      'schedule not',
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.shade400, width: 2),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: Icon(
                    Icons.info_outline,
                    color: Colors.orange,
                    size: 22,
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '⚠ This plan contains AI-generated recommendations.',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '✓ Verified official Kumbh schedule and transport details are not yet available.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                          height: 1.3,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Please confirm bookings and schedules with official sources.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ...days.map((day) => _buildDayCard(day, unavailableKeywords)),
          const SizedBox(height: 20),
          SizedBox(
            height: 48,
            child: OutlinedButton.icon(
              onPressed: _startOver,
              icon: const Icon(Icons.refresh, color: Color(0xFFEA7A1A)),
              label: const Text(
                'Start Over',
                style: TextStyle(
                  color: Color(0xFFEA7A1A),
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFEA7A1A), width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildDayCard(
      Map<String, dynamic> day, List<String> unavailableKeywords) {
    final content = day['content'] as String;
    final title = day['title'] as String;
    final lines =
        content.split('\n').where((l) => l.trim().isNotEmpty).toList();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFFFFF3E0),
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              border: Border(bottom: BorderSide(color: Color(0xFFFFCC80))),
            ),
            child: Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEA7A1A),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    title.toUpperCase().contains('DAY')
                        ? title.toUpperCase()
                        : title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: lines.map((line) {
                final lowerLine = line.toLowerCase();
                final hasUnavailable = unavailableKeywords.any(
                  (k) => lowerLine.contains(k),
                );
                final isVerified = lowerLine.contains('verified') ||
                    lowerLine.contains('official') ||
                    lowerLine.contains('✓');

                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (hasUnavailable) ...[
                            const Padding(
                              padding: EdgeInsets.only(top: 2),
                              child: Icon(
                                Icons.warning_amber_rounded,
                                color: Colors.red,
                                size: 16,
                              ),
                            ),
                            const SizedBox(width: 6),
                          ] else if (isVerified) ...[
                            Container(
                              margin: const EdgeInsets.only(top: 2),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                color: Colors.green.shade100,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                '✓ VERIFIED',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                          ] else ...[
                            Container(
                              margin: const EdgeInsets.only(top: 2),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: Colors.blue.shade200),
                              ),
                              child: Text(
                                'AI recommendation',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                          ],
                          Expanded(
                            child: Text(
                              line,
                              style: TextStyle(
                                fontSize: 14,
                                height: 1.5,
                                fontWeight: hasUnavailable
                                    ? FontWeight.w700
                                    : FontWeight.normal,
                                color: hasUnavailable
                                    ? Colors.red.shade800
                                    : Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
