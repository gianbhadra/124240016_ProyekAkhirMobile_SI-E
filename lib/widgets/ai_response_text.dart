import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import '../theme/app_theme.dart';

class AiResponseText extends StatelessWidget {
  const AiResponseText({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return MarkdownBody(
      data: text,
      softLineBreak: true,
      styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
        p: const TextStyle(
          color: AppColors.text,
          fontSize: 15,
          height: 1.45,
        ),
      ),
    );
  }
}
