import 'package:flutter/material.dart';
import '../../constants/colors.dart';
import '../../constants/dimensions.dart';

class ChatInput extends StatefulWidget {
  final Function(String) onSendMessage;

  const ChatInput({
    super.key,
    required this.onSendMessage,
  });

  @override
  State<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends State<ChatInput> {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isComposing = false;

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleSubmitted(String text) {
    if (text.trim().isEmpty) return;

    widget.onSendMessage(text.trim());
    _textController.clear();
    setState(() => _isComposing = false);
  }

  void _handleTextChanged(String text) {
    setState(() => _isComposing = text.trim().isNotEmpty);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.paddingMedium),
          child: Row(
            children: [
              // Attachment button
              IconButton(
                onPressed: _showAttachmentOptions,
                icon: const Icon(
                  Icons.add_circle_outline,
                  color: AppColors.textSecondary,
                ),
              ),

              // Text input
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSecondary,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _textController,
                          focusNode: _focusNode,
                          onChanged: _handleTextChanged,
                          onSubmitted: _handleSubmitted,
                          maxLines: null,
                          textInputAction: TextInputAction.newline,
                          decoration: const InputDecoration(
                            hintText: 'Tapez votre message...',
                            hintStyle: TextStyle(color: AppColors.textTertiary),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: AppDimensions.paddingMedium,
                              vertical: AppDimensions.paddingSmall + 2,
                            ),
                          ),
                        ),
                      ),

                      // Microphone button (when not composing)
                      if (!_isComposing)
                        IconButton(
                          onPressed: _startVoiceRecording,
                          icon: const Icon(
                            Icons.mic_outlined,
                            color: AppColors.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: AppDimensions.spacingSmall),

              // Send button
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                child: GestureDetector(
                  onTap: _isComposing
                      ? () => _handleSubmitted(_textController.text)
                      : null,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: _isComposing
                          ? AppColors.primaryGradient
                          : null,
                      color: _isComposing
                          ? null
                          : AppColors.surfaceSecondary,
                      borderRadius: BorderRadius.circular(24),
                      border: !_isComposing
                          ? Border.all(color: AppColors.border)
                          : null,
                    ),
                    child: Icon(
                      Icons.send,
                      color: _isComposing
                          ? Colors.white
                          : AppColors.textSecondary,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAttachmentOptions() {
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

              Padding(
                padding: const EdgeInsets.all(AppDimensions.paddingLarge),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildAttachmentOption(
                          icon: Icons.photo_camera_outlined,
                          label: 'Caméra',
                          color: AppColors.primary,
                          onTap: () {
                            Navigator.pop(context);
                            _takePhoto();
                          },
                        ),
                        _buildAttachmentOption(
                          icon: Icons.photo_library_outlined,
                          label: 'Galerie',
                          color: AppColors.accent,
                          onTap: () {
                            Navigator.pop(context);
                            _pickImage();
                          },
                        ),
                        _buildAttachmentOption(
                          icon: Icons.insert_drive_file_outlined,
                          label: 'Document',
                          color: AppColors.info,
                          onTap: () {
                            Navigator.pop(context);
                            _pickDocument();
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: AppDimensions.spacingLarge),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildAttachmentOption(
                          icon: Icons.location_on_outlined,
                          label: 'Position',
                          color: AppColors.success,
                          onTap: () {
                            Navigator.pop(context);
                            _shareLocation();
                          },
                        ),
                        _buildAttachmentOption(
                          icon: Icons.person_outline,
                          label: 'Contact',
                          color: AppColors.warning,
                          onTap: () {
                            Navigator.pop(context);
                            _shareContact();
                          },
                        ),
                        const SizedBox(width: 60), // Placeholder for alignment
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppDimensions.paddingMedium),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAttachmentOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Icon(
              icon,
              color: color,
              size: 28,
            ),
          ),
          const SizedBox(height: AppDimensions.spacingSmall),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  void _startVoiceRecording() {
    // TODO: Implement voice recording
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Enregistrement vocal - Fonctionnalité à venir'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _takePhoto() {
    // TODO: Implement camera
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Appareil photo - Fonctionnalité à venir'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _pickImage() {
    // TODO: Implement image picker
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Sélection d\'image - Fonctionnalité à venir'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _pickDocument() {
    // TODO: Implement document picker
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Sélection de document - Fonctionnalité à venir'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _shareLocation() {
    // TODO: Implement location sharing
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Partage de position - Fonctionnalité à venir'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _shareContact() {
    // TODO: Implement contact sharing
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Partage de contact - Fonctionnalité à venir'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}