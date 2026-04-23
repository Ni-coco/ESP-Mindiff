import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:async';
import 'dart:io';
import 'package:mindiff_app/utils/theme.dart';
import 'package:mindiff_app/pages/register_onboarding_page.dart';
import 'package:mindiff_app/navigation_menu.dart';
import 'package:mindiff_app/services/api_client.dart';
import 'package:mindiff_app/services/auth_service.dart';
import 'package:mindiff_app/controllers/user_profile_controller.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'L\'email est requis';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Veuillez entrer un email valide';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Le mot de passe est requis';
    }
    return null;
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authService = Get.find<AuthService>();
      await authService.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      final userData = await authService.getCurrentUser();
      Get.find<UserProfileController>().setFromApiResponse(userData);
      Get.offAll(() => const NavigationMenu());
    } on UnauthorizedException {
      Get.snackbar('Erreur', 'Email ou mot de passe incorrect',
          snackPosition: SnackPosition.BOTTOM);
    } on ApiException catch (e) {
      Get.snackbar('Erreur', e.message, snackPosition: SnackPosition.BOTTOM);
    } catch (e, st) {
      debugPrint('Login unexpected error: $e');
      debugPrint('Login stacktrace: $st');

      String message = 'Impossible de se connecter au serveur';
      if (e is SocketException) {
        message = 'Serveur inaccessible. Vérifiez que le backend est démarré.';
      } else if (e is HandshakeException) {
        message = 'Erreur SSL/TLS lors de la connexion au serveur.';
      } else if (e is TimeoutException) {
        message = 'Le serveur met trop de temps à répondre.';
      }

      Get.snackbar('Erreur', message, snackPosition: SnackPosition.BOTTOM);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: THelperFunctions.backgroundColor(context),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                
                // Logo/Title Section
                Column(
                  children: [
                    Image.asset(
                      'assets/images/Mindiff.png',
                      height: 160,
                      width: 160,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Bienvenue',
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: THelperFunctions.textColor(context),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Connectez-vous à votre compte Mindiff',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: THelperFunctions.isDarkMode(context)
                            ? Colors.grey[400]
                            : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 48),
                
                // Email Field
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: _validateEmail,
                ),
                
                const SizedBox(height: 16),
                
                // Password Field
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Mot de passe',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword 
                            ? Icons.visibility_outlined 
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                  validator: _validatePassword,
                ),
                
                const SizedBox(height: 8),
                
                // Forgot Password Link
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      // TODO: Implement forgot password functionality
                      Get.snackbar(
                        'Mot de passe oublié',
                        'Cette fonctionnalité sera bientôt disponible',
                        snackPosition: SnackPosition.BOTTOM,
                      );
                    },
                    child: Text(
                      'Mot de passe oublié?',
                      style: TextStyle(
                        color: TColors.primary,
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Login Button
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: TColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Se connecter',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
                
                const SizedBox(height: 32),
                
                // Divider
                Row(
                  children: [
                    Expanded(
                      child: Divider(
                        color: THelperFunctions.isDarkMode(context)
                            ? Colors.grey[700]
                            : Colors.grey[300],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'OU',
                        style: TextStyle(
                          color: THelperFunctions.isDarkMode(context)
                              ? Colors.grey[400]
                              : Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Divider(
                        color: THelperFunctions.isDarkMode(context)
                            ? Colors.grey[700]
                            : Colors.grey[300],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 32),
                
                // Register Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Vous n\'avez pas de compte? ',
                      style: TextStyle(
                        color: THelperFunctions.isDarkMode(context)
                            ? Colors.grey[400]
                            : Colors.grey[600],
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Get.to(() => const RegisterOnboardingPage());
                      },
                      child: Text(
                        'S\'inscrire',
                        style: TextStyle(
                          color: TColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

