import 'package:flutter/material.dart';

import '../theme/app_dimens.dart';
import 'app_background.dart';

/// Standard screen scaffold that applies the ambient [AppBackground], a
/// transparent app bar and consistent horizontal padding.
class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    required this.body,
    this.title,
    this.titleWidget,
    this.actions,
    this.leading,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.padded = true,
    this.showAppBar = true,
    this.centerTitle = false,
    this.resizeToAvoidBottomInset = true,
    this.extendBodyBehindAppBar = true,
  });

  final Widget body;
  final String? title;
  final Widget? titleWidget;
  final List<Widget>? actions;
  final Widget? leading;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final bool padded;
  final bool showAppBar;
  final bool centerTitle;
  final bool resizeToAvoidBottomInset;
  final bool extendBodyBehindAppBar;

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: extendBodyBehindAppBar,
        resizeToAvoidBottomInset: resizeToAvoidBottomInset,
        appBar: showAppBar
            ? AppBar(
                title: titleWidget ?? (title != null ? Text(title!) : null),
                centerTitle: centerTitle,
                actions: actions,
                leading: leading,
              )
            : null,
        floatingActionButton: floatingActionButton,
        bottomNavigationBar: bottomNavigationBar,
        body: SafeArea(
          bottom: false,
          child: Padding(
            padding: padded
                ? const EdgeInsets.symmetric(horizontal: AppSpacing.lg)
                : EdgeInsets.zero,
            child: body,
          ),
        ),
      ),
    );
  }
}
