import 'package:flutter/material.dart';
import '../../../core/theme/suicang_theme.dart';

class GenerationErrorCard extends StatelessWidget {
  const GenerationErrorCard(
      {required this.message, required this.onRetry, super.key});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(16)),
      child: Row(children: [
        Icon(Icons.cloud_off_outlined,
            color: Theme.of(context).colorScheme.onErrorContainer),
        const SizedBox(width: 10),
        Expanded(
            child: Text(message,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onErrorContainer))),
        TextButton(onPressed: onRetry, child: const Text('重试'))
      ]));
}
