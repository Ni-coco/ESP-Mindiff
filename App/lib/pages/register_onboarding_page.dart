// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mindiff_app/utils/theme.dart';
import 'package:mindiff_app/navigation_menu.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:mindiff_app/widgets/dropdown_button.dart';
import 'package:mindiff_app/pages/login_page.dart';
import 'package:mindiff_app/controllers/user_profile_controller.dart';
import 'package:mindiff_app/services/api_client.dart';
import 'package:mindiff_app/services/auth_service.dart';

class RegisterOnboardingPage extends StatelessWidget {
  const RegisterOnboardingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(RegisterOnboardingController());
    
    return Scaffold(
      backgroundColor: THelperFunctions.backgroundColor(context),
      body: Column(
        children: [
          // Progress Indicator with title
          Obx(() => _buildProgressIndicator(context, controller)),
          
          // PageView for steps
          Expanded(
            child: PageView.builder(
              controller: controller.pageController,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: controller.totalSteps,
              itemBuilder: (context, index) {
                return _buildStep(context, index, controller);
              },
            ),
          ),
          
          // Navigation Buttons (always at bottom)
          Obx(() => _buildBottomNavigation(context, controller.currentStep.value, controller)),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator(BuildContext context, RegisterOnboardingController controller) {
    final stepInfo = _getStepInfo(controller.currentStep.value);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Bouton retour login (toujours accessible)
          Align(
            alignment: Alignment.topRight,
            child: IconButton(
              onPressed: () => Get.off(() => const LoginPage()),
              icon: const Icon(Icons.close),
              tooltip: 'Retour à la connexion',
              style: IconButton.styleFrom(
                foregroundColor: THelperFunctions.isDarkMode(context)
                    ? Colors.grey[400]
                    : Colors.grey[600],
              ),
            ),
          ),
          // Title
          Text(
            stepInfo['title']!,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: THelperFunctions.textColor(context),
            ),
          ),
          const SizedBox(height: 8),
          // Description
          Text(
            stepInfo['description']!,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: THelperFunctions.isDarkMode(context)
                  ? Colors.grey[400]
                  : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),
          // Progress dots
          SmoothPageIndicator(
            controller: controller.pageController,
            count: controller.totalSteps,
            effect: ExpandingDotsEffect(
              activeDotColor: TColors.primary,
              dotColor: THelperFunctions.isDarkMode(context)
                  ? Colors.grey[700]!
                  : Colors.grey[300]!,
              dotHeight: 8,
              dotWidth: 8,
              spacing: 8,
              expansionFactor: 3,
            ),
          ),
        ],
      ),
    );
  }

  Map<String, String> _getStepInfo(int step) {
    switch (step) {
      case 0:
        return {
          'title': 'Informations du compte',
          'description': 'Créez votre compte pour commencer',
        };
      case 1:
        return {
          'title': 'Informations personnelles',
          'description': 'Aidez-nous à personnaliser votre expérience',
        };
      case 2:
        return {
          'title': 'Objectifs de remise en forme',
          'description': 'Définissez vos objectifs pour un programme personnalisé',
        };
      case 3:
        return {
          'title': 'Nombre de séances par semaine',
          'description': 'Combien de séances souhaitez-vous faire par semaine ?',
        };
      case 4:
        return {
          'title': 'Considérations de santé',
          'description': 'Informations optionnelles pour votre sécurité',
        };
      default:
        return {'title': '', 'description': ''};
    }
  }

  Widget _buildStep(BuildContext context, int step, RegisterOnboardingController controller) {
    switch (step) {
      case 0:
        return _Step1AccountInfo(key: const ValueKey(0), controller: controller);
      case 1:
        return _Step2PersonalInfo(key: const ValueKey(1), controller: controller);
      case 2:
        return _Step3FitnessGoals(key: const ValueKey(2), controller: controller);
      case 3:
        return _Step4ActivityLevel(key: const ValueKey(3), controller: controller);
      case 4:
        return _Step5HealthConsiderations(key: const ValueKey(4), controller: controller);
      default:
        return const SizedBox();
    }
  }

  Widget _buildBottomNavigation(BuildContext context, int currentStep, RegisterOnboardingController controller) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      color: THelperFunctions.backgroundColor(context),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Bouton gauche : retour étape précédente, ou retour login sur étape 0
            _CircularArrowButton(
              onPressed: currentStep > 0
                  ? () => controller.previousStep()
                  : () => Get.off(() => const LoginPage()),
              icon: currentStep > 0 ? Icons.arrow_back : Icons.login,
              size: 48.0,
              backgroundColor: THelperFunctions.isDarkMode(context)
                  ? Colors.grey[800]!
                  : Colors.grey[200]!,
              iconColor: THelperFunctions.textColor(context) ?? Colors.black,
            ),
            
            // Next/Complete button
            if (currentStep == 4)
              _CircularArrowButton(
                onPressed: () => controller.completeRegistration(),
                icon: Icons.check,
                size: 64.0,
                backgroundColor: TColors.primary,
                iconColor: Colors.white,
              )
            else
              _CircularArrowButton(
                onPressed: () => controller.validateAndNextStep(),
                icon: Icons.arrow_forward,
                size: 64.0,
                backgroundColor: TColors.primary,
                iconColor: Colors.white,
              ),
          ],
        ),
      ),
    );
  }
}

