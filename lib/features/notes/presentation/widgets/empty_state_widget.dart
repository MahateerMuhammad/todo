import 'package:flutter/material.dart';
import 'package:notes_app/features/notes/data/models/category_model.dart';

class EmptyStateWidget extends StatefulWidget {
  final String searchQuery;
  final CategoryModel? selectedCategory;

  const EmptyStateWidget({
    super.key,
    required this.searchQuery,
    this.selectedCategory,
  });

  @override
  State<EmptyStateWidget> createState() => _EmptyStateWidgetState();
}

class _EmptyStateWidgetState extends State<EmptyStateWidget>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.8, curve: Curves.easeOut),
    ));
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSearching = widget.searchQuery.isNotEmpty;
    final hasCategory = widget.selectedCategory != null;

    String title;
    String subtitle;
    IconData icon;

    if (isSearching) {
      title = 'No results found';
      subtitle = 'Try adjusting your search terms';
      icon = Icons.search_off;
    } else if (hasCategory) {
      title = 'No notes in ${widget.selectedCategory!.name}';
      subtitle = 'Create your first note in this category';
      icon = Icons.folder_open;
    } else {
      title = 'No notes yet';
      subtitle = 'Tap the + button to create your first note';
      icon = Icons.note_add;
    }

    return Center(
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Padding(
            padding: const EdgeInsets.all(48.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(60),
                  ),
                  child: Icon(
                    icon,
                    size: 48,
                    color: theme.colorScheme.primary.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  title,
                  style: theme.textTheme.headlineLarge?.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  subtitle,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
