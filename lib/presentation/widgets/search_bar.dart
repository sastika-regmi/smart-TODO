import 'package:flutter/material.dart';

/// Search field for the task list.
///
/// The clear button's visibility is driven by the controller itself, so typing
/// rebuilds only this field — not the surrounding list.
class TaskSearchBar extends StatelessWidget {
  const TaskSearchBar({
    super.key,
    required this.controller,
    required this.onChanged,
    this.hintText = 'Search tasks',
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final String hintText;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        return TextField(
          controller: controller,
          onChanged: onChanged,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: hintText,
            prefixIcon: const Icon(Icons.search),
            suffixIcon: value.text.isEmpty
                ? null
                : IconButton(
                    icon: const Icon(Icons.clear),
                    tooltip: 'Clear search',
                    onPressed: () {
                      controller.clear();
                      onChanged('');
                    },
                  ),
          ),
        );
      },
    );
  }
}
