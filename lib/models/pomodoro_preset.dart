/// Predefined Pomodoro timer presets (not persisted to DB)
class PomodoroPreset {
  final String id;
  final String name;
  final int workMinutes;
  final int breakMinutes;

  const PomodoroPreset({
    required this.id,
    required this.name,
    required this.workMinutes,
    required this.breakMinutes,
  });

  static const List<PomodoroPreset> defaults = [
    PomodoroPreset(id: 'sprint', name: 'Sprint', workMinutes: 15, breakMinutes: 3),
    PomodoroPreset(id: 'pomodoro', name: 'Pomodoro', workMinutes: 25, breakMinutes: 5),
    PomodoroPreset(id: 'deep', name: 'Deep Focus', workMinutes: 50, breakMinutes: 10),
    PomodoroPreset(id: 'marathon', name: 'Marathon', workMinutes: 90, breakMinutes: 20),
  ];
}
