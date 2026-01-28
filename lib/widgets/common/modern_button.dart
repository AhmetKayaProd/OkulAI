import 'package:flutter/material.dart';
import '../../theme/tokens.dart';

enum ModernButtonStyle { primary, secondary, outline, ghost }

class ModernButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final ModernButtonStyle style;
  final bool isLoading;
  final Color? color;

  const ModernButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.style = ModernButtonStyle.primary,
    this.isLoading = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isEnabled = onPressed != null && !isLoading;
    
    switch (style) {
      case ModernButtonStyle.primary:
        return ElevatedButton(
          onPressed: isEnabled ? onPressed : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: color ?? AppTokens.primaryLight,
          ),
          child: _buildContent(),
        );
      case ModernButtonStyle.secondary:
        return ElevatedButton(
          onPressed: isEnabled ? onPressed : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: color ?? AppTokens.primaryLightSoft,
            foregroundColor: AppTokens.primaryLight,
          ),
          child: _buildContent(),
        );
      case ModernButtonStyle.outline:
        return OutlinedButton(
          onPressed: isEnabled ? onPressed : null,
          style: OutlinedButton.styleFrom(
            foregroundColor: color ?? AppTokens.primaryLight,
            side: BorderSide(color: color ?? AppTokens.borderLight, width: 1.5),
          ),
          child: _buildContent(),
        );
      case ModernButtonStyle.ghost:
        return TextButton(
          onPressed: isEnabled ? onPressed : null,
          style: TextButton.styleFrom(
            foregroundColor: color ?? AppTokens.textSecondaryLight,
            padding: const EdgeInsets.symmetric(horizontal: AppTokens.spacing16),
          ),
          child: _buildContent(),
        );
    }
  }

  Widget _buildContent() {
    if (isLoading) {
      return const SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 20),
          const SizedBox(width: AppTokens.spacing8),
        ],
        Text(label),
      ],
    );
  }
}
