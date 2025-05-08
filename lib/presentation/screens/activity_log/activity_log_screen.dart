import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:smartgymai/core/theme/app_theme.dart';
import 'package:smartgymai/domain/entities/check_in_log.dart';
import 'package:smartgymai/domain/entities/user.dart';

class ActivityLogScreen extends StatefulWidget {
  const ActivityLogScreen({Key? key}) : super(key: key);

  @override
  State<ActivityLogScreen> createState() => _ActivityLogScreenState();
}

class _ActivityLogScreenState extends State<ActivityLogScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'All';
  String _selectedTimeRange = 'Today';

  final List<String> _filterOptions = [
    'All',
    'Active',
    'Completed',
  ];

  final List<String> _timeRangeOptions = [
    'Today',
    'Yesterday',
    'This Week',
    'This Month',
    'Custom',
  ];

  DateTimeRange? _customDateRange;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Activity Log'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              _showFilterDialog(context);
            },
          ),
          IconButton(
            icon: const Icon(Icons.file_download),
            onPressed: () {
              _exportActivityLog();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildFilterChips(),
          Expanded(
            child: _buildActivityList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search by name...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    setState(() {
                      _searchController.clear();
                      _searchQuery = '';
                    });
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          fillColor: Theme.of(context).colorScheme.surface,
          filled: true,
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
      ),
    );
  }

  Widget _buildFilterChips() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Status',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _filterOptions.map((filter) {
                final isSelected = _selectedFilter == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(filter),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedFilter = filter;
                      });
                    },
                    backgroundColor: Colors.white,
                    selectedColor: AppTheme.primaryColor.withOpacity(0.2),
                    checkmarkColor: AppTheme.primaryColor,
                    labelStyle: TextStyle(
                      color: isSelected
                          ? AppTheme.primaryColor
                          : Theme.of(context).colorScheme.onSurface,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Time Range',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              if (_customDateRange != null)
                TextButton(
                  onPressed: () {
                    setState(() {
                      _customDateRange = null;
                      _selectedTimeRange = 'Today';
                    });
                  },
                  child: const Text('Clear Dates'),
                ),
            ],
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _timeRangeOptions.map((timeRange) {
                final isSelected = _selectedTimeRange == timeRange;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(timeRange),
                    selected: isSelected,
                    onSelected: (selected) async {
                      if (timeRange == 'Custom' && selected) {
                        final result = await _selectDateRange(context);
                        if (result != null) {
                          setState(() {
                            _customDateRange = result;
                            _selectedTimeRange = timeRange;
                          });
                        }
                      } else {
                        setState(() {
                          _selectedTimeRange = timeRange;
                          if (timeRange != 'Custom') {
                            _customDateRange = null;
                          }
                        });
                      }
                    },
                    backgroundColor: Colors.white,
                    selectedColor: AppTheme.primaryColor.withOpacity(0.2),
                    checkmarkColor: AppTheme.primaryColor,
                    labelStyle: TextStyle(
                      color: isSelected
                          ? AppTheme.primaryColor
                          : Theme.of(context).colorScheme.onSurface,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          if (_customDateRange != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'From ${DateFormat('MMM d, yyyy').format(_customDateRange!.start)} to ${DateFormat('MMM d, yyyy').format(_customDateRange!.end)}',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          const SizedBox(height: 16),
          const Divider(),
        ],
      ),
    );
  }

  Widget _buildActivityList() {
    // Placeholder data
    // In a real app, this would come from the repository
    final activities = _getMockActivities();
    
    // Apply filters and search
    final filteredActivities = activities.where((activity) {
      // Apply search
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchesName = activity.userName.toLowerCase().contains(query);
        
        if (!matchesName) {
          return false;
        }
      }
      
      // Apply status filter
      switch (_selectedFilter) {
        case 'Active':
          return activity.isActive;
        case 'Completed':
          return !activity.isActive;
        default:
          return true;
      }
      
      // Apply time filter based on _selectedTimeRange and _customDateRange
      // This would be implemented in a real app
    }).toList();
    
    if (filteredActivities.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_busy,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No activity records found',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your search or filters',
              style: TextStyle(
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }
    
    return RefreshIndicator(
      onRefresh: () async {
        // Pull to refresh functionality
        // In a real app, this would refresh the activity log
        await Future.delayed(const Duration(seconds: 1));
      },
      child: ListView.builder(
        itemCount: filteredActivities.length,
        itemBuilder: (context, index) {
          final activity = filteredActivities[index];
          return _buildActivityItem(activity);
        },
      ),
    );
  }

  Widget _buildActivityItem(ActivityRecord activity) {
    final theme = Theme.of(context);
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: activity.isActive
                    ? AppTheme.occupancyLowColor.withOpacity(0.2)
                    : AppTheme.disabledColor.withOpacity(0.2),
                  child: Icon(
                    activity.isActive ? Icons.person : Icons.person_outline,
                    color: activity.isActive
                      ? AppTheme.occupancyLowColor
                      : AppTheme.disabledColor,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        activity.userName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        activity.membershipType,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: _getMembershipColor(activity.membershipType),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: activity.isActive
                      ? AppTheme.occupancyLowColor.withOpacity(0.2)
                      : AppTheme.disabledColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    activity.isActive ? 'Active' : 'Completed',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: activity.isActive
                        ? AppTheme.occupancyLowColor
                        : AppTheme.disabledColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Check In',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppTheme.onSurfaceColor.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('MMM d, h:mm a').format(activity.checkInTime),
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                if (activity.checkoutTime != null)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Check Out',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppTheme.onSurfaceColor.withOpacity(0.7),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('MMM d, h:mm a').format(activity.checkoutTime!),
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Duration',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppTheme.onSurfaceColor.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        activity.isActive
                          ? 'In progress'
                          : _formatDuration(activity.durationMinutes),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: activity.isActive ? FontWeight.bold : null,
                          color: activity.isActive ? AppTheme.occupancyLowColor : null,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getMembershipColor(String membershipType) {
    switch (membershipType.toLowerCase()) {
      case 'premium':
        return Colors.amber;
      case 'standard':
        return Colors.blue;
      case 'basic':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _formatDuration(int? minutes) {
    if (minutes == null) return 'N/A';
    
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    
    if (hours > 0) {
      return '$hours hr ${mins > 0 ? '$mins min' : ''}';
    } else {
      return '$mins min';
    }
  }

  Future<DateTimeRange?> _selectDateRange(BuildContext context) async {
    final now = DateTime.now();
    final firstDate = now.subtract(const Duration(days: 365));
    final lastDate = now;
    
    return showDateRangePicker(
      context: context,
      firstDate: firstDate,
      lastDate: lastDate,
      initialDateRange: _customDateRange ?? DateTimeRange(
        start: now.subtract(const Duration(days: 7)),
        end: now,
      ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppTheme.primaryColor,
            ),
            appBarTheme: Theme.of(context).appBarTheme.copyWith(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: AppTheme.onPrimaryColor,
            ),
          ),
          child: child!,
        );
      },
    );
  }

  void _showFilterDialog(BuildContext context) {
    // In a real app, this would show a dialog with more advanced filter options
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Advanced filter options would show here'),
      ),
    );
  }

  void _exportActivityLog() {
    // In a real app, this would export the activity log to a file
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Exporting activity log...'),
      ),
    );
  }

  List<ActivityRecord> _getMockActivities() {
    final now = DateTime.now();
    
    return [
      ActivityRecord(
        id: '1',
        userId: '1',
        userName: 'John Doe',
        membershipType: 'Premium',
        checkInTime: now.subtract(const Duration(hours: 1)),
        checkoutTime: null,
        durationMinutes: null,
      ),
      ActivityRecord(
        id: '2',
        userId: '2',
        userName: 'Jane Smith',
        membershipType: 'Standard',
        checkInTime: now.subtract(const Duration(hours: 3)),
        checkoutTime: now.subtract(const Duration(hours: 1)),
        durationMinutes: 120,
      ),
      ActivityRecord(
        id: '3',
        userId: '3',
        userName: 'Michael Johnson',
        membershipType: 'Basic',
        checkInTime: now.subtract(const Duration(hours: 5)),
        checkoutTime: now.subtract(const Duration(hours: 3)),
        durationMinutes: 120,
      ),
      ActivityRecord(
        id: '4',
        userId: '4',
        userName: 'Sarah Williams',
        membershipType: 'Premium',
        checkInTime: now.subtract(const Duration(days: 1)),
        checkoutTime: now.subtract(const Duration(days: 1, hours: 2)),
        durationMinutes: 120,
      ),
      ActivityRecord(
        id: '5',
        userId: '5',
        userName: 'David Brown',
        membershipType: 'Standard',
        checkInTime: now.subtract(const Duration(days: 2)),
        checkoutTime: now.subtract(const Duration(days: 2, hours: 1)),
        durationMinutes: 60,
      ),
    ];
  }
}

class ActivityRecord {
  final String id;
  final String userId;
  final String userName;
  final String membershipType;
  final DateTime checkInTime;
  final DateTime? checkoutTime;
  final int? durationMinutes;

  const ActivityRecord({
    required this.id,
    required this.userId,
    required this.userName,
    required this.membershipType,
    required this.checkInTime,
    this.checkoutTime,
    this.durationMinutes,
  });

  bool get isActive => checkoutTime == null;
} 