import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/colors.dart';
import '../constants/text_styles.dart';
import '../constants/dimensions.dart';
import '../services/chat_service.dart';
import '../widgets/chat/message_bubble.dart';
import '../widgets/chat/chat_input.dart';
import '../widgets/chat/typing_indicator.dart';

class ChatScreen extends StatefulWidget {
  final String? initialMessage;

  const ChatScreen({
    super.key,
    this.initialMessage,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    // Send initial message if provided
    if (widget.initialMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final chatService = Provider.of<ChatService>(context, listen: false);
        chatService.sendMessage(widget.initialMessage!);
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Consumer<ChatService>(
        builder: (context, chatService, child) {
          final currentChat = chatService.currentChat;

          if (currentChat == null) {
            return const Center(
              child: Text('Aucune conversation sélectionnée'),
            );
          }

          // Scroll to bottom when new messages arrive
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _scrollToBottom();
          });

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(AppDimensions.paddingMedium),
                  itemCount: currentChat.messages.length + (chatService.isTyping ? 1 : 0),
                  itemBuilder: (context, index) {
                    // Show typing indicator as last item
                    if (index == currentChat.messages.length && chatService.isTyping) {
                      return const TypingIndicator();
                    }

                    final message = currentChat.messages[index];
                    return MessageBubble(
                      message: message,
                      isConsecutive: _isConsecutiveMessage(currentChat.messages, index),
                    );
                  },
                ),
              ),
              ChatInput(
                onSendMessage: (content) {
                  chatService.sendMessage(content);
                  _scrollToBottom();
                },
              ),
            ],
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Consumer<ChatService>(
        builder: (context, chatService, child) {
          final currentChat = chatService.currentChat;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                currentChat?.title ?? 'Chat',
                style: AppTextStyles.bodyLarge.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (chatService.isTyping)
                Text(
                  'En train d\'écrire...',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.primary,
                  ),
                ),
            ],
          );
        },
      ),
      actions: [
        IconButton(
          onPressed: () {
            // TODO: Show chat options
            _showChatOptions();
          },
          icon: const Icon(Icons.more_vert),
        ),
      ],
    );
  }

  bool _isConsecutiveMessage(List messages, int index) {
    if (index == 0) return false;

    final currentMessage = messages[index];
    final previousMessage = messages[index - 1];

    return currentMessage.sender == previousMessage.sender &&
        currentMessage.timestamp.difference(previousMessage.timestamp).inMinutes < 5;
  }

  void _showChatOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppDimensions.radiusLarge),
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: AppDimensions.paddingMedium),
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.push_pin_outlined),
                title: const Text('Épingler la conversation'),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Toggle pin
                },
              ),
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('Renommer'),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Rename chat
                },
              ),
              ListTile(
                leading: const Icon(Icons.share_outlined),
                title: const Text('Partager'),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Share chat
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: AppColors.error),
                title: const Text('Supprimer', style: TextStyle(color: AppColors.error)),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteConfirmation();
                },
              ),
              const SizedBox(height: AppDimensions.paddingMedium),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la conversation'),
        content: const Text('Cette action est irréversible. Voulez-vous vraiment supprimer cette conversation ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
              // TODO: Delete chat
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}