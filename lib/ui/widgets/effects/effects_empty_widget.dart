import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

import '../../../l10n/strings.dart';

class EffectsEmptyWidget extends StatelessWidget {
  const EffectsEmptyWidget({
    super.key,
    required this.addEffect,
    this.title,
    this.icon = Feather.droplet,
  });

  final VoidCallback addEffect;
  final String? title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final s = Strings.of(context);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 48,
              color:
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            if (title != null) ...[
              Text(
                title!,
                key: const ValueKey('effects-empty-workspace-title'),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 4),
            ],
            Text(
              s.noEffectsApplied,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              key: const ValueKey('effects-empty-add'),
              icon: const Icon(Icons.add),
              label: Text(s.effectsPanelAddEffect),
              onPressed: addEffect,
            ),
          ],
        ),
      ),
    );
  }
}
