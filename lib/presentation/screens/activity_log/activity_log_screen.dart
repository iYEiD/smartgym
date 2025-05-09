import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:smartgymai/core/theme/app_theme.dart';
import 'package:smartgymai/domain/entities/check_in_log.dart';
import 'package:smartgymai/domain/entities/user.dart';
import 'package:smartgymai/providers/activities_provider.dart';
import 'package:smartgymai/providers/users_provider.dart';
import 'package:smartgymai/data/models/check_in_log_model.dart';

class ActivityLogScreen extends ConsumerStatefulWidget {
  const ActivityLogScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ActivityLogScreen> createState() => _ActivityLogScreenState();
}

class _ActivityLogScreenState extends ConsumerState<ActivityLogScreen> {
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
  void initState() {
    super.initState();
    // Fetch activities when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(activitiesProvider.notifier).fetchActivities();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Watch the activities state
    final activitiesState = ref.watch(activitiesProvider);
    // Watch the users state to get user names
    final usersState = ref.watch(usersProvider);

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
          if (activitiesState.isLoading) 
            const Expanded(
              child: Center(
                child: CircularProgressIndicator(),
              ),
            )
          else if (activitiesState.errorMessage != null)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error loading activities',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        activitiesState.errorMessage!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey[500],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        ref.read(activitiesProvider.notifier).fetchActivities();
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Try Again'),
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: _buildActivityList(
                activities: activitiesState.activities,
                users: usersState.users,
              ),
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

  Widget _buildActivityList({
    required List<CheckInLog> activities,
    required List<User> users,
  }) {
    // Apply filters and search
    final filteredActivities = activities.where((activity) {
      // Get user name from activity if it's a CheckInLogModel with firstName/lastName
      String fullName = 'Unknown User';
      if (activity is CheckInLogModel && activity.firstName != null && activity.lastName != null) {
        fullName = activity.fullName;
      } else {
        // Fallback to looking up user from the users list
        final user = users.firstWhere(
          (u) => u.id == activity.userId,
          orElse: () => User(
            id: activity.userId,
            firstName: 'Unknown', 
            lastName: 'User',
            membershipType: 'Unknown',
            registrationDate: DateTime.now(),
          ),
        );
        fullName = user.fullName;
      }
      
      // Apply search
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchesName = fullName.toLowerCase().contains(query);
        
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
      
      // Time filter logic would go here
      // This would use _selectedTimeRange and _customDateRange
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
        await ref.read(activitiesProvider.notifier).fetchActivities();
      },
      child: ListView.builder(
        itemCount: filteredActivities.length,
        itemBuilder: (context, index) {
          final activity = filteredActivities[index];
          // Find the associated user
          final user = users.firstWhere(
            (u) => u.id == activity.userId,
            orElse: () => User(
              id: activity.userId,
              firstName: 'Unknown', 
              lastName: 'User',
              membershipType: 'Unknown',
              registrationDate: DateTime.now(),
            ),
          );
          
          return _buildActivityItem(activity, user);
        },
      ),
    );
  }

  Widget _buildActivityItem(CheckInLog activity, User user) {
    final theme = Theme.of(context);
    
    // Get user information directly from CheckInLogModel if available
    String fullName = user.fullName;
    String membershipType = user.membershipType;
    
    if (activity is CheckInLogModel) {
      if (activity.firstName != null && activity.lastName != null) {
        fullName = activity.fullName;
      }
      if (activity.membershipType != null) {
        membershipType = activity.membershipType!;
      }
    }
    
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
                        fullName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        membershipType,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: _getMembershipColor(membershipType),
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
} 