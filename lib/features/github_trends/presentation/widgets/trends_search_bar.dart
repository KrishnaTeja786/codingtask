import 'package:flutter/material.dart';

import '../../../../core/utils/debouncer.dart';

class TrendsSearchBar extends StatefulWidget {
  const TrendsSearchBar({
    required this.initial,
    required this.onChanged,
    super.key,
  });

  final String initial;
  final ValueChanged<String> onChanged;

  @override
  State<TrendsSearchBar> createState() => _TrendsSearchBarState();
}

class _TrendsSearchBarState extends State<TrendsSearchBar> {
  late final TextEditingController _ctrl =
      TextEditingController(text: widget.initial);
  final _debouncer = Debouncer();

  @override
  void dispose() {
    _ctrl.dispose();
    _debouncer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _ctrl,
      textInputAction: TextInputAction.search,
      decoration: const InputDecoration(
        hintText: 'Search GitHub (e.g. flutter language:dart)',
        prefixIcon: Icon(Icons.search),
      ),
      onChanged: (v) => _debouncer.run(() => widget.onChanged(v)),
      onSubmitted: widget.onChanged,
    );
  }
}

class TopicChips extends StatelessWidget {
  const TopicChips({required this.onPick, super.key});
  final ValueChanged<String> onPick;

  static const _topics = <(String, String)>[
    ('Flutter', 'flutter language:dart'),
    ('Dart', 'language:dart'),
    ('Android', 'android language:kotlin'),
    ('AI', 'ai topic:llm'),
    ('Mobile', 'mobile'),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemBuilder: (_, i) {
          final (label, query) = _topics[i];
          return ActionChip(
            label: Text(label),
            onPressed: () => onPick(query),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemCount: _topics.length,
      ),
    );
  }
}
