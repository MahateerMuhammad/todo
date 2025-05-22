


// lib/features/notes/presentation/widgets/floating_action_button_widget.dart
import 'package:flutter/material.dart';

class FloatingActionButtonWidget extends StatelessWidget {
  final VoidCallback onPressed;
  final AnimationController animationController;

  const FloatingActionButtonWidget({
    super.key,
    required this.onPressed,
    required this.animationController,
  });

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: Tween<double>(
        begin: 1.0,
        end: 1.1,
      ).animate(CurvedAnimation(
        parent: animationController,
        curve: Curves.elasticOut,
      )),
      child: FloatingActionButton.large(
        onPressed: () {
          animationController.forward().then((_) {
            animationController.reverse();
          });
          onPressed();
        },
        child: const Icon(Icons.add, size: 32),
      ),
    );
  }
}



