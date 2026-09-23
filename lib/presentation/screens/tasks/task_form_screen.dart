import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/utils/validators.dart';
import '../../../domain/entities/task.dart';
import '../../providers/task_provider.dart';
import '../../widgets/confirmation_dialog.dart';
import '../../widgets/priority_style.dart';

/// Create/edit form for a task.
///
/// One screen serves both cases — the previous version had separate add and
/// edit screens that drifted apart. [task] being null means "create".
class TaskFormScreen extends StatefulWidget {
  const TaskFormScreen({super.key, this.task});

  final Task? task;

  @override
  State<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends State<TaskFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  late final String _initialTitle;
  late final String _initialDescription;
  late final TaskPriority _initialPriority;
  late final DateTime? _initialDueDate;

  late TaskPriority _priority;
  DateTime? _dueDate;

  bool _isSaving = false;
  bool _isDirty = false;

  bool get _isEditing => widget.task != null;

  @override
  void initState() {
    super.initState();
    final task = widget.task;

    _initialTitle = task?.title ?? '';
    _initialDescription = task?.description ?? '';
    _initialPriority = task?.priority ?? TaskPriority.medium;
    _initialDueDate = task?.dueDate == null
        ? null
        : AppDateUtils.normalizeDate(task!.dueDate!);

    _titleController.text = _initialTitle;
    _descriptionController.text = _initialDescription;
    _priority = _initialPriority;
    _dueDate = _initialDueDate;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  /// Two dates are the same due date when they land on the same calendar day —
  /// a stored Firestore timestamp carries a time component, a picked one does
  /// not, and treating those as different edits would nag about nothing.
  static bool _sameDay(DateTime? a, DateTime? b) {
    if (a == null || b == null) return a == b;
    return AppDateUtils.normalizeDate(a) == AppDateUtils.normalizeDate(b);
  }

  bool get _computeIsDirty =>
      _titleController.text.trim() != _initialTitle ||
      _descriptionController.text.trim() != _initialDescription ||
      _priority != _initialPriority ||
      !_sameDay(_dueDate, _initialDueDate);

  /// Rebuilds only when the dirty flag actually flips, so typing does not
  /// rebuild the form on every keystroke.
  void _syncDirty() {
    final dirty = _computeIsDirty;
    if (dirty == _isDirty) return;
    setState(() => _isDirty = dirty);
  }

  /// Mutates [change] and re-evaluates dirtiness in the same frame. Calling
  /// `setState` from inside another `setState` works but nests two rebuild
  /// requests, and assigning the field outside would skip the rebuild whenever
  /// the dirty flag happens not to flip.
  void _edit(void Function() change) {
    setState(() {
      change();
      _isDirty = _computeIsDirty;
    });
  }

  static String? _nullIfEmpty(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  Future<void> _pickDueDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 10),
      helpText: 'Select due date',
    );
    if (picked == null || !mounted) return;
    _edit(() => _dueDate = AppDateUtils.normalizeDate(picked));
  }

  void _clearDueDate() => _edit(() => _dueDate = null);

  Future<void> _save() async {
    if (_isSaving) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final provider = context.read<TaskProvider>();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    final title = _titleController.text.trim();
    final description = _nullIfEmpty(_descriptionController.text);
    final dueDate = _dueDate;

    setState(() => _isSaving = true);

    final task = widget.task;
    final error = task == null
        ? await provider.createTask(
            title: title,
            description: description,
            priority: _priority,
            dueDate: dueDate,
          )
        : await provider.updateTask(
            task.copyWith(
              title: title,
              description: description,
              priority: _priority,
              dueDate: dueDate,
            ),
          );

    if (!mounted) return;

    if (error == null) {
      navigator.pop();
      return;
    }

    setState(() => _isSaving = false);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(error), showCloseIcon: true),
      );
  }

  Future<void> _delete() async {
    final task = widget.task;
    if (task == null || _isSaving) return;

    final provider = context.read<TaskProvider>();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    final confirmed = await showConfirmationDialog(
      context,
      title: 'Delete task',
      message: 'Delete "${task.title}"? This cannot be undone.',
    );
    if (!confirmed || !mounted) return;

    setState(() => _isSaving = true);

    final error = await provider.deleteTask(task.id);

    if (!mounted) return;
    if (error == null) {
      navigator.pop();
      return;
    }

    setState(() => _isSaving = false);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(error), showCloseIcon: true));
  }

  Future<void> _confirmDiscard() async {
    final navigator = Navigator.of(context);
    final discard = await showConfirmationDialog(
      context,
      title: 'Discard changes?',
      message: 'Your edits will be lost.',
      confirmLabel: 'Discard',
      cancelLabel: 'Keep editing',
    );
    if (discard) navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return PopScope(
      // Only guard when there is something to lose: an untouched form should
      // close immediately.
      canPop: !_isDirty,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _confirmDiscard();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_isEditing ? 'Edit task' : 'New task'),
          actions: [
            if (_isEditing)
              IconButton(
                onPressed: _isSaving ? null : _delete,
                icon: const Icon(Icons.delete_outline),
                tooltip: 'Delete task',
              ),
            const SizedBox(width: 4),
          ],
        ),
        body: Form(
          key: _formKey,
          child: ContentContainer(
            maxWidth: Responsive.maxFormWidth(context),
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 24),
              children: [
                TextFormField(
                  controller: _titleController,
                  autofocus: !_isEditing,
                  maxLength: AppConstants.maxTaskTitleLength,
                  textInputAction: TextInputAction.next,
                  textCapitalization: TextCapitalization.sentences,
                  onChanged: (_) => _syncDirty(),
                  validator: Validators.validateTaskTitle,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    hintText: 'What needs doing?',
                    prefixIcon: Icon(Icons.title),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descriptionController,
                  maxLength: AppConstants.maxTaskDescriptionLength,
                  maxLines: 5,
                  minLines: 3,
                  textCapitalization: TextCapitalization.sentences,
                  onChanged: (_) => _syncDirty(),
                  validator: Validators.validateTaskDescription,
                  decoration: const InputDecoration(
                    labelText: 'Description (optional)',
                    hintText: 'Any details worth remembering',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 12),
                Text('Priority', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final priority in TaskPriority.values)
                      ChoiceChip(
                        avatar: Icon(
                          priority.icon,
                          size: 18,
                          color: _priority == priority
                              ? priority.color(scheme)
                              : scheme.onSurfaceVariant,
                        ),
                        label: Text(priority.displayName),
                        selected: _priority == priority,
                        onSelected: (_) => _edit(() => _priority = priority),
                      ),
                  ],
                ),
                const SizedBox(height: 24),
                Text('Due date (optional)', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                _DueDateField(
                  dueDate: _dueDate,
                  enabled: !_isSaving,
                  onPick: _pickDueDate,
                  onClear: _clearDueDate,
                ),
                if (_dueDate != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    AppDateUtils.describeDueDate(_dueDate!),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
                const SizedBox(height: 32),
                FilledButton(
                  onPressed: _isSaving ? null : _save,
                  child: _isSaving
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(_isEditing ? 'Save changes' : 'Add task'),
                ),
                if (_isEditing) ...[
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _isSaving ? null : _delete,
                    style: TextButton.styleFrom(foregroundColor: scheme.error),
                    child: const Text('Delete task'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DueDateField extends StatelessWidget {
  const _DueDateField({
    required this.dueDate,
    required this.enabled,
    required this.onPick,
    required this.onClear,
  });

  final DateTime? dueDate;
  final bool enabled;
  final VoidCallback onPick;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final hasDate = dueDate != null;

    return InkWell(
      onTap: enabled ? onPick : null,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: scheme.outlineVariant),
        ),
        child: Row(
          children: [
            Icon(Icons.event_outlined, color: scheme.onSurfaceVariant),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                hasDate ? AppDateUtils.formatDate(dueDate!) : 'No due date',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: hasDate ? scheme.onSurface : scheme.onSurfaceVariant,
                ),
              ),
            ),
            // Removing a due date has to be possible — otherwise the picker
            // becomes a one-way door.
            if (hasDate)
              IconButton(
                onPressed: enabled ? onClear : null,
                icon: const Icon(Icons.clear),
                tooltip: 'Remove due date',
              ),
          ],
        ),
      ),
    );
  }
}
