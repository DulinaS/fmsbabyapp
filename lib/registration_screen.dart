/* import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fmsbabyapp/login_page.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  // Password visibility toggles
  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;

  // Firebase Auth instance
  final FirebaseAuth _auth = FirebaseAuth.instance;
  Future<void> _register() async {
    // Validate input fields
    if (_nameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    // Validate that passwords match
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Passwords do not match')));
      return;
    }

    try {
      // Create user with email and password
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );

      // Update user display name
      await userCredential.user?.updateDisplayName(_nameController.text.trim());

      // Show success message
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Registration successful!')));

      // Navigate back to login page after short delay
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        Navigator.pop(context);
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Registration failed';

      if (e.code == 'weak-password') {
        errorMessage = 'The password provided is too weak';
      } else if (e.code == 'email-already-in-use') {
        errorMessage = 'An account already exists for that email';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'Please enter a valid email address';
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $errorMessage')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 26),
                // Logo or Image
                Container(
                  width: 140,
                  height: 130,
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    image: const DecorationImage(
                      image: AssetImage('assets/images/start_logo.jpeg'),
                      fit: BoxFit.cover,
                      //onError: NetworkImage("https://placehold.co/207x180"),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Name Field
                _buildInputField(
                  label: 'Enter your name',
                  controller: _nameController,
                  placeholder: 'Enter your name',
                ),
                const SizedBox(height: 24),

                // Email Field
                _buildInputField(
                  label: 'Enter your email',
                  controller: _emailController,
                  placeholder: 'Enter your email address',
                ),
                const SizedBox(height: 24),

                // Password Field
                _buildInputField(
                  label: 'Create your password',
                  controller: _passwordController,
                  placeholder: '************',
                  isPassword: true,
                ),
                const SizedBox(height: 24),

                // Confirm Password Field
                _buildInputField(
                  label: 'Confirm your password',
                  controller: _confirmPasswordController,
                  placeholder: '************',
                  isPassword: true,
                ),
                const SizedBox(height: 25),

                // Register Button
                ElevatedButton(
                  onPressed: () {
                    _register(); // Call the register function
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1873EA),
                    minimumSize: const Size(double.infinity, 40),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Register',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontFamily: 'Nunito',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Login Text
                TextButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoginPage(),
                      ),
                    );
                  },
                  child: Text.rich(
                    TextSpan(
                      children: [
                        const TextSpan(
                          text: 'Already have account? ',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 12,
                            fontFamily: 'Nunito',
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const TextSpan(
                          text: 'Login',
                          style: TextStyle(
                            color: Color(0xFF1873EA),
                            fontSize: 12,
                            fontFamily: 'Nunito',
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // OR Divider
                Row(
                  children: [
                    Expanded(
                      child: Divider(color: Colors.grey[300], thickness: 1),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text(
                        'OR',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 12,
                          fontFamily: 'Nunito',
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Divider(color: Colors.grey[300], thickness: 1),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Google
                OutlinedButton(
                  onPressed: () {
                    // Google
                  },
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 40),
                    side: const BorderSide(
                      width: 0.5,
                      color: Color(0xFF8C8A8A),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Sign up with Google',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 14,
                          fontFamily: 'Nunito',
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required String placeholder,
    bool isPassword = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 14,
            fontFamily: 'Nunito',
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: const Color(0xFF1873EA), // Blue border for all fields
              width: 1.0, // Consistent border width
            ),
          ),
          alignment: Alignment.center, // Center the TextField content
          child: Center(
            child: TextField(
              controller: controller,
              obscureText:
                  isPassword ? !_getPasswordVisibility(controller) : false,
              style: const TextStyle(fontSize: 14, fontFamily: 'Nunito'),
              decoration: InputDecoration(
                hintText: placeholder,
                hintStyle: const TextStyle(
                  color: Color(0xFF8C8A8A),
                  fontSize: 14,
                  fontFamily: 'Nunito',
                  fontWeight: FontWeight.w400,
                ),
                //padding for all fields
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                border: InputBorder.none,
                isDense: false,
                alignLabelWithHint: false,
                isCollapsed: false,
                suffixIcon:
                    isPassword
                        ? IconButton(
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                          icon: Icon(
                            _getPasswordVisibility(controller)
                                ? Icons.visibility
                                : Icons.visibility_off,
                            size: 20,
                            color: Colors.grey,
                          ),
                          onPressed: () {
                            // Toggle password visibility
                            setState(() {
                              if (controller == _passwordController) {
                                _passwordVisible = !_passwordVisible;
                              } else if (controller ==
                                  _confirmPasswordController) {
                                _confirmPasswordVisible =
                                    !_confirmPasswordVisible;
                              }
                            });
                          },
                        )
                        : null,
              ),
              // Center the text vertically
              textAlignVertical: TextAlignVertical.center,
            ),
          ),
        ),
      ],
    );
  }

  // Helper method to determine password visibility based on controller
  bool _getPasswordVisibility(TextEditingController controller) {
    if (controller == _passwordController) {
      return _passwordVisible;
    } else if (controller == _confirmPasswordController) {
      return _confirmPasswordVisible;
    }
    return false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
 */
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fmsbabyapp/login_page.dart';
import 'package:fmsbabyapp/user_service.dart'; // Import the new service

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  // Password visibility toggles
  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;

  // Firebase Auth instance and user service
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final UserService _userService = UserService(); // Add user service

  // Loading state
  bool _isLoading = false;

  Future<void> _register() async {
    // Set loading state
    setState(() {
      _isLoading = true;
    });

    try {
      // Validate input fields
      if (_nameController.text.isEmpty ||
          _emailController.text.isEmpty ||
          _passwordController.text.isEmpty ||
          _confirmPasswordController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill in all fields')),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Validate that passwords match
      if (_passwordController.text != _confirmPasswordController.text) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Passwords do not match')));
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Create user with email and password
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );

      // Update user display name
      await userCredential.user?.updateDisplayName(_nameController.text.trim());

      // Create user document in Firestore
      await _userService.createUserDocument(
        userCredential.user!,
        _nameController.text.trim(),
      );

      // Show success message
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Registration successful!')));

      // Navigate back to login page after short delay
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        Navigator.pop(context);
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Registration failed';

      if (e.code == 'weak-password') {
        errorMessage = 'The password provided is too weak';
      } else if (e.code == 'email-already-in-use') {
        errorMessage = 'An account already exists for that email';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'Please enter a valid email address';
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $errorMessage')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 26),
                // Logo or Image (unchanged)
                Container(
                  width: 140,
                  height: 130,
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    image: const DecorationImage(
                      image: AssetImage('assets/images/start_logo.jpeg'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Form fields (unchanged)
                _buildInputField(
                  label: 'Enter your name',
                  controller: _nameController,
                  placeholder: 'Enter your name',
                ),
                const SizedBox(height: 24),
                _buildInputField(
                  label: 'Enter your email',
                  controller: _emailController,
                  placeholder: 'Enter your email address',
                ),
                const SizedBox(height: 24),
                _buildInputField(
                  label: 'Create your password',
                  controller: _passwordController,
                  placeholder: '************',
                  isPassword: true,
                ),
                const SizedBox(height: 24),
                _buildInputField(
                  label: 'Confirm your password',
                  controller: _confirmPasswordController,
                  placeholder: '************',
                  isPassword: true,
                ),
                const SizedBox(height: 25),

                // Register Button with loading state
                ElevatedButton(
                  onPressed: _isLoading ? null : _register,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1873EA),
                    minimumSize: const Size(double.infinity, 40),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child:
                      _isLoading
                          ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.0,
                            ),
                          )
                          : const Text(
                            'Register',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontFamily: 'Nunito',
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                ),

                // Rest of the UI (unchanged)
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoginPage(),
                      ),
                    );
                  },
                  child: Text.rich(
                    TextSpan(
                      children: [
                        const TextSpan(
                          text: 'Already have account? ',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 12,
                            fontFamily: 'Nunito',
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const TextSpan(
                          text: 'Login',
                          style: TextStyle(
                            color: Color(0xFF1873EA),
                            fontSize: 12,
                            fontFamily: 'Nunito',
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: Divider(color: Colors.grey[300], thickness: 1),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text(
                        'OR',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 12,
                          fontFamily: 'Nunito',
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Divider(color: Colors.grey[300], thickness: 1),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () {
                    // Google sign up
                  },
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 40),
                    side: const BorderSide(
                      width: 0.5,
                      color: Color(0xFF8C8A8A),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Sign up with Google',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 14,
                          fontFamily: 'Nunito',
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Input field widget (unchanged)
  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required String placeholder,
    bool isPassword = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 14,
            fontFamily: 'Nunito',
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF1873EA), width: 1.0),
          ),
          alignment: Alignment.center,
          child: Center(
            child: TextField(
              controller: controller,
              obscureText:
                  isPassword ? !_getPasswordVisibility(controller) : false,
              style: const TextStyle(fontSize: 14, fontFamily: 'Nunito'),
              decoration: InputDecoration(
                hintText: placeholder,
                hintStyle: const TextStyle(
                  color: Color(0xFF8C8A8A),
                  fontSize: 14,
                  fontFamily: 'Nunito',
                  fontWeight: FontWeight.w400,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                border: InputBorder.none,
                isDense: false,
                alignLabelWithHint: false,
                isCollapsed: false,
                suffixIcon:
                    isPassword
                        ? IconButton(
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                          icon: Icon(
                            _getPasswordVisibility(controller)
                                ? Icons.visibility
                                : Icons.visibility_off,
                            size: 20,
                            color: Colors.grey,
                          ),
                          onPressed: () {
                            setState(() {
                              if (controller == _passwordController) {
                                _passwordVisible = !_passwordVisible;
                              } else if (controller ==
                                  _confirmPasswordController) {
                                _confirmPasswordVisible =
                                    !_confirmPasswordVisible;
                              }
                            });
                          },
                        )
                        : null,
              ),
              textAlignVertical: TextAlignVertical.center,
            ),
          ),
        ),
      ],
    );
  }

  // Helper method (unchanged)
  bool _getPasswordVisibility(TextEditingController controller) {
    if (controller == _passwordController) {
      return _passwordVisible;
    } else if (controller == _confirmPasswordController) {
      return _confirmPasswordVisible;
    }
    return false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
