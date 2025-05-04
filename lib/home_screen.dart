import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'child_service.dart';
import 'child_model.dart';
import 'vaccination_page.dart';
import 'growth_milestone_page.dart';
import 'nutrition.dart';
import 'baby_details_screen.dart';
import 'placeholder_page.dart';

class HomeScreen extends StatefulWidget {
  final String? initialChildId; // Optional starting child

  const HomeScreen({Key? key, this.initialChildId}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late ChildService _childService;
  String? _selectedChildId;
  List<Child> _children = [];
  bool _isLoading = true;
  Child? _selectedChild;
  int _selectedIndex = 0;
  
  // Get current date
  final DateTime _currentDate = DateTime.now();

  // Updated feature list to use only childId without child object
  final List<Map<String, dynamic>> features = [
    {
      'label': 'Vaccinations',
      'image': 'assets/images/vaccination.png',
      'getPage': (String childId) => VaccinationPage(childId: childId),
    },
    {
      'label': 'Growth',
      'image': 'assets/images/Milestones.png',
      'getPage': (String childId) => GrowthMilestonePage(childId: childId),
    },
    {
      'label': 'Safety & First Aid',
      'image': 'assets/images/first_aid.png',
      'getPage': (String childId) => PlaceholderPage(title: 'Safety & First Aid'),
    },
    {
      'label': 'Hospitals',
      'image': 'assets/images/Hospital.png',
      'getPage': (String childId) => PlaceholderPage(title: 'Hospitals'),
    },
    {
      'label': 'Nutrition & Feeding',
      'image': 'assets/images/nutrition.png',
      'getPage': (String childId) => BabyFeedingFAQPage(),
    },
    {
      'label': 'Your New Born',
      'image': 'assets/images/article.png',
      'getPage': (String childId) => PlaceholderPage(title: 'Your New Born'),
    },
  ];

  @override
  void initState() {
    super.initState();
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      _childService = ChildService(currentUser.uid);
      _selectedChildId = widget.initialChildId;
      _loadChildren();
    } else {
      // Handle not logged in case
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/login');
      });
    }
  }

  Future<void> _loadChildren() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Subscribe to the children stream
      _childService.getChildren().listen((children) {
        if (mounted) {
          setState(() {
            _children = children;
            
            // If no child is selected and we have children, select the first one
            if ((_selectedChildId == null || _selectedChild == null) && children.isNotEmpty) {
              _selectedChildId = children[0].id;
            }
            
            // Update selected child
            if (_selectedChildId != null) {
              _selectedChild = children.firstWhere(
                (child) => child.id == _selectedChildId,
                orElse: () => children[0],
              );
            }
            
            _isLoading = false;
          });
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        // Show error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading children: ${e.toString()}')),
        );
      }
    }
  }

  // Logout function
  Future<void> _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      // Navigate to login screen after logout
      Navigator.of(context).pushReplacementNamed('/login');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error signing out: ${e.toString()}')),
      );
    }
  }

  // Calculate week number from birth date to today
  int calculateWeeksSinceBirth(DateTime birthDate) {
    final difference = _currentDate.difference(birthDate).inDays;
    return (difference / 7).ceil();
  }

  // Generate a list of weeks for the horizontal scroller
  List<Map<String, String>> generateWeeks() {
    if (_selectedChild == null) return [];
    
    final birthDate = _selectedChild!.dateOfBirth;
    final currentWeek = calculateWeeksSinceBirth(birthDate);
    
    // Generate the current week and 3 weeks before and after
    List<Map<String, String>> weeks = [];
    for (int i = currentWeek - 3; i <= currentWeek + 3; i++) {
      if (i <= 0) continue; // Skip negative weeks
      
      final weekDate = birthDate.add(Duration(days: (i - 1) * 7));
      weeks.add({
        'week': 'Week $i',
        'date': DateFormat('MMM d').format(weekDate),
        'isActive': (i == currentWeek).toString(),
      });
    }
    
    return weeks;
  }

  Widget buildWeekCard(String week, String date, {bool isActive = false}) {
    return Container(
      width: 85,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF1873EA) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            week,
            style: TextStyle(
              color: isActive ? Colors.white : const Color(0xFF8C8A8A),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            date,
            style: TextStyle(
              color: isActive ? Colors.white : Colors.black87,
              fontSize: 12,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  // Updated to use only childId and not child object
  Widget buildFeatureCard(
    BuildContext context,
    String label, {
    String? imageUrl,
    required Function(String) getPage,
  }) {
    return GestureDetector(
      onTap: () {
        if (_selectedChildId != null) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => getPage(_selectedChildId!)),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Please select a child first')),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (imageUrl != null && imageUrl.isNotEmpty)
              Image.asset(imageUrl, width: 40, height: 40, fit: BoxFit.contain)
            else
              const SizedBox(width: 40, height: 40),
            const SizedBox(height: 12),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBabyStatItem(String label, String value) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF8C8A8A),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF333333),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoChildrenView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.child_care, size: 84, color: Color(0xFF1873EA).withOpacity(0.6)),
          SizedBox(height: 24),
          Text(
            'No babies added yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          SizedBox(height: 16),
          Text(
            'Add your first baby to get started',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 32),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => BabyDetailsScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF1873EA),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
            child: Text(
              'Add Your First Baby',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  void _onNavItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    
    // Handle navigation based on index
    switch (index) {
      case 0: // Home - Already there
        break;
      case 1: // Search
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Search functionality coming soon!')),
        );
        break;
      case 2: // Favorites
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Favorites functionality coming soon!')),
        );
        break;
      case 3: // Profile
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Profile functionality coming soon!')),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get current user name
    final User? currentUser = FirebaseAuth.instance.currentUser;
    final String? userEmail = currentUser?.email;
    
    return Scaffold(
      backgroundColor: Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Baby Tracker',
          style: TextStyle(
            color: Color(0xFF1873EA),
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.menu, color: Color(0xFF1873EA)),
          onPressed: () {
            // Menu functionality
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Menu functionality coming soon!')),
            );
          },
        ),
        actions: [
          // Child dropdown selector
          _isLoading
              ? Container(width: 40, height: 40, padding: EdgeInsets.all(10), child: CircularProgressIndicator(strokeWidth: 2))
              : _children.isEmpty
                  ? TextButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => BabyDetailsScreen(),
                          ),
                        );
                      },
                      icon: Icon(Icons.add, size: 18),
                      label: Text('Add Baby'),
                      style: TextButton.styleFrom(
                        foregroundColor: Color(0xFF1873EA),
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Color(0xFF1873EA).withOpacity(0.3)),
                        ),
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        margin: EdgeInsets.only(right: 8),
                        child: DropdownButton<String>(
                          value: _selectedChildId,
                          icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF1873EA)),
                          elevation: 16,
                          style: TextStyle(color: Color(0xFF1873EA), fontWeight: FontWeight.w600),
                          underline: Container(height: 0),
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedChildId = newValue;
                              if (_selectedChildId != null) {
                                _selectedChild = _children.firstWhere(
                                  (child) => child.id == _selectedChildId,
                                  orElse: () => _children.first,
                                );
                              }
                            });
                          },
                          items: _children.map<DropdownMenuItem<String>>((Child child) {
                            // Show name and birth year
                            String displayText = '${child.name} (${child.dateOfBirth.year})';
                            
                            return DropdownMenuItem<String>(
                              value: child.id,
                              child: Text(displayText, style: TextStyle(fontSize: 14)),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
          // User profile with dropdown menu
          Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: PopupMenuButton<String>(
              offset: Offset(0, 40),
              onSelected: (value) {
                if (value == 'logout') {
                  _logout();
                } else if (value == 'profile') {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Profile functionality coming soon!')),
                  );
                } else if (value == 'settings') {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Settings functionality coming soon!')),
                  );
                }
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                PopupMenuItem<String>(
                  value: 'account',
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 15,
                        backgroundColor: Color(0xFF1873EA).withOpacity(0.2),
                        child: Icon(Icons.person, color: Color(0xFF1873EA), size: 18),
                      ),
                      SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Account',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            userEmail ?? 'Unknown',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                PopupMenuItem<String>(
                  value: 'profile',
                  child: Row(
                    children: [
                      Icon(Icons.account_circle, color: Color(0xFF1873EA), size: 20),
                      SizedBox(width: 10),
                      Text('Profile'),
                    ],
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'settings',
                  child: Row(
                    children: [
                      Icon(Icons.settings, color: Color(0xFF1873EA), size: 20),
                      SizedBox(width: 10),
                      Text('Settings'),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                PopupMenuItem<String>(
                  value: 'logout',
                  child: Row(
                    children: [
                      Icon(Icons.logout, color: Colors.red, size: 20),
                      SizedBox(width: 10),
                      Text('Logout', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
              child: CircleAvatar(
                radius: 18,
                backgroundColor: Color(0xFF1873EA),
                child: Icon(Icons.person, color: Colors.white, size: 20),
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _children.isEmpty
              ? _buildNoChildrenView()
              : _selectedChild == null
                  ? Center(child: Text('Please select a child'))
                  : _buildHomeContentForChild(_selectedChild!),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Color(0x99E5EAED),
              blurRadius: 20,
              offset: Offset(0, -2),
              spreadRadius: 0,
            )
          ],
        ),
        child: BottomNavigationBar(
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.search),
              label: 'Search',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.favorite_border),
              activeIcon: Icon(Icons.favorite),
              label: 'Favorites',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: Color(0xFF1873EA),
          unselectedItemColor: Colors.grey[600],
          onTap: _onNavItemTapped,
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          elevation: 0,
        ),
      ),
    );
  }

  Widget _buildHomeContentForChild(Child child) {
    // Calculate the current week
    final currentWeek = calculateWeeksSinceBirth(child.dateOfBirth);
    final weeks = generateWeeks();
    
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        children: [
          // Welcome section with gradient background
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1873EA).withOpacity(0.9), Color(0xFF1873EA).withOpacity(0.7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hello Parent,',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  "${child.name}'s Growth Journey",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  "Week $currentWeek of development",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          
          SizedBox(height: 24),
          
          // Week scroller
          Container(
            height: 85,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: weeks.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: buildWeekCard(
                    weeks[index]['week']!,
                    weeks[index]['date']!,
                    isActive: weeks[index]['isActive'] == 'true',
                  ),
                );
              },
            ),
          ),
          
          SizedBox(height: 24),
          
          // Baby info card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        color: Color(0xFF1873EA).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(45),
                        child: Image.asset(
                          child.gender == 'boy' 
                            ? 'assets/images/baby.png' 
                            : 'assets/images/baby.png',
                          width: 150,
                          height: 150,
                          fit: BoxFit.cover,
                          errorBuilder: (ctx, obj, stack) => Icon(
                            Icons.child_care,
                            size: 50,
                            color: Color(0xFF1873EA),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            child.name,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF333333),
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            "Born ${DateFormat('MMMM d, yyyy').format(child.dateOfBirth)}",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            "Age: $currentWeek weeks",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF1873EA),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                SizedBox(height: 24),
                
                // Stats row
                Row(
                  children: [
                    Expanded(
                      child: _buildBabyStatItem(
                        'Height',
                        '${child.height != null ? child.height!.toStringAsFixed(1) : "N/A"} cm',
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: _buildBabyStatItem(
                        'Weight',
                        '${child.weight != null ? child.weight!.toStringAsFixed(0) : "N/A"} g',
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: _buildBabyStatItem(
                        'Gender',
                        child.gender.substring(0, 1).toUpperCase() + child.gender.substring(1),
                      ),
                    ),
                  ],
                ),
                
                SizedBox(height: 16),
                
                // Growth milestone link
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => GrowthMilestonePage(childId: child.id),
                      ),
                    );
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF1873EA), Color(0xFF3D95FF)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Track Growth Milestones",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward,
                          color: Colors.white,
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          SizedBox(height: 24),
          
          // Features grid
          Text(
            "Baby Care Options",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF333333),
            ),
          ),
          
          SizedBox(height: 16),
          
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.1,
            ),
            itemCount: features.length,
            itemBuilder: (context, index) {
              return buildFeatureCard(
                context,
                features[index]['label'],
                imageUrl: features[index]['image'],
                getPage: features[index]['getPage'],
              );
            },
          ),
          
          SizedBox(height: 24),
        ],
      ),
    );
  }
}