// Circular Arrow Button Widget
class _CircularArrowButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final IconData icon;
  final double size;
  final Color backgroundColor;
  final Color iconColor;

  const _CircularArrowButton({
    required this.onPressed,
    required this.icon,
    this.size = 56.0,
    required this.backgroundColor,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: backgroundColor,
          ),
          child: Icon(
            icon,
            color: iconColor,
            size: size * 0.4,
          ),
        ),
      ),
    );
  }
}

// Step 1: Account Information
class _Step1AccountInfo extends StatefulWidget {
  final RegisterOnboardingController controller;
  
  const _Step1AccountInfo({super.key, required this.controller});

  @override
  State<_Step1AccountInfo> createState() => _Step1AccountInfoState();
}

class _Step1AccountInfoState extends State<_Step1AccountInfo> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  late final TextEditingController _confirmPasswordController;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.controller.name ?? '');
    _emailController = TextEditingController(text: widget.controller.email ?? '');
    _passwordController = TextEditingController(text: widget.controller.password ?? '');
    _confirmPasswordController = TextEditingController(text: widget.controller.password ?? '');
    
    // Save data as user types
    _nameController.addListener(() {
      widget.controller.setName(_nameController.text);
    });
    _emailController.addListener(() {
      widget.controller.setEmail(_emailController.text);
    });
    _passwordController.addListener(() {
      widget.controller.setPassword(_passwordController.text);
    });

    // Register validation callback
    widget.controller.registerValidationCallback(0, _validateAndNext);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  bool _validateAndNext() {
    return _formKey.currentState!.validate();
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
    if (value.length < 8) {
      return 'Le mot de passe doit contenir au moins 8 caractères';
    }
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'Le mot de passe doit contenir au moins une majuscule';
    }
    if (!value.contains(RegExp(r'[a-z]'))) {
      return 'Le mot de passe doit contenir au moins une minuscule';
    }
    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'Le mot de passe doit contenir au moins un chiffre';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Veuillez confirmer le mot de passe';
    }
    if (value != _passwordController.text) {
      return 'Les mots de passe ne correspondent pas';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Name Field
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nom complet',
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Le nom est requis';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
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
                    _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
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
            Text(
              '• Au moins 8 caractères\n• Au moins une majuscule\n• Au moins une minuscule\n• Au moins un chiffre',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: THelperFunctions.isDarkMode(context)
                    ? Colors.grey[400]
                    : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            
            // Confirm Password Field
            TextFormField(
              controller: _confirmPasswordController,
              obscureText: _obscureConfirmPassword,
              decoration: InputDecoration(
                labelText: 'Confirmer le mot de passe',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirmPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureConfirmPassword = !_obscureConfirmPassword;
                    });
                  },
                ),
              ),
              validator: _validateConfirmPassword,
            ),
            
            const SizedBox(height: 24),
            
            // Login Link
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () {
                  Get.off(() => const LoginPage());
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Vous avez déjà un compte? ',
                      style: TextStyle(
                        color: THelperFunctions.isDarkMode(context)
                            ? Colors.grey[400]
                            : Colors.grey[600],
                      ),
                    ),
                    Text(
                      'Se connecter',
                      style: TextStyle(
                        color: TColors.primary,
                        fontWeight: FontWeight.w600,
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
  }
}

