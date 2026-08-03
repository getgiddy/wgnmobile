import 'package:flutter/material.dart';

import '../../core/theme/wgn_colors.dart';
import '../../core/theme/wgn_theme.dart';
import '../../core/widgets/wgn_widgets.dart';

/// Back chevron + big title used on pushed screens.
class DetailHeader extends StatelessWidget {
  const DetailHeader(this.title, {super.key, this.trailing});
  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final c = context.wgn;
    return Row(
      children: [
        const BackChevron(),
        Expanded(child: Text(title, style: WgnText.display(21, color: c.txt))),
        ?trailing,
      ],
    );
  }
}
