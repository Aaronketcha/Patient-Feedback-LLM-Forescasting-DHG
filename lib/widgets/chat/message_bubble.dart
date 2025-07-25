import 'package:flutter/material.dart';
import '../../constants/colors.dart';
import '../../constants/text_styles.dart';
import '../../constants/dimensions.dart';
import '../../models/message.dart';

class MessageBubble extends StatelessWidget {
  final Message message;
  final bool isConsecutive;

  const MessageBubble({
    super.key,
    required this.message,
    this.isConsecutive = false,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.sender == MessageSender.user;

    return Container(
      margin: EdgeInsets.only(
        bottom: isConsecutive ? 4 : AppDimensions.spacingMedium,
        top: isConsecutive ? 0 : AppDimensions.spacingSmall,
      ),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser && !isConsecutive) _buildAvatar(),
          if (!isUser && isConsecutive) const SizedBox(width: 40),
          if (!isUser) const SizedBox(width: AppDimensions.spacingSmall),

          Flexible(
            child: Container(
              constraints: const BoxConstraints(
                maxWidth: AppDimensions.messageMaxWidth,
              ),
              child: Column(
                crossAxisAlignment: isUser
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  _buildMessageContent(isUser),
                  if (!isConsecutive) _buildTimestamp(),
                ],
              ),
            ),
          ),

          if (isUser) const SizedBox(width: AppDimensions.spacingSmall),
          if (isUser && !isConsecutive) _buildUserAvatar(),
          if (isUser && isConsecutive) const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Icon(
        Icons.smart_toy,
        size: 18,
        color: Colors.white,
      ),
    );
  }

  Widget _buildUserAvatar() {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: AppColors.surfaceSecondary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: const Icon(
        Icons.person,
        size: 18,
        color: AppColors.textSecondary,
      ),
    );
  }

  Widget _buildMessageContent(bool isUser) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingMedium,
        vertical: AppDimensions.paddingSmall + 2,
      ),
      decoration: BoxDecoration(
        color: isUser ? AppColors.userMessage : AppColors.botMessage,
        borderRadius: _getBorderRadius(isUser),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMessageText(isUser),
          if (message.type != MessageType.text) _buildAttachment(),
        ],
      ),
    );
  }

  Widget _buildMessageText(bool isUser) {
    return SelectableText(
      message.content,
      style: isUser ? AppTextStyles.messageUser : AppTextStyles.messageBot,
    );
  }

  Widget _buildAttachment() {
    switch (message.type) {
      case MessageType.image:
        return _buildImageAttachment();
      case MessageType.audio:
        return _buildAudioAttachment();
      case MessageType.file:
        return _buildFileAttachment();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildImageAttachment() {
    if (message.imageUrl == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: AppDimensions.spacingSmall),
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
        color: AppColors.surfaceSecondary,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
        child: Image.network(
          message.imageUrl!,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            alignment: Alignment.center,
            child: const Icon(
              Icons.broken_image,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAudioAttachment() {
    return Container(
      margin: const EdgeInsets.only(top: AppDimensions.spacingSmall),
      padding: const EdgeInsets.all(AppDimensions.paddingSmall),
      decoration: BoxDecoration(
        color: AppColors.surfaceSecondary,
        borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: () {
              // TODO: Play/pause audio
            },
            icon: const Icon(Icons.play_arrow),
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            padding: EdgeInsets.zero,
          ),
          const SizedBox(width: AppDimensions.spacingSmall),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Message vocal',
                  style: AppTextStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '0:32', // Duration placeholder
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFileAttachment() {
    return Container(
      margin: const EdgeInsets.only(top: AppDimensions.spacingSmall),
      padding: const EdgeInsets.all(AppDimensions.paddingSmall),
      decoration: BoxDecoration(
        color: AppColors.surfaceSecondary,
        borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
            ),
            child: const Icon(
              Icons.description,
              size: 18,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: AppDimensions.spacingSmall),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message.fileName ?? 'Fichier',
                  style: AppTextStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Document', // File type placeholder
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              // TODO: Download/open file
            },
            icon: const Icon(Icons.download),
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  Widget _buildTimestamp() {
    return Container(
      margin: const EdgeInsets.only(top: AppDimensions.spacingXSmall),
      child: Text(
        _formatTimestamp(message.timestamp),
        style: AppTextStyles.messageTime,
      ),
    );
  }

  BorderRadius _getBorderRadius(bool isUser) {
    const radius = AppDimensions.messageBubbleRadius;

    if (isConsecutive) {
      return BorderRadius.circular(radius);
    }

    return BorderRadius.only(
      topLeft: const Radius.circular(radius),
      topRight: const Radius.circular(radius),
      bottomLeft: isUser
          ? const Radius.circular(radius)
          : const Radius.circular(4),
      bottomRight: isUser
          ? const Radius.circular(4)
          : const Radius.circular(radius),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    } else if (difference.inHours > 0) {
      return 'Il y a ${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return 'Il y a ${difference.inMinutes}min';
    } else {
      return 'À l\'instant';
    }
  }
}