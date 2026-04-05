import 'package:flutter/material.dart';

OverlayEntry showLoader(BuildContext context, {String? loadingText}) {
  OverlayEntry loader = OverlayEntry(builder: (context) {
    return DefaultTextStyle(
      style: const TextStyle(),
      child: Align(
        alignment: Alignment.center,
        child: Container(
          height: 200,
          width: 200,
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: BorderRadius.circular(16.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                spreadRadius: 2,
                blurRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 25),
              Text(
                loadingText ?? 'Загрузка...',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onBackground,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  });
  Overlay.of(context).insert(loader);

  return loader;
}
