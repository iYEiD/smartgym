import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartgymai/core/constants/mqtt_constants.dart';
import 'package:smartgymai/core/theme/app_theme.dart';
import 'package:smartgymai/data/services/mqtt_service.dart';
import 'package:smartgymai/providers/repository_providers.dart';

class SensorCommandDialog extends ConsumerStatefulWidget {
  final String sensorType;
  final bool currentState;

  const SensorCommandDialog({
    Key? key,
    required this.sensorType,
    required this.currentState,
  }) : super(key: key);

  @override
  ConsumerState<SensorCommandDialog> createState() => _SensorCommandDialogState();
}

class _SensorCommandDialogState extends ConsumerState<SensorCommandDialog> {
  bool _isSending = false;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Control ${widget.sensorType}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            ),
          ..._buildCommandButtons(context),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isSending ? null : () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }

  List<Widget> _buildCommandButtons(BuildContext context) {
    final mqttService = ref.read(mqttServiceProvider);
    final commands = _getCommandsForSensor();
    
    return commands.map((command) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: ElevatedButton(
          onPressed: _isSending ? null : () => _sendCommand(mqttService, command),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 45),
          ),
          child: _isSending
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(command['label'] as String),
        ),
      );
    }).toList();
  }

  List<Map<String, String>> _getCommandsForSensor() {
    switch (widget.sensorType.toLowerCase()) {
      case 'lighting':
        return [
          {'command': 'toggle_led_on', 'label': 'Turn On'},
          {'command': 'toggle_led_off', 'label': 'Turn Off'},
        ];
      case 'gate':
        return [
          {'command': 'open_door', 'label': 'Open Door'},
          {'command': 'close_door', 'label': 'Close Door'},
        ];
      case 'motion':
        return [
          {'command': 'toggle_alarm_on', 'label': 'Enable Alarm'},
        ];
      case 'ac':
        return [
          {'command': 'toggle_ac_on', 'label': 'Turn On AC'},
          {'command': 'toggle_ac_off', 'label': 'Turn Off AC'},
        ];
      default:
        return [];
    }
  }

  Future<void> _sendCommand(MqttService mqttService, Map<String, String> command) async {
    setState(() {
      _isSending = true;
      _errorMessage = null;
    });

    try {
      // Ensure MQTT connection is established
      await mqttService.connect();
      
      // Wait a moment to ensure connection is stable
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Publish the command
      await mqttService.publishMessage(
        MqttConstants.commandsTopic,
        {'command': command['command']},
      );

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Command sent: ${command['label']}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to send command: ${e.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }
} 