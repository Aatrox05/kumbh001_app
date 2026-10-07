import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../app/providers.dart';

class AuthorityResponderScreen extends ConsumerStatefulWidget {
  const AuthorityResponderScreen({super.key});

  @override
  ConsumerState<AuthorityResponderScreen> createState() =>
      _AuthorityResponderScreenState();
}

class _AuthorityResponderScreenState
    extends ConsumerState<AuthorityResponderScreen> {
  bool _isAuthenticated = false;
  bool _isLoading = false;
  String _activeFilter = 'ALL';
  String _userRole = '';
  String _userName = '';

  final _usernameController = TextEditingController(text: 'police_control');
  final _passwordController = TextEditingController(text: 'PoliceDuty2027!');

  List<Map<String, dynamic>> _sosAlerts = [];
  String? _errorMessage;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login([String? username, String? password]) async {
    final u = username ?? _usernameController.text.trim();
    final p = password ?? _passwordController.text.trim();

    if (u.isEmpty || p.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter username and password')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final dio = ref.read(dioClientProvider);
      final response = await dio.login(u, p);

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        final token = data['token'] as String?;
        final user = data['user'] as Map<String, dynamic>?;

        dio.setAuthToken(token);

        setState(() {
          _isAuthenticated = true;
          _userRole = user?['role'] ?? 'OFFICER';
          _userName = user?['name'] ?? u;
        });

        await _fetchAlerts();
      } else {
        setState(() {
          _errorMessage = 'Invalid authority credentials';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Login failed: Could not connect to Central Command.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _logout() {
    ref.read(dioClientProvider).setAuthToken(null);
    setState(() {
      _isAuthenticated = false;
      _sosAlerts = [];
      _userRole = '';
      _userName = '';
    });
  }

  Future<void> _fetchAlerts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final dio = ref.read(dioClientProvider);
      final filterStatus = _activeFilter == 'ALL' ? null : _activeFilter;
      final response = await dio.getSOSList(status: filterStatus);

      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> list = response.data['data'] ?? [];
        setState(() {
          _sosAlerts = list.map((e) => Map<String, dynamic>.from(e)).toList();
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load live SOS alerts: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _updateAlertStatus(int id, String newStatus) async {
    final remarksController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Update Incident #$id Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Setting status to $newStatus.'),
            const SizedBox(height: 12),
            TextField(
              controller: remarksController,
              decoration: const InputDecoration(
                labelText: 'Operational Remarks',
                hintText: 'e.g. PCR Unit 4 deployed to Ramkund North gate',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF7A00),
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final dio = ref.read(dioClientProvider);
      final res = await dio.updateSOSStatus(
        id,
        newStatus,
        remarks: remarksController.text.trim().isNotEmpty
            ? remarksController.text.trim()
            : null,
      );

      if (res.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Incident #$id updated to $newStatus')),
          );
        }
        await _fetchAlerts();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Update failed: $e')),
        );
      }
    }
  }

  Future<void> _callPilgrim(String? phone) async {
    if (phone == null || phone.isEmpty) return;
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _navigateToLocation(double? lat, double? lng) async {
    if (lat == null || lng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('GPS coordinates not available for this alert')),
      );
      return;
    }
    final uri = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF6E9),
      appBar: AppBar(
        title: const Text('Authority SOS Command Desk'),
        backgroundColor: const Color(0xFFB71C1C),
        foregroundColor: Colors.white,
        actions: [
          if (_isAuthenticated) ...[
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _fetchAlerts,
              tooltip: 'Refresh Incidents',
            ),
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: _logout,
              tooltip: 'Logout',
            ),
          ],
        ],
      ),
      body: SafeArea(
        child: _isAuthenticated ? _buildDashboard() : _buildLoginForm(),
      ),
    );
  }

  Widget _buildLoginForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 20),
          Center(
            child: CircleAvatar(
              radius: 40,
              backgroundColor: const Color(0xFFB71C1C).withValues(alpha: 0.12),
              child: const Icon(Icons.shield, size: 48, color: Color(0xFFB71C1C)),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Official Responder Portal',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Restricted access for Nashik Police, Disaster Management, and Medical Response teams.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.black54),
          ),
          const SizedBox(height: 28),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 3)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _usernameController,
                  decoration: const InputDecoration(
                    labelText: 'Officer Username / ID',
                    prefixIcon: Icon(Icons.person),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    prefixIcon: Icon(Icons.lock),
                    border: OutlineInputBorder(),
                  ),
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red, fontSize: 13),
                  ),
                ],
                const SizedBox(height: 20),
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : () => _login(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFB71C1C),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Sign In to Command Desk',
                            style: TextStyle(
                                fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'QUICK VERIFIED DEMO LOGINS',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.black54,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              ActionChip(
                avatar: const Icon(Icons.local_police, size: 16),
                label: const Text('Police Control'),
                onPressed: () => _login('police_control', 'PoliceDuty2027!'),
              ),
              ActionChip(
                avatar: const Icon(Icons.medical_services, size: 16),
                label: const Text('Medical Control'),
                onPressed: () => _login('medical_control', 'MedicalDuty2027!'),
              ),
              ActionChip(
                avatar: const Icon(Icons.admin_panel_settings, size: 16),
                label: const Text('Disaster Admin'),
                onPressed: () => _login('admin', 'KumbhAdmin2027!'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDashboard() {
    return Column(
      children: [
        // Responder Badge Banner
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: const Color(0xFFB71C1C),
          child: Row(
            children: [
              const CircleAvatar(
                backgroundColor: Colors.white24,
                child: Icon(Icons.verified_user, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _userName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      'Role: $_userRole · Central Incident Dispatch',
                      style: const TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_sosAlerts.length} Alerts',
                  style: const TextStyle(
                    color: Color(0xFFB71C1C),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Filter Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: Colors.white,
          child: Row(
            children: [
              _buildFilterChip('ALL'),
              const SizedBox(width: 8),
              _buildFilterChip('RECEIVED'),
              const SizedBox(width: 8),
              _buildFilterChip('DISPATCHED'),
              const SizedBox(width: 8),
              _buildFilterChip('RESOLVED'),
            ],
          ),
        ),

        // Incidents List
        Expanded(
          child: RefreshIndicator(
            onRefresh: _fetchAlerts,
            child: _isLoading && _sosAlerts.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : _sosAlerts.isEmpty
                    ? const Center(
                        child: Text(
                          'No emergency alerts matching current filter.',
                          style: TextStyle(color: Colors.black54),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _sosAlerts.length,
                        itemBuilder: (context, index) {
                          final alert = _sosAlerts[index];
                          return _buildIncidentCard(alert);
                        },
                      ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String filter) {
    final isSelected = _activeFilter == filter;
    return InkWell(
      onTap: () {
        setState(() {
          _activeFilter = filter;
        });
        _fetchAlerts();
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFB71C1C) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          filter,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }

  Widget _buildIncidentCard(Map<String, dynamic> alert) {
    final int id = alert['id'] ?? 0;
    final String status = alert['status'] ?? 'RECEIVED';
    final String contactName = alert['contact_name'] ?? 'Anonymous Pilgrim';
    final String contactPhone = alert['contact_phone'] ?? '';
    final double? lat = (alert['latitude'] as num?)?.toDouble();
    final double? lng = (alert['longitude'] as num?)?.toDouble();
    final String remarks = alert['remarks'] ?? '';
    final String time = alert['created_at'] ?? '';

    Color statusColor;
    if (status == 'RESOLVED') {
      statusColor = Colors.green.shade700;
    } else if (status == 'DISPATCHED') {
      statusColor = Colors.orange.shade800;
    } else {
      statusColor = Colors.red.shade700;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(color: statusColor, width: 4),
        ),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'INCIDENT #$id',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Colors.black87,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.person, size: 16, color: Colors.black54),
              const SizedBox(width: 6),
              Text(
                contactName,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              const Spacer(),
              if (time.isNotEmpty)
                Text(
                  time.length > 16 ? time.substring(0, 16) : time,
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.phone, size: 16, color: Colors.black54),
              const SizedBox(width: 6),
              Text(
                contactPhone.isNotEmpty ? contactPhone : 'No phone provided',
                style: const TextStyle(fontSize: 13, color: Colors.black87),
              ),
            ],
          ),
          if (lat != null && lng != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.location_on, size: 16, color: Colors.red),
                const SizedBox(width: 6),
                Text(
                  'GPS: ${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}',
                  style: const TextStyle(fontSize: 12, color: Colors.black87),
                ),
              ],
            ),
          ],
          if (remarks.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                remarks,
                style: const TextStyle(fontSize: 12, color: Colors.black87),
              ),
            ),
          ],
          const SizedBox(height: 12),
          // Action Buttons: Call, Navigate, Transition Status
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (contactPhone.isNotEmpty)
                OutlinedButton.icon(
                  onPressed: () => _callPilgrim(contactPhone),
                  icon: const Icon(Icons.call, size: 14),
                  label: const Text('Call Pilgrim'),
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    foregroundColor: Colors.green.shade800,
                  ),
                ),
              if (lat != null && lng != null)
                OutlinedButton.icon(
                  onPressed: () => _navigateToLocation(lat, lng),
                  icon: const Icon(Icons.navigation, size: 14),
                  label: const Text('Navigate'),
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    foregroundColor: Colors.blue.shade800,
                  ),
                ),
              if (status == 'RECEIVED')
                ElevatedButton.icon(
                  onPressed: () => _updateAlertStatus(id, 'DISPATCHED'),
                  icon: const Icon(Icons.send, size: 14),
                  label: const Text('Dispatch Team'),
                  style: ElevatedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    backgroundColor: Colors.orange.shade800,
                    foregroundColor: Colors.white,
                  ),
                ),
              if (status == 'DISPATCHED' || status == 'RECEIVED')
                ElevatedButton.icon(
                  onPressed: () => _updateAlertStatus(id, 'RESOLVED'),
                  icon: const Icon(Icons.check, size: 14),
                  label: const Text('Mark Resolved'),
                  style: ElevatedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    backgroundColor: Colors.green.shade700,
                    foregroundColor: Colors.white,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
