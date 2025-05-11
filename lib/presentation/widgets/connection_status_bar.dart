import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartgymai/core/theme/app_theme.dart';
import 'package:smartgymai/data/services/mqtt_service.dart';
import 'package:smartgymai/providers/repository_providers.dart';

class ConnectionStatusBar extends ConsumerWidget {
  const ConnectionStatusBar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch MQTT connection state
    final mqttConnectionState = ref.watch(mqttServiceProvider.select(
      (mqttService) => mqttService.connectionStateStream,
    ));

    return StreamBuilder<MqttConnectionState>(
      stream: mqttConnectionState,
      builder: (context, snapshot) {
        final mqttState = snapshot.data ?? MqttConnectionState.idle;
        
        // Check if database is accessible by checking if any repository is loading
        // This is a simplistic approach; a real app would have a dedicated status provider
        final isLoading = ref.watch(
          Provider((ref) => ref.watch(userRepositoryProvider) != null),
        );
        
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
          color: _getBackgroundColor(mqttState),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    _getIconData(mqttState),
                    size: 16,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _getStatusText(mqttState),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: () {
                  // Reconnect to MQTT if disconnected
                  if (mqttState != MqttConnectionState.connected) {
                    ref.read(mqttServiceProvider).connect();
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    mqttState == MqttConnectionState.connected
                        ? 'Connected'
                        : 'Reconnect',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Color _getBackgroundColor(MqttConnectionState state) {
    switch (state) {
      case MqttConnectionState.connected:
        return AppTheme.occupancyLowColor;
      case MqttConnectionState.connecting:
        return AppTheme.occupancyMediumColor;
      case MqttConnectionState.disconnected:
      case MqttConnectionState.error:
        return AppTheme.occupancyHighColor;
      default:
        return AppTheme.disabledColor;
    }
  }

  IconData _getIconData(MqttConnectionState state) {
    switch (state) {
      case MqttConnectionState.connected:
        return Icons.cloud_done;
      case MqttConnectionState.connecting:
        return Icons.cloud_queue;
      case MqttConnectionState.disconnected:
        return Icons.cloud_off;
      case MqttConnectionState.error:
        return Icons.error_outline;
      default:
        return Icons.cloud_off;
    }
  }

  String _getStatusText(MqttConnectionState state) {
    switch (state) {
      case MqttConnectionState.connected:
        return 'Connected to MQTT';
      case MqttConnectionState.connecting:
        return 'Connecting to MQTT...';
      case MqttConnectionState.disconnected:
        return 'Disconnected from MQTT';
      case MqttConnectionState.error:
        return 'MQTT Connection Error';
      default:
        return 'Not connected to MQTT';
    }
  }
} 