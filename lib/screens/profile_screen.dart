import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants/colors.dart';
import '../constants/text_styles.dart';
import '../constants/dimensions.dart';
import '../services/auth_service.dart';
import '../models/user.dart';
import '../widgets/common/custom_button.dart';
import 'settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Consumer<AuthService>(
          builder: (context, authService, child) {
            final User? user = authService.currentUser;

            return FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppDimensions.paddingLarge),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(context),
                      const SizedBox(height: AppDimensions.spacingXLarge),
                      _buildProfileCard(user),
                      const SizedBox(height: AppDimensions.spacingLarge),
                      _buildStatsSection(user),
                      const SizedBox(height: AppDimensions.spacingLarge),
                      _buildMenuSection(context, authService),
                      const SizedBox(height: AppDimensions.spacingLarge),
                      _buildLogoutButton(context, authService),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Mon Profil',
          style: AppTextStyles.h2.copyWith(color: AppColors.textPrimary),
        ),
        IconButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SettingsScreen()),
            );
          },
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadow.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              Icons.settings,
              color: AppColors.textSecondary,
              size: 24,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileCard(User? user) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingLarge),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withOpacity(0.1),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 50,
                backgroundColor: AppColors.primary.withOpacity(0.1),
                backgroundImage: user?.avatarUrl != null ? NetworkImage(user!.avatarUrl!) : null,
                child: user?.avatarUrl == null
                    ? Icon(
                  Icons.person,
                  size: 50,
                  color: AppColors.primary,
                )
                    : null,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.surface,
                      width: 3,
                    ),
                  ),
                  child: const Icon(
                    Icons.camera_alt,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingMedium),
          Text(
            user?.name ?? 'Utilisateur',
            style: AppTextStyles.h3.copyWith(color: AppColors.textPrimary),
          ),
          const SizedBox(height: AppDimensions.spacingSmall),
          Text(
            user?.email ?? 'email@example.com',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppDimensions.spacingSmall),
          if (user?.isPremium ?? false)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppDimensions.radiusXLarge),
              ),
              child: Text(
                'Premium',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.success,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatsSection(User? user) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingLarge),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withOpacity(0.1),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Statistiques',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
          ),
          const SizedBox(height: AppDimensions.spacingMedium),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  icon: Icons.chat_bubble_outline,
                  title: 'Conversations',
                  value: '${user?.preferences['totalChats'] ?? 0}',
                  color: AppColors.primary,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  icon: Icons.message_outlined,
                  title: 'Messages',
                  value: '${user?.preferences['totalMessages'] ?? 0}',
                  color: AppColors.accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingMedium),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  icon: Icons.access_time,
                  title: 'Temps total',
                  value: '${user?.preferences['totalTimeSpent'] ?? 0}h',
                  color: AppColors.warning,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  icon: Icons.calendar_today,
                  title: 'Membre depuis',
                  value: _formatDate(user?.createdAt),
                  color: AppColors.success,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMenuSection(BuildContext context, AuthService authService) {
    final menuItems = [
      {
        'icon': Icons.edit,
        'title': 'Modifier le profil',
        'subtitle': 'Mettre à jour vos informations',
        'onTap': () => _showEditProfileDialog(context, authService),
      },
      {
        'icon': Icons.history,
        'title': 'Historique des conversations',
        'subtitle': 'Voir toutes vos conversations',
        'onTap': () => _showChatHistory(context),
      },
      {
        'icon': Icons.star,
        'title': 'Conversations favorites',
        'subtitle': 'Vos conversations sauvegardées',
        'onTap': () => _showFavoriteChats(context),
      },
      {
        'icon': Icons.help_outline,
        'title': 'Aide & Support',
        'subtitle': 'Obtenir de l\'aide',
        'onTap': () => _showHelpDialog(context),
      },
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withOpacity(0.1),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: menuItems.map((item) {
          return ListTile(
            contentPadding: EdgeInsets.symmetric(
              horizontal: AppDimensions.paddingLarge,
              vertical: AppDimensions.paddingSmall,
            ),
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
              ),
              child: Icon(
                item['icon'] as IconData,
                color: AppColors.primary,
                size: 20,
              ),
            ),
            title: Text(
              item['title'] as String,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              item['subtitle'] as String,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            trailing: Icon(
              Icons.chevron_right,
              color: AppColors.textSecondary,
            ),
            onTap: item['onTap'] as VoidCallback,
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context, AuthService authService) {
    return CustomButton(
      text: 'Se déconnecter',
      onPressed: () => _handleLogout(context, authService),
      backgroundColor: AppColors.error.withOpacity(0.1),
      textColor: AppColors.error,
      icon: Icons.logout,
      borderColor: AppColors.error.withOpacity(0.3),
    );
  }

  void _showEditProfileDialog(BuildContext context, AuthService authService) {
    final nameController = TextEditingController(text: authService.currentUser?.name);
    final emailController = TextEditingController(text: authService.currentUser?.email);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        ),
        title: Text('Modifier le profil', style: AppTextStyles.h3),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'Nom',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              decoration: InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () {
              // Logique pour mettre à jour le profil ici (à implémenter)
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Profil mis à jour avec succès')),
              );
            },
            child: const Text('Sauvegarder'),
          ),
        ],
      ),
    );
  }

  void _showChatHistory(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Historique des conversations - À implémenter')),
    );
  }

  void _showFavoriteChats(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Conversations favorites - À implémenter')),
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        ),
        title: const Text('Aide & Support'),
        content: const Text('Pour toute question, contactez-nous à support@aichatbot.com'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Fermer')),
        ],
      ),
    );
  }

  void _handleLogout(BuildContext context, AuthService authService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        ),
        title: const Text('Confirmation'),
        content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () {
              authService.logout();
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, '/login');
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Se déconnecter'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    final now = DateTime.now();
    final difference = now.difference(date).inDays;
    return '${difference}j';
  }
}
