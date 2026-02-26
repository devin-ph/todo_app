import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/todo_item.dart';
import '../widgets/todo_item_widget.dart';

enum TaskFilter { all, active, done }

enum TaskSort { smart, dueDate, createdAt, priority }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const String _storageKey = 'todos_v2';

  final List<TodoItem> _todos = [];
  final TextEditingController _searchController = TextEditingController();

  TaskFilter _filter = TaskFilter.all;
  TaskSort _sort = TaskSort.smart;
  TodoPriority? _priorityFilter;
  String _searchQuery = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadTodos();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadTodos() async {
    final prefs = await SharedPreferences.getInstance();
    final v2Raw = prefs.getStringList(_storageKey);
    final legacyRaw = prefs.getStringList('todos_v1') ?? [];
    final source = v2Raw ?? legacyRaw;

    final parsed = <TodoItem>[];
    for (final item in source) {
      try {
        parsed.add(TodoItem.fromJson(item));
      } catch (_) {}
    }

    setState(() {
      _todos
        ..clear()
        ..addAll(parsed);
      _loading = false;
    });

    if (v2Raw == null && source.isNotEmpty) {
      await _saveTodos();
    }
  }

  Future<void> _saveTodos() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_storageKey, _todos.map((e) => e.toJson()).toList());
  }

  List<TodoItem> get _visibleTodos {
    final query = _searchQuery.trim().toLowerCase();
    final now = DateTime.now();

    final filtered = _todos.where((todo) {
      final byFilter = switch (_filter) {
        TaskFilter.all => true,
        TaskFilter.active => !todo.isDone,
        TaskFilter.done => todo.isDone,
      };

      final byPriority = _priorityFilter == null || todo.priority == _priorityFilter;
      final bySearch = query.isEmpty ||
          todo.title.toLowerCase().contains(query) ||
          todo.description.toLowerCase().contains(query);

      return byFilter && byPriority && bySearch;
    }).toList();

    int priorityScore(TodoPriority p) {
      switch (p) {
        case TodoPriority.high:
          return 0;
        case TodoPriority.medium:
          return 1;
        case TodoPriority.low:
          return 2;
      }
    }

    filtered.sort((a, b) {
      if (a.isPinned != b.isPinned) {
        return a.isPinned ? -1 : 1;
      }

      switch (_sort) {
        case TaskSort.smart:
          if (a.isDone != b.isDone) {
            return a.isDone ? 1 : -1;
          }

          final aOverdue = a.dueDate != null && !a.isDone && a.dueDate!.isBefore(now);
          final bOverdue = b.dueDate != null && !b.isDone && b.dueDate!.isBefore(now);
          if (aOverdue != bOverdue) {
            return aOverdue ? -1 : 1;
          }

          final p = priorityScore(a.priority).compareTo(priorityScore(b.priority));
          if (p != 0) return p;

          if (a.dueDate != null && b.dueDate != null) {
            return a.dueDate!.compareTo(b.dueDate!);
          }
          if (a.dueDate != null) return -1;
          if (b.dueDate != null) return 1;

          return b.createdAt.compareTo(a.createdAt);
        case TaskSort.dueDate:
          if (a.dueDate != null && b.dueDate != null) {
            return a.dueDate!.compareTo(b.dueDate!);
          }
          if (a.dueDate != null) return -1;
          if (b.dueDate != null) return 1;
          return b.createdAt.compareTo(a.createdAt);
        case TaskSort.createdAt:
          return b.createdAt.compareTo(a.createdAt);
        case TaskSort.priority:
          final p = priorityScore(a.priority).compareTo(priorityScore(b.priority));
          if (p != 0) return p;
          return b.createdAt.compareTo(a.createdAt);
      }
    });

    return filtered;
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _upsertTodo(TodoItem todo) async {
    final index = _todos.indexWhere((item) => item.id == todo.id);

    setState(() {
      if (index >= 0) {
        _todos[index] = todo;
      } else {
        _todos.insert(0, todo);
      }
    });

    await _saveTodos();
  }

  Future<void> _toggleDone(TodoItem todo, bool? value) async {
    final done = value ?? false;
    await _upsertTodo(
      todo.copyWith(
        isDone: done,
        completedAt: done ? DateTime.now() : null,
        clearCompletedAt: !done,
      ),
    );
  }

  Future<void> _togglePin(TodoItem todo) async {
    await _upsertTodo(todo.copyWith(isPinned: !todo.isPinned));
  }

  Future<void> _confirmDelete(TodoItem todo) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa công việc?'),
        content: Text('"${todo.title}" sẽ bị xóa khỏi danh sách.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Hủy'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _deleteWithUndo(todo);
    }
  }

  Future<void> _deleteWithUndo(TodoItem todo) async {
    final index = _todos.indexWhere((item) => item.id == todo.id);
    if (index < 0) return;

    setState(() {
      _todos.removeAt(index);
    });
    await _saveTodos();

    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: const Text('Đã xóa công việc'),
          action: SnackBarAction(
            label: 'Hoàn tác',
            onPressed: () async {
              setState(() {
                final restoredIndex = index <= _todos.length ? index : _todos.length;
                _todos.insert(restoredIndex, todo);
              });
              await _saveTodos();
            },
          ),
        ),
      );
  }

  Future<void> _clearCompleted() async {
    final completedCount = _todos.where((todo) => todo.isDone).length;
    if (completedCount == 0) {
      _showMessage('Không có công việc hoàn thành để dọn dẹp');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Dọn dẹp công việc hoàn thành'),
        content: Text('Xóa $completedCount công việc đã hoàn thành?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Hủy'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Xóa tất cả'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _todos.removeWhere((todo) => todo.isDone);
    });
    await _saveTodos();
  }

  Future<void> _showAddEditSheet({TodoItem? todo}) async {
    final result = await showModalBottomSheet<TodoItem>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => _TodoEditorSheet(todo: todo),
    );

    if (result == null) {
      return;
    }

    await _upsertTodo(result);
  }

  int get _completedCount => _todos.where((todo) => todo.isDone).length;

  int get _overdueCount {
    final now = DateTime.now();
    return _todos.where((todo) => !todo.isDone && todo.dueDate != null && todo.dueDate!.isBefore(now)).length;
  }

  String _sortLabel(TaskSort sort) {
    switch (sort) {
      case TaskSort.smart:
        return 'Thông minh';
      case TaskSort.dueDate:
        return 'Deadline';
      case TaskSort.createdAt:
        return 'Mới tạo';
      case TaskSort.priority:
        return 'Ưu tiên';
    }
  }

  Widget _buildStatsHeader() {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Tổng', style: textTheme.labelLarge),
                    const SizedBox(height: 4),
                    Text('${_todos.length}', style: textTheme.headlineSmall),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Hoàn thành', style: textTheme.labelLarge),
                    const SizedBox(height: 4),
                    Text('$_completedCount', style: textTheme.headlineSmall),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Trễ hạn', style: textTheme.labelLarge),
                    const SizedBox(height: 4),
                    Text('$_overdueCount', style: textTheme.headlineSmall),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskList() {
    final items = _visibleTodos;

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.task_alt,
                size: 56,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 12),
              Text(
                'Chưa có công việc phù hợp',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 6),
              Text(
                'Tạo công việc mới hoặc thay đổi bộ lọc để tiếp tục.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 96),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final todo = items[index];

        return Dismissible(
          key: ValueKey(todo.id),
          background: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Icon(
              todo.isDone ? Icons.undo : Icons.check,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
          secondaryBackground: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Icon(
              Icons.delete,
              color: Theme.of(context).colorScheme.onErrorContainer,
            ),
          ),
          confirmDismiss: (direction) async {
            if (direction == DismissDirection.startToEnd) {
              await _toggleDone(todo, !todo.isDone);
              return false;
            }

            if (direction == DismissDirection.endToStart) {
              await _confirmDelete(todo);
              return false;
            }

            return false;
          },
          child: TodoItemWidget(
            todo: todo,
            onToggle: (value) => _toggleDone(todo, value),
            onEdit: () => _showAddEditSheet(todo: todo),
            onDelete: () => _confirmDelete(todo),
            onTogglePin: () => _togglePin(todo),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Todo'),
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Tùy chọn',
            onSelected: (value) {
              if (value == 'clear_done') {
                _clearCompleted();
              } else if (value == 'settings') {
                Navigator.of(context).pushNamed('/settings');
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem<String>(
                value: 'clear_done',
                child: Text('Dọn dẹp đã hoàn thành'),
              ),
              PopupMenuItem<String>(
                value: 'settings',
                child: Text('Cài đặt'),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: SearchBar(
              controller: _searchController,
              hintText: 'Tìm kiếm công việc...',
              leading: const Icon(Icons.search),
              trailing: _searchQuery.isEmpty
                  ? null
                  : [
                      IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      ),
                    ],
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SegmentedButton<TaskFilter>(
                segments: const [
                  ButtonSegment(value: TaskFilter.all, label: Text('Tất cả')),
                  ButtonSegment(value: TaskFilter.active, label: Text('Đang làm')),
                  ButtonSegment(value: TaskFilter.done, label: Text('Hoàn thành')),
                ],
                selected: {_filter},
                onSelectionChanged: (selection) {
                  setState(() {
                    _filter = selection.first;
                  });
                },
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 8,
                    children: [
                      FilterChip(
                        label: const Text('Ưu tiên cao'),
                        selected: _priorityFilter == TodoPriority.high,
                        onSelected: (_) {
                          setState(() {
                            _priorityFilter = _priorityFilter == TodoPriority.high ? null : TodoPriority.high;
                          });
                        },
                      ),
                      FilterChip(
                        label: const Text('Ưu tiên TB'),
                        selected: _priorityFilter == TodoPriority.medium,
                        onSelected: (_) {
                          setState(() {
                            _priorityFilter = _priorityFilter == TodoPriority.medium ? null : TodoPriority.medium;
                          });
                        },
                      ),
                      FilterChip(
                        label: const Text('Ưu tiên thấp'),
                        selected: _priorityFilter == TodoPriority.low,
                        onSelected: (_) {
                          setState(() {
                            _priorityFilter = _priorityFilter == TodoPriority.low ? null : TodoPriority.low;
                          });
                        },
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<TaskSort>(
                  initialValue: _sort,
                  tooltip: 'Sắp xếp',
                  onSelected: (value) {
                    setState(() {
                      _sort = value;
                    });
                  },
                  itemBuilder: (context) => TaskSort.values
                      .map(
                        (item) => PopupMenuItem<TaskSort>(
                          value: item,
                          child: Text(_sortLabel(item)),
                        ),
                      )
                      .toList(),
                  child: Chip(
                    avatar: const Icon(Icons.swap_vert, size: 18),
                    label: Text(_sortLabel(_sort)),
                  ),
                ),
              ],
            ),
          ),
          _buildStatsHeader(),
          Expanded(child: _buildTaskList()),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditSheet(),
        icon: const Icon(Icons.add),
        label: const Text('Thêm công việc'),
      ),
    );
  }
}

class _TodoEditorSheet extends StatefulWidget {
  const _TodoEditorSheet({this.todo});

  final TodoItem? todo;

  @override
  State<_TodoEditorSheet> createState() => _TodoEditorSheetState();
}

class _TodoEditorSheetState extends State<_TodoEditorSheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;

  late TodoPriority _priority;
  DateTime? _dueDate;

  bool get _isEdit => widget.todo != null;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.todo?.title ?? '');
    _descriptionController = TextEditingController(text: widget.todo?.description ?? '');
    _priority = widget.todo?.priority ?? TodoPriority.medium;
    _dueDate = widget.todo?.dueDate;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDeadline() async {
    final now = DateTime.now();
    final initialDate = _dueDate ?? now;
    final date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 3650)),
    );

    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: _dueDate != null ? TimeOfDay.fromDateTime(_dueDate!) : TimeOfDay.now(),
    );

    if (!mounted) return;

    setState(() {
      _dueDate = DateTime(
        date.year,
        date.month,
        date.day,
        time?.hour ?? 0,
        time?.minute ?? 0,
      );
    });
  }

  void _save() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final item = (widget.todo ??
            TodoItem(
              id: DateTime.now().microsecondsSinceEpoch.toString(),
              title: '',
            ))
        .copyWith(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      dueDate: _dueDate,
      clearDueDate: _dueDate == null,
      priority: _priority,
    );

    Navigator.of(context).pop(item);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        8,
        16,
        MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _isEdit ? 'Cập nhật công việc' : 'Tạo công việc mới',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleController,
                autofocus: true,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Tiêu đề',
                  prefixIcon: Icon(Icons.edit_note),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Tiêu đề không được để trống';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Mô tả',
                  prefixIcon: Icon(Icons.notes),
                ),
              ),
              const SizedBox(height: 16),
              Text('Mức ưu tiên', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              SegmentedButton<TodoPriority>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(
                    value: TodoPriority.low,
                    label: Text('Thấp'),
                    icon: Icon(Icons.flag_outlined),
                  ),
                  ButtonSegment(
                    value: TodoPriority.medium,
                    label: Text('TB'),
                    icon: Icon(Icons.flag),
                  ),
                  ButtonSegment(
                    value: TodoPriority.high,
                    label: Text('Cao'),
                    icon: Icon(Icons.priority_high),
                  ),
                ],
                selected: {_priority},
                onSelectionChanged: (selected) {
                  setState(() {
                    _priority = selected.first;
                  });
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.tonalIcon(
                      onPressed: _pickDeadline,
                      icon: const Icon(Icons.event),
                      label: Text(
                        _dueDate != null
                            ? DateFormat('dd/MM/yyyy · HH:mm').format(_dueDate!)
                            : 'Đặt deadline',
                      ),
                    ),
                  ),
                  if (_dueDate != null) ...[
                    const SizedBox(width: 8),
                    IconButton.filledTonal(
                      onPressed: () {
                        setState(() {
                          _dueDate = null;
                        });
                      },
                      icon: const Icon(Icons.clear),
                      tooltip: 'Xóa deadline',
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Hủy'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _save,
                      child: Text(_isEdit ? 'Lưu thay đổi' : 'Tạo công việc'),
                    ),
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
