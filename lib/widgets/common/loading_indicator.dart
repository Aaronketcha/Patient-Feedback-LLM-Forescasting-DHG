import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:chatbot_ai/constants/text_styles.dart';
import 'package:chatbot_ai/constants/colors.dart';
import 'package:chatbot_ai/constants/dimensions.dart';
enum LoadingType {
  circular,
  dots,
  pulse,
  wave,
  spinner,
  typing,
  custom,
}

class LoadingIndicator extends StatefulWidget {
  final LoadingType type;
  final String? message;
  final Color? color;
  final double size;
  final Duration duration;
  final bool showMessage;

  const LoadingIndicator({
    Key? key,
    this.type = LoadingType.circular,
    this.message,
    this.color,
    this.size = 40.0,
    this.duration = const Duration(milliseconds: 1500),
    this.showMessage = true,
  }) : super(key: key);

  @override
  State<LoadingIndicator> createState() => _LoadingIndicatorState();
}

class _LoadingIndicatorState extends State<LoadingIndicator>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.linear,
    ));
    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? AppColors.primary;

    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildLoadingWidget(color),
        if (widget.showMessage && widget.message != null) ...[
          const SizedBox(height: AppDimensions.spacingMedium),
          Text(
            widget.message!,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  Widget _buildLoadingWidget(Color color) {
    switch (widget.type) {
      case LoadingType.circular:
        return _buildCircularLoader(color);
      case LoadingType.dots:
        return _buildDotsLoader(color);
      case LoadingType.pulse:
        return _buildPulseLoader(color);
      case LoadingType.wave:
        return _buildWaveLoader(color);
      case LoadingType.spinner:
        return _buildSpinnerLoader(color);
      case LoadingType.typing:
        return _buildTypingLoader(color);
      case LoadingType.custom:
        return _buildCustomLoader(color);
      default:
        return _buildCircularLoader(color);
    }
  }

  Widget _buildCircularLoader(Color color) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.rotate(
          angle: _animation.value * 2 * math.pi,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: color.withOpacity(0.2),
                width: 3,
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  top: 0,
                  left: widget.size / 2 - 1.5,
                  child: Container(
                    width: 3,
                    height: widget.size / 4,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDotsLoader(Color color) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            final delay = index * 0.3;
            final animationValue = (_animation.value + delay) % 1.0;
            final scale = 0.5 + (math.sin(animationValue * 2 * math.pi) * 0.5);

            return Container(
              margin: EdgeInsets.symmetric(horizontal: widget.size * 0.1),
              child: Transform.scale(
                scale: scale,
                child: Container(
                  width: widget.size * 0.2,
                  height: widget.size * 0.2,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildPulseLoader(Color color) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final scale = 0.5 + (math.sin(_animation.value * 2 * math.pi) * 0.5);
        final opacity = 0.3 + (math.sin(_animation.value * 2 * math.pi) * 0.7);

        return Transform.scale(
          scale: scale,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              color: color.withOpacity(opacity),
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }

  Widget _buildWaveLoader(Color color) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(5, (index) {
            final delay = index * 0.1;
            final animationValue = (_animation.value + delay) % 1.0;
            final height = widget.size * 0.3 +
                (math.sin(animationValue * 2 * math.pi) * widget.size * 0.3);

            return Container(
              margin: EdgeInsets.symmetric(horizontal: widget.size * 0.05),
              width: widget.size * 0.1,
              height: height,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(widget.size * 0.05),
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildSpinnerLoader(Color color) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.rotate(
          angle: _animation.value * 2 * math.pi,
          child: Container(
            width: widget.size,
            height: widget.size,
            child: CustomPaint(
              painter: SpinnerPainter(
                color: color,
                strokeWidth: widget.size * 0.08,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTypingLoader(Color color) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            final delay = index * 0.2;
            final animationValue = (_animation.value + delay) % 1.0;
            final opacity = animationValue < 0.5
                ? animationValue * 2
                : 2 - (animationValue * 2);

            return Container(
              margin: EdgeInsets.symmetric(horizontal: widget.size * 0.08),
              child: Container(
                width: widget.size * 0.15,
                height: widget.size * 0.15,
                decoration: BoxDecoration(
                  color: color.withOpacity(opacity.clamp(0.2, 1.0)),
                  shape: BoxShape.circle,
                ),
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildCustomLoader(Color color) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.size,
          height: widget.size,
          child: CustomPaint(
            painter: CustomLoadingPainter(
              progress: _animation.value,
              color: color,
            ),
          ),
        );
      },
    );
  }
}

class SpinnerPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;

  SpinnerPainter({
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.3)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Cercle de fond
    canvas.drawCircle(center, radius, paint);

    // Arc coloré
    paint.color = color;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      math.pi,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class CustomLoadingPainter extends CustomPainter {
  final double progress;
  final Color color;

  CustomLoadingPainter({
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Dessiner des cercles concentriques animés
    for (int i = 0; i < 3; i++) {
      final animatedRadius = radius * (0.3 + i * 0.2) *
          (0.5 + 0.5 * math.sin((progress + i * 0.3) * 2 * math.pi));
      final opacity = 0.7 - i * 0.2;

      paint.color = color.withOpacity(opacity);
      canvas.drawCircle(center, animatedRadius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Widget d'overlay de chargement plein écran
class LoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final Widget child;
  final String? message;
  final LoadingType type;
  final Color? backgroundColor;
  final Color? indicatorColor;

  const LoadingOverlay({
    Key? key,
    required this.isLoading,
    required this.child,
    this.message,
    this.type = LoadingType.circular,
    this.backgroundColor,
    this.indicatorColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Container(
            color: backgroundColor ?? Colors.black.withOpacity(0.5),
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(AppDimensions.paddingLarge),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppDimensions.borderRadiusMedium as double),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.shadow.withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: LoadingIndicator(
                  type: type,
                  message: message ?? 'Chargement...',
                  color: indicatorColor,
                  size: 50,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// Widget de chargement pour les listes
class ListLoadingIndicator extends StatelessWidget {
  final LoadingType type;
  final Color? color;
  final String? message;

  const ListLoadingIndicator({
    Key? key,
    this.type = LoadingType.dots,
    this.color,
    this.message,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingLarge),
      child: Center(
        child: LoadingIndicator(
          type: type,
          color: color,
          message: message ?? 'Chargement des données...',
          size: 30,
        ),
      ),
    );
  }
}

// Widget de chargement pour les boutons
class ButtonLoadingIndicator extends StatelessWidget {
  final Color? color;
  final double size;

  const ButtonLoadingIndicator({
    Key? key,
    this.color,
    this.size = 20,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LoadingIndicator(
      type: LoadingType.circular,
      color: color ?? Colors.white,
      size: size,
      showMessage: false,
    );
  }
}

// Extension pour faciliter l'utilisation
extension LoadingExtension on Widget {
  Widget withLoading({
    required bool isLoading,
    String? message,
    LoadingType type = LoadingType.circular,
    Color? backgroundColor,
    Color? indicatorColor,
  }) {
    return LoadingOverlay(
      isLoading: isLoading,
      message: message,
      type: type,
      backgroundColor: backgroundColor,
      indicatorColor: indicatorColor,
      child: this,
    );
  }
}