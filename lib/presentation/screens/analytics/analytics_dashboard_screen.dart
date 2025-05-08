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

class AnalyticsDashboardScreen extends StatelessWidget {
  const AnalyticsDashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              // Refresh data
              // In a real implementation, this would trigger data refresh
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // Pull to refresh functionality
          // In a real implementation, this would refresh data
          await Future.delayed(const Duration(seconds: 1));
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCurrentOccupancyCard(),
              _buildEnvironmentSensorsGrid(),
              _buildOccupancyTrendChart(),
              _buildParkingAvailability(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentOccupancyCard() {
    // This is a placeholder implementation
    // In a real app, this would be connected to the repository via state management
    const currentOccupancy = 42;
    const capacity = 100;
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
            Row(
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
                value: currentOccupancy / capacity,
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
                  'Last updated: ${DateFormat('HH:mm:ss').format(DateTime.now())}',
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

  Widget _buildEnvironmentSensorsGrid() {
    // Placeholder sensor data
    // In a real app, this would be connected to the repository
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
            children: const [
              SensorValueCard(
                title: 'Temperature',
                value: '24.5',
                unit: '°C',
                icon: Icons.thermostat,
                color: Colors.orange,
              ),
              SensorValueCard(
                title: 'Humidity',
                value: '65',
                unit: '%',
                icon: Icons.water_drop,
                color: Colors.blue,
              ),
              SensorValueCard(
                title: 'Light Level',
                value: '850',
                unit: 'lux',
                icon: Icons.light_mode,
                color: Colors.amber,
              ),
              SensorValueCard(
                title: 'Motion',
                value: 'Yes',
                unit: '',
                icon: Icons.directions_run,
                color: Colors.green,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOccupancyTrendChart() {
    // Placeholder data
    // In a real app, this would come from the repository
    final now = DateTime.now();
    final records = [
      OccupancyRecord(
        timestamp: now.subtract(const Duration(hours: 5)),
        count: 12,
      ),
      OccupancyRecord(
        timestamp: now.subtract(const Duration(hours: 4)),
        count: 25,
      ),
      OccupancyRecord(
        timestamp: now.subtract(const Duration(hours: 3)),
        count: 45,
      ),
      OccupancyRecord(
        timestamp: now.subtract(const Duration(hours: 2)),
        count: 58,
      ),
      OccupancyRecord(
        timestamp: now.subtract(const Duration(hours: 1)),
        count: 42,
      ),
    ];
    
    return OccupancyChart(
      records: records,
      capacity: 100,
    );
  }

  Widget _buildParkingAvailability() {
    // Placeholder parking data
    // In a real app, this would come from the repository
    final parkingSpots = [
      true, false, true, true, false,
      true, true, false, true, false,
    ];
    
    return ParkingSpotIndicator(
      parkingSpots: parkingSpots,
    );
  }
} 