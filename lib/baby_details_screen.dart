/* import 'package:flutter/material.dart';
import 'package:fmsbabyapp/home_screen.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'child_service.dart';

class BabyDetailsScreen extends StatefulWidget {
  final String?
  nextScreenRoute; // Optional route to navigate to after adding baby

  const BabyDetailsScreen({Key? key, this.nextScreenRoute}) : super(key: key);

  @override
  State<BabyDetailsScreen> createState() => _BabyDetailsScreenState();
}

class _BabyDetailsScreenState extends State<BabyDetailsScreen> {
  bool isBoySelected = true;
  DateTime? selectedDate;
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _circumferenceController =
      TextEditingController();

  bool _isLoading = false;
  late ChildService _childService;

  @override
  void initState() {
    super.initState();
    // Initialize the child service with current user ID
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      _childService = ChildService(currentUser.uid);
    } else {
      // Handle not logged in case (redirect to login or show error)
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/login');
      });
    }
  }

  @override
  void dispose() {
    _dobController.dispose();
    _nameController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _circumferenceController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(DateTime.now().year - 2),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary:
                  isBoySelected
                      ? const Color(0xFF1873EA)
                      : const Color(0xFFF50ED6),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        selectedDate = picked;
        _dobController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  Color get primaryColor =>
      isBoySelected ? const Color(0xFF1873EA) : const Color(0xFFF50ED6);

  // Save baby details to Firebase
  Future<void> _saveBabyDetails() async {
    // Validate required fields
    if (_nameController.text.isEmpty || selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please fill all required fields"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Parse optional numeric fields
      double? weight =
          _weightController.text.isNotEmpty
              ? double.tryParse(_weightController.text)
              : null;

      double? height =
          _heightController.text.isNotEmpty
              ? double.tryParse(_heightController.text)
              : null;

      double? headCircumference =
          _circumferenceController.text.isNotEmpty
              ? double.tryParse(_circumferenceController.text)
              : null;

      // Add child to Firebase
      await _childService.addChild(
        name: _nameController.text,
        dateOfBirth: selectedDate!,
        gender: isBoySelected ? 'boy' : 'girl',
        weight: weight,
        height: height,
        headCircumference: headCircumference,
      );

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Baby added successfully!"),
            backgroundColor: Colors.green,
          ),
        );
      }

      // Navigate to next screen if specified
      if ( mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomeScreen()),
        );
      }
    } catch (e) {
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error adding baby: ${e.toString()}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Back Button
                Align(
                  alignment: Alignment.topLeft,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                ),

                const SizedBox(height: 15),

                // App Logo/Mascot
                Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withOpacity(0.2),
                        spreadRadius: 2,
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(75),
                    child: Image.asset(
                      'assets/images/start_logo.jpeg',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),

                const SizedBox(height: 25),

                // Title
                Text(
                  "Let's Start the Journey",
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: primaryColor,
                  ),
                ),

                const SizedBox(height: 8),

                // Subtitle
                Text(
                  "Add your baby's details",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: Colors.grey[600],
                  ),
                ),

                const SizedBox(height: 30),

                // Gender Selection
                Container(
                  width: 280,
                  height: 55,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(27.5),
                    color: const Color(0xFFEEEEEE),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.15),
                        spreadRadius: 1,
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      // Gender selection highlight
                      AnimatedPositioned(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeInOut,
                        left: isBoySelected ? 140 : 0,
                        child: Container(
                          width: 140,
                          height: 55,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(27.5),
                            color: primaryColor,
                          ),
                        ),
                      ),

                      // Gender text and icons
                      Row(
                        children: [
                          // Girl Option
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  isBoySelected = false;
                                });
                              },
                              child: Center(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.female,
                                      size: 24,
                                      color:
                                          !isBoySelected
                                              ? Colors.white
                                              : Colors.black54,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      "Girl",
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color:
                                            !isBoySelected
                                                ? Colors.white
                                                : Colors.black54,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          // Boy Option
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  isBoySelected = true;
                                });
                              },
                              child: Center(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.male,
                                      size: 24,
                                      color:
                                          isBoySelected
                                              ? Colors.white
                                              : Colors.black54,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      "Boy",
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color:
                                            isBoySelected
                                                ? Colors.white
                                                : Colors.black54,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // Baby's Name Input (Required)
                _buildInputField(
                  controller: _nameController,
                  hintText: "Baby's Name",
                  icon: Icons.person,
                  isRequired: true,
                ),

                const SizedBox(height: 16),

                // Date of Birth Input with Date Picker (Required)
                Stack(
                  children: [
                    AbsorbPointer(
                      child: _buildInputField(
                        controller: _dobController,
                        hintText: "Tap to Select Date Of Birth",
                        icon: Icons.calendar_today,
                        isRequired: true,
                        isReadOnly: true,
                        suffixIcon: Icon(
                          Icons.arrow_drop_down,
                          color: primaryColor,
                          size: 28,
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(27.5),
                          onTap: () => _selectDate(context),
                          splashColor: primaryColor.withOpacity(0.1),
                          highlightColor: primaryColor.withOpacity(0.05),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 25),

                // Optional fields section
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(
                      "Optional Details",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Baby's Weight Input (Optional)
                _buildInputField(
                  controller: _weightController,
                  hintText: "Enter Baby's Weight in grams",
                  icon: Icons.monitor_weight_outlined,
                  keyboardType: TextInputType.number,
                ),

                const SizedBox(height: 16),

                // Baby's Height Input (Optional)
                _buildInputField(
                  controller: _heightController,
                  hintText: "Enter Baby's Height in cm",
                  icon: Icons.height,
                  keyboardType: TextInputType.number,
                ),

                const SizedBox(height: 16),

                // Baby's Head Circumference Input (Optional)
                _buildInputField(
                  controller: _circumferenceController,
                  hintText: "Enter Baby's Head Circumference in cm",
                  icon: Icons.circle_outlined,
                  keyboardType: TextInputType.number,
                ),

                const SizedBox(height: 40),

                // Continue Button
                Container(
                  width: 230,
                  height: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(25),
                    color: primaryColor,
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withOpacity(0.3),
                        spreadRadius: 1,
                        blurRadius: 5,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(25),
                      onTap: _isLoading ? null : _saveBabyDetails,
                      child: Center(
                        child:
                            _isLoading
                                ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                                : const Text(
                                  "Continue",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    bool isRequired = false,
    bool isReadOnly = false,
    TextInputType keyboardType = TextInputType.text,
    Widget? suffixIcon,
  }) {
    return Container(
      width: 300,
      height: 55,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(27.5),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const SizedBox(width: 20),
          Icon(icon, size: 22, color: primaryColor),
          const SizedBox(width: 15),
          Expanded(
            child: TextField(
              controller: controller,
              readOnly: isReadOnly,
              keyboardType: keyboardType,
              decoration: InputDecoration(
                hintText: hintText,
                border: InputBorder.none,
                hintStyle: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Colors.grey[500],
                ),
                suffixIcon:
                    suffixIcon != null
                        ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isRequired)
                              const Icon(
                                Icons.star,
                                size: 8,
                                color: Colors.red,
                              ),
                            suffixIcon,
                          ],
                        )
                        : isRequired
                        ? const Icon(Icons.star, size: 8, color: Colors.red)
                        : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
 */
