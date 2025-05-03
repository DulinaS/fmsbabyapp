import 'package:flutter/material.dart';

import 'vaccination.dart';
import 'growth_milestone_page.dart';
import 'nutrition.dart';

class HomeScreen extends StatelessWidget {
  final List<Map<String, String>> days = [
    {'day': 'Mon', 'date': '16'},
    {'day': 'Tue', 'date': '17'},
    {'day': 'Wed', 'date': '18'},
    {'day': 'Thu', 'date': '19'},
    {'day': 'Fri', 'date': '20'},
    {'day': 'Sat', 'date': '21'},
    {'day': 'Sun', 'date': '22'},
  ];

  final List<Map<String, dynamic>> features = [
    {
      'label': 'Vaccinations',
      'image': 'assets/images/vaccination.png',
      'page': VaccinationPage(),
    },
    {
      'label': 'Growth',
      'image': 'assets/images/Milestones.png',
      'page': GrowthMilestonePage(),
    },
    {
      'label': 'Safety & First Aid',
      'image': 'assets/images/first_aid.png',
      'page': VaccinationPage(),
    },
    {
      'label': 'Hospitals',
      'image': 'assets/images/Hospital.png',
      'page': VaccinationPage(),
    },
    {
      'label': 'Nutrition & Feeding',
      'image': 'assets/images/nutrition.png',
      'page': BabyFeedingFAQPage(),
    },
    {
      'label': 'Your New Born',
      'image': 'assets/images/article.png',
      'page': VaccinationPage(),
    },
  ];

  HomeScreen({Key? key}) : super(key: key);

  Widget buildDayCard(String day, String date, {bool isActive = false}) {
    return Container(
      width: 48,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF1873EA) : Colors.white,
        borderRadius: BorderRadius.circular(8),
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
            day,
            style: TextStyle(
              color: isActive ? Colors.white : const Color(0xFF8C8A8A),
              fontSize: 12,
              fontFamily: 'Nunito',
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            date,
            style: TextStyle(
              color: isActive ? Colors.white : Colors.black,
              fontSize: 16,
              fontFamily: 'Nunito',
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildFeatureBox(
    BuildContext context,
    String label, {
    String? imageUrl,
    Widget? page,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    // Calculate to fit 3 items per row with padding
    final itemWidth = (screenWidth - 64) / 3;
    
    return GestureDetector(
      onTap: () {
        if (page != null) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => page),
          );
        }
      },
      child: Container(
        width: itemWidth,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFDADCE0), width: 1),
          boxShadow: [
            BoxShadow(
              color: const Color(0x1A000000),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (imageUrl != null && imageUrl.isNotEmpty)
              Image.asset(imageUrl, width: 32, height: 32, fit: BoxFit.contain)
            else
              const SizedBox(width: 32, height: 32),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 12,
                fontFamily: 'Nunito',
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Home',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: const Icon(Icons.menu, color: Colors.black87),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: Colors.blue,
              child: Icon(Icons.person, color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Hello Piumini.W',
              style: TextStyle(
                color: Color(0xFF8C8A8A),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "16th Week of Baby Sasank's Growth",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF333333),
              ),
            ),
            const SizedBox(height: 20),
            // Calendar days
            SizedBox(
              height: 70,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: days.length,
                itemBuilder: (context, index) {
                  bool isActive = days[index]['day'] == 'Wed';
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: buildDayCard(
                      days[index]['day']!,
                      days[index]['date']!,
                      isActive: isActive,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            // Baby info card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
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
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.asset(
                          'assets/images/profile.png',
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Text(
                          'Is my Baby doing Great?',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Stats row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildBabyStatItem('Baby Height', '17 cm'),
                      _buildBabyStatItem('Baby Weight', '110 g'),
                      _buildBabyStatItem('Gender', 'Male'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Features grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.9,
              ),
              itemCount: features.length,
              itemBuilder: (context, index) {
                return buildFeatureBox(
                  context,
                  features[index]['label'],
                  imageUrl: features[index]['image'],
                  page: features[index]['page'],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBabyStatItem(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF8C8A8A),
              fontSize: 12,
              fontFamily: 'Nunito',
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontFamily: 'Nunito',
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}