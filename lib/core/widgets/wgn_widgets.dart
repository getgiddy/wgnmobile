import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/wgn_colors.dart';
import '../theme/wgn_theme.dart';

/// 34px round bordered icon button used across headers.
class CircleIconButton extends StatelessWidget {
  const CircleIconButton({
    super.key,
    this.icon,
    this.glyph,
    this.onTap,
    this.color,
    this.size = 34,
    this.fontSize = 13,
    this.iconSize,
  }) : assert(icon != null || glyph != null);

  final IconData? icon;
  final String? glyph;
  final VoidCallback? onTap;
  final Color? color;
  final double size;
  final double fontSize;
  final double? iconSize;

  @override
  Widget build(BuildContext context) {
    final c = context.wgn;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: c.line2),
        ),
        alignment: Alignment.center,
        child: icon != null
            ? Icon(
                icon,
                size: iconSize ?? (fontSize + 4),
                color: color ?? c.txt2,
              )
            : Text(
                glyph!,
                style: WgnText.ui(
                  fontSize,
                  weight: FontWeight.w600,
                  color: color ?? c.txt2,
                ),
              ),
      ),
    );
  }
}

/// Gold monospace eyebrow label, e.g. "TODAY · DAILY FEAST".
class GoldEyebrow extends StatelessWidget {
  const GoldEyebrow(this.text, {super.key, this.size = 10, this.color});
  final String text;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = context.wgn;
    return Text(
      text,
      style: WgnText.mono(
        size,
        color: color ?? c.gold,
        letterSpacing: size * 0.16,
      ),
    );
  }
}

/// Section header: serif title + muted action link.
class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.action, this.onAction});
  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final c = context.wgn;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Expanded(child: Text(title, style: WgnText.display(19, color: c.txt))),
        if (action != null)
          GestureDetector(
            onTap: onAction,
            child: Text(
              action!,
              style: WgnText.ui(11.5, weight: FontWeight.w600, color: c.txt3),
            ),
          ),
      ],
    );
  }
}

/// Serif screen title for a top-level tab (Sermons, Daily Feast, Live, More).
class ScreenTitle extends StatelessWidget {
  const ScreenTitle(this.title, {super.key, this.size = 24});
  final String title;
  final double size;

  @override
  Widget build(BuildContext context) =>
      Text(title, style: WgnText.display(size, color: context.wgn.txt));
}

/// Borderless back chevron used at the top of pushed screens.
class BackChevron extends StatelessWidget {
  const BackChevron({super.key, this.onTap});
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.wgn;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap ?? () => context.canPop() ? context.pop() : context.go('/'),
      // Design hangs the glyph back into the gutter, so it sits flush left
      // inside a 34px tap target rather than centred.
      child: SizedBox(
        width: 34,
        height: 34,
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            '‹',
            style: WgnText.ui(22, weight: FontWeight.w400, color: c.txt2),
          ),
        ),
      ),
    );
  }
}

/// Selectable pill chip (giving purposes, prayer tags).
class PillChip extends StatelessWidget {
  const PillChip({
    super.key,
    required this.label,
    required this.selected,
    this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.wgn;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: selected ? c.accent : c.line2),
          color: selected ? c.accentSoft : Colors.transparent,
        ),
        child: Text(
          label,
          style: WgnText.ui(
            11.5,
            weight: FontWeight.w600,
            color: selected ? c.gold : c.txt2,
          ),
        ),
      ),
    );
  }
}

/// Segmented pill tabs (Audio/Video/Series, Latest/Saved).
class SegmentedTabs extends StatelessWidget {
  const SegmentedTabs({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onChanged,
  });

  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.wgn;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: c.surf,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(i),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: i == selectedIndex ? c.accent : Colors.transparent,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    labels[i],
                    style: WgnText.ui(
                      11.5,
                      weight: FontWeight.w700,
                      color: i == selectedIndex ? c.onAccent : c.txt2,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Gold-knob toggle matching the design's switches.
class WgnToggle extends StatelessWidget {
  const WgnToggle({
    super.key,
    required this.value,
    this.onChanged,
    this.width = 48,
  });
  final bool value;
  final ValueChanged<bool>? onChanged;
  final double width;

  @override
  Widget build(BuildContext context) {
    final c = context.wgn;
    final knob = width - 28;
    return GestureDetector(
      onTap: onChanged == null ? null : () => onChanged!(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: width,
        height: knob + 6,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: c.accentSoft,
          border: Border.all(color: c.line2),
        ),
        alignment: value ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          width: knob,
          height: knob,
          decoration: BoxDecoration(shape: BoxShape.circle, color: c.accent),
        ),
      ),
    );
  }
}

/// Centered muted empty-state text.
class EmptyState extends StatelessWidget {
  const EmptyState(this.lines, {super.key});
  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    final c = context.wgn;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 44, horizontal: 20),
      child: Center(
        child: Text(
          lines.join('\n'),
          textAlign: TextAlign.center,
          style: WgnText.ui(12.5, color: c.txt3, height: 1.6),
        ),
      ),
    );
  }
}

/// Full-width gold action button.
class WgnButton extends StatelessWidget {
  const WgnButton({
    super.key,
    required this.label,
    this.onTap,
    this.padding = const EdgeInsets.symmetric(vertical: 16),
    this.fontSize = 13.5,
  });

  final String label;
  final VoidCallback? onTap;
  final EdgeInsets padding;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final c = context.wgn;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: padding,
        decoration: BoxDecoration(
          color: c.accent,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: WgnText.ui(
            fontSize,
            weight: FontWeight.w700,
            color: c.onAccent,
          ),
        ),
      ),
    );
  }
}

/// Card container with the standard surface + hairline border.
class WgnCard extends StatelessWidget {
  const WgnCard({
    super.key,
    required this.child,
    this.radius = 18,
    this.padding,
    this.color,
    this.borderColor,
    this.onTap,
    this.clip = false,
  });

  final Widget child;
  final double radius;
  final EdgeInsets? padding;
  final Color? color;
  final Color? borderColor;
  final VoidCallback? onTap;
  final bool clip;

  @override
  Widget build(BuildContext context) {
    final c = context.wgn;
    final card = Container(
      padding: padding,
      clipBehavior: clip ? Clip.antiAlias : Clip.none,
      decoration: BoxDecoration(
        color: color ?? c.surf,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColor ?? c.line),
      ),
      child: child,
    );
    if (onTap == null) return card;
    return GestureDetector(onTap: onTap, child: card);
  }
}
