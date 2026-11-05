// SPIKE: combined capture registry. Do not edit per screen: add entries to
// the group file (capture_group_*.dart) that fits, one line each.
import 'capture_entry.dart';
import 'capture_group_existing.dart';
import 'capture_group_life.dart';
import 'capture_group_money.dart';
import 'capture_group_tasks.dart';
import 'capture_group_time.dart';

final List<CaptureEntry> captureRegistry = <CaptureEntry>[
  ...captureExistingEntries,
  ...captureTasksEntries,
  ...captureTimeEntries,
  ...captureMoneyEntries,
  ...captureLifeEntries,
];
