// lib/features/notes/presentation/pages/category_manager_page.dart (New)
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/database/database_helper.dart';
import '../../data/models/category_model.dart';

class CategoryManagerPage extends StatefulWidget {
  final List<CategoryModel> categories;

  const CategoryManagerPage({super.key, required this.categories});

  @override
  State<CategoryManagerPage> createState() => _CategoryManagerPageState();
}

class _CategoryManagerPageState extends State<CategoryManagerPage> {
  late List<CategoryModel> _categories;
  final List<Color> _availableColors = [
    const Color(0xFF6366F1),
    const Color(0xFFF59E0B),
    const Color(0xFF10B981),
    const Color(0xFFEF4444),
    const Color(0xFF8B5CF6),
    const Color(0xFFEC4899),
    const Color(0xFF06B6D4),
    const Color(0xFF84CC16),
  ];

  @override
  void initState() {
    super.initState();
    _categories = List.from(widget.categories);
  }

  Future<void> _addCategory() async {
    final result = await _showCategoryDialog();
    if (result != null) {
      try {
        final id = await DatabaseHelper.instance.insertCategory(result);
        setState(() {
          _categories.add(result.copyWith(id: id));
        });
        _showSuccessMessage('Category "${result.name}" added');
      } catch (e) {
        _showErrorMessage('Error adding category: $e');
      }
    }
  }

  Future<void> _editCategory(CategoryModel category) async {
    final result = await _showCategoryDialog(category: category);
    if (result != null) {
      try {
        await DatabaseHelper.instance.updateCategory(result);
        setState(() {
          final index = _categories.indexWhere((c) => c.id == category.id);
          if (index != -1) {
            _categories[index] = result;
          }
        });
        _showSuccessMessage('Category updated');
      } catch (e) {
        _showErrorMessage('Error updating category: $e');
      }
    }
  }

  Future<void> _deleteCategory(CategoryModel category) async {
    final confirmed = await _showDeleteConfirmation(category);
    if (confirmed) {
      try {
        await DatabaseHelper.instance.deleteCategory(category.id!);
        setState(() {
          _categories.removeWhere((c) => c.id == category.id);
        });
        _showSuccessMessage('Category "${category.name}" deleted');
      } catch (e) {
        _showErrorMessage('Error deleting category: $e');
      }
    }
  }

  Future<CategoryModel?> _showCategoryDialog({CategoryModel? category}) async {
    final nameController = TextEditingController(text: category?.name ?? '');
    Color selectedColor = category?.colorValue ?? _availableColors.first;

    return await showDialog<CategoryModel>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(category == null ? 'Add Category' : 'Edit Category'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Category Name',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),
              const Text('Choose Color:'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                children: _availableColors.map((color) {
                  final isSelected = color.value == selectedColor.value;
                  return GestureDetector(
                    onTap: () => setState(() => selectedColor = color),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(20),
                        border: isSelected
                            ? Border.all(color: Colors.black, width: 3)
                            : null,
                      ),
                      child: isSelected
                          ? const Icon(Icons.check, color: Colors.white)
                          : null,
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.trim().isNotEmpty) {
                  Navigator.pop(
                    context,
                    CategoryModel(
                      id: category?.id,
                      name: nameController.text.trim(),
                      color: selectedColor.value,
                      createdAt: category?.createdAt ?? DateTime.now(),
                    ),
                  );
                }
              },
              child: Text(category == null ? 'Add' : 'Update'),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> _showDeleteConfirmation(CategoryModel category) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Category'),
        content: Text(
          'Are you sure you want to delete "${category.name}"? All notes in this category will also be deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    ) ?? false;
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Categories'),
        actions: [
          IconButton(
            onPressed: _addCategory,
            icon: const Icon(Icons.add),
            tooltip: 'Add Category',
          ),
        ],
      ),
      body: _categories.isEmpty
          ? const Center(
              child: Text('No categories available'),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: category.colorValue,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(Icons.folder, color: Colors.white),
                    ),
                    title: Text(
                      category.name,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: () => _editCategory(category),
                          icon: const Icon(Icons.edit),
                          tooltip: 'Edit',
                        ),
                        IconButton(
                          onPressed: () => _deleteCategory(category),
                          icon: const Icon(Icons.delete, color: Colors.red),
                          tooltip: 'Delete',
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
