import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/colors.dart';
import '../constants/text_styles.dart';
import '../constants/dimensions.dart';
import '../services/chat_service.dart';
import '../services/auth_service.dart';
import '../widgets/common/custom_button.dart';
import '../widgets/navigation/bottom_nav_bar.dart';
import 'chat_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ChatService>(context, listen: false).initialize();
    });
  }

  void _onTabChanged(int index) {
    setState(() => _currentIndex = index);
  }

  void _startNewChat() async {
    final chatService = Provider.of<ChatService>(context, listen: false);
    await chatService.createNewChat('Nouvelle conversation');

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const ChatScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      _buildHomeTab(),
      _buildHistoryTab(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: pages[_currentIndex],
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onTabChanged,
      ),
      floatingActionButton: _currentIndex == 0 || _currentIndex == 1
          ? FloatingActionButton(
        onPressed: _startNewChat,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      )
          : null,
    );
  }

  Widget _buildHomeTab() {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.paddingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: AppDimensions.spacingXLarge),
            _buildQuickActions(),
            const SizedBox(height: AppDimensions.spacingXLarge),
            _buildSuggestedPrompts(),
            const SizedBox(height: AppDimensions.spacingXLarge),
            _buildRecentChats(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Consumer<AuthService>(
      builder: (context, authService, child) {
        final user = authService.currentUser;
        final hour = DateTime.now().hour;
        String greeting = 'Bonjour';

        if (hour >= 12 && hour < 18) {
          greeting = 'Bon après-midi';
        } else if (hour >= 18) {
          greeting = 'Bonsoir';
        }

        return Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$greeting${user?.name != null ? ', ${user!.name.split(' ').first}' : ''}',
                    style: AppTextStyles.h3,
                  ),
                  const SizedBox(height: AppDimensions.spacingXSmall),
                  Text(
                    'Comment puis-je vous aider aujourd\'hui ?',
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
              ),
              child: user?.avatarUrl != null
                  ? ClipRRect(
                borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                child: Image.network(
                  user!.avatarUrl!,
                  fit: BoxFit.cover,
                ),
              )
                  : Icon(
                Icons.person,
                color: Colors.white,
                size: AppDimensions.iconMedium,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildQuickActions() {
    final actions = [
      QuickAction(
        icon: Icons.chat_outlined,
        title: 'Nouvelle conversation',
        subtitle: 'Commencer à discuter',
        onTap: _startNewChat,
      ),
      QuickAction(
        icon: Icons.lightbulb_outline,
        title: 'Idées créatives',
        subtitle: 'Inspiration et brainstorming',
        onTap: () => _startChatWithPrompt('Aide-moi à générer des idées créatives pour...'),
      ),
      QuickAction(
        icon: Icons.school_outlined,
        title: 'Aide aux devoirs',
        subtitle: 'Assistance éducative',
        onTap: () => _startChatWithPrompt('J\'ai besoin d\'aide pour comprendre...'),
      ),
      QuickAction(
        icon: Icons.code_outlined,
        title: 'Programmation',
        subtitle: 'Aide au développement',
        onTap: () => _startChatWithPrompt('Peux-tu m\'aider avec ce code...'),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Actions rapides',
          style: AppTextStyles.h4,
        ),
        const SizedBox(height: AppDimensions.spacingMedium),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: AppDimensions.spacingMedium,
            mainAxisSpacing: AppDimensions.spacingMedium,
            childAspectRatio: 1.2,
          ),
          itemCount: actions.length,
          itemBuilder: (context, index) {
            final action = actions[index];
            return _buildQuickActionCard(action);
          },
        ),
      ],
    );
  }

  Widget _buildQuickActionCard(QuickAction action) {
    return GestureDetector(
      onTap: action.onTap,
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.paddingMedium),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
          border: Border.all(color: AppColors.border),
          boxShadow: const [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
              ),
              child: Icon(
                action.icon,
                color: AppColors.primary,
                size: AppDimensions.iconMedium,
              ),
            ),
            const SizedBox(height: AppDimensions.spacingMedium),
            Text(
              action.title,
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppDimensions.spacingXSmall),
            Text(
              action.subtitle,
              style: AppTextStyles.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestedPrompts() {
    final prompts = [
      'Explique-moi la photosynthèse simplement',
      'Aide-moi à planifier mes vacances',
      'Quelles sont les tendances tech de 2024 ?',
      'Comment améliorer ma productivité ?',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Suggestions',
          style: AppTextStyles.h4,
        ),
        const SizedBox(height: AppDimensions.spacingMedium),
        ...prompts.map((prompt) => _buildPromptCard(prompt)),
      ],
    );
  }

  Widget _buildPromptCard(String prompt) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: AppDimensions.spacingSmall),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        child: InkWell(
          onTap: () => _startChatWithPrompt(prompt),
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          child: Container(
            padding: const EdgeInsets.all(AppDimensions.paddingMedium),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    prompt,
                    style: AppTextStyles.bodyMedium,
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecentChats() {
    return Consumer<ChatService>(
      builder: (context, chatService, child) {
        final recentChats = chatService.chats.take(3).toList();

        if (recentChats.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Conversations récentes',
                  style: AppTextStyles.h4,
                ),
                TextButton(
                  onPressed: () => setState(() => _currentIndex = 1),
                  child: Text(
                    'Voir tout',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.spacingMedium),
            ...recentChats.map((chat) => _buildChatCard(chat)),
          ],
        );
      },
    );
  }

  Widget _buildChatCard(chat) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: AppDimensions.spacingSmall),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        child: InkWell(
          onTap: () {
            final chatService = Provider.of<ChatService>(context, listen: false);
            chatService.setCurrentChat(chat);
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const ChatScreen()),
            );
          },
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          child: Container(
            padding: const EdgeInsets.all(AppDimensions.paddingMedium),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  chat.title,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppDimensions.spacingXSmall),
                Text(
                  chat.lastMessagePreview,
                  style: AppTextStyles.bodySmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryTab() {
    return Consumer<ChatService>(
      builder: (context, chatService, child) {
        return SafeArea(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(AppDimensions.paddingLarge),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Historique',
                        style: AppTextStyles.h3,
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        // TODO: Implement search
                      },
                      icon: const Icon(Icons.search),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: chatService.chats.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.paddingLarge,
                  ),
                  itemCount: chatService.chats.length,
                  itemBuilder: (context, index) {
                    final chat = chatService.chats[index];
                    return _buildHistoryChatCard(chat);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHistoryChatCard(chat) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.spacingMedium),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        child: InkWell(
          onTap: () {
            final chatService = Provider.of<ChatService>(context, listen: false);
            chatService.setCurrentChat(chat);
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const ChatScreen()),
            );
          },
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          child: Container(
            padding: const EdgeInsets.all(AppDimensions.paddingMedium),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                  ),
                  child: const Icon(
                    Icons.chat_outlined,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppDimensions.spacingMedium),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              chat.title,
                              style: AppTextStyles.bodyMedium.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (chat.isPinned)
                            const Icon(
                              Icons.push_pin,
                              size: 16,
                              color: AppColors.primary,
                            ),
                        ],
                      ),
                      const SizedBox(height: AppDimensions.spacingXSmall),
                      Text(
                        chat.lastMessagePreview,
                        style: AppTextStyles.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {
                    // TODO: Show chat options
                  },
                  icon: const Icon(
                    Icons.more_vert,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.surfaceSecondary,
              borderRadius: BorderRadius.circular(AppDimensions.radiusXLarge),
            ),
            child: const Icon(
              Icons.chat_outlined,
              size: 40,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppDimensions.spacingLarge),
          Text(
            'Aucune conversation',
            style: AppTextStyles.h4,
          ),
          const SizedBox(height: AppDimensions.spacingSmall),
          Text(
            'Commencez une nouvelle conversation\navec votre assistant IA',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppDimensions.spacingLarge),
          CustomButton(
            text: 'Nouvelle conversation',
            onPressed: _startNewChat,
            isFullWidth: false,
          ),
        ],
      ),
    );
  }

  void _startChatWithPrompt(String prompt) async {
    final chatService = Provider.of<ChatService>(context, listen: false);
    await chatService.createNewChat(prompt.length > 30 ? '${prompt.substring(0, 30)}...' : prompt);

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ChatScreen(initialMessage: prompt),
      ),
    );
  }
}

class QuickAction {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  QuickAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
}