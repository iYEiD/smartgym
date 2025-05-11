import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:smartgymai/core/config/app_config.dart';
import 'package:smartgymai/core/theme/app_theme.dart';
import 'package:smartgymai/domain/entities/occupancy_record.dart';
import 'package:smartgymai/domain/entities/sensor_data.dart';
import 'package:smartgymai/presentation/widgets/occupancy_chart.dart';
import 'package:smartgymai/presentation/widgets/parking_spot_indicator.dart';
import 'package:smartgymai/presentation/widgets/sensor_value_card.dart';
import 'package:smartgymai/providers/sensors_provider.dart';
import 'package:smartgymai/core/constants/mqtt_constants.dart';
import 'package:smartgymai/providers/repository_providers.dart';

class AnalyticsDashboardScreen extends ConsumerStatefulWidget {
  const AnalyticsDashboardScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<AnalyticsDashboardScreen> createState() => _AnalyticsDashboardScreenState();
}

class _AnalyticsDashboardScreenState extends ConsumerState<AnalyticsDashboardScreen> {
  bool _isAutomaticControlEnabled = false;

  @override
  void initState() {
    super.initState();
    // Refresh data when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(sensorsProvider.notifier).refreshOccupancyData();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Watch the sensors provider state
    final sensorsState = ref.watch(sensorsProvider);
    
    // Get the gym capacity from app config
    final gymCapacity = AppConfig().gymCapacity;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              // Refresh data
              ref.read(sensorsProvider.notifier).refreshOccupancyData();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // Pull to refresh functionality
          await ref.read(sensorsProvider.notifier).refreshOccupancyData();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCurrentOccupancyCard(
                context, 
                sensorsState.latestOccupancy, 
                gymCapacity,
                isLoading: sensorsState.isLoading,
              ),
              _buildAutomaticControlSwitch(context),
              _buildEnvironmentSensorsGrid(
                context, 
                sensorsState.latestSensorData,
                isLoading: sensorsState.isLoading,
              ),
              _buildOccupancyTrendChart(
                context, 
                sensorsState.occupancyHistory,
                gymCapacity,
                isLoading: sensorsState.isLoading,
              ),
              _buildParkingAvailability(
                context, 
                sensorsState.latestSensorData?.parking,
                isLoading: sensorsState.isLoading,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentOccupancyCard(
    BuildContext context, 
    OccupancyRecord? occupancy, 
    int capacity, 
    {bool isLoading = false}
  ) {
    // Use actual data or default values if not available
    final currentOccupancy = occupancy?.count ?? 0;
    final percentage = (currentOccupancy / capacity * 100).round();
    
    Color statusColor;
    String statusText;
    
    if (percentage < 30) {
      statusColor = AppTheme.occupancyLowColor;
      statusText = 'Low Occupancy';
    } else if (percentage < 70) {
      statusColor = AppTheme.occupancyMediumColor;
      statusText = 'Medium Occupancy';
    } else {
      statusColor = AppTheme.occupancyHighColor;
      statusText = 'High Occupancy';
    }
    
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Column(
              children: [
                Text(
                  'Current Occupancy',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: statusColor),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            isLoading
              ? const CircularProgressIndicator()
              : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$currentOccupancy',
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '/$capacity',
                    style: TextStyle(
                      fontSize: 24,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 24),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: isLoading ? 0.0 : currentOccupancy / capacity,
                backgroundColor: Colors.grey[200],
                color: statusColor,
                minHeight: 16,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Last updated: ${occupancy != null ? DateFormat('HH:mm:ss').format(occupancy.timestamp) : 'N/A'}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  '$percentage% of capacity',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAutomaticControlSwitch(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Automatic Control',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Card(
          margin: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Auto Sensors',
                  style: TextStyle(
                    fontSize: 16,
                  ),
                ),
                Row(
                  children: [
                    Switch(
                      value: _isAutomaticControlEnabled,
                      onChanged: (bool value) {
                        setState(() {
                          _isAutomaticControlEnabled = value;
                        });
                        final mqttService = ref.read(mqttServiceProvider);
                        final command = value 
                          ? {'command': 'automatic_control_on'}
                          : {'command': 'automatic_control_off'};
                        
                        mqttService.publishMessage(
                          MqttConstants.commandsTopic,
                          command,
                        );
                      },
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () {
                        // Settings functionality will be added later
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        'Settings',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEnvironmentSensorsGrid(
    BuildContext context, 
    SensorData? sensorData,
    {bool isLoading = false}
  ) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Environment Sensors',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              SensorValueCard(
                title: 'Temperature',
                value: sensorData?.temperature?.toString() ?? '--',
                unit: '°C',
                icon: Icons.thermostat,
                color: Colors.orange,
                isLoading: isLoading,
              ),
              SensorValueCard(
                title: 'Humidity',
                value: sensorData?.humidity?.toString() ?? '--',
                unit: '%',
                icon: Icons.water_drop,
                color: Colors.blue,
                isLoading: isLoading,
              ),
              SensorValueCard(
                title: 'Light Level',
                value: sensorData?.light?.toString() ?? '--',
                unit: 'lux',
                icon: Icons.light_mode,
                color: Colors.amber,
                isLoading: isLoading,
              ),
              SensorValueCard(
                title: 'Motion',
                value: sensorData?.motion == true ? 'Yes' : 'None',
                unit: '',
                icon: Icons.directions_run,
                color: sensorData?.motion == true ? Colors.red : Colors.green,
                isLoading: isLoading,
                isClickable: true,
              ),
              SensorValueCard(
                title: 'Lighting',
                value: sensorData?.lighting == true ? 'On' : 'Off',
                unit: '',
                icon: Icons.lightbulb,
                color: Colors.yellow,
                isLoading: isLoading,
                isClickable: true,
              ),
              SensorValueCard(
                title: 'AC',
                value: sensorData?.ac == true ? 'On' : 'Off',
                unit: '',
                icon: Icons.ac_unit,
                color: Colors.cyan,
                isLoading: isLoading,
                isClickable: true,
              ),
              SensorValueCard(
                title: 'Gate',
                value: sensorData?.gate == true ? 'Open' : 'Closed',
                unit: '',
                icon: Icons.door_sliding,
                color: Colors.purple,
                isLoading: isLoading,
                isClickable: true,
              ),
              SensorValueCard(
                title: 'Parking',
                value: '${_calculateAvailableParkingSpots(sensorData?.parking)}/8',
                unit: 'spots',
                icon: Icons.local_parking,
                color: Colors.indigo,
                isLoading: isLoading,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOccupancyTrendChart(
    BuildContext context, 
    List<OccupancyRecord> records,
    int capacity,
    {bool isLoading = false}
  ) {
    return OccupancyChart(
      records: records,
      capacity: capacity,
      isLoading: isLoading,
    );
  }

  Widget _buildParkingAvailability(
    BuildContext context, 
    bool? parkingStatus,
    {bool isLoading = false}
  ) {
    // Create a list of 8 parking spots:
    // - 1 dynamic spot (from sensor)
    // - 5 static spots (always available)
    // - 2 static spots (always taken)
    final List<bool> parkingSpots = [
      parkingStatus ?? false, // Dynamic spot from sensor
      true, // Static spot 1 (available)
      true, // Static spot 2 (available)
      true, // Static spot 3 (available)
      true, // Static spot 4 (available)
      true, // Static spot 5 (available)
      false, // Static spot 6 (always taken)
      false, // Static spot 7 (always taken)
    ];

    return ParkingSpotIndicator(
      parkingSpots: parkingSpots,
      isLoading: isLoading,
    );
  }

  // Helper method to calculate available parking spots
  int _calculateAvailableParkingSpots(bool? parkingStatus) {
    // 5 static spots (always available) + 2 static spots (always taken) + 1 dynamic spot
    final staticAvailableSpots = 5;
    final dynamicSpot = parkingStatus == true ? 1 : 0;
    return staticAvailableSpots + dynamicSpot;
  }
} 