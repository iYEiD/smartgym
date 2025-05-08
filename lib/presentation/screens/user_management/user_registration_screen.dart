import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartgymai/core/constants/mqtt_constants.dart';
import 'package:smartgymai/core/theme/app_theme.dart';
import 'package:smartgymai/domain/entities/user.dart';
import 'package:uuid/uuid.dart';

class UserRegistrationScreen extends ConsumerStatefulWidget {
  final String? rfidId;

  const UserRegistrationScreen({
    Key? key,
    this.rfidId,
  }) : super(key: key);

  @override
  ConsumerState<UserRegistrationScreen> createState() => _UserRegistrationScreenState();
}

class _UserRegistrationScreenState extends ConsumerState<UserRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  
  String _membershipType = 'Standard';
  String? _rfidId;
  bool _isWaitingForRfid = false;
  bool _isSubmitting = false;
  
  StreamSubscription? _rfidSubscription;
  
  final List<String> _membershipTypes = [
    'Basic',
    'Standard',
    'Premium',
  ];

  @override
  void initState() {
    super.initState();
    _rfidId = widget.rfidId;
    
    if (_rfidId == null) {
      // In a real app, this would listen to MQTT for RFID scan events
      _startListeningForRfid();
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _rfidSubscription?.cancel();
    super.dispose();
  }

  void _startListeningForRfid() {
    setState(() {
      _isWaitingForRfid = true;
    });
    
    // In a real app, this would subscribe to the MQTT topic
    // For this demo, we'll simulate an RFID scan after 3 seconds
    _rfidSubscription = Stream.periodic(const Duration(seconds: 3), (i) => i)
        .take(1)
        .listen((_) {
          // Simulate receiving an RFID
          _onRfidReceived('${const Uuid().v4().substring(0, 8)}');
        });
  }

  void _stopListeningForRfid() {
    _rfidSubscription?.cancel();
    _rfidSubscription = null;
    
    setState(() {
      _isWaitingForRfid = false;
    });
  }

  void _onRfidReceived(String rfidId) {
    setState(() {
      _rfidId = rfidId;
      _isWaitingForRfid = false;
    });
    
    // In a real app, this would check if the RFID already exists
    // by calling your repository
    _checkRfidExists(rfidId);
  }

  Future<void> _checkRfidExists(String rfidId) async {
    // In a real app, this would query your repository
    // For this demo, we'll simulate that the RFID is new
    
    // Simulate a check
    await Future.delayed(const Duration(milliseconds: 500));
    
    // For demo purposes, let's assume it's a new RFID
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('New RFID card detected: $_rfidId'),
          backgroundColor: AppTheme.infoColor,
        ),
      );
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate() || _rfidId == null) {
      return;
    }
    
    setState(() {
      _isSubmitting = true;
    });
    
    // In a real app, this would create a new user in your repository
    // For this demo, we'll simulate the registration process
    
    final user = User(
      id: _rfidId!,
      firstName: _firstNameController.text,
      lastName: _lastNameController.text,
      email: _emailController.text,
      phone: _phoneController.text,
      membershipType: _membershipType,
      registrationDate: DateTime.now(),
    );
    
    // Simulate registration delay
    await Future.delayed(const Duration(seconds: 1));
    
    setState(() {
      _isSubmitting = false;
    });
    
    if (!mounted) return;
    
    // Show success message and return to the previous screen
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('User ${user.fullName} registered successfully'),
        backgroundColor: AppTheme.successColor,
      ),
    );
    
    Navigator.of(context).pop(user);
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _firstNameController.clear();
    _lastNameController.clear();
    _emailController.clear();
    _phoneController.clear();
    
    setState(() {
      _membershipType = 'Standard';
      _rfidId = null;
      _isWaitingForRfid = false;
    });
    
    _startListeningForRfid();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Registration'),
      ),
      body: _isSubmitting
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildRfidSection(),
                    const SizedBox(height: 24),
                    _buildPersonalInfoSection(),
                    const SizedBox(height: 24),
                    _buildMembershipSection(),
                    const SizedBox(height: 32),
                    _buildActionButtons(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildRfidSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.nfc),
                const SizedBox(width: 8),
                Text(
                  'RFID Card',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_isWaitingForRfid)
              Center(
                child: Column(
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(
                      'Waiting for RFID card...',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Please scan a card on the reader',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.onSurfaceColor.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton.icon(
                      onPressed: _stopListeningForRfid,
                      icon: const Icon(Icons.cancel),
                      label: const Text('Cancel'),
                    ),
                  ],
                ),
              )
            else if (_rfidId != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Card ID',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.onSurfaceColor.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppTheme.primaryColor.withOpacity(0.5),
                            ),
                          ),
                          child: Text(
                            _rfidId!,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () {
                          setState(() {
                            _rfidId = null;
                          });
                          _startListeningForRfid();
                        },
                        icon: const Icon(Icons.refresh),
                        tooltip: 'Scan again',
                      ),
                    ],
                  ),
                ],
              )
            else
              Center(
                child: ElevatedButton.icon(
                  onPressed: _startListeningForRfid,
                  icon: const Icon(Icons.nfc),
                  label: const Text('Scan RFID Card'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalInfoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.person_outline),
                const SizedBox(width: 8),
                Text(
                  'Personal Information',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _firstNameController,
              decoration: const InputDecoration(
                labelText: 'First Name',
                hintText: 'John',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter first name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _lastNameController,
              decoration: const InputDecoration(
                labelText: 'Last Name',
                hintText: 'Doe',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter last name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email Address',
                hintText: 'john.doe@example.com',
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return null; // Email is optional
                }
                // Basic email validation
                if (!value.contains('@') || !value.contains('.')) {
                  return 'Please enter a valid email address';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                hintText: '(123) 456-7890',
              ),
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return null; // Phone is optional
                }
                // Here you could add phone number validation if needed
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMembershipSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.card_membership),
                const SizedBox(width: 8),
                Text(
                  'Membership Type',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _membershipType,
              decoration: const InputDecoration(
                labelText: 'Select Membership Type',
              ),
              items: _membershipTypes.map((type) {
                return DropdownMenuItem<String>(
                  value: type,
                  child: Text(type),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _membershipType = value;
                  });
                }
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please select a membership type';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: _rfidId == null ? null : _submitForm,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('Register User'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: OutlinedButton(
            onPressed: _resetForm,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('Reset Form'),
          ),
        ),
      ],
    );
  }
} 