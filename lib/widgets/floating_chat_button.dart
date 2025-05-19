import 'package:flutter/material.dart';
import '../utils/navigation_helper.dart';

class FloatingChatButton extends StatelessWidget {
  final Function()? onPressed;
  
  const FloatingChatButton({
    Key? key,
    required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 20,
      bottom: 80,
      child: FloatingActionButton(
        heroTag: 'chatButton', // Add a unique hero tag to prevent conflicts
        onPressed: () {
          // Use provided callback if available, otherwise use the default handler
          if (onPressed != null) {
            onPressed!();
          } else {
            handleChatButtonPress(context);
          }
        },
        backgroundColor: const Color(0xFF4D9164), // Same color as app theme
        child: const Icon(
          Icons.chat,
          color: Colors.white,
        ),
      ),
    );
  }
} 