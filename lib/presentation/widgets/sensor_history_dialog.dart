import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:smartgymai/domain/entities/sensor_data.dart';
import 'package:smartgymai/providers/repository_providers.dart';
import 'package:smartgymai/providers/sensors_provider.dart';

class SensorHistoryDialog extends ConsumerStatefulWidget {
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
  ConsumerState<SensorHistoryDialog> createState() => _SensorHistoryDialogState();
}

class _SensorHistoryDialogState extends ConsumerState<SensorHistoryDialog> {
  bool _isLoading = true;
  List<SensorData> _historyData = [];
  String? _errorMessage;
  int _selectedDays = 1;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final sensorRepository = ref.read(sensorRepositoryProvider);
      final now = DateTime.now();
      final start = now.subtract(Duration(days: _selectedDays));
      
      final history = await sensorRepository.getSensorDataHistory(start, now);
      
      setState(() {
        _historyData = history;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load history data: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  double? _getSensorValue(SensorData data) {
    switch (widget.sensorType.toLowerCase()) {
      case 'temperature':
        return data.temperature;
      case 'humidity':
        return data.humidity;
      case 'light level':
      case 'light':
        return data.light?.toDouble();
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        padding: const EdgeInsets.all(16),
        constraints: const BoxConstraints(
          maxWidth: 600,
          maxHeight: 400,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    '${widget.sensorType} History',
                    style: Theme.of(context).textTheme.titleLarge,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    _buildTimeButton(1, 'Last 24h'),
                    const SizedBox(width: 8),
                    _buildTimeButton(7, 'Last Week'),
                    const SizedBox(width: 8),
                    _buildTimeButton(30, 'Last Month'),
                    const SizedBox(width: 8),
                    _buildTimeButton(90, 'Last 3 Months'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              )
            else if (_isLoading)
              const Expanded(
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              )
            else
              Expanded(
                child: _buildChart(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeButton(int days, String label) {
    return OutlinedButton(
      onPressed: () {
        setState(() {
          _selectedDays = days;
        });
        _fetchData();
      },
      style: OutlinedButton.styleFrom(
        backgroundColor: _selectedDays == days ? widget.color.withOpacity(0.1) : null,
        side: BorderSide(
          color: _selectedDays == days ? widget.color : Colors.grey,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: _selectedDays == days ? widget.color : Colors.grey,
        ),
      ),
    );
  }

  Widget _buildChart() {
    if (_historyData.isEmpty) {
      return const Center(
        child: Text('No data available for the selected period'),
      );
    }

    final spots = _historyData
        .map((data) {
          final value = _getSensorValue(data);
          if (value == null) return null;
          return FlSpot(
            data.timestamp.millisecondsSinceEpoch.toDouble(),
            value,
          );
        })
        .whereType<FlSpot>()
        .toList();

    if (spots.isEmpty) {
      return const Center(
        child: Text('No valid data points for the selected period'),
      );
    }

    return LineChart(
      LineChartData(
        gridData: FlGridData(show: true),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                final date = DateTime.fromMillisecondsSinceEpoch(value.toInt());
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    DateFormat(_selectedDays == 1 ? 'HH:mm' : 'MM/dd').format(date),
                    style: const TextStyle(fontSize: 10),
                  ),
                );
              },
            ),
          ),
          rightTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: true),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: widget.color,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: widget.color.withOpacity(0.1),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            tooltipBgColor: Colors.blueGrey.withOpacity(0.8),
            getTooltipItems: (List<LineBarSpot> touchedSpots) {
              return touchedSpots.map((LineBarSpot touchedSpot) {
                final date = DateTime.fromMillisecondsSinceEpoch(
                  touchedSpot.x.toInt(),
                );
                return LineTooltipItem(
                  '${DateFormat('MM/dd HH:mm').format(date)}\n',
                  const TextStyle(color: Colors.white, fontSize: 12),
                  children: [
                    TextSpan(
                      text: '${touchedSpot.y.toStringAsFixed(1)}${widget.unit}',
                      style: TextStyle(
                        color: widget.color,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }
} 