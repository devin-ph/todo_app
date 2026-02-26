import 'dart:convert';

enum TodoPriority {
  low,
  medium,
  high,
}

class TodoItem {
  final String id;
  final String title;
  final String description;
  final DateTime? dueDate;
  final bool isDone;
  final bool isPinned;
  final TodoPriority priority;
  final DateTime createdAt;
  final DateTime? completedAt;

  TodoItem({
    required this.id,
    required this.title,
    this.description = '',
    this.dueDate,
    this.isDone = false,
    this.isPinned = false,
    this.priority = TodoPriority.medium,
    DateTime? createdAt,
    this.completedAt,
  }) : createdAt = createdAt ?? DateTime.now();

  TodoItem copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? dueDate,
    bool? isDone,
    bool? isPinned,
    TodoPriority? priority,
    DateTime? createdAt,
    DateTime? completedAt,
    bool clearDueDate = false,
    bool clearCompletedAt = false,
  }) {
    return TodoItem(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: clearDueDate ? null : (dueDate ?? this.dueDate),
      isDone: isDone ?? this.isDone,
      isPinned: isPinned ?? this.isPinned,
      priority: priority ?? this.priority,
      createdAt: createdAt ?? this.createdAt,
      completedAt: clearCompletedAt ? null : (completedAt ?? this.completedAt),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'dueDate': dueDate?.toIso8601String(),
      'isDone': isDone,
      'isPinned': isPinned,
      'priority': priority.name,
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
    };
  }

  factory TodoItem.fromMap(Map<String, dynamic> map) {
    final rawPriority = map['priority'] as String?;

    return TodoItem(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String? ?? '',
      dueDate: map['dueDate'] != null ? DateTime.parse(map['dueDate'] as String) : null,
      isDone: map['isDone'] as bool? ?? false,
      isPinned: map['isPinned'] as bool? ?? false,
      priority: TodoPriority.values.firstWhere(
        (item) => item.name == rawPriority,
        orElse: () => TodoPriority.medium,
      ),
      createdAt: DateTime.parse(map['createdAt'] as String),
      completedAt: map['completedAt'] != null ? DateTime.parse(map['completedAt'] as String) : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory TodoItem.fromJson(String source) => TodoItem.fromMap(json.decode(source));
}
