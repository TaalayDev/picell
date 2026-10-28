import 'package:flutter/widgets.dart';

class McpControl extends StatelessWidget {
  const McpControl({super.key, required this.child, required this.navigatorKey});
  final Widget child;
  final GlobalKey<NavigatorState> navigatorKey;
  @override
  Widget build(BuildContext context) => child;
}
