import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:smartgymai/core/theme/app_theme.dart';
import 'package:smartgymai/domain/entities/user.dart';

class UserListItem extends StatelessWidget {
  final User user;
  final VoidCallback? onTap;
  final VoidCallback? onCheckIn;
  final VoidCallback? onCheckout;

  const UserListItem({
    Key? key,
    required this.user,
    this.onTap,
    this.onCheckIn,
    this.onCheckout,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildAvatar(),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.fullName,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user.email ?? 'No email provided',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppTheme.onSurfaceColor.withOpacity(0.7),
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user.phone ?? 'No phone provided',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppTheme.onSurfaceColor.withOpacity(0.7),
                              ),
                        ),
                      ],
                    ),
                  ),
                  _buildMembershipBadge(context),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildLastActivityInfo(context),
                  _buildActionButtons(context),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    return CircleAvatar(
      radius: 28,
      backgroundColor: AppTheme.primaryColor.withOpacity(0.2),
      child: Text(
        _getInitials(),
        style: TextStyle(
          color: AppTheme.primaryColor,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
    );
  }

  Widget _buildMembershipBadge(BuildContext context) {
    Color badgeColor;
    
    switch (user.membershipType.toLowerCase()) {
      case 'premium':
        badgeColor = Colors.amber;
        break;
      case 'standard':
        badgeColor = Colors.blue;
        break;
      case 'basic':
        badgeColor = Colors.green;
        break;
      default:
        badgeColor = Colors.grey;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: badgeColor,
          width: 1,
        ),
      ),
      child: Text(
        user.membershipType,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: badgeColor,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  Widget _buildLastActivityInfo(BuildContext context) {
    final DateFormat dateFormat = DateFormat('MMM d, h:mm a');
    
    if (user.isCurrentlyCheckedIn) {
      final checkInTime = user.lastCheckIn;
      return Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: const BoxDecoration(
              color: AppTheme.occupancyLowColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Currently Checked In',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.occupancyLowColor,
                    ),
              ),
              if (checkInTime != null)
                Text(
                  'Since ${dateFormat.format(checkInTime)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.onSurfaceColor.withOpacity(0.7),
                      ),
                ),
            ],
          ),
        ],
      );
    } else {
      final lastActivity = user.lastCheckout ?? user.lastCheckIn;
      
      if (lastActivity == null) {
        return Text(
          'No recent activity',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.onSurfaceColor.withOpacity(0.7),
              ),
        );
      }
      
      return Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: Colors.grey[400],
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Last Activity',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Text(
                dateFormat.format(lastActivity),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.onSurfaceColor.withOpacity(0.7),
                    ),
              ),
            ],
          ),
        ],
      );
    }
  }

  Widget _buildActionButtons(BuildContext context) {
    if (user.isCurrentlyCheckedIn) {
      return ElevatedButton.icon(
        onPressed: onCheckout,
        icon: const Icon(Icons.logout),
        label: const Text('Check Out'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.occupancyHighColor,
          foregroundColor: Colors.white,
        ),
      );
    } else {
      return ElevatedButton.icon(
        onPressed: onCheckIn,
        icon: const Icon(Icons.login),
        label: const Text('Check In'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.occupancyLowColor,
          foregroundColor: Colors.white,
        ),
      );
    }
  }

  String _getInitials() {
    final List<String> names = user.fullName.split(' ');
    String initials = '';
    
    if (names.length >= 2) {
      initials = names[0][0] + names[1][0];
    } else if (names.isNotEmpty) {
      initials = names[0][0];
    }
    
    return initials.toUpperCase();
  }
} 