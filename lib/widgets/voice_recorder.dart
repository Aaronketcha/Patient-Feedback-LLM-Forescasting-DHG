import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/feedback_provider.dart';
import '../l10n/generated/app_localizations.dart';

class VoiceRecorder extends StatelessWidget {
  const VoiceRecorder({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Consumer<FeedbackProvider>(
      builder: (context, provider, child) {
        return Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.mic,
                    color: Colors.blue[700],
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    localizations.recordVoice,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.blue[700],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Recording Controls
              Row(
                children: [
                  // Record/Stop Button
                  ElevatedButton.icon(
                    onPressed: provider.isRecording
                        ? provider.stopRecording
                        : provider.startRecording,
                    icon: Icon(
                      provider.isRecording ? Icons.stop : Icons.fiber_manual_record,
                      color: provider.isRecording ? Colors.white : Colors.red,
                    ),
                    label: Text(
                      provider.isRecording
                          ? localizations.stopRecording
                          : localizations.recordVoice,
                      style: const TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: provider.isRecording
                          ? Colors.red
                          : Colors.blue[700],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Play/Pause Button (only if recording exists)
                  if (provider.recordingPath != null) ...[
                    ElevatedButton.icon(
                      onPressed: provider.playRecording,
                      icon: Icon(
                        provider.isPlaying ? Icons.pause : Icons.play_arrow,
                        color: Colors.white,
                      ),
                      label: Text(
                        provider.isPlaying ? 'Pause' : localizations.playRecording,
                        style: const TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[700],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),

                    const SizedBox(width: 8),

                    // Delete Button
                    ElevatedButton.icon(
                      onPressed: provider.deleteRecording,
                      icon: const Icon(Icons.delete, color: Colors.white),
                      label: Text(
                        localizations.deleteRecording,
                        style: const TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[700],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ],
              ),

              // Recording Status
              if (provider.isRecording) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      localizations.recording,
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],

              // Recording exists indicator
              if (provider.recordingPath != null && !provider.isRecording) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Recording saved',
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}