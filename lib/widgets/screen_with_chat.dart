import 'package:flutter/material.dart';
import 'floating_chat_button.dart';
import '../utils/navigation_helper.dart';
import '../screens/chat/chat_screen.dart';

class ScreenWithChat extends StatelessWidget {
  final Widget child;
  final bool showFloatingChat;
  final Function()? onChatPressed;

  const ScreenWithChat({
    Key? key,
    required this.child,
    this.showFloatingChat = true,
    this.onChatPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Get the current route
    final String? routeName = ModalRoute.of(context)?.settings.name;
    
    // If showing the chat button is explicitly disabled or should not be shown for this route
    if (!showFloatingChat || !shouldShowChatButton(routeName)) {
      return child;
    }
    
    // Show the floating chat button for allowed screens
    return Stack(
      children: [
        child,
        FloatingChatButton(
          onPressed: onChatPressed ?? () {
            handleChatButtonPress(context);
          },
        ),
      ],
    );
  }
} 