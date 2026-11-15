import '../../domain/entities/task_kind.dart';

/// Label tampilan untuk jenis tugas.
String taskKindLabel(TaskKind kind) {
  return switch (kind) {
    TaskKind.habit => 'Kebiasaan',
    TaskKind.counter => 'Hitungan',
    TaskKind.progress => 'Progres',
  };
}
