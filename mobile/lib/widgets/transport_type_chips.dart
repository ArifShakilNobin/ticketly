import 'package:flutter/material.dart';

import '../models/enums.dart';
import '../utils/ui.dart';
import 'selectable_chip.dart';

/// Transport mode picker (`TRAIN`, `BUS`, `LAUNCH`, `FLIGHT`, `ALL`).
class TransportTypeChips extends StatelessWidget {
  const TransportTypeChips({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final TransportType selected;
  final ValueChanged<TransportType> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: <Widget>[
        for (final type in TransportType.values)
          SelectableChip(
            label: type.labelBn,
            icon: transportTypeIcon(type),
            selected: type == selected,
            onTap: () => onChanged(type),
          ),
      ],
    );
  }
}
