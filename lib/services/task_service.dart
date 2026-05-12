import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/task_item.dart';

class TaskService {
  TaskService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _taskCollection(String userId) {
    return _firestore.collection('users').doc(userId).collection('tasks');
  }

  Stream<List<TaskItem>> watchTasks(String userId) {
    return _taskCollection(userId)
        .orderBy('date')
        .snapshots()
        .map((snapshot) => snapshot.docs.map(TaskItem.fromDocument).toList());
  }

  Future<void> saveTask(String userId, TaskItem task) async {
    final payload = <String, dynamic>{
      ...task.toFirestoreMap(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (task.id.isEmpty) {
      await _taskCollection(
        userId,
      ).add({...payload, 'createdAt': FieldValue.serverTimestamp()});
      return;
    }

    await _taskCollection(
      userId,
    ).doc(task.id).set(payload, SetOptions(merge: true));
  }

  Future<void> deleteTask(String userId, String taskId) {
    return _taskCollection(userId).doc(taskId).delete();
  }

  Future<void> setCompleted(String userId, String taskId, bool completed) {
    return _taskCollection(userId).doc(taskId).update({
      'completed': completed,
      'status': completed ? 'Completed' : 'Pending',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
