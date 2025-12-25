import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import 'custom_button.dart';

class EmptyStateWidget extends StatelessWidget {
  final IconData? icon;
  final String title;
  final String message;
  final String? buttonText;
  final VoidCallback? onButtonPressed;
  final bool isIconCrossed; // For "No Internet" wifi slash look

  const EmptyStateWidget({
    super.key,
    this.icon,
    required this.title,
    required this.message,
    this.buttonText,
    this.onButtonPressed,
    this.isIconCrossed = false,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null)
              Stack(
                alignment: Alignment.center,
                children: [
                   Icon(
                    icon,
                    size: 150,
                    color: Colors.grey[300],
                  ),
                   if (isIconCrossed)
                     Positioned(
                       child: Transform.rotate(
                         angle: -0.785, // -45 degrees
                         child: Container(
                           width: 150,
                           height: 4,
                           color: Colors.grey[300],
                         ),
                       ),
                     )
                ],
              ),
            const SizedBox(height: 32),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 24,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 16,
              ),
            ),
            if (buttonText != null) ...[
              const SizedBox(height: 40),
              PrimaryButton(
                text: buttonText!,
                onPressed: onButtonPressed ?? () {},
              )
            ]
          ],
        ),
      ),
    );
  }
}
