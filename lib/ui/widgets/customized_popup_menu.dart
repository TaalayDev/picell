import 'package:flutter/material.dart';

Future<T?> showCustomizedMenu<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  Color barrierColor = Colors.transparent,
  Offset? position,
  bool barrierDismissible = true,
  double barrierRadius = 0.0,
  String barrierLabel = '',
  Duration transitionDuration = const Duration(milliseconds: 200),
}) {
  return Navigator.of(context, rootNavigator: true).push<T>(
    CustomizedPopupRoute<T>(
      builder: builder,
      barrierColor: barrierColor,
      barrierDismissible: barrierDismissible,
      barrierRadius: barrierRadius,
      barrierLabel: barrierLabel,
      transitionDuration: transitionDuration,
      position: position,
    ),
  );
}

class CustomizedDropdownMenu extends StatefulWidget {
  const CustomizedDropdownMenu({
    super.key,
    this.isOpen = false,
    this.wrapContentWidth = false,
    this.onClosed,
    required this.menuBuilder,
    required this.child,
    this.menuWidth,
  });

  final bool isOpen;
  final bool wrapContentWidth;
  final double? menuWidth;
  final Function()? onClosed;
  final Widget Function(BuildContext context) menuBuilder;
  final Widget child;

  @override
  State<CustomizedDropdownMenu> createState() => _CustomzedDropdownMenuState();
}

class _CustomzedDropdownMenuState<T> extends State<CustomizedDropdownMenu> {
  void openMenu() async {
    final renderObject = context.findRenderObject();
    if (renderObject is! RenderBox) {
      return;
    }

    final renderBox = renderObject;
    final position = renderBox.localToGlobal(Offset.zero);
    await showCustomizedMenu(
      context: context,
      builder: (context) {
        return SizedBox(
          width:
              widget.wrapContentWidth ? renderBox.size.width : widget.menuWidth,
          child: widget.menuBuilder(context),
        );
      },
      position: Offset(
        position.dx,
        position.dy + renderBox.size.height,
      ),
    );
    widget.onClosed?.call();
  }

  @override
  void didUpdateWidget(CustomizedDropdownMenu oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isOpen && !oldWidget.isOpen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        openMenu();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(child: widget.child);
  }
}

class CustomizedPopupRoute<T> extends PopupRoute<T> {
  CustomizedPopupRoute({
    required this.builder,
    required this.barrierColor,
    required this.barrierLabel,
    this.barrierDismissible = true,
    this.barrierRadius = 0.0,
    this.transitionDuration = const Duration(milliseconds: 200),
    this.position,
    super.settings,
  });

  final WidgetBuilder builder;
  final Color barrierColor;
  final bool barrierDismissible;
  final double barrierRadius;
  final String barrierLabel;
  final Duration transitionDuration;
  final Offset? position;

  @override
  bool get maintainState => false;

  @override
  Widget buildPage(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation) {
    return this.builder(context);
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curveTween = CurveTween(curve: Curves.easeInOut);
    final animationCurve = animation.drive(curveTween);
    final secondaryAnimationCurve = secondaryAnimation.drive(curveTween);

    return MediaQuery.removePadding(
      context: context,
      removeTop: true,
      removeBottom: true,
      removeLeft: true,
      removeRight: true,
      child: FadeTransition(
        opacity: animationCurve,
        child: CustomSingleChildLayout(
          delegate: _PopupDialogRouteLayout(
            progress: animationCurve,
            secondaryProgress: secondaryAnimationCurve,
            alignment: Alignment(
              position?.dx ?? 0.0,
              position?.dy ?? 0,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: child,
          ),
        ),
      ),
    );
  }
}

class _PopupDialogRouteLayout extends SingleChildLayoutDelegate {
  _PopupDialogRouteLayout({
    required this.progress,
    required this.secondaryProgress,
    required this.alignment,
  });

  final Alignment alignment;
  final Animation<double> progress;
  final Animation<double> secondaryProgress;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    return BoxConstraints.loose(constraints.biggest);
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    // alignment.y - size.height * (1 - progress.value),

    return Offset(
      alignment.x,
      alignment.y,
    );
  }

  @override
  bool shouldRelayout(_PopupDialogRouteLayout oldDelegate) {
    return progress != oldDelegate.progress ||
        secondaryProgress != oldDelegate.secondaryProgress ||
        alignment != oldDelegate.alignment;
  }
}
