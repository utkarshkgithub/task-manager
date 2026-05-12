import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../models/task_item.dart';
import '../services/task_service.dart';

sealed class TaskEvent {
  const TaskEvent();
}

final class TaskSubscriptionRequested extends TaskEvent {
  const TaskSubscriptionRequested(this.userId);

  final String userId;
}

final class TaskCompletedRequested extends TaskEvent {
  const TaskCompletedRequested({required this.taskId, required this.completed});

  final String taskId;
  final bool completed;
}

final class TaskDeletedRequested extends TaskEvent {
  const TaskDeletedRequested(this.taskId);

  final String taskId;
}

final class _TaskItemsChanged extends TaskEvent {
  const _TaskItemsChanged(this.tasks);

  final List<TaskItem> tasks;
}

final class _TaskItemsFailed extends TaskEvent {
  const _TaskItemsFailed(this.message);

  final String message;
}

enum TaskLoadStatus { initial, loading, loaded, failure }

class TaskState {
  const TaskState({
    this.loadStatus = TaskLoadStatus.initial,
    this.tasks = const <TaskItem>[],
    this.errorMessage,
    this.isUpdating = false,
  });

  final TaskLoadStatus loadStatus;
  final List<TaskItem> tasks;
  final String? errorMessage;
  final bool isUpdating;

  static const Object _errorMessageUnset = Object();

  TaskState copyWith({
    TaskLoadStatus? loadStatus,
    List<TaskItem>? tasks,
    Object? errorMessage = _errorMessageUnset,
    bool? isUpdating,
  }) {
    return TaskState(
      loadStatus: loadStatus ?? this.loadStatus,
      tasks: tasks ?? this.tasks,
      errorMessage: identical(errorMessage, _errorMessageUnset)
          ? this.errorMessage
          : errorMessage as String?,
      isUpdating: isUpdating ?? this.isUpdating,
    );
  }
}

class TaskBloc extends Bloc<TaskEvent, TaskState> {
  TaskBloc({required TaskService taskService})
    : _taskService = taskService,
      super(const TaskState()) {
    on<TaskSubscriptionRequested>(_onSubscriptionRequested);
    on<_TaskItemsChanged>(_onItemsChanged);
    on<_TaskItemsFailed>(_onItemsFailed);
    on<TaskCompletedRequested>(_onCompletedRequested);
    on<TaskDeletedRequested>(_onDeletedRequested);
  }

  final TaskService _taskService;
  StreamSubscription<List<TaskItem>>? _taskSubscription;
  String? _userId;

  Future<void> _onSubscriptionRequested(
    TaskSubscriptionRequested event,
    Emitter<TaskState> emit,
  ) async {
    _userId = event.userId;
    await _taskSubscription?.cancel();
    emit(
      state.copyWith(
        loadStatus: TaskLoadStatus.loading,
        tasks: const <TaskItem>[],
        errorMessage: null,
        isUpdating: false,
      ),
    );

    _taskSubscription = _taskService
        .watchTasks(event.userId)
        .listen(
          (tasks) => add(_TaskItemsChanged(tasks)),
          onError: (_, __) =>
              add(const _TaskItemsFailed('Unable to load tasks right now.')),
        );
  }

  void _onItemsChanged(_TaskItemsChanged event, Emitter<TaskState> emit) {
    emit(
      state.copyWith(
        loadStatus: TaskLoadStatus.loaded,
        tasks: event.tasks,
        errorMessage: null,
        isUpdating: false,
      ),
    );
  }

  void _onItemsFailed(_TaskItemsFailed event, Emitter<TaskState> emit) {
    emit(
      state.copyWith(
        loadStatus: TaskLoadStatus.failure,
        errorMessage: event.message,
        isUpdating: false,
      ),
    );
  }

  Future<void> _onCompletedRequested(
    TaskCompletedRequested event,
    Emitter<TaskState> emit,
  ) async {
    final userId = _userId;
    if (userId == null) {
      return;
    }

    emit(state.copyWith(isUpdating: true, errorMessage: null));

    try {
      await _taskService.setCompleted(userId, event.taskId, event.completed);
    } catch (_) {
      emit(
        state.copyWith(
          isUpdating: false,
          errorMessage: 'Unable to update the task right now.',
        ),
      );
      return;
    }

    emit(state.copyWith(isUpdating: false));
  }

  Future<void> _onDeletedRequested(
    TaskDeletedRequested event,
    Emitter<TaskState> emit,
  ) async {
    final userId = _userId;
    if (userId == null) {
      return;
    }

    emit(state.copyWith(isUpdating: true, errorMessage: null));

    try {
      await _taskService.deleteTask(userId, event.taskId);
    } catch (_) {
      emit(
        state.copyWith(
          isUpdating: false,
          errorMessage: 'Unable to delete the task right now.',
        ),
      );
      return;
    }

    emit(state.copyWith(isUpdating: false));
  }

  @override
  Future<void> close() async {
    await _taskSubscription?.cancel();
    return super.close();
  }
}
