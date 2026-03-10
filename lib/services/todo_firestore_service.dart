import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/todo_item.dart';

class TodoFirestoreService {
  static const String _legacyStorageKeyV2 = 'todos_v2';
  static const String _legacyStorageKeyV1 = 'todos_v1';

  static FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  static String _requireUserId() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null || userId.trim().isEmpty) {
      throw StateError('Người dùng chưa đăng nhập');
    }
    return userId;
  }

  static CollectionReference<Map<String, dynamic>> _todosCollection(
    String userId,
  ) {
    return _firestore.collection('users').doc(userId).collection('todos');
  }

  static Stream<List<TodoItem>> watchTodos() {
    final userId = _requireUserId();

    return _todosCollection(userId).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return TodoItem.fromMap({...data, 'id': doc.id});
      }).toList();
    });
  }

  static Future<void> upsertTodo(TodoItem todo) async {
    final userId = _requireUserId();
    await _todosCollection(userId).doc(todo.id).set(todo.toMap());
  }

  static Future<void> deleteTodo(String todoId) async {
    final userId = _requireUserId();
    await _todosCollection(userId).doc(todoId).delete();
  }

  static Future<void> deleteTodosByIds(List<String> ids) async {
    if (ids.isEmpty) return;

    final userId = _requireUserId();
    final batch = _firestore.batch();

    for (final id in ids) {
      final ref = _todosCollection(userId).doc(id);
      batch.delete(ref);
    }

    await batch.commit();
  }

  static Future<void> migrateLocalTodosIfNeeded() async {
    final userId = _requireUserId();
    final migratedKey = 'todos_firestore_migrated_$userId';

    final prefs = await SharedPreferences.getInstance();
    final alreadyMigrated = prefs.getBool(migratedKey) ?? false;
    if (alreadyMigrated) return;

    final scopedStorageKey = 'todos_v2_$userId';
    final scopedRaw = prefs.getStringList(scopedStorageKey);
    final anonymousRaw = prefs.getStringList('todos_v2_anonymous');
    final legacyV2Raw = prefs.getStringList(_legacyStorageKeyV2);
    final legacyV1Raw = prefs.getStringList(_legacyStorageKeyV1);

    final source =
        scopedRaw ?? anonymousRaw ?? legacyV2Raw ?? legacyV1Raw ?? <String>[];

    final parsed = <TodoItem>[];
    for (final item in source) {
      try {
        parsed.add(TodoItem.fromJson(item));
      } catch (_) {}
    }

    if (parsed.isNotEmpty) {
      final collection = _todosCollection(userId);
      final existingDocs = await collection.get();
      final existingIds = existingDocs.docs.map((doc) => doc.id).toSet();

      final batch = _firestore.batch();
      for (final todo in parsed) {
        if (!existingIds.contains(todo.id)) {
          batch.set(collection.doc(todo.id), todo.toMap());
        }
      }
      await batch.commit();
    }

    await prefs.setBool(migratedKey, true);
    await prefs.remove(scopedStorageKey);
    await prefs.remove('todos_v2_anonymous');
    await prefs.remove(_legacyStorageKeyV2);
    await prefs.remove(_legacyStorageKeyV1);
  }
}
