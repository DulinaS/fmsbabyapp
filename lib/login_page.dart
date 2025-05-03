/* 
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fmsbabyapp/baby_details_screen.dart';
import 'package:fmsbabyapp/nutrition.dart';
import 'package:fmsbabyapp/registration_screen.dart';
//import 'package:fmsbabyapp/screens/home_screen.dart'; // Import the home screen

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // Controllers for email and password input
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // Password visibility toggle
  bool _passwordVisible = false;

  // Firebase Auth instance
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Loading state
  bool _isLoading = false;

  // Function to handle user login
  Future<void> _login() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter email and password')),
      );
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      
      // Navigate to HomeScreen on successful login and remove the login screen from stack
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => BabyDetailsScreen()),
        );
      }
    } catch (e) {
      // Show error message
      if (mounted) {
        String errorMessage = 'Login failed';
        
        if (e is FirebaseAuthException) {
          if (e.code == 'user-not-found') {
            errorMessage = 'No user found with this email';
          } else if (e.code == 'wrong-password') {
            errorMessage = 'Wrong password provided';
          } else if (e.code == 'invalid-email') {
            errorMessage = 'Please enter a valid email address';
          }
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $errorMessage')),
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

  // Function to navigate to registration screen
  void _navigateToRegister() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const RegistrationScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    // The rest of the build method remains the same
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                
                // Logo (unchanged)
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
                      image: AssetImage('assets/images/baby.png'),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                
                // App Title (unchanged)
                const Text(
                  'Baby Growth Tracker',
                  style: TextStyle(
                    color: Color(0xFF1873EA),
                    fontSize: 24,
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 40),
                
                // Email Field (unchanged)
                _buildInputField(
                  label: 'Email',
                  controller: _emailController,
                  placeholder: 'Enter your email address',
                ),
                const SizedBox(height: 24),
                
                // Password Field (unchanged)
                _buildInputField(
                  label: 'Password',
                  controller: _passwordController,
                  placeholder: '************',
                  isPassword: true,
                ),
                const SizedBox(height: 10),
                
                // Forgot Password (unchanged)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      // Implement forgot password functionality
                      showDialog(
                        context: context,
                        builder: (context) => _buildForgotPasswordDialog(),
                      );
                    },
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 30),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      'Forgot Password?',
                      style: TextStyle(
                        color: Color(0xFF1873EA),
                        fontSize: 12,
                        fontFamily: 'Nunito',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                
                // Login Button (add loading state)
                ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1873EA),
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.0,
                          ),
                        )
                      : const Text(
                          'Login',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontFamily: 'Nunito',
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                ),
                const SizedBox(height: 20),
                
                // Register Text (unchanged)
                TextButton(
                  onPressed: _navigateToRegister,
                  child: Text.rich(
                    TextSpan(
                      children: [
                        const TextSpan(
                          text: 'Don\'t have an account? ',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 12,
                            fontFamily: 'Nunito',
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const TextSpan(
                          text: 'Register',
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
                const SizedBox(height: 20),
                
                // OR Divider (unchanged)
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
                const SizedBox(height: 20),
                
                // Google Sign In Button (unchanged)
                OutlinedButton(
                  onPressed: () {
                    // Implement Google sign in
                  },
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
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
                        'Sign in with Google',
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
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Forgot password dialog
  Widget _buildForgotPasswordDialog() {
    final TextEditingController emailController = TextEditingController();
    
    return AlertDialog(
      title: const Text('Reset Password'),
      content: TextField(
        controller: emailController,
        decoration: const InputDecoration(
          labelText: 'Email Address',
          hintText: 'Enter your email address',
        ),
        keyboardType: TextInputType.emailAddress,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () async {
            if (emailController.text.trim().isNotEmpty) {
              try {
                await FirebaseAuth.instance.sendPasswordResetEmail(
                  email: emailController.text.trim(),
                );
                
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Password reset email sent!'),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: ${e.toString()}'),
                    ),
                  );
                }
              }
            }
          },
          child: const Text('Send Email'),
        ),
      ],
    );
  }

  // Input field builder remains unchanged
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
          child: TextField(
            controller: controller,
            obscureText: isPassword ? !_passwordVisible : false,
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
              suffixIcon:
                  isPassword
                      ? IconButton(
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                        icon: Icon(
                          _passwordVisible
                              ? Icons.visibility
                              : Icons.visibility_off,
                          size: 20,
                          color: Colors.grey,
                        ),
                        onPressed: () {
                          // Toggle password visibility
                          setState(() {
                            _passwordVisible = !_passwordVisible;
                          });
                        },
                      )
                      : null,
            ),
            textAlignVertical: TextAlignVertical.center,
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
} */
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fmsbabyapp/baby_details_screen.dart';
import 'package:fmsbabyapp/home_screen.dart';
import 'package:fmsbabyapp/registration_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fmsbabyapp/child_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // Controllers for email and password input
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // Password visibility toggle
  bool _passwordVisible = false;

  // Firebase Auth instance
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Loading state
  bool _isLoading = false;

  // Function to check if user has children and navigate accordingly
  Future<void> _checkUserChildrenAndNavigate(String userId) async {
    try {
      // Create a ChildService instance with the user ID
      final childService = ChildService(userId);
      
      // Get the children stream and listen to the first event
      // This is more efficient than using the Firestore query directly
      final childrenStream = childService.getChildren();
      final children = await childrenStream.first;

      if (mounted) {
        if (children.isNotEmpty) {
          // User has children, navigate to HomeScreen
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => HomeScreen()),
          );
        } else {
          // User has no children, navigate to BabyDetailsScreen
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => BabyDetailsScreen()),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        // Default to BabyDetailsScreen if there's an error checking for children
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => BabyDetailsScreen()),
        );
        
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error checking user data: ${e.toString()}')),
        );
      }
    }
  }

  // Function to handle user login
  Future<void> _login() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter email and password')),
      );
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Authenticate the user
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      
      // Get the user ID
      final userId = userCredential.user?.uid;
      
      if (userId != null && mounted) {
        // Check if user has children and navigate accordingly
        await _checkUserChildrenAndNavigate(userId);
      }
    } catch (e) {
      // Show error message
      if (mounted) {
        String errorMessage = 'Login failed';
        
        if (e is FirebaseAuthException) {
          if (e.code == 'user-not-found') {
            errorMessage = 'No user found with this email';
          } else if (e.code == 'wrong-password') {
            errorMessage = 'Wrong password provided';
          } else if (e.code == 'invalid-email') {
            errorMessage = 'Please enter a valid email address';
          }
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $errorMessage')),
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

  // Function to navigate to registration screen
  void _navigateToRegister() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const RegistrationScreen()),
    );
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
                const SizedBox(height: 40),
                
                // Logo (unchanged)
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
                      image: AssetImage('assets/images/baby.png'),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                
                // App Title (unchanged)
                const Text(
                  'Baby Growth Tracker',
                  style: TextStyle(
                    color: Color(0xFF1873EA),
                    fontSize: 24,
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 40),
                
                // Email Field (unchanged)
                _buildInputField(
                  label: 'Email',
                  controller: _emailController,
                  placeholder: 'Enter your email address',
                ),
                const SizedBox(height: 24),
                
                // Password Field (unchanged)
                _buildInputField(
                  label: 'Password',
                  controller: _passwordController,
                  placeholder: '************',
                  isPassword: true,
                ),
                const SizedBox(height: 10),
                
                // Forgot Password (unchanged)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      // Implement forgot password functionality
                      showDialog(
                        context: context,
                        builder: (context) => _buildForgotPasswordDialog(),
                      );
                    },
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 30),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      'Forgot Password?',
                      style: TextStyle(
                        color: Color(0xFF1873EA),
                        fontSize: 12,
                        fontFamily: 'Nunito',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                
                // Login Button (add loading state)
                ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1873EA),
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.0,
                          ),
                        )
                      : const Text(
                          'Login',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontFamily: 'Nunito',
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                ),
                const SizedBox(height: 20),
                
                // Register Text (unchanged)
                TextButton(
                  onPressed: _navigateToRegister,
                  child: Text.rich(
                    TextSpan(
                      children: [
                        const TextSpan(
                          text: 'Don\'t have an account? ',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 12,
                            fontFamily: 'Nunito',
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const TextSpan(
                          text: 'Register',
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
                const SizedBox(height: 20),
                
                // OR Divider (unchanged)
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
                const SizedBox(height: 20),
                
                // Google Sign In Button (unchanged)
                OutlinedButton(
                  onPressed: () {
                    // Implement Google sign in
                  },
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
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
                        'Sign in with Google',
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
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Forgot password dialog
  Widget _buildForgotPasswordDialog() {
    final TextEditingController emailController = TextEditingController();
    
    return AlertDialog(
      title: const Text('Reset Password'),
      content: TextField(
        controller: emailController,
        decoration: const InputDecoration(
          labelText: 'Email Address',
          hintText: 'Enter your email address',
        ),
        keyboardType: TextInputType.emailAddress,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () async {
            if (emailController.text.trim().isNotEmpty) {
              try {
                await FirebaseAuth.instance.sendPasswordResetEmail(
                  email: emailController.text.trim(),
                );
                
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Password reset email sent!'),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: ${e.toString()}'),
                    ),
                  );
                }
              }
            }
          },
          child: const Text('Send Email'),
        ),
      ],
    );
  }

  // Input field builder
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
          child: TextField(
            controller: controller,
            obscureText: isPassword ? !_passwordVisible : false,
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
              suffixIcon:
                  isPassword
                      ? IconButton(
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                        icon: Icon(
                          _passwordVisible
                              ? Icons.visibility
                              : Icons.visibility_off,
                          size: 20,
                          color: Colors.grey,
                        ),
                        onPressed: () {
                          // Toggle password visibility
                          setState(() {
                            _passwordVisible = !_passwordVisible;
                          });
                        },
                      )
                      : null,
            ),
            textAlignVertical: TextAlignVertical.center,
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}