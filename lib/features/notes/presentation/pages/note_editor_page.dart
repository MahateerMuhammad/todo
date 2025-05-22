import 'package:flutter/material.dart';
import '../../../../../../../core/database/database_helper.dart';
import 'package:notes_app/features/notes/data/models/note_model.dart';
import 'package:notes_app/features/notes/data/models/category_model.dart';
import 'package:notes_app/features/notes/presentation/widgets/category_selector_widget.dart';

class NoteEditorPage extends StatefulWidget {
  final NoteModel? note;
  final List<CategoryModel> categories;
  final int? initialCategoryId;

  const NoteEditorPage({
    super.key,
    this.note,
    required this.categories,
    this.initialCategoryId,
  });

  @override
  State<NoteEditorPage> createState() => _NoteEditorPageState();
}

class _NoteEditorPageState extends State<NoteEditorPage>
    with TickerProviderStateMixin {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late CategoryModel _selectedCategory;
  late FocusNode _titleFocusNode;
  late FocusNode _contentFocusNode;
  bool _isEditing = false;
  bool _hasChanges = false;
  bool _isTitleFocused = false;
  bool _isContentFocused = false;

  late AnimationController _saveAnimationController;
  late Animation<double> _saveAnimation;

  @override
  void initState() {
    super.initState();

    _saveAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _saveAnimation = Tween<double>(begin: 1.0, end: 0.8).animate(
      CurvedAnimation(
        parent: _saveAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _isEditing = widget.note != null;
    _titleController = TextEditingController(text: widget.note?.title ?? '');
    _contentController = TextEditingController(
      text: widget.note?.content ?? '',
    );

    _titleFocusNode = FocusNode();
    _contentFocusNode = FocusNode();

    // Set initial category
    if (widget.note != null) {
      _selectedCategory = widget.categories.firstWhere(
        (c) => c.id == widget.note!.categoryId,
        orElse: () => widget.categories.first,
      );
    } else if (widget.initialCategoryId != null) {
      _selectedCategory = widget.categories.firstWhere(
        (c) => c.id == widget.initialCategoryId,
        orElse: () => widget.categories.first,
      );
    } else {
      _selectedCategory = widget.categories.first;
    }

    // Listen for changes and focus
    _titleController.addListener(_onTextChanged);
    _contentController.addListener(_onTextChanged);
    _titleFocusNode.addListener(_onTitleFocusChanged);
    _contentFocusNode.addListener(_onContentFocusChanged);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _titleFocusNode.dispose();
    _contentFocusNode.dispose();
    _saveAnimationController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final hasTitle = _titleController.text.isNotEmpty;
    final hasContent = _contentController.text.isNotEmpty;
    final hasChanges = hasTitle || hasContent;

    if (_hasChanges != hasChanges) {
      setState(() => _hasChanges = hasChanges);
    }
  }

  void _onTitleFocusChanged() {
    setState(() => _isTitleFocused = _titleFocusNode.hasFocus);
  }

  void _onContentFocusChanged() {
    setState(() => _isContentFocused = _contentFocusNode.hasFocus);
  }

  Future<bool> _onWillPop() async {
    if (!_hasChanges) return true;

    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Discard changes?'),
            content: const Text(
              'You have unsaved changes. Are you sure you want to go back?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Discard'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _saveNote() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a title')),
      );
      return;
    }

    _saveAnimationController.forward().then((_) {
      _saveAnimationController.reverse();
    });

    try {
      final now = DateTime.now();
      final noteData = NoteModel(
        id: widget.note?.id,
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        categoryId: _selectedCategory.id!,
        isPinned: widget.note?.isPinned ?? false,
        createdAt: widget.note?.createdAt ?? now,
        updatedAt: now,
      );

      if (_isEditing) {
        await DatabaseHelper.instance.updateNote(noteData);
      } else {
        await DatabaseHelper.instance.insertNote(noteData);
      }

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving note: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: colorScheme.surface,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          leading: IconButton(
            onPressed: () async {
              if (await _onWillPop()) {
                Navigator.of(context).pop();
              }
            },
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: colorScheme.onSurface,
            ),
          ),
          title: Text(
            _isEditing ? 'Edit Note' : 'New Note',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          actions: [
            ScaleTransition(
              scale: _saveAnimation,
              child: Container(
                margin: const EdgeInsets.only(right: 16),
                child: IconButton(
                  onPressed: _hasChanges ? _saveNote : null,
                  style: IconButton.styleFrom(
                    backgroundColor: _hasChanges 
                        ? colorScheme.primary 
                        : colorScheme.surfaceVariant,
                    foregroundColor: _hasChanges 
                        ? colorScheme.onPrimary 
                        : colorScheme.onSurfaceVariant,
                    padding: const EdgeInsets.all(12),
                    minimumSize: const Size(48, 48),
                  ),
                  icon: const Icon(Icons.check_rounded, size: 20),
                ),
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            // Category Selector
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: CategorySelectorWidget(
                categories: widget.categories,
                selectedCategory: _selectedCategory,
                onCategorySelected: (category) {
                  setState(() => _selectedCategory = category);
                },
              ),
            ),

            // Content Area
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Title Field
                    Container(
                      margin: const EdgeInsets.only(bottom: 4),
                      child: TextField(
                        controller: _titleController,
                        focusNode: _titleFocusNode,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: colorScheme.onSurface,
                          height: 1.1,
                          letterSpacing: -0.5,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Untitled',
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 12,
                          ),
                          hintStyle: theme.textTheme.headlineMedium?.copyWith(
                            color: colorScheme.onSurface.withOpacity(0.25),
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                        textCapitalization: TextCapitalization.sentences,
                        maxLines: 3,
                        textInputAction: TextInputAction.next,
                        onSubmitted: (_) => _contentFocusNode.requestFocus(),
                        cursorColor: colorScheme.primary,
                        cursorWidth: 2.5,
                        cursorHeight: 32,
                      ),
                    ),

                    // Subtle divider
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      height: 1,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            (_isTitleFocused || _isContentFocused)
                                ? colorScheme.primary.withOpacity(0.3)
                                : colorScheme.outline.withOpacity(0.1),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Content Field
                    Expanded(
                      child: TextField(
                        controller: _contentController,
                        focusNode: _contentFocusNode,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          height: 1.7,
                          color: colorScheme.onSurface,
                          fontSize: 17,
                          fontWeight: FontWeight.w400,
                          letterSpacing: 0.1,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Write something beautiful...',
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          isDense: true,
                          contentPadding: const EdgeInsets.all(4),
                          hintStyle: theme.textTheme.bodyLarge?.copyWith(
                            color: colorScheme.onSurface.withOpacity(0.3),
                            fontSize: 17,
                            fontStyle: FontStyle.italic,
                            fontWeight: FontWeight.w300,
                          ),
                        ),
                        maxLines: null,
                        expands: true,
                        textAlignVertical: TextAlignVertical.top,
                        textCapitalization: TextCapitalization.sentences,
                        keyboardType: TextInputType.multiline,
                        cursorColor: colorScheme.primary,
                        cursorWidth: 2,
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}