import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

import '../../../l10n/strings.dart';

class EffectsEmptyWidget extends StatelessWidget {
  const EffectsEmptyWidget({super.key, required this.addEffect});

  final VoidCallback addEffect;

  @override
  Widget build(BuildContext context) {
    final s = Strings.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Feather.droplet,
            size: 48,
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            s.noEffectsApplied,
            style: TextStyle(
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            icon: const Icon(Icons.add),
            label: Text(s.effectsPanelAddEffect),
            onPressed: addEffect,
          ),
        ],
      ),
    );
  }
}
