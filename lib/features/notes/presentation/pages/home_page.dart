import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:notes_app/core/database/database_helper.dart';
import 'package:notes_app/features/notes/data/models/note_model.dart';
import 'package:notes_app/features/notes/data/models/category_model.dart';
import 'package:notes_app/features/notes/presentation/widgets/note_card.dart';
import 'package:notes_app/features/notes/presentation/widgets/category_chip.dart';
import 'package:notes_app/features/notes/presentation/widgets/search_bar_widget.dart';
import 'package:notes_app/features/notes/presentation/widgets/empty_state_widget.dart';
import 'package:notes_app/features/notes/presentation/widgets/action_button_widget.dart';
import 'note_editor_page.dart';
import 'category_manager_page.dart';
import 'package:notes_app/core/theme/theme_manager.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  List<NoteModel> _notes = [];
  List<CategoryModel> _categories = [];
  CategoryModel? _selectedCategory;
  String _searchQuery = '';
  bool _isLoading = true;
  
  late AnimationController _fabAnimationController;
  late AnimationController _searchAnimationController;
  
  @override
  void initState() {
    super.initState();
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _searchAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _loadData();
  }

  @override
  void dispose() {
    _fabAnimationController.dispose();
    _searchAnimationController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      final categories = await DatabaseHelper.instance.getCategories();
      final notes = await DatabaseHelper.instance.getNotes(
        categoryId: _selectedCategory?.id,
        searchQuery: _searchQuery.isEmpty ? null : _searchQuery,
      );
      
      setState(() {
        _categories = categories;
        _notes = notes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    }
  }

  void _onCategorySelected(CategoryModel? category) {
    setState(() => _selectedCategory = category);
    _loadData();
  }

  void _onSearchChanged(String query) {
    setState(() => _searchQuery = query);
    _loadData();
  }

  void _navigateToEditor({NoteModel? note}) async {
    final result = await Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => NoteEditorPage(
          note: note,
          categories: _categories,
          initialCategoryId: _selectedCategory?.id,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(0.0, 1.0);
          const end = Offset.zero;
          const curve = Curves.easeInOutCubic;
          
          var tween = Tween(begin: begin, end: end).chain(
            CurveTween(curve: curve),
          );
          
          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
    
    if (result == true) {
      _loadData();
    }
  }

  void _navigateToCategoryManager() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CategoryManagerPage(categories: _categories),
      ),
    );
    
    if (result == true) {
      _loadData();
    }
  }

  Future<void> _deleteNote(NoteModel note) async {
    try {
      await DatabaseHelper.instance.deleteNote(note.id!);
      _loadData();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Note "${note.title}" deleted'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting note: $e')),
        );
      }
    }
  }

  Future<void> _togglePinNote(NoteModel note) async {
    try {
      await DatabaseHelper.instance.togglePinNote(note.id!);
      _loadData();
      
      // Add haptic feedback
      HapticFeedback.lightImpact();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating note: $e')),
        );
      }
    }
  }

  Future<void> _duplicateNote(NoteModel note) async {
    try {
      await DatabaseHelper.instance.duplicateNote(note.id!);
      _loadData();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Note "${note.title}" duplicated'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error duplicating note: $e')),
        );
      }
    }
  }

  void _showOptionsMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: const Icon(Icons.category),
              title: const Text('Manage Categories'),
              onTap: () {
                Navigator.pop(context);
                _navigateToCategoryManager();
              },
            ),
            ListTile(
              leading: Consumer<ThemeManager>(
                builder: (context, themeManager, child) {
                  return Icon(themeManager.themeIcon);
                },
              ),
              title: const Text('Toggle Theme'),
              onTap: () {
                Navigator.pop(context);
                context.read<ThemeManager>().toggleTheme();
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Notes',
                        style: Theme.of(context).textTheme.displayLarge,
                      ),
                      const Spacer(),
                      Consumer<ThemeManager>(
                        builder: (context, themeManager, child) {
                          return IconButton(
                            onPressed: themeManager.toggleTheme,
                            icon: Icon(themeManager.themeIcon),
                            iconSize: 28,
                            tooltip: 'Toggle theme',
                          );
                        },
                      ),
                      IconButton(
                        onPressed: _showOptionsMenu,
                        icon: const Icon(Icons.more_vert),
                        iconSize: 28,
                        tooltip: 'More options',
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _notes.length == 1 ? '1 note' : '${_notes.length} notes',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            
            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: SearchBarWidget(
                onChanged: _onSearchChanged,
                animationController: _searchAnimationController,
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Category Chips
            if (_categories.isNotEmpty)
              SizedBox(
                height: 48,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: _categories.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: CategoryChip(
                          label: 'All',
                          isSelected: _selectedCategory == null,
                          onTap: () => _onCategorySelected(null),
                        ),
                      );
                    }
                    
                    final category = _categories[index - 1];
                    return Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: CategoryChip(
                        label: category.name,
                        color: category.colorValue,
                        isSelected: _selectedCategory?.id == category.id,
                        onTap: () => _onCategorySelected(category),
                      ),
                    );
                  },
                ),
              ),
            
            const SizedBox(height: 24),
            
            // Notes List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _notes.isEmpty
                      ? EmptyStateWidget(
                          searchQuery: _searchQuery,
                          selectedCategory: _selectedCategory,
                        )
                      : AnimationLimiter(
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            itemCount: _notes.length,
                            itemBuilder: (context, index) {
                              final note = _notes[index];
                              final category = _categories.firstWhere(
                                (c) => c.id == note.categoryId,
                                orElse: () => _categories.first,
                              );
                              
                              return AnimationConfiguration.staggeredList(
                                position: index,
                                duration: const Duration(milliseconds: 375),
                                child: SlideAnimation(
                                  verticalOffset: 50.0,
                                  child: FadeInAnimation(
                                    child: Padding(
                                      padding: const EdgeInsets.only(bottom: 16),
                                      child: NoteCard(
                                        note: note,
                                        category: category,
                                        onTap: () => _navigateToEditor(note: note),
                                        onDelete: () => _deleteNote(note),
                                        onTogglePin: () => _togglePinNote(note),
                                        onDuplicate: () => _duplicateNote(note),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButtonWidget(
        onPressed: () => _navigateToEditor(),
        animationController: _fabAnimationController,
      ),
    );
  }
}