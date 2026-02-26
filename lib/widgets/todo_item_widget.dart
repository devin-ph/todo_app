import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/todo_item.dart';

class TodoItemWidget extends StatelessWidget {
  final TodoItem todo;
  final ValueChanged<bool?> onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onTogglePin;

  const TodoItemWidget({
    super.key,
    required this.todo,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
    required this.onTogglePin,
  });

  String _priorityLabel(TodoPriority priority) {
    switch (priority) {
      case TodoPriority.high:
        return 'Cao';
      case TodoPriority.medium:
        return 'Trung bình';
      case TodoPriority.low:
        return 'Thấp';
    }
  }

  Color _priorityColor(ColorScheme scheme, TodoPriority priority) {
    switch (priority) {
      case TodoPriority.high:
        return scheme.error;
      case TodoPriority.medium:
        return scheme.primary;
      case TodoPriority.low:
        return scheme.tertiary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final dueText = todo.dueDate != null ? DateFormat('dd/MM/yyyy · HH:mm').format(todo.dueDate!) : null;
    final priorityColor = _priorityColor(colorScheme, todo.priority);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onEdit,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 4, 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(
                value: todo.isDone,
                onChanged: onToggle,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (todo.isPinned)
                          Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: Icon(Icons.push_pin, size: 16, color: colorScheme.primary),
                          ),
                        Expanded(
                          child: Text(
                            todo.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.titleMedium?.copyWith(
                              decoration: todo.isDone ? TextDecoration.lineThrough : TextDecoration.none,
                              color: todo.isDone ? colorScheme.onSurfaceVariant : colorScheme.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (todo.description.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          todo.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                        ),
                      ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        Chip(
                          avatar: Icon(Icons.flag, size: 16, color: priorityColor),
                          label: Text(_priorityLabel(todo.priority)),
                          visualDensity: VisualDensity.compact,
                        ),
                        if (dueText != null)
                          Chip(
                            avatar: Icon(Icons.event, size: 16, color: colorScheme.primary),
                            label: Text(dueText),
                            visualDensity: VisualDensity.compact,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                tooltip: 'Tùy chọn',
                onSelected: (value) {
                  if (value == 'pin') {
                    onTogglePin();
                  } else if (value == 'edit') {
                    onEdit();
                  } else if (value == 'delete') {
                    onDelete();
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem<String>(
                    value: 'pin',
                    child: Text(todo.isPinned ? 'Bỏ ghim' : 'Ghim'),
                  ),
                  const PopupMenuItem<String>(
                    value: 'edit',
                    child: Text('Sửa'),
                  ),
                  const PopupMenuItem<String>(
                    value: 'delete',
                    child: Text('Xóa'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