import 'package:flutter/material.dart';
import 'package:fmsbabyapp/home_screen.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'child_service.dart';

class BabyDetailsScreen extends StatefulWidget {
  final String?
  nextScreenRoute; // Optional route to navigate to after adding baby

  const BabyDetailsScreen({Key? key, this.nextScreenRoute}) : super(key: key);

  @override
  State<BabyDetailsScreen> createState() => _BabyDetailsScreenState();
}

class _BabyDetailsScreenState extends State<BabyDetailsScreen> {
  bool isBoySelected = true;
  DateTime? selectedDate;
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _circumferenceController =
      TextEditingController();

  bool _isLoading = false;
  late ChildService _childService;

  @override
  void initState() {
    super.initState();
    // Initialize the child service with current user ID
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      _childService = ChildService(currentUser.uid);
    } else {
      // Handle not logged in case (redirect to login or show error)
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/login');
      });
    }
  }

  @override
  void dispose() {
    _dobController.dispose();
    _nameController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _circumferenceController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(DateTime.now().year - 2),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary:
                  isBoySelected
                      ? const Color(0xFF1873EA)
                      : const Color(0xFFF50ED6),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        selectedDate = picked;
        _dobController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  Color get primaryColor =>
      isBoySelected ? const Color(0xFF1873EA) : const Color(0xFFF50ED6);

  /* // Save baby details to Firebase
  Future<void> _saveBabyDetails() async {
    // Validate required fields
    if (_nameController.text.isEmpty || selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please fill all required fields"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Parse optional numeric fields
      double? weight =
          _weightController.text.isNotEmpty
              ? double.tryParse(_weightController.text)
              : null;

      double? height =
          _heightController.text.isNotEmpty
              ? double.tryParse(_heightController.text)
              : null;

      double? headCircumference =
          _circumferenceController.text.isNotEmpty
              ? double.tryParse(_circumferenceController.text)
              : null;

      // Add child to Firebase
      String childId = await _childService.addChild(
        name: _nameController.text,
        dateOfBirth: selectedDate!,
        gender: isBoySelected ? 'boy' : 'girl',
        weight: weight,
        height: height,
        headCircumference: headCircumference,
      );

      // If weight is provided, automatically add it as day 1 data
      if (weight != null) {
        await _childService.addDailyWeight(
          childId,
          dayNumber: 1,
          date: selectedDate!, // Birth date is day 1
          weight: weight,
        );
      }

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Baby added successfully!"),
            backgroundColor: Colors.green,
          ),
        );
      }

      // Navigate to home screen with the new child selected
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomeScreen(initialChildId: childId),
          ),
        );
      }
    } catch (e) {
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error adding baby: ${e.toString()}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  } */
  // Save baby details to Firebase
  Future<void> _saveBabyDetails() async {
    // Validate required fields
    if (_nameController.text.isEmpty || selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please fill all required fields"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Parse optional numeric fields
      double? weight =
          _weightController.text.isNotEmpty
              ? double.tryParse(_weightController.text)
              : null;

      double? height =
          _heightController.text.isNotEmpty
              ? double.tryParse(_heightController.text)
              : null;

      double? headCircumference =
          _circumferenceController.text.isNotEmpty
              ? double.tryParse(_circumferenceController.text)
              : null;

      // Add child to Firebase
      String childId = await _childService.addChild(
        name: _nameController.text,
        dateOfBirth: selectedDate!,
        gender: isBoySelected ? 'boy' : 'girl',
        weight: weight,
        height: height,
        headCircumference: headCircumference,
      );

      // If weight is provided, automatically add it as day 1 data
      if (weight != null) {
        await _childService.addDailyWeight(
          childId,
          dayNumber: 1,
          date: selectedDate!, // Birth date is day 1
          weight: weight,
        );
      }

      // Initialize vaccinations for the new child
      await _childService.initializeVaccinations(childId);

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Baby added successfully!"),
            backgroundColor: Colors.green,
          ),
        );
      }

      // Navigate to home screen with the new child selected
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomeScreen(initialChildId: childId),
          ),
        );
      }
    } catch (e) {
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error adding baby: ${e.toString()}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Skip adding baby details and go to home screen
  void _skipBabyDetails() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Top Row with Back Button and Skip Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Back Button
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),

                    // Skip Button
                    TextButton(
                      onPressed: _skipBabyDetails,
                      child: Text(
                        "Skip",
                        style: TextStyle(
                          color: primaryColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 15),

                // App Logo/Mascot
                Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withOpacity(0.2),
                        spreadRadius: 2,
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(75),
                    child: Image.asset(
                      'assets/images/start_logo.jpeg',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),

                const SizedBox(height: 25),

                // Title
                Text(
                  "Let's Start the Journey",
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: primaryColor,
                  ),
                ),

                const SizedBox(height: 8),

                // Subtitle
                Text(
                  "Add your baby's details",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: Colors.grey[600],
                  ),
                ),

                const SizedBox(height: 30),

                // Gender Selection
                Container(
                  width: 280,
                  height: 55,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(27.5),
                    color: const Color(0xFFEEEEEE),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.15),
                        spreadRadius: 1,
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      // Gender selection highlight
                      AnimatedPositioned(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeInOut,
                        left: isBoySelected ? 140 : 0,
                        child: Container(
                          width: 140,
                          height: 55,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(27.5),
                            color: primaryColor,
                          ),
                        ),
                      ),

                      // Gender text and icons
                      Row(
                        children: [
                          // Girl Option
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  isBoySelected = false;
                                });
                              },
                              child: Center(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.female,
                                      size: 24,
                                      color:
                                          !isBoySelected
                                              ? Colors.white
                                              : Colors.black54,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      "Girl",
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color:
                                            !isBoySelected
                                                ? Colors.white
                                                : Colors.black54,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          // Boy Option
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  isBoySelected = true;
                                });
                              },
                              child: Center(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.male,
                                      size: 24,
                                      color:
                                          isBoySelected
                                              ? Colors.white
                                              : Colors.black54,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      "Boy",
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color:
                                            isBoySelected
                                                ? Colors.white
                                                : Colors.black54,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // Baby's Name Input (Required)
                _buildInputField(
                  controller: _nameController,
                  hintText: "Baby's Name",
                  icon: Icons.person,
                  isRequired: true,
                ),

                const SizedBox(height: 16),

                // Date of Birth Input with Date Picker (Required)
                Stack(
                  children: [
                    AbsorbPointer(
                      child: _buildInputField(
                        controller: _dobController,
                        hintText: "Tap to Select Date Of Birth",
                        icon: Icons.calendar_today,
                        isRequired: true,
                        isReadOnly: true,
                        suffixIcon: Icon(
                          Icons.arrow_drop_down,
                          color: primaryColor,
                          size: 28,
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(27.5),
                          onTap: () => _selectDate(context),
                          splashColor: primaryColor.withOpacity(0.1),
                          highlightColor: primaryColor.withOpacity(0.05),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 25),

                // Optional fields section
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(
                      "Optional Details",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Baby's Weight Input (Optional)
                _buildInputField(
                  controller: _weightController,
                  hintText: "Enter Baby's Weight in grams",
                  icon: Icons.monitor_weight_outlined,
                  keyboardType: TextInputType.number,
                ),

                const SizedBox(height: 16),

                // Baby's Height Input (Optional)
                _buildInputField(
                  controller: _heightController,
                  hintText: "Enter Baby's Height in cm",
                  icon: Icons.height,
                  keyboardType: TextInputType.number,
                ),

                const SizedBox(height: 16),

                // Baby's Head Circumference Input (Optional)
                _buildInputField(
                  controller: _circumferenceController,
                  hintText: "Enter Baby's Head Circumference in cm",
                  icon: Icons.circle_outlined,
                  keyboardType: TextInputType.number,
                ),

                const SizedBox(height: 40),

                // Continue Button
                Container(
                  width: 230,
                  height: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(25),
                    color: primaryColor,
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withOpacity(0.3),
                        spreadRadius: 1,
                        blurRadius: 5,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(25),
                      onTap: _isLoading ? null : _saveBabyDetails,
                      child: Center(
                        child:
                            _isLoading
                                ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                                : const Text(
                                  "Continue",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    bool isRequired = false,
    bool isReadOnly = false,
    TextInputType keyboardType = TextInputType.text,
    Widget? suffixIcon,
  }) {
    return Container(
      width: 300,
      height: 55,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(27.5),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const SizedBox(width: 20),
          Icon(icon, size: 22, color: primaryColor),
          const SizedBox(width: 15),
          Expanded(
            child: TextField(
              controller: controller,
              readOnly: isReadOnly,
              keyboardType: keyboardType,
              decoration: InputDecoration(
                hintText: hintText,
                border: InputBorder.none,
                hintStyle: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Colors.grey[500],
                ),
                suffixIcon:
                    suffixIcon != null
                        ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isRequired)
                              const Icon(
                                Icons.star,
                                size: 8,
                                color: Colors.red,
                              ),
                            suffixIcon,
                          ],
                        )
                        : isRequired
                        ? const Icon(Icons.star, size: 8, color: Colors.red)
                        : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
