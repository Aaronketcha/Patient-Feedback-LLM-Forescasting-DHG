import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../constants/text_styles.dart';
import '../constants/dimensions.dart';
import '../widgets/common/custom_button.dart';
import 'login_screen.dart';

class OnboardingPage {
  final IconData icon;
  final String title;
  final String description;

  OnboardingPage({
    required this.icon,
    required this.title,
    required this.description,
  });
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingPage> _pages = [
    OnboardingPage(
      icon: Icons.chat_bubble_outline,
      title: 'Conversations Intelligentes',
      description: 'Discutez avec notre IA avancée pour obtenir des réponses précises et personnalisées.',
    ),
    OnboardingPage(
      icon: Icons.lightbulb_outline,
      title: 'Assistance 24/7',
      description: 'Obtenez de l\'aide à tout moment, que ce soit pour le travail, les études ou la vie quotidienne.',
    ),
    OnboardingPage(
      icon: Icons.security_outlined,
      title: 'Sécurisé et Privé',
      description: 'Vos conversations sont protégées et votre vie privée est notre priorité absolue.',
    ),
  ];

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _navigateToLogin();
    }
  }

  void _navigateToLogin() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Padding(
              padding: const EdgeInsets.all(AppDimensions.paddingMedium),
              child: Align(
                alignment: Alignment.topRight,
                child: TextButton(
                  onPressed: _navigateToLogin,
                  child: Text(
                    'Passer',
                    style: AppTextStyles.buttonMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),

            // Pages
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  return Padding(
                    padding: const EdgeInsets.all(AppDimensions.paddingLarge),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            borderRadius: BorderRadius.circular(AppDimensions.radiusXLarge),
                          ),
                          child: Icon(
                            page.icon,
                            size: 60,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: AppDimensions.spacingXLarge),
                        Text(
                          page.title,
                          style: AppTextStyles.h2,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppDimensions.spacingMedium),
                        Text(
                          page.description,
                          style: AppTextStyles.bodyLarge.copyWith(
                            color: AppColors.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Bouton suivant
            Padding(
              padding: const EdgeInsets.all(AppDimensions.paddingMedium),
              child: CustomButton(
                text: _currentPage == _pages.length - 1 ? 'Commencer' : 'Suivant',
                onPressed: _nextPage,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
