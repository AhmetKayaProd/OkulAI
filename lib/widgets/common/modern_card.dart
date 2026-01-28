import 'package:flutter/material.dart';
import '../../theme/tokens.dart';

class ModernCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final Color? color;
  final BorderSide? border;

  const ModernCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.color,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color ?? AppTokens.surfaceLight,
        borderRadius: BorderRadius.circular(AppTokens.radiusMedium),
        border: Border.all(
          color: border?.color ?? AppTokens.borderLight,
          width: border?.width ?? 1,
        ),
        boxShadow: AppTokens.shadowSubtle,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTokens.radiusMedium),
          child: Padding(
            padding: padding ?? const EdgeInsets.all(AppTokens.spacing16),
            child: child,
          ),
        ),
      ),
    );
  }
}
