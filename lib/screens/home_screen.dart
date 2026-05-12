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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(),
        icon: const Icon(Icons.add),
        label: const Text('Add task'),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF8FAFC), Color(0xFFE8F4F1)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
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
              final completedCount = tasks
                  .where((task) => task.completed)
                  .length;
              final pendingCount = tasks.length - completedCount;

              return RefreshIndicator(
                onRefresh: _refreshQuote,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
                  children: [
                    _HeaderCard(
                      email: user.email ?? 'Signed in user',
                      onSignOut: _signOut,
                    ),
                    const SizedBox(height: 20),
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
                            label: 'Total tasks',
                            value: tasks.length.toString(),
                            icon: Icons.list_alt_rounded,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatCard(
                            label: 'Completed',
                            value: completedCount.toString(),
                            icon: Icons.check_circle_rounded,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _StatCard(
                      label: 'Pending',
                      value: pendingCount.toString(),
                      icon: Icons.timelapse_rounded,
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Your tasks',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                        ),
                        if (taskState.loadStatus == TaskLoadStatus.failure &&
                            tasks.isEmpty)
                          TextButton.icon(
                            onPressed: () => context.read<TaskBloc>().add(
                              TaskSubscriptionRequested(user.uid),
                            ),
                            icon: const Icon(Icons.refresh),
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
    final textTheme = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(
                Icons.checklist_rounded,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Task Manager',
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    email,
                    style: textTheme.bodyMedium?.copyWith(
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Logout',
              onPressed: onSignOut,
              icon: const Icon(Icons.logout_rounded),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: Theme.of(context).colorScheme.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    label,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.black54),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyStateCard extends StatelessWidget {
  const _EmptyStateCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                Icons.inbox_rounded,
                size: 34,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No tasks yet',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              'Add your first task to start tracking deadlines and progress.',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingTasksCard extends StatelessWidget {
  const _LoadingTasksCard();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.refresh),
              label: Text(actionLabel),
            ),
          ],
        ),
      ),
    );
  }
}
