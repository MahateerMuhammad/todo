// lib/features/notes/presentation/widgets/category_selector_widget.dart
import 'package:flutter/material.dart';
import 'package:notes_app/features/notes/data/models/category_model.dart';

class CategorySelectorWidget extends StatelessWidget {
  final List<CategoryModel> categories;
  final CategoryModel selectedCategory;
  final Function(CategoryModel) onCategorySelected;

  const CategorySelectorWidget({
    super.key,
    required this.categories,
    required this.selectedCategory,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Row(
        children: categories.map((category) {
          final isSelected = category.id == selectedCategory.id;
          
          return Expanded(
            child: GestureDetector(
              onTap: () => onCategorySelected(category),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? category.colorValue : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.white : category.colorValue,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      category.name,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: isSelected ? Colors.white : category.colorValue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

