import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartgymai/core/config/app_config.dart';
import 'package:smartgymai/core/theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // MQTT settings
  final _mqttHostController = TextEditingController();
  final _mqttPortController = TextEditingController();
  bool _mqttUseSecure = false;
  
  // Database settings
  final _dbHostController = TextEditingController();
  final _dbPortController = TextEditingController();
  final _dbNameController = TextEditingController();
  final _dbUserController = TextEditingController();
  final _dbPasswordController = TextEditingController();
  bool _dbUseSecure = false;
  
  // Gym settings
  final _gymNameController = TextEditingController();
  final _gymCapacityController = TextEditingController();
  
  // App settings
  final _refreshRateController = TextEditingController();
  
  bool _isLoading = true;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _mqttHostController.dispose();
    _mqttPortController.dispose();
    _dbHostController.dispose();
    _dbPortController.dispose();
    _dbNameController.dispose();
    _dbUserController.dispose();
    _dbPasswordController.dispose();
    _gymNameController.dispose();
    _gymCapacityController.dispose();
    _refreshRateController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    // In a real app, this would be loaded from AppConfig
    // For demonstration, we'll use placeholder values
    
    setState(() {
      _isLoading = true;
    });
    
    // Simulate loading delay
    await Future.delayed(const Duration(milliseconds: 500));
    
    setState(() {
      // MQTT settings
      _mqttHostController.text = 'broker.hivemq.com';
      _mqttPortController.text = '1883';
      _mqttUseSecure = false;
      
      // Database settings
      _dbHostController.text = 'localhost';
      _dbPortController.text = '5432';
      _dbNameController.text = 'smartgym_db';
      _dbUserController.text = 'smartgym_admin';
      _dbPasswordController.text = 'smartgym_password';
      _dbUseSecure = false;
      
      // Gym settings
      _gymNameController.text = 'Smart Gym';
      _gymCapacityController.text = '100';
      
      // App settings
      _refreshRateController.text = '30';
      
      _isLoading = false;
      _hasChanges = false;
    });
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    // In a real app, this would save to AppConfig
    // For demonstration, we'll just simulate a delay
    await Future.delayed(const Duration(milliseconds: 1000));
    
    setState(() {
      _isLoading = false;
      _hasChanges = false;
    });
    
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Settings saved successfully'),
        backgroundColor: AppTheme.successColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        actions: [
          if (_hasChanges && !_isLoading)
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveSettings,
              tooltip: 'Save Settings',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                onChanged: () {
                  setState(() {
                    _hasChanges = true;
                  });
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildMqttSettings(),
                    const SizedBox(height: 24),
                    _buildDatabaseSettings(),
                    const SizedBox(height: 24),
                    _buildGymSettings(),
                    const SizedBox(height: 24),
                    _buildAppSettings(),
                    const SizedBox(height: 32),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _hasChanges ? _saveSettings : null,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: const Text('Save Settings'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _loadSettings,
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: const Text('Discard Changes'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () {
                          _showResetConfirmation();
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.errorColor,
                          side: const BorderSide(color: AppTheme.errorColor),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('Reset to Defaults'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildMqttSettings() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.cloud_outlined),
                const SizedBox(width: 8),
                Text(
                  'MQTT Broker Settings',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _mqttHostController,
              decoration: const InputDecoration(
                labelText: 'Broker Host',
                hintText: 'broker.hivemq.com',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a broker host';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _mqttPortController,
              decoration: const InputDecoration(
                labelText: 'Broker Port',
                hintText: '1883',
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a port number';
                }
                if (int.tryParse(value) == null) {
                  return 'Please enter a valid port number';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Use Secure Connection (TLS)'),
              value: _mqttUseSecure,
              onChanged: (value) {
                setState(() {
                  _mqttUseSecure = value;
                  _hasChanges = true;
                });
              },
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () {
                _testConnection('MQTT');
              },
              icon: const Icon(Icons.power),
              label: const Text('Test Connection'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDatabaseSettings() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.storage_outlined),
                const SizedBox(width: 8),
                Text(
                  'Database Settings',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _dbHostController,
              decoration: const InputDecoration(
                labelText: 'Database Host',
                hintText: 'localhost',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a database host';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _dbPortController,
              decoration: const InputDecoration(
                labelText: 'Database Port',
                hintText: '5432',
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a port number';
                }
                if (int.tryParse(value) == null) {
                  return 'Please enter a valid port number';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _dbNameController,
              decoration: const InputDecoration(
                labelText: 'Database Name',
                hintText: 'smartgym_db',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a database name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _dbUserController,
              decoration: const InputDecoration(
                labelText: 'Username',
                hintText: 'smartgym_admin',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a username';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _dbPasswordController,
              decoration: const InputDecoration(
                labelText: 'Password',
                hintText: '********',
              ),
              obscureText: true,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a password';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Use Secure Connection (SSL)'),
              value: _dbUseSecure,
              onChanged: (value) {
                setState(() {
                  _dbUseSecure = value;
                  _hasChanges = true;
                });
              },
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () {
                _testConnection('Database');
              },
              icon: const Icon(Icons.power),
              label: const Text('Test Connection'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGymSettings() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.fitness_center_outlined),
                const SizedBox(width: 8),
                Text(
                  'Gym Settings',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _gymNameController,
              decoration: const InputDecoration(
                labelText: 'Gym Name',
                hintText: 'Smart Gym',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a gym name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _gymCapacityController,
              decoration: const InputDecoration(
                labelText: 'Maximum Capacity',
                hintText: '100',
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a maximum capacity';
                }
                final capacity = int.tryParse(value);
                if (capacity == null) {
                  return 'Please enter a valid number';
                }
                if (capacity <= 0) {
                  return 'Capacity must be greater than 0';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppSettings() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.settings_outlined),
                const SizedBox(width: 8),
                Text(
                  'App Settings',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _refreshRateController,
              decoration: const InputDecoration(
                labelText: 'Dashboard Refresh Rate (seconds)',
                hintText: '30',
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a refresh rate';
                }
                final rate = int.tryParse(value);
                if (rate == null) {
                  return 'Please enter a valid number';
                }
                if (rate < 5) {
                  return 'Refresh rate must be at least 5 seconds';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  void _testConnection(String type) {
    // In a real app, this would test the connection to the service
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Testing $type connection...'),
      ),
    );
    
    // Simulate connection test
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$type connection successful'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    });
  }

  void _showResetConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset to Defaults'),
        content: const Text(
          'Are you sure you want to reset all settings to default values? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _resetToDefaults();
            },
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.errorColor,
            ),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  void _resetToDefaults() {
    // In a real app, this would reset settings to defaults in AppConfig
    _loadSettings();
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Settings reset to defaults'),
      ),
    );
  }
} 