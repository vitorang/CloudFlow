import 'package:flutter/material.dart';

class CloudFlowBrand extends StatelessWidget {
  final double? fontSize;
  final TextAlign textAlign;

  const CloudFlowBrand({
    super.key,
    this.fontSize,
    this.textAlign = TextAlign.start,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return RichText(
      textAlign: textAlign,
      text: TextSpan(
        style: TextStyle(
          fontSize: fontSize ?? 24,
          fontWeight: FontWeight.bold,
        ),
        children: [
          TextSpan(
            text: 'Cloud',
            style: TextStyle(color: theme.colorScheme.onSurface),
          ),
          TextSpan(
            text: 'Flow',
            style: TextStyle(color: theme.colorScheme.primary),
          ),
        ],
      ),
    );
  }
}
