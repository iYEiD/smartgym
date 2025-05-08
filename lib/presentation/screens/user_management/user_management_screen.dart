import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:smartgymai/core/theme/app_theme.dart';
import 'package:smartgymai/domain/entities/user.dart';
import 'package:smartgymai/presentation/screens/user_management/user_registration_screen.dart';
import 'package:smartgymai/presentation/widgets/user_list_item.dart';
import 'package:smartgymai/providers/users_provider.dart';

class UserManagementScreen extends ConsumerStatefulWidget {
  const UserManagementScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends ConsumerState<UserManagementScreen> {
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
  void initState() {
    super.initState();
    // Refresh users data when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(usersProvider.notifier).fetchUsers();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Watch the users state
    final usersState = ref.watch(usersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              // Refresh users data
              ref.read(usersProvider.notifier).fetchUsers();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchAndFilterBar(),
          if (usersState.isLoading) 
            const Expanded(
              child: Center(
                child: CircularProgressIndicator(),
              ),
            )
          else if (usersState.errorMessage != null)
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
                      'Error loading users',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        usersState.errorMessage!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey[500],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        ref.read(usersProvider.notifier).fetchUsers();
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
              child: _buildUserList(usersState.users),
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

  Widget _buildUserList(List<User> users) {
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
        await ref.read(usersProvider.notifier).fetchUsers();
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

  void _navigateToUserRegistration(BuildContext context) async {
    // Navigate to registration screen and refresh users when returning
    final result = await Navigator.push<User?>(
      context,
      MaterialPageRoute(
        builder: (context) => const UserRegistrationScreen(),
      ),
    );
    
    if (result != null) {
      // User was registered, refresh the list
      if (mounted) {
        ref.read(usersProvider.notifier).fetchUsers();
      }
    }
  }

  void _navigateToUserDetails(BuildContext context, User user) {
    // In a real app, this would navigate to the user details screen
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('User details for ${user.fullName} would open here'),
      ),
    );
  }

  void _checkInUser(User user) async {
    try {
      // Call the check-in method from the provider
      await ref.read(usersProvider.notifier).checkInUser(user.id);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${user.fullName} has been checked in'),
            backgroundColor: AppTheme.occupancyLowColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error checking in: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  void _checkoutUser(User user) async {
    try {
      // Call the check-out method from the provider
      await ref.read(usersProvider.notifier).checkOutUser(user.id);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${user.fullName} has been checked out'),
            backgroundColor: AppTheme.occupancyHighColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error checking out: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }
} 