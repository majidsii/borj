import 'package:borj/features/tasks/application/task_reminder_projection_service.dart';
import 'package:borj/features/tasks/domain/task_item.dart';
import 'package:borj/features/tasks/domain/task_reminder_repository.dart';
import 'package:borj/features/tasks/domain/task_repository.dart';
import 'package:borj/features/tasks/domain/task_status.dart';

final class ReminderAwareTaskRepository
    implements TaskRepository, TaskRestorer {
  factory ReminderAwareTaskRepository({
    required TaskRepository inner,
    required TaskReminderRepository reminderRepository,
    required TaskReminderProjectionService Function() projection,
  }) {
    return ReminderAwareTaskRepository._(inner, reminderRepository, projection);
  }

  const ReminderAwareTaskRepository._(
    this._inner,
    this._reminderRepository,
    this._projection,
  );

  final TaskRepository _inner;
  final TaskReminderRepository _reminderRepository;
  final TaskReminderProjectionService Function() _projection;

  @override
  Stream<List<TaskItem>> watchAll() => _inner.watchAll();

  @override
  Stream<List<TaskItem>> watchByStatus(TaskStatus status) {
    return _inner.watchByStatus(status);
  }

  @override
  Future<TaskItem?> getById(String id) => _inner.getById(id);

  @override
  Future<void> create(TaskItem task) async {
    await _inner.create(task);
    await _reprojectIfConfigured(task.id);
  }

  @override
  Future<void> restore(TaskItem task) async {
    final inner = _inner;
    if (inner is! TaskRestorer) {
      throw StateError('The wrapped task repository cannot restore tasks.');
    }
    await (inner as TaskRestorer).restore(task);
    await _reprojectIfConfigured(task.id);
  }

  @override
  Future<void> update(TaskItem task) async {
    await _inner.update(task);
    await _reprojectIfConfigured(task.id);
  }

  @override
  Future<void> transition({
    required String id,
    required TaskStatus status,
    required int targetPosition,
    required DateTime changedAtUtc,
  }) async {
    await _inner.transition(
      id: id,
      status: status,
      targetPosition: targetPosition,
      changedAtUtc: changedAtUtc,
    );
    await _reprojectIfConfigured(id);
  }

  @override
  Future<void> reorderWithinStatus({
    required TaskStatus status,
    required List<String> orderedIds,
  }) {
    return _inner.reorderWithinStatus(status: status, orderedIds: orderedIds);
  }

  @override
  Future<void> delete(String id) async {
    final hadRules = (await _reminderRepository.getByTask(id)).isNotEmpty;
    await _inner.delete(id);
    if (hadRules) {
      await _projection().clear(id);
    }
  }

  @override
  Future<void> deleteCompleted() async {
    final completedIds = (await _inner.watchAll().first)
        .where((task) => task.status == TaskStatus.completed)
        .map((task) => task.id)
        .toList(growable: false);
    final ownersWithRules = <String>[];
    for (final id in completedIds) {
      if ((await _reminderRepository.getByTask(id)).isNotEmpty) {
        ownersWithRules.add(id);
      }
    }

    await _inner.deleteCompleted();
    for (final id in ownersWithRules) {
      await _projection().clear(id);
    }
  }

  Future<void> _reprojectIfConfigured(String id) async {
    if ((await _reminderRepository.getByTask(id)).isEmpty) return;
    final persisted = await _inner.getById(id);
    if (persisted != null) {
      await _projection().reproject(persisted);
    }
  }
}
