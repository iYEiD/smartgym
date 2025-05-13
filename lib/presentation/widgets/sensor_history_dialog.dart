import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:smartgymai/core/theme/app_theme.dart';
import 'package:smartgymai/domain/entities/sensor_data.dart';
import 'package:smartgymai/providers/sensors_provider.dart';
import 'package:smartgymai/providers/repository_providers.dart';

class SensorHistoryDialog extends ConsumerWidget {
  final String sensorType;
  final String unit;
  final Color color;

  const SensorHistoryDialog({
    Key? key,
    required this.sensorType,
    required this.unit,
    required this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sensorRepository = ref.read(sensorRepositoryProvider);
    final now = DateTime.now();
    final start = now.subtract(const Duration(days: 7));
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SizedBox(
          width: 350,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$sensorType History',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              FutureBuilder<List<SensorData>>(
                future: sensorRepository.getSensorDataHistory(start, now),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final allHistory = snapshot.data ?? [];
                  List<SensorData> history;
                  switch (sensorType.toLowerCase()) {
                    case 'temperature':
                      history = allHistory.where((d) => d.temperature != null).toList();
                      break;
                    case 'humidity':
                      history = allHistory.where((d) => d.humidity != null).toList();
                      break;
                    case 'light':
                    case 'light level':
                      history = allHistory.where((d) => d.light != null).toList();
                      break;
                    default:
                      history = [];
                  }
                  return SizedBox(
                    height: 220,
                    child: history.isEmpty
                        ? _buildEmptyChart(context)
                        : LineChart(_buildChartData(history)),
                  );
                },
              ),
              const SizedBox(height: 12),
              FutureBuilder<List<SensorData>>(
                future: sensorRepository.getSensorDataHistory(start, now),
                builder: (context, snapshot) {
                  final allHistory = snapshot.data ?? [];
                  List<SensorData> history;
                  switch (sensorType.toLowerCase()) {
                    case 'temperature':
                      history = allHistory.where((d) => d.temperature != null).toList();
                      break;
                    case 'humidity':
                      history = allHistory.where((d) => d.humidity != null).toList();
                      break;
                    case 'light':
                    case 'light level':
                      history = allHistory.where((d) => d.light != null).toList();
                      break;
                    default:
                      history = [];
                  }
                  if (history.isEmpty) {
                    return Center(
                      child: Text(
                        'No history data available.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyChart(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Icon(Icons.show_chart, color: Colors.grey[300], size: 64),
      ),
    );
  }

  LineChartData _buildChartData(List<SensorData> history) {
    final spots = history.asMap().entries.map((entry) {
      final i = entry.key;
      final data = entry.value;
      double y;
      switch (sensorType.toLowerCase()) {
        case 'temperature':
          y = data.temperature ?? 0;
          break;
        case 'humidity':
          y = data.humidity ?? 0;
          break;
        case 'light':
        case 'light level':
          y = (data.light ?? 0).toDouble();
          break;
        default:
          y = 0;
      }
      return FlSpot(i.toDouble(), y);
    }).toList();

    return LineChartData(
      gridData: FlGridData(show: true, drawVerticalLine: false),
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(
          sideTitles: SideTitles(showTitles: true, reservedSize: 40),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      borderData: FlBorderData(show: true, border: Border.all(color: Colors.grey[300]!)),
      minX: 0,
      maxX: (spots.length - 1).toDouble(),
      minY: 0,
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          color: color,
          barWidth: 3,
          dotData: FlDotData(show: false),
        ),
      ],
    );
  }
}
