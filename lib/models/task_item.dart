import 'package:cloud_firestore/cloud_firestore.dart';

class TaskItem {
  const TaskItem({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.completed,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String title;
  final String description;
  final DateTime date;
  final bool completed;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  String get status => completed ? 'Completed' : 'Pending';

  TaskItem copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? date,
    bool? completed,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TaskItem(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      date: date ?? this.date,
      completed: completed ?? this.completed,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toFirestoreMap() {
    return {
      'title': title,
      'description': description,
      'date': Timestamp.fromDate(date),
      'completed': completed,
      'status': status,
    };
  }

  factory TaskItem.fromDocument(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return TaskItem(
      id: doc.id,
      title: data['title']?.toString() ?? '',
      description: data['description']?.toString() ?? '',
      date: _readDate(data['date']) ?? DateTime.now(),
      completed:
          data['completed'] as bool? ?? _isCompletedStatus(data['status']),
      createdAt: _readDate(data['createdAt']),
      updatedAt: _readDate(data['updatedAt']),
    );
  }

  static bool _isCompletedStatus(dynamic status) {
    return status?.toString().toLowerCase() == 'completed';
  }

  static DateTime? _readDate(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is DateTime) {
      return value;
    }
    return null;
  }
}