// Step 2: Personal Information
class _Step2PersonalInfo extends StatefulWidget {
  final RegisterOnboardingController controller;
  
  const _Step2PersonalInfo({super.key, required this.controller});

  @override
  State<_Step2PersonalInfo> createState() => _Step2PersonalInfoState();
}

class _Step2PersonalInfoState extends State<_Step2PersonalInfo> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _ageController;
  late final TextEditingController _heightController;
  late final TextEditingController _weightController;
  String? _selectedGender;

  @override
  void initState() {
    super.initState();
    _ageController = TextEditingController(
      text: widget.controller.age != null ? widget.controller.age.toString() : '',
    );
    _heightController = TextEditingController(
      text: widget.controller.height != null ? widget.controller.height.toString() : '',
    );
    _weightController = TextEditingController(
      text: widget.controller.weight != null ? widget.controller.weight.toString() : '',
    );
    _selectedGender = widget.controller.gender;
    
    // Save data as user types
    _ageController.addListener(() {
      final age = int.tryParse(_ageController.text);
      if (age != null) {
        widget.controller.setAge(age);
      }
    });
    _heightController.addListener(() {
      final raw = _heightController.text.replaceAll(',', '.');
      final height = double.tryParse(raw);
      if (height != null) {
        widget.controller.setHeight(height);
      }
    });
    _weightController.addListener(() {
      final raw = _weightController.text.replaceAll(',', '.');
      final weight = double.tryParse(raw);
      if (weight != null) {
        widget.controller.setWeight(weight);
      }
    });

    // Register validation callback
    widget.controller.registerValidationCallback(1, _validateAndNext);
  }

  @override
  void dispose() {
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  bool _validateAndNext() {
    return _formKey.currentState!.validate() && _selectedGender != null;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Age Field
            TextFormField(
              controller: _ageController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Âge',
                prefixIcon: Icon(Icons.calendar_today_outlined),
                suffixText: 'ans',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'L\'âge est requis';
                }
                final age = int.tryParse(value);
                if (age == null || age < 13 || age > 120) {
                  return 'Veuillez entrer un âge valide';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            // Gender Dropdown
            FormField<String>(
              initialValue: _selectedGender,
              validator: (value) {
                if (value == null) {
                  return 'Veuillez sélectionner un genre';
                }
                return null;
              },
              builder: (field) {
                const genderLabels = {
                  'male': 'Homme',
                  'female': 'Femme',
                  'other': 'Autre',
                };
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomDropdownButton2(
                      hint: 'Sélectionner un genre',
                      value: _selectedGender,
                      dropdownItems: const ['male', 'female', 'other'],
                      dropdownLabels: genderLabels,
                      selectedItemBuilder: (context) {
                        return const ['Homme', 'Femme', 'Autre']
                            .map((String item) => Text(item))
                            .toList();
                      },
                      labelText: 'Genre',
                      prefixIcon: const Icon(Icons.person_outline),
                      onChanged: (value) {
                        setState(() {
                          _selectedGender = value;
                        });
                        if (value != null) {
                          widget.controller.setGender(value);
                          field.didChange(value);
                        }
                      },
                    ),
                    if (field.hasError)
                      Padding(
                        padding: const EdgeInsets.only(top: 8, left: 16),
                        child: Text(
                          field.errorText!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            
            // Height Field
            TextFormField(
              controller: _heightController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Taille',
                prefixIcon: Icon(Icons.height_outlined),
                suffixText: 'cm',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'La taille est requise';
                }
                final height = double.tryParse(value.replaceAll(',', '.'));
                if (height == null || height < 50 || height > 250) {
                  return 'Veuillez entrer une taille valide (50-250 cm)';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            // Weight Field
            TextFormField(
              controller: _weightController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Poids',
                prefixIcon: Icon(Icons.monitor_weight_outlined),
                suffixText: 'kg',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Le poids est requis';
                }
                final weight = double.tryParse(value.replaceAll(',', '.'));
                if (weight == null || weight < 20 || weight > 300) {
                  return 'Veuillez entrer un poids valide (20-300 kg)';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }
}

// Step 3: Fitness Goals
class _Step3FitnessGoals extends StatefulWidget {
  final RegisterOnboardingController controller;
  
  const _Step3FitnessGoals({super.key, required this.controller});

  @override
  State<_Step3FitnessGoals> createState() => _Step3FitnessGoalsState();
}

class _Step3FitnessGoalsState extends State<_Step3FitnessGoals> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _targetWeightController;
  String? _selectedGoal;

  @override
  void initState() {
    super.initState();
    _targetWeightController = TextEditingController(
      text: widget.controller.targetWeight != null 
          ? widget.controller.targetWeight.toString() 
          : '',
    );
    _selectedGoal = widget.controller.primaryGoal;
    
    // Save data as user types
    _targetWeightController.addListener(() {
      final raw = _targetWeightController.text.replaceAll(',', '.');
      final weight = double.tryParse(raw);
      if (weight != null) {
        widget.controller.setTargetWeight(weight);
      }
    });

    // Register validation callback
    widget.controller.registerValidationCallback(2, _validateAndNext);
  }

  @override
  void dispose() {
    _targetWeightController.dispose();
    super.dispose();
  }

  bool _validateAndNext() {
    return _formKey.currentState!.validate() && _selectedGoal != null;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Primary Goal Dropdown
            FormField<String>(
              initialValue: _selectedGoal,
              validator: (value) {
                if (value == null) {
                  return 'Veuillez sélectionner un objectif';
                }
                return null;
              },
              builder: (field) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomDropdownButton2(
                      hint: 'Sélectionner un objectif',
                      value: _selectedGoal,
                      dropdownItems: const [
                        'lose_weight',
                        'build_muscle',
                        'maintain',
                        'improve_endurance',
                        'increase_strength',
                        'general_fitness',
                      ],
                      dropdownLabels: const {
                        'lose_weight': 'Perdre du poids',
                        'build_muscle': 'Prendre du muscle',
                        'maintain': 'Maintenir mon poids',
                        'improve_endurance': 'Améliorer l\'endurance',
                        'increase_strength': 'Augmenter la force',
                        'general_fitness': 'Forme générale',
                      },
                      selectedItemBuilder: (context) {
                        return const [
                          'Perdre du poids',
                          'Prendre du muscle',
                          'Maintenir mon poids',
                          'Améliorer l\'endurance',
                          'Augmenter la force',
                          'Forme générale',
                        ].map((String item) => Text(item)).toList();
                      },
                      labelText: 'Objectif principal',
                      prefixIcon: const Icon(Icons.flag_outlined),
                      onChanged: (value) {
                        setState(() {
                          _selectedGoal = value;
                        });
                        if (value != null) {
                          widget.controller.setPrimaryGoal(value);
                          field.didChange(value);
                        }
                      },
                    ),
                    if (field.hasError)
                      Padding(
                        padding: const EdgeInsets.only(top: 8, left: 16),
                        child: Text(
                          field.errorText!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            
            // Target Weight Field (Optional)
            TextFormField(
              controller: _targetWeightController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Poids cible (optionnel)',
                prefixIcon: Icon(Icons.track_changes_outlined),
                suffixText: 'kg',
              ),
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  final weight = double.tryParse(value.replaceAll(',', '.'));
                  if (weight == null || weight < 20 || weight > 300) {
                    return 'Veuillez entrer un poids valide (20-300 kg)';
                  }
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }
}

// Step 4: Sessions Per Week
class _Step4ActivityLevel extends StatefulWidget {
  final RegisterOnboardingController controller;
  
  const _Step4ActivityLevel({super.key, required this.controller});

  @override
  State<_Step4ActivityLevel> createState() => _Step4ActivityLevelState();
}

class _Step4ActivityLevelState extends State<_Step4ActivityLevel> {
  final TextEditingController _sessionsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.controller.sessionsPerWeek != null) {
      _sessionsController.text = widget.controller.sessionsPerWeek.toString();
    }
    
    // Register validation callback
    widget.controller.registerValidationCallback(3, _validateAndNext);
  }

  @override
  void dispose() {
    _sessionsController.dispose();
    super.dispose();
  }

  bool _validateAndNext() {
    final value = _sessionsController.text.trim();
    if (value.isEmpty) {
      return false;
    }
    final sessions = int.tryParse(value);
    return sessions != null && sessions >= 0 && sessions <= 14;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Sessions Per Week Input
          TextFormField(
            controller: _sessionsController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Nombre de séances par semaine',
              hintText: 'Ex: 3',
              prefixIcon: Icon(Icons.fitness_center_outlined),
              suffixText: 'séances/semaine',
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Veuillez entrer le nombre de séances souhaité';
              }
              final sessions = int.tryParse(value);
              if (sessions == null) {
                return 'Veuillez entrer un nombre valide';
              }
              if (sessions < 0) {
                return 'Le nombre de séances ne peut pas être négatif';
              }
              if (sessions > 14) {
                return 'Le nombre de séances ne peut pas dépasser 14 par semaine';
              }
              return null;
            },
            onChanged: (value) {
              final sessions = int.tryParse(value);
              if (sessions != null && sessions >= 0 && sessions <= 14) {
                widget.controller.setSessionsPerWeek(sessions);
              }
            },
          ),
        ],
      ),
    );
  }
}

// Step 5: Health Considerations
class _Step5HealthConsiderations extends StatefulWidget {
  final RegisterOnboardingController controller;
  
  const _Step5HealthConsiderations({super.key, required this.controller});

  @override
  State<_Step5HealthConsiderations> createState() => _Step5HealthConsiderationsState();
}

class _Step5HealthConsiderationsState extends State<_Step5HealthConsiderations> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _healthController;

  @override
  void initState() {
    super.initState();
    _healthController = TextEditingController(
      text: widget.controller.healthConsiderations ?? '',
    );
    
    // Save data as user types
    _healthController.addListener(() {
      widget.controller.setHealthConsiderations(_healthController.text);
    });

    // Register complete callback (on lance l'async sans l'await ici)
    widget.controller.registerCompleteCallback(() { _completeRegistration(); });
  }

  Future<void> _completeRegistration() async {
    final c = widget.controller;
    final authService = Get.find<AuthService>();
    final userProfileController = Get.find<UserProfileController>();

    // Afficher un indicateur de chargement
    Get.dialog(
      const Center(child: CircularProgressIndicator()),
      barrierDismissible: false,
    );

    try {
      // 1. Créer le compte sur le backend
      await authService.register(
        email: c.email ?? '',
        password: c.password ?? '',
        name: c.name ?? '',
      );

      // 2. Auto-login pour obtenir le JWT
      await authService.login(
        email: c.email ?? '',
        password: c.password ?? '',
      );

      // 3. Récupérer le profil serveur (id, username, email)
      final userData = await authService.getCurrentUser();
      userProfileController.setFromApiResponse(userData);

      // 4. Envoyer le profil complet au backend
      final userId = userProfileController.userId.value;
      final email = userData['email'] as String? ?? '';
      final username = userData['username'] as String? ?? '';
      if (userId != null) {
        await authService.updateUserProfile(
          userId,
          email: email,
          username: username,
          weight: c.weight,
          height: c.height?.toInt(),
          age: c.age,
          gender: c.gender,
          sportObjective: c.primaryGoal,
          targetWeight: c.targetWeight,
          sessionsPerWeek: c.sessionsPerWeek,
          healthConsiderations: c.healthConsiderations,
        );
      }

      // 5. Sauvegarder les données locales (genre, objectifs, etc.)
      userProfileController.setFromRegistration(
        name: c.name ?? '',
        email: c.email ?? '',
        weight: c.weight,
        height: c.height,
        sportObjective: c.primaryGoal,
        targetWeight: c.targetWeight,
        sessionsPerWeek: c.sessionsPerWeek,
        age: c.age,
        gender: c.gender,
      );

      // Fermer le loader
      Get.back();

      Get.snackbar(
        'Inscription réussie !',
        'Votre compte a été créé avec succès',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: TColors.primary,
        colorText: Colors.white,
      );

      Get.delete<RegisterOnboardingController>();
      Get.offAll(() => const NavigationMenu());

    } on ApiException catch (e) {
      Get.back(); // Fermer le loader
      String message = e.message;
      if (message.contains('Email already registered')) {
        message = 'Cet email est déjà utilisé';
      } else if (message.contains('Username already taken')) {
        message = 'Ce nom d\'utilisateur est déjà pris';
      }
      Get.snackbar('Erreur', message, snackPosition: SnackPosition.BOTTOM);
    } catch (_) {
      Get.back(); // Fermer le loader
      Get.snackbar('Erreur', 'Impossible de se connecter au serveur',
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  @override
  void dispose() {
    _healthController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Health Considerations Field (Optional)
            TextFormField(
              controller: _healthController,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Blessures, limitations ou conditions médicales (optionnel)',
                prefixIcon: Icon(Icons.health_and_safety_outlined),
                alignLabelWithHint: true,
                hintText: 'Décrivez toute blessure, limitation physique ou condition médicale que nous devrions connaître...',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Ces informations nous aident à créer un programme d\'entraînement sûr et adapté à vos besoins.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: THelperFunctions.isDarkMode(context)
                    ? Colors.grey[400]
                    : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Controller for managing onboarding state
class RegisterOnboardingController extends GetxController {
  final PageController pageController = PageController();
  final RxInt currentStep = 0.obs;
  final int totalSteps = 5;

  // User data
  String? name;
  String? email;
  String? password;
  int? age;
  String? gender;
  double? height;
  double? weight;
  String? primaryGoal;
  double? targetWeight;
  int? sessionsPerWeek;
  String? healthConsiderations;

  // Validation callbacks for each step
  final Map<int, bool Function()> _validationCallbacks = {};
  VoidCallback? _completeCallback;

  void registerValidationCallback(int step, bool Function() callback) {
    _validationCallbacks[step] = callback;
  }

  void registerCompleteCallback(VoidCallback callback) {
    _completeCallback = callback;
  }

  void setName(String value) => name = value;
  void setEmail(String value) => email = value;
  void setPassword(String value) => password = value;
  void setAge(int value) => age = value;
  void setGender(String value) => gender = value;
  void setHeight(double value) => height = value;
  void setWeight(double value) => weight = value;
  void setPrimaryGoal(String value) => primaryGoal = value;
  void setTargetWeight(double value) => targetWeight = value;
  void setSessionsPerWeek(int value) => sessionsPerWeek = value;
  void setHealthConsiderations(String value) => healthConsiderations = value;

  void reset() {
    name = null;
    email = null;
    password = null;
    age = null;
    gender = null;
    height = null;
    weight = null;
    primaryGoal = null;
    targetWeight = null;
    sessionsPerWeek = null;
    healthConsiderations = null;
    currentStep.value = 0;
    _validationCallbacks.clear();
    _completeCallback = null;
    if (pageController.hasClients) {
      pageController.jumpToPage(0);
    }
  }

  void validateAndNextStep() {
    final callback = _validationCallbacks[currentStep.value];
    if (callback != null && callback()) {
      nextStep();
    }
  }

  void completeRegistration() {
    _completeCallback?.call();
  }

  void nextStep() {
    if (currentStep.value < totalSteps - 1) {
      currentStep.value++;
      pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void previousStep() {
    if (currentStep.value > 0) {
      currentStep.value--;
      pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  void onClose() {
    reset();
    pageController.dispose();
    super.onClose();
  }
}

