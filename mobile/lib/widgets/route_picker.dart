import 'package:flutter/material.dart';

import '../config/app_theme.dart';
import '../config/cities.dart';

/// A single city input backed by an autocomplete over [bangladeshiCities].
///
/// The controller and focus node belong to the parent so screens can fill the
/// field programmatically (after a voice query, for example).
class CityField extends StatelessWidget {
  const CityField({
    super.key,
    required this.label,
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    this.hintText,
    this.icon,
  });

  final String label;
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final String? hintText;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (icon != null) ...<Widget>[
              Icon(icon, size: 15, color: const Color(0xFF6B726B)),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: theme.textTheme.labelLarge?.copyWith(
                color: const Color(0xFF4A524A),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Autocomplete<City>(
          focusNode: focusNode,
          textEditingController: controller,
          displayStringForOption: (city) => city.bn,
          optionsBuilder: (value) => citySuggestions(value.text),
          optionsViewBuilder: (context, onSelected, options) =>
              _CityOptionsView(options: options, onSelected: onSelected),
          onSelected: (city) => onChanged(city.bn),
          fieldViewBuilder:
              (context, fieldController, fieldFocusNode, onFieldSubmitted) {
            return TextField(
              controller: fieldController,
              focusNode: fieldFocusNode,
              onChanged: onChanged,
              onSubmitted: (_) => onFieldSubmitted(),
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                hintText: hintText ?? 'শহরের নাম লিখুন',
              ),
            );
          },
        ),
      ],
    );
  }
}

/// Both ends of the journey: origin and destination plus a swap button.
class RoutePicker extends StatelessWidget {
  const RoutePicker({
    super.key,
    required this.sourceController,
    required this.sourceFocusNode,
    required this.destinationController,
    required this.destinationFocusNode,
    required this.onSourceChanged,
    required this.onDestinationChanged,
    required this.onSwap,
  });

  final TextEditingController sourceController;
  final FocusNode sourceFocusNode;
  final TextEditingController destinationController;
  final FocusNode destinationFocusNode;
  final ValueChanged<String> onSourceChanged;
  final ValueChanged<String> onDestinationChanged;
  final VoidCallback onSwap;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: CityField(
            label: 'যাত্রার শুরু',
            icon: Icons.trip_origin_outlined,
            controller: sourceController,
            focusNode: sourceFocusNode,
            onChanged: onSourceChanged,
          ),
        ),
        const SizedBox(width: 8),
        Padding(
          padding: const EdgeInsets.only(top: 26),
          child: IconButton.filledTonal(
            onPressed: onSwap,
            tooltip: 'দিক বদলান',
            icon: const Icon(Icons.swap_horiz),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: CityField(
            label: 'গন্তব্য',
            icon: Icons.place_outlined,
            controller: destinationController,
            focusNode: destinationFocusNode,
            onChanged: onDestinationChanged,
          ),
        ),
      ],
    );
  }
}

/// The suggestion list rendered under a focused [CityField].
class _CityOptionsView extends StatelessWidget {
  const _CityOptionsView({
    required this.options,
    required this.onSelected,
  });

  final Iterable<City> options;
  final AutocompleteOnSelected<City> onSelected;

  @override
  Widget build(BuildContext context) {
    final list = options.toList();
    return Align(
      alignment: AlignmentDirectional.topStart,
      child: Material(
        elevation: 5,
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 250),
          child: ListView.builder(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            itemCount: list.length,
            itemBuilder: (context, index) {
              final city = list[index];
              return InkWell(
                onTap: () => onSelected(city),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Row(
                    children: <Widget>[
                      const Icon(
                        Icons.location_on_outlined,
                        size: 17,
                        color: kBrandGreen,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          city.label,
                          style: const TextStyle(fontSize: 14.5),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
