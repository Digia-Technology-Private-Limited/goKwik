import 'dart:math';
import 'package:flutter/material.dart';

class LoadingModal extends StatefulWidget {
  final bool visible;
  final TextStyle? titleStyle;
  final TextStyle? messageStyle;
  final BoxDecoration? containerStyle;
  final Color? overlayStyle;
  final Color? primaryColor;
  final Color? secondaryColor;
  final bool showSpinner;
  final Widget? customSpinner;
  final String? backgroundImage;
  final String? title;
  final String? message;

  const LoadingModal({
    super.key,
    required this.visible,
    this.titleStyle,
    this.messageStyle,
    this.containerStyle,
    this.overlayStyle,
    this.primaryColor,
    this.secondaryColor,
    this.showSpinner = true,
    this.customSpinner,
    this.backgroundImage,
    this.title,
    this.message,
  });

  @override
  State<LoadingModal> createState() => _LoadingModalState();
}

class _LoadingModalState extends State<LoadingModal>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );

    if (widget.visible) {
      _fadeController.forward();
    }
  }

  @override
  void didUpdateWidget(LoadingModal oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.visible != oldWidget.visible) {
      if (widget.visible) {
        _fadeController.forward();
      } else {
        _fadeController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.visible) {
      return const SizedBox.shrink();
    }

    return Material(
      type: MaterialType.transparency,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: widget.backgroundImage != null
            ? BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(widget.backgroundImage!),
                  fit: BoxFit.cover,
                ),
              )
            : const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF6366F1),
                    Color(0xFF8B5CF6),
                    Color(0xFFEC4899),
                  ],
                ),
              ),
        child: Container(
          color: widget.overlayStyle,
          padding: const EdgeInsets.all(24.0),
          child: Center(
            child: AnimatedBuilder(
              animation: _fadeController,
              builder: (context, child) {
                return Opacity(
                  opacity: _fadeAnimation.value,
                  child: Transform.scale(
                    scale: _scaleAnimation.value,
                    child: child,
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(40.0),
                decoration: widget.containerStyle,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (widget.title != null && widget.title!.isNotEmpty)
                      Text(
                        widget.title!,
                        style: widget.titleStyle ??
                            const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                        textAlign: TextAlign.center,
                      ),
                    if (widget.title != null && widget.title!.isNotEmpty)
                      const SizedBox(height: 18),
                    if (widget.message != null && widget.message!.isNotEmpty)
                      Text(
                        widget.message!,
                        style: widget.messageStyle ??
                            const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w400,
                              color: Color(0xFFE5E7EB),
                              height: 1.09,
                            ),
                        textAlign: TextAlign.center,
                      ),
                    if (widget.message != null && widget.message!.isNotEmpty)
                      const SizedBox(height: 18),
                    if (widget.showSpinner)
                      widget.customSpinner ?? const AnimatedSpinner(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AnimatedSpinner extends StatefulWidget {
  const AnimatedSpinner({Key? key}) : super(key: key);

  @override
  State<AnimatedSpinner> createState() => _AnimatedSpinnerState();
}

class _AnimatedSpinnerState extends State<AnimatedSpinner>
    with SingleTickerProviderStateMixin {
  late AnimationController _spinController;

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _spinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 60,
      height: 60,
      child: AnimatedBuilder(
        animation: _spinController,
        builder: (context, child) {
          return Transform.rotate(
            angle: _spinController.value * 2 * pi,
            child: child,
          );
        },
        child: Stack(
          alignment: Alignment.center,
          children: List.generate(12, (index) {
            final angle = (index * 360 / 12) * pi / 180;
            final opacity = max(0.15, 1 - (index * 0.08));

            return Transform(
              transform: Matrix4.identity()
                ..rotateZ(angle)
                ..translate(0.0, -22.0),
              alignment: Alignment.center,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(opacity),
                  shape: BoxShape.circle,
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
