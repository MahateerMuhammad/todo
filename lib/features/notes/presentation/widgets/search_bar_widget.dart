// lib/features/notes/presentation/widgets/search_bar_widget.dart
import 'package:flutter/material.dart';

class SearchBarWidget extends StatefulWidget {
  final Function(String) onChanged;
  final AnimationController animationController;

  const SearchBarWidget({
    super.key,
    required this.onChanged,
    required this.animationController,
  });

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
  final TextEditingController _controller = TextEditingController();
  bool _isExpanded = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (!_isExpanded) {
        _controller.clear();
        widget.onChanged('');
      }
    });
    
    if (_isExpanded) {
      widget.animationController.forward();
    } else {
      widget.animationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOutCubic,
      height: 56,
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isExpanded
              ? theme.colorScheme.primary
              : Colors.grey.shade200,
          width: _isExpanded ? 2 : 1,
        ),
        boxShadow: [
          if (_isExpanded)
            BoxShadow(
              color: theme.colorScheme.primary.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
        ],
      ),
      child: Row(
        children: [
          const SizedBox(width: 16),
          Icon(
            Icons.search,
            color: _isExpanded
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _isExpanded
                ? TextField(
                    controller: _controller,
                    autofocus: true,
                    decoration: const InputDecoration(
                      hintText: 'Search notes...',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                    onChanged: widget.onChanged,
                  )
                : GestureDetector(
                    onTap: _toggleSearch,
                    child: Container(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Search notes...',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
          ),
          if (_isExpanded)
            IconButton(
              onPressed: _toggleSearch,
              icon: const Icon(Icons.close),
            )
          else
            const SizedBox(width: 16),
        ],
      ),
    );
  }
}
