import 'package:flutter/material.dart';

class CategoryModel {
  final int? id;
  final String name;
  final int color;
  final DateTime createdAt;

  const CategoryModel({
    this.id,
    required this.name,
    required this.color,
    required this.createdAt,
  });

  Color get colorValue => Color(color);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'color': color,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory CategoryModel.fromMap(Map<String, dynamic> map) {
    return CategoryModel(
      id: map['id']?.toInt(),
      name: map['name'] ?? '',
      color: map['color']?.toInt() ?? 0xFF6366F1,
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  CategoryModel copyWith({
    int? id,
    String? name,
    int? color,
    DateTime? createdAt,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
