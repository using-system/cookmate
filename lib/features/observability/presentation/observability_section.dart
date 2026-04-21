import 'package:flutter/material.dart';

import 'crashlytics_toggle_tile.dart';

class ObservabilitySection extends StatelessWidget {
  const ObservabilitySection({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CrashlyticsToggleTile(),
        Divider(height: 1),
      ],
    );
  }
}
