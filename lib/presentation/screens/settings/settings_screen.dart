import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartgymai/core/config/app_config.dart';
import 'package:smartgymai/core/theme/app_theme.dart';
import 'package:smartgymai/data/services/database_service.dart';
import 'package:smartgymai/data/services/mqtt_service.dart';

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
  bool _isTestingDbConnection = false;
  bool _isTestingMqttConnection = false;

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
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Simulate loading (in a real app, this would fetch settings from storage)
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Load from AppConfig
      final appConfig = AppConfig();
      
      // MQTT settings
      _mqttHostController.text = appConfig.mqttServerHost;
      _mqttPortController.text = appConfig.mqttServerPort.toString();
      _mqttUseSecure = appConfig.mqttUseSecure;
      
      // Database settings
      _dbHostController.text = appConfig.dbHost;
      _dbPortController.text = appConfig.dbPort.toString();
      _dbNameController.text = appConfig.dbName;
      _dbUserController.text = appConfig.dbUser;
      _dbPasswordController.text = appConfig.dbPassword;
      _dbUseSecure = appConfig.dbUseSecure;
      
      // Gym settings
      _gymNameController.text = appConfig.gymName;
      _gymCapacityController.text = appConfig.gymCapacity.toString();
      
      // App settings
      _refreshRateController.text = appConfig.dashboardRefreshRate.toString();
      
      setState(() {
        _isLoading = false;
        _hasChanges = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading settings: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final appConfig = AppConfig();
      
      // Save MQTT settings
      await appConfig.setMqttServerHost(_mqttHostController.text);
      await appConfig.setMqttServerPort(int.parse(_mqttPortController.text));
      await appConfig.setMqttUseSecure(_mqttUseSecure);
      
      // Save database settings
      await appConfig.setDbHost(_dbHostController.text);
      await appConfig.setDbPort(int.parse(_dbPortController.text));
      await appConfig.setDbName(_dbNameController.text);
      await appConfig.setDbUser(_dbUserController.text);
      await appConfig.setDbPassword(_dbPasswordController.text);
      await appConfig.setDbUseSecure(_dbUseSecure);
      
      // Save gym settings
      await appConfig.setGymName(_gymNameController.text);
      await appConfig.setGymCapacity(int.parse(_gymCapacityController.text));
      
      // Save app settings
      await appConfig.setDashboardRefreshRate(int.parse(_refreshRateController.text));
      
      setState(() {
        _isLoading = false;
        _hasChanges = false;
      });
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Settings saved successfully. App restart recommended for database changes.'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving settings: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
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
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _hasChanges ? _saveSettings : null,
                                  icon: const Icon(Icons.save),
                                  label: const Text('Save Settings'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.primaryColor,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _hasChanges ? _discardChanges : null,
                                  icon: const Icon(Icons.cancel),
                                  label: const Text('Discard Changes'),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () async {
                                    // Show confirmation dialog
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text('Reset Settings'),
                                        content: const Text(
                                          'This will reset all settings to their default values. This may help resolve connection issues. Continue?'
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.of(context).pop(false),
                                            child: const Text('Cancel'),
                                          ),
                                          ElevatedButton(
                                            onPressed: () => Navigator.of(context).pop(true),
                                            child: const Text('Reset'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.red,
                                              foregroundColor: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                    
                                    if (confirm == true && mounted) {
                                      setState(() {
                                        _isLoading = true;
                                      });
                                      
                                      try {
                                        await AppConfig().resetToDefaults();
                                        await _loadSettings(); // Reload settings from defaults
                                        
                                        if (mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text('Settings reset to defaults. App restart recommended.'),
                                              backgroundColor: Colors.green,
                                            ),
                                          );
                                        }
                                      } catch (e) {
                                        if (mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('Error resetting settings: $e'),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                        }
                                      } finally {
                                        if (mounted) {
                                          setState(() {
                                            _isLoading = false;
                                          });
                                        }
                                      }
                                    }
                                  },
                                  icon: const Icon(Icons.restore, color: Colors.red),
                                  label: const Text('Reset All Settings', style: TextStyle(color: Colors.red)),
                                ),
                              ),
                            ],
                          ),
                        ],
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
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton.icon(
                  onPressed: _isTestingMqttConnection ? null : _testMqttConnection,
                  icon: _isTestingMqttConnection 
                    ? const SizedBox(
                        width: 20, 
                        height: 20, 
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.wifi),
                  label: Text(_isTestingMqttConnection ? 'Testing...' : 'Test Connection'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
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
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton.icon(
                  onPressed: _isTestingDbConnection ? null : _testDatabaseConnection,
                  icon: _isTestingDbConnection 
                    ? const SizedBox(
                        width: 20, 
                        height: 20, 
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.checklist),
                  label: Text(_isTestingDbConnection ? 'Testing...' : 'Test Connection'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
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

  Future<void> _testDatabaseConnection() async {
    setState(() {
      _isTestingDbConnection = true;
    });
    
    try {
      final databaseService = DatabaseService();
      // Get diagnostic info first
      final diagnostics = await databaseService.getDiagnosticInfo();
      
      // Try a simple query to test the connection
      final result = await databaseService.query('SELECT 1 as test');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Database connection successful! Result: ${result.first['test']}'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Show detailed diagnostic information
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Database Diagnostics'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Connection successful!', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  const Text('Configuration details:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ...diagnostics.entries.map((entry) => 
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text('${entry.key}: ${entry.value}'),
                    )
                  ),
                  const SizedBox(height: 16),
                  const Text('Note: For Android emulators, the host is automatically changed to 10.0.2.2'),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        // Get diagnostic info to help troubleshoot
        final diagnostics = await DatabaseService().getDiagnosticInfo().catchError((_) => <String, String>{
          'error': 'Could not get diagnostics',
          'host': AppConfig().dbHost,
          'port': AppConfig().dbPort.toString(),
        });
        
        // Show detailed error message for troubleshooting
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Database Connection Error'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Error: $e', style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 16),
                  const Text('Diagnostic information:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ...diagnostics.entries.map((entry) => 
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text('${entry.key}: ${entry.value}'),
                    )
                  ),
                  const SizedBox(height: 16),
                  const Text('Troubleshooting steps:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text('1. Ensure Docker containers are running (docker ps)'),
                  const Text('2. Check container logs (docker logs smartgym_postgres)'),
                  const Text('3. For Android emulator, use 10.0.2.2 instead of localhost'),
                  const Text('4. Verify DB credentials in app_config.dart'),
                  const Text('5. Try clicking "Reset All Settings" below'),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('OK'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  try {
                    await AppConfig().resetToDefaults();
                    await _loadSettings();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Settings reset to defaults. Please try reconnecting.'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error resetting settings: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                style: TextButton.styleFrom(
                  foregroundColor: Colors.orange,
                ),
                child: const Text('Reset All Settings'),
              ),
            ],
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isTestingDbConnection = false;
        });
      }
    }
  }

  Future<void> _testMqttConnection() async {
    setState(() {
      _isTestingMqttConnection = true;
    });
    
    try {
      final mqttService = MqttService();
      
      // Use the new comprehensive test method
      final testResult = await mqttService.testConnection();
      
      if (mounted) {
        if (testResult['success'] == true) {
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('MQTT connection successful!'),
              backgroundColor: Colors.green,
            ),
          );
          
          // Show detailed diagnostic information
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('MQTT Connection Successful'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Connection established and test message sent!', 
                      style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    const Text('Connection details:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ...testResult['diagnostics'].entries.map((entry) => 
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text('${entry.key}: ${entry.value}'),
                      )
                    ),
                    const SizedBox(height: 16),
                    const Text('To verify data transmission, try publishing to:', 
                      style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    SelectableText('${testResult['testTopic'] ?? 'UA/IOT/test'}'),
                    const SizedBox(height: 8),
                    const Text('You can use an MQTT client like MQTT Explorer or mosquitto_pub to send test messages.'),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        } else {
          // Show error details
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('MQTT Connection Failed'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Error: ${testResult['error'] ?? "Unknown error"}', 
                      style: const TextStyle(color: Colors.red)),
                    const SizedBox(height: 16),
                    const Text('Diagnostic information:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ...testResult['diagnostics'].entries.map((entry) => 
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text('${entry.key}: ${entry.value}'),
                      )
                    ),
                    const SizedBox(height: 16),
                    const Text('Troubleshooting steps:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    const Text('1. Check your internet connection'),
                    const Text('2. Verify the MQTT broker address is correct (test.mosquitto.org is recommended)'),
                    const Text('3. Make sure port 1883 is not blocked by a firewall'),
                    const Text('4. Try clicking "Reset All Settings" below to restore defaults'),
                    const SizedBox(height: 16),
                    const Text('Test mosquitto.org from Terminal:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SelectableText('mosquitto_pub -h test.mosquitto.org -t "UA/IOT/test" -m "hello"'),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('OK'),
                ),
                TextButton(
                  onPressed: () async {
                    Navigator.of(context).pop();
                    try {
                      await AppConfig().resetToDefaults();
                      await _loadSettings();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Settings reset to defaults. Please try reconnecting.'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error resetting settings: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.orange,
                  ),
                  child: const Text('Reset All Settings'),
                ),
              ],
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error testing MQTT connection: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isTestingMqttConnection = false;
        });
      }
    }
  }

  void _discardChanges() {
    setState(() {
      _hasChanges = false;
    });
    
    // Reload settings from shared preferences
    _loadSettings();
  }
} 