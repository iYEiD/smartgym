import 'package:flutter/material.dart';
import 'package:smartgymai/core/theme/app_theme.dart';
import 'package:smartgymai/presentation/widgets/sensor_command_dialog.dart';
import 'package:smartgymai/presentation/widgets/sensor_history_dialog.dart';

class SensorValueCard extends StatelessWidget {
  final String title;
  final String value;
  final String unit;
  final IconData icon;
  final Color color;
  final bool isLoading;
  final bool isClickable;
  final bool showHistory;

  const SensorValueCard({
    Key? key,
    required this.title,
    required this.value,
    required this.unit,
    required this.icon,
    required this.color,
    this.isLoading = false,
    this.isClickable = false,
    this.showHistory = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: isClickable ? () => _showCommandDialog(context) : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.onSurfaceColor.withOpacity(0.7),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(
                    icon,
                    color: color,
                    size: 24,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              isLoading
                  ? _buildLoadingIndicator()
                  : Wrap(
                      crossAxisAlignment: WrapCrossAlignment.end,
                      children: [
                        Text(
                          value,
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(width: 4),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            unit,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.onSurfaceColor.withOpacity(0.7),
                            ),
                          ),
                        ),
                      ],
                    ),
              if (showHistory) ...[
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: () => _showHistoryDialog(context),
                    icon: Icon(
                      Icons.history,
                      size: 16,
                      color: color,
                    ),
                    label: Text(
                      'View History',
                      style: TextStyle(
                        color: color,
                        fontSize: 12,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ),
              ] else if (isClickable) ...[
                const SizedBox(height: 8),
                Text(
                  'Tap to control',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Container(
      height: 32,
      width: 100,
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Center(
        child: SizedBox(
          height: 16,
          width: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
          ),
        ),
      ),
    );
  }

  void _showCommandDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => SensorCommandDialog(
        sensorType: title,
        currentState: value.toLowerCase() == 'on' || value.toLowerCase() == 'yes',
      ),
    );
  }

  void _showHistoryDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => SensorHistoryDialog(
        sensorType: title,
        unit: unit,
        color: color,
      ),
    );
  }
} 