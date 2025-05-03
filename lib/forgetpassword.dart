import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_page.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  _ForgotPasswordPageState createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  TextEditingController emailController = TextEditingController();
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Container(
        width: screenWidth,
        height: screenHeight,
        clipBehavior: Clip.antiAlias,
        decoration: ShapeDecoration(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child: Stack(
          children: [
            // Back Arrow at the top-left corner
            Positioned(
              left: screenWidth * 0.05,
              top: screenHeight * 0.05,
              child: IconButton(
                icon: Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () {
                  Navigator.pop(context); // Go back to LoginPage
                },
              ),
            ),
            // Logo
            Positioned(
              left: (screenWidth - 200) / 2, // Center the logo horizontally
              top: screenHeight * 0.15, // Keep the vertical position as is

              child: SizedBox(
                width: 200,
                height: 200,
                child: Image.asset(
                  'assets/images/start_logo.jpeg',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            // Title Text
            Positioned(
              left: (screenWidth - 250) / 2,
              top: screenHeight * 0.40,
              child: Text(
                'Forgot Password?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 30,
                  fontFamily: 'Nunito',
                  fontWeight: FontWeight.w700,
                  height: 1.40,
                  letterSpacing: 0.30,
                ),
              ),
            ),
            // Description Text
            Positioned(
              left: (screenWidth - 331) / 2,
              top: screenHeight * 0.45,
              child: SizedBox(
                width: 331,
                child: Text(
                  'Don’t worry! It occurs. Please enter the email address linked with your account.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 13,
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.w400,
                    height: 1.50,
                  ),
                ),
              ),
            ),
            // Email Input Field
            Positioned(
              left: screenWidth * 0.08,
              top: screenHeight * 0.55,
              child: Container(
                width: screenWidth * 0.83,
                height: 40,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                decoration: ShapeDecoration(
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    side: BorderSide(
                      width: 0.20,
                      color: const Color(0xFF8C8A8A),
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: TextField(
                  controller: emailController,
                  decoration: InputDecoration(
                    hintText: 'Email',
                    hintStyle: TextStyle(
                      color: const Color(0xFF8C8A8A),
                      fontSize: 13,
                      fontFamily: 'Nunito',
                      fontWeight: FontWeight.w400,
                    ),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
            // Send Code Button
            Positioned(
              left: screenWidth * 0.08,
              top: screenHeight * 0.70,
              child: ElevatedButton(
                onPressed: isLoading ? null : _sendPasswordResetEmail,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1873EA),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(27.5),
                  ),
                  minimumSize: Size(screenWidth * 0.83, 40),
                ),
                child:
                    isLoading
                        ? CircularProgressIndicator(color: Colors.white)
                        : Text(
                          'Send Code',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontFamily: 'Nunito',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
              ),
            ),
            // "Remember Password?" Link
            Positioned(
              left: screenWidth * 0.31,
              top: screenHeight * 0.64,
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginPage()),
                  ); // Go back to LoginPage
                },
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: 'Remember Password? ',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 12,
                          fontFamily: 'Nunito',
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      TextSpan(
                        text: 'Login',
                        style: TextStyle(
                          color: const Color(0xFF1873EA),
                          fontSize: 12,
                          fontFamily: 'Nunito',
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /*   Future<void> _sendPasswordResetEmail() async {
    setState(() {
      isLoading = true;
    });

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: emailController.text.trim(),
      );
      // Show success dialog
      _showDialog('Success! Check your inbox for the reset link.', true);
    } catch (e) {
      // Show error dialog
      _showDialog('Error: ${e.toString()}', false);
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  } */
  Future<void> _sendPasswordResetEmail() async {
    // Validate email format first
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');

    if (emailController.text.trim().isEmpty) {
      _showDialog('Please enter your email address.', false);
      return;
    }

    if (!emailRegex.hasMatch(emailController.text.trim())) {
      _showDialog('Please enter a valid email address.', false);
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      // Add a small delay to ensure Firebase has time to process
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: emailController.text.trim(),
      );

      if (mounted) {
        // This message is now more descriptive about checking spam
        _showDialog(
          'Password reset email sent! Please check your inbox and spam/junk folder. It may take a few minutes to arrive.',
          true,
        );

        // Print to console for debugging
        print('Password reset email sent to: ${emailController.text.trim()}');
      }
    } on FirebaseAuthException catch (e) {
      // Handle specific Firebase Auth exceptions
      String errorMessage =
          'An error occurred while sending the password reset email.';

      if (e.code == 'user-not-found') {
        errorMessage = 'No user found with this email address.';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'The email address is not valid.';
      } else if (e.code == 'too-many-requests') {
        errorMessage = 'Too many attempts. Please try again later.';
      } else {
        // Log the error code for debugging
        print('Firebase Auth Error Code: ${e.code}');
        errorMessage = 'Error: ${e.message}';
      }

      if (mounted) {
        _showDialog(errorMessage, false);
      }
    } catch (e) {
      // Handle generic exceptions
      if (mounted) {
        _showDialog('Error: ${e.toString()}', false);
        print('Generic Error: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void _showDialog(String message, bool isSuccess) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(isSuccess ? 'Success' : 'Error'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                if (isSuccess) {
                  // Only pop the ForgotPasswordPage if successful
                  Navigator.pop(
                    context,
                  ); // Close the screen and return to the previous one
                }
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }
}
