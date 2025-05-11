import 'package:flutter/material.dart';
import 'package:smartgymai/core/theme/app_theme.dart';

class ParkingSpotIndicator extends StatelessWidget {
  final List<bool> parkingSpots;
  final bool isLoading;

  const ParkingSpotIndicator({
    Key? key,
    required this.parkingSpots,
    this.isLoading = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Parking Availability',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getColorForAvailability(
                    isLoading ? 0 : _getAvailablePercentage(),
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isLoading
                      ? 'Loading...'
                      : '${_getAvailableCount()}/${parkingSpots.length} available',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        isLoading
            ? _buildLoadingIndicator()
            : Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Center(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: List.generate(
                      parkingSpots.length,
                      (index) => ParkingSpot(
                        isAvailable: parkingSpots[index],
                        spotNumber: index + 1,
                      ),
                    ),
                  ),
                ),
              ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildLoadingIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Center(
        child: Column(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Loading parking data...',
              style: TextStyle(
                color: AppTheme.onSurfaceColor.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  int _getAvailableCount() {
    return parkingSpots.where((spot) => spot).length;
  }

  double _getAvailablePercentage() {
    if (parkingSpots.isEmpty) return 0;
    return _getAvailableCount() / parkingSpots.length * 100;
  }

  Color _getColorForAvailability(double percentage) {
    if (percentage >= 60) {
      return AppTheme.occupancyLowColor;
    } else if (percentage >= 30) {
      return AppTheme.occupancyMediumColor;
    } else {
      return AppTheme.occupancyHighColor;
    }
  }
}

class ParkingSpot extends StatelessWidget {
  final bool isAvailable;
  final int spotNumber;

  const ParkingSpot({
    Key? key,
    required this.isAvailable,
    required this.spotNumber,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 60,
      height: 76,
      decoration: BoxDecoration(
        color: isAvailable
            ? AppTheme.occupancyLowColor.withOpacity(0.2)
            : AppTheme.occupancyHighColor.withOpacity(0.2),
        border: Border.all(
          color: isAvailable
              ? AppTheme.occupancyLowColor
              : AppTheme.occupancyHighColor,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isAvailable ? Icons.local_parking : Icons.car_crash,
            color: isAvailable
                ? AppTheme.occupancyLowColor
                : AppTheme.occupancyHighColor,
            size: 28,
          ),
          const SizedBox(height: 2),
          Text(
            '$spotNumber',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isAvailable
                  ? AppTheme.occupancyLowColor
                  : AppTheme.occupancyHighColor,
            ),
          ),
          Text(
            isAvailable ? 'Free' : 'Taken',
            style: TextStyle(
              fontSize: 10,
              color: isAvailable
                  ? AppTheme.occupancyLowColor
                  : AppTheme.occupancyHighColor,
            ),
          ),
        ],
      ),
    );
  }
} 