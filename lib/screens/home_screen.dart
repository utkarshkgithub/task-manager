import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/task_bloc.dart';
import '../models/task_item.dart';
import '../services/auth_service.dart';
import '../services/quote_service.dart';
import '../services/task_service.dart';
import '../widgets/quote_card.dart';
import '../widgets/task_card.dart';
import 'task_editor_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.authService,
    required this.taskService,
    required this.quoteService,
  });

  final AuthService authService;
  final TaskService taskService;
  final QuoteService quoteService;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<MotivationalQuote> _quoteFuture;

  @override
  void initState() {
    super.initState();
    _quoteFuture = widget.quoteService.fetchQuote();
  }

  Future<void> _refreshQuote() async {
    setState(() {
      _quoteFuture = widget.quoteService.fetchQuote();
    });
    await _quoteFuture;
  }

  Future<void> _signOut() async {
    await widget.authService.signOut();
  }

  Future<void> _openEditor({TaskItem? task}) async {
    final user = widget.authService.currentUser;
    if (user == null) {
      return;
    }

    await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => TaskEditorScreen(
          userId: user.uid,
          taskService: widget.taskService,
          initialTask: task,
        ),
      ),
    );
  }

  void _toggleTask(TaskItem task, bool completed) {
    context.read<TaskBloc>().add(
      TaskCompletedRequested(taskId: task.id, completed: completed),
    );
  }

  Future<void> _deleteTask(TaskItem task) async {
    final user = widget.authService.currentUser;
    if (user == null) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete task?'),
          content: Text('Remove "${task.title}" from your list?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    if (!mounted) return;

    context.read<TaskBloc>().add(TaskDeletedRequested(task.id));
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.authService.currentUser;
    if (user == null) {
      return const Scaffold(body: SizedBox.shrink());
    }

    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(),
        icon: const Icon(Icons.add, size: 20),
        label: const Text('Add task'),
      ),
      body: SafeArea(
        child: BlocConsumer<TaskBloc, TaskState>(
          listenWhen: (previous, current) =>
              previous.errorMessage != current.errorMessage &&
              current.errorMessage != null &&
              current.loadStatus == TaskLoadStatus.loaded,
          listener: (context, state) {
            final message = state.errorMessage;
            if (message == null) {
              return;
            }

            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(message)));
          },
          builder: (context, taskState) {
            final tasks = taskState.tasks;
            final completedCount = tasks.where((task) => task.completed).length;
            final pendingCount = tasks.length - completedCount;

            return RefreshIndicator(
              color: Colors.black,
              backgroundColor: Colors.white,
              onRefresh: _refreshQuote,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
                children: [
                  // ── Header ──
                  _HeaderCard(
                    email: user.email ?? 'Signed in user',
                    onSignOut: _signOut,
                  ),
                  const SizedBox(height: 20),

                  // ── Quote ──
                  FutureBuilder<MotivationalQuote>(
                    future: _quoteFuture,
                    builder: (context, quoteSnapshot) {
                      return QuoteCard(
                        snapshot: quoteSnapshot,
                        onRetry: _refreshQuote,
                      );
                    },
                  ),
                  const SizedBox(height: 20),

                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          label: 'Total',
                          value: tasks.length.toString(),
                          // icon: Icons.layers_outlined,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          label: 'Done',
                          value: completedCount.toString(),
                          // icon: Icons.check_circle_outline,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          label: 'Pending',
                          value: pendingCount.toString(),
                          // icon: Icons.schedule_outlined,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Your tasks',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
                              ),
                        ),
                      ),
                      if (taskState.loadStatus == TaskLoadStatus.failure &&
                          tasks.isEmpty)
                        TextButton.icon(
                          onPressed: () => context.read<TaskBloc>().add(
                            TaskSubscriptionRequested(user.uid),
                          ),
                          icon: const Icon(Icons.refresh, size: 18),
                          label: const Text('Retry'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  if (taskState.loadStatus == TaskLoadStatus.failure &&
                      tasks.isEmpty)
                    _ErrorCard(
                      message:
                          taskState.errorMessage ??
                          'Unable to load tasks right now.',
                      actionLabel: 'Try again',
                      onAction: () => context.read<TaskBloc>().add(
                        TaskSubscriptionRequested(user.uid),
                      ),
                    )
                  else if ((taskState.loadStatus == TaskLoadStatus.loading ||
                          taskState.loadStatus == TaskLoadStatus.initial) &&
                      tasks.isEmpty)
                    const _LoadingTasksCard()
                  else if (tasks.isEmpty)
                    const _EmptyStateCard()
                  else
                    ...tasks.map(
                      (task) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: TaskCard(
                          task: task,
                          onEdit: () => _openEditor(task: task),
                          onDelete: () => _deleteTask(task),
                          onToggleCompleted: (value) =>
                              _toggleTask(task, value),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.email, required this.onSignOut});

  final String email;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.checklist_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          const Text(
            'Task Manager',
            style: TextStyle(
              color: Colors.white,
              fontSize: 19,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E5E5)),
        backgroundBlendMode: BlendMode.darken,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1A1A1A),
              letterSpacing: -1,
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF888888),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyStateCard extends StatelessWidget {
  const _EmptyStateCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE5E5E5)),
            ),
            child: const Icon(
              Icons.inbox_outlined,
              size: 26,
              color: Color(0xFF888888),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'No tasks yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1A1A),
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Tap "Add task" to get started.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Color(0xFF888888)),
          ),
        ],
      ),
    );
  }
}

class _LoadingTasksCard extends StatelessWidget {
  const _LoadingTasksCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: Colors.black,
          ),
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E5E5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: onAction,
            icon: const Icon(Icons.refresh, size: 18),
            label: Text(actionLabel),
          ),
        ],
      ),
    );
  }
}
