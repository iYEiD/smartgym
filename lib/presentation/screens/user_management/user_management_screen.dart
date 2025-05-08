import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:smartgymai/core/theme/app_theme.dart';
import 'package:smartgymai/domain/entities/user.dart';
import 'package:smartgymai/presentation/screens/user_management/user_registration_screen.dart';
import 'package:smartgymai/presentation/widgets/user_list_item.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({Key? key}) : super(key: key);

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'All';

  final List<String> _filterOptions = [
    'All',
    'Currently Checked In',
    'Premium',
    'Standard',
    'Basic',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management'),
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
      body: Column(
        children: [
          _buildSearchAndFilterBar(),
          Expanded(
            child: _buildUserList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _navigateToUserRegistration(context);
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSearchAndFilterBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search users...',
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
          const SizedBox(height: 16),
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
        ],
      ),
    );
  }

  Widget _buildUserList() {
    // Placeholder data
    // In a real app, this would be populated from the repository
    final users = _getMockUsers();
    
    // Apply filters and search
    final filteredUsers = users.where((user) {
      // Apply search filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchesName = user.fullName.toLowerCase().contains(query);
        final matchesEmail = (user.email ?? '').toLowerCase().contains(query);
        final matchesPhone = (user.phone ?? '').contains(query);
        
        if (!matchesName && !matchesEmail && !matchesPhone) {
          return false;
        }
      }
      
      // Apply category filter
      switch (_selectedFilter) {
        case 'Currently Checked In':
          return user.isCurrentlyCheckedIn;
        case 'Premium':
        case 'Standard':
        case 'Basic':
          return user.membershipType == _selectedFilter;
        default:
          return true;
      }
    }).toList();
    
    if (filteredUsers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No users found',
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
        // In a real app, this would refresh the user list
        await Future.delayed(const Duration(seconds: 1));
      },
      child: ListView.builder(
        itemCount: filteredUsers.length,
        itemBuilder: (context, index) {
          final user = filteredUsers[index];
          return UserListItem(
            user: user,
            onTap: () {
              _navigateToUserDetails(context, user);
            },
            onCheckIn: () {
              _checkInUser(user);
            },
            onCheckout: () {
              _checkoutUser(user);
            },
          );
        },
      ),
    );
  }

  List<User> _getMockUsers() {
    final now = DateTime.now();
    return [
      User(
        id: '1',
        firstName: 'John',
        lastName: 'Doe',
        email: 'john.doe@example.com',
        phone: '(123) 456-7890',
        membershipType: 'Premium',
        lastCheckIn: now.subtract(const Duration(hours: 1)),
        registrationDate: DateTime(2022, 1, 15),
      ),
      User(
        id: '2',
        firstName: 'Jane',
        lastName: 'Smith',
        email: 'jane.smith@example.com',
        phone: '(234) 567-8901',
        membershipType: 'Standard',
        lastCheckIn: now.subtract(const Duration(days: 2)),
        lastCheckout: now.subtract(const Duration(days: 2, hours: 2)),
        registrationDate: DateTime(2022, 3, 10),
      ),
      User(
        id: '3',
        firstName: 'Michael',
        lastName: 'Johnson',
        email: 'michael.j@example.com',
        phone: '(345) 678-9012',
        membershipType: 'Basic',
        lastCheckIn: now.subtract(const Duration(hours: 5)),
        lastCheckout: now.subtract(const Duration(hours: 3)),
        registrationDate: DateTime(2022, 5, 20),
      ),
      User(
        id: '4',
        firstName: 'Sarah',
        lastName: 'Williams',
        email: 'sarah.w@example.com',
        phone: '(456) 789-0123',
        membershipType: 'Premium',
        lastCheckIn: now.subtract(const Duration(days: 1)),
        lastCheckout: now.subtract(const Duration(days: 1, hours: 2)),
        registrationDate: DateTime(2022, 2, 8),
      ),
      User(
        id: '5',
        firstName: 'David',
        lastName: 'Brown',
        email: 'david.brown@example.com',
        phone: '(567) 890-1234',
        membershipType: 'Standard',
        registrationDate: DateTime(2022, 4, 15),
      ),
    ];
  }

  void _navigateToUserRegistration(BuildContext context) {
    // In a real app, this would navigate to the registration screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('User registration would open here'),
      ),
    );
  }

  void _navigateToUserDetails(BuildContext context, User user) {
    // In a real app, this would navigate to the user details screen
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('User details for ${user.fullName} would open here'),
      ),
    );
  }

  void _checkInUser(User user) {
    // In a real app, this would check in the user via the repository
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${user.fullName} has been checked in'),
        backgroundColor: AppTheme.occupancyLowColor,
      ),
    );
  }

  void _checkoutUser(User user) {
    // In a real app, this would check out the user via the repository
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${user.fullName} has been checked out'),
        backgroundColor: AppTheme.occupancyHighColor,
      ),
    );
  }
} 