import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

class EffectsEmptyWidget extends StatelessWidget {
  const EffectsEmptyWidget({super.key, required this.addEffect});

  final VoidCallback addEffect;

  @override
  Widget build(BuildContext context) {
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
            'No effects applied',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Add Effect'),
            onPressed: addEffect,
          ),
        ],
      ),
    );
  }
}
