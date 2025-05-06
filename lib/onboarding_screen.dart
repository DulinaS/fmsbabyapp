/* import 'package:flutter/material.dart';
import 'package:betterme_caregiver_companion/registration_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  final List<String> titles = [
    "Welcome",
    "Tracking Tools",
    "Parenting Tips",
    "Stay Connected",
    "Vaccination Reminder",
  ];

  final List<String> subtitles = [
    "Welcome to BetterMe – your caring companion for a smooth, safe, and healthy parenting journey. 💙",
    "This app helps parents track their baby's growth, feeding, sleep, and diapers while providing guidance on vaccinations, injury care, and first aid.",
    "BetterMe offers educational resources to help parents learn about baby care, including articles, videos, and podcasts on health, safety, and development.",
    "The app will provide a community support feature to help users connect with other users, share experiences, and receive support.",
    "Stay on top of your baby’s immunization schedule with timely vaccine reminders. Get alerts for upcoming vaccinations to ensure your little one stays protected and healthy.",
  ];

  final List<String> imagePaths = [
    "assets/images/start_logo.png",
    "assets/images/onboarding_2.png",
    "assets/images/onboarding_3.jpeg",
    "assets/images/onboarding_4.jpeg",
    "assets/images/onboarding_5.jpeg",
  ];

  void _nextPage() {
    if (_currentPage < 4) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeIn,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: PageView.builder(
        controller: _controller,
        itemCount: 5,
        onPageChanged: (index) {
          setState(() {
            _currentPage = index;
          });
        },
        itemBuilder: (context, index) {
          return Center(
            child: Container(
              width: 360,
              height: 760,
              clipBehavior: Clip.antiAlias,
              decoration: ShapeDecoration(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: Stack(
                children: [
                  // Title above image
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 70,
                    child: Center(
                      child: Text(
                        titles[index],
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFF1873EA),
                          fontSize: 32,
                          fontFamily: 'Nunito',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  // Illustration Image
                  Positioned(
                    left: 47,
                    top: 150,
                    child: Container(
                      width: 266,
                      height: 230,
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage(imagePaths[index]),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),

                  // Description text
                  Positioned(
                    left: 30,
                    top: 400,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 300,
                          child: Text(
                            subtitles[index],
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 14,
                              fontFamily: 'Nunito',
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  if (_currentPage == 4)
                    Positioned(
                      top: 510,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => RegistrationScreen(),
                              ),
                            );
                          },
                          child: Container(
                            width: 196,
                            height: 45,
                            padding: const EdgeInsets.all(10),
                            decoration: ShapeDecoration(
                              color: const Color(0xFF1873EA),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(22),
                              ),
                            ),
                            child: const Center(
                              child: Text(
                                'Get Started',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontFamily: 'Nunito',
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                  // Bottom Navigation (Skip, Page Indicators, Next)
                  Positioned(
                    left: 0,
                    bottom: 0,
                    child: Container(
                      width: 360,
                      height: 80,
                      decoration: BoxDecoration(color: Colors.white),
                      child: Stack(
                        children: [
                          Container(
                            width: 360,
                            height: 80,
                            decoration: ShapeDecoration(
                              color: Colors.white,
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(12),
                                  topRight: Radius.circular(12),
                                ),
                              ),
                              shadows: [
                                BoxShadow(
                                  color: const Color(0x99E5EAED),
                                  blurRadius: 51.10,
                                  offset: const Offset(0, 7.94),
                                ),
                              ],
                            ),
                          ),
                          Positioned(
                            left: 0,
                            right: 0,
                            top: 25,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 30,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  // Skip button
                                  GestureDetector(
                                    onTap: () {
                                      _controller.jumpToPage(4); // Skip to last
                                    },
                                    child: const Text(
                                      'SKIP',
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontSize: 14,
                                        fontFamily: 'Nunito',
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),

                                  // Dots for page indicators
                                  Row(
                                    children: List.generate(5, (dotIndex) {
                                      return Container(
                                        margin: const EdgeInsets.symmetric(
                                          horizontal: 3,
                                        ),
                                        width: 10,
                                        height: 10,
                                        decoration: ShapeDecoration(
                                          color:
                                              _currentPage == dotIndex
                                                  ? const Color(0xFF1873EA)
                                                  : const Color(0xFFD9D9D9),
                                          shape: const OvalBorder(),
                                        ),
                                      );
                                    }),
                                  ),

                                  // Next button
                                  GestureDetector(
                                    onTap: _nextPage,
                                    child: const Text(
                                      'NEXT',
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontSize: 14,
                                        fontFamily: 'Nunito',
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
 */