// SPIKE: capture entries for the screens that already exist in the gallery.
import '../all_glass_prototype.dart';
import '../screens/envelopes_screen.dart';
import '../screens/focus_timer_screen.dart';
import '../screens/habits_screen.dart';
import '../screens/month_lens_screen.dart';
import '../screens/quick_entry_screen.dart';
import '../screens/rings_screen.dart';
import '../screens/season_forecast_screen.dart';
import '../screens/wallet_stack_screen.dart';
import 'capture_entry.dart';

final List<CaptureEntry> captureExistingEntries = <CaptureEntry>[
  CaptureEntry(
    'home_today_money',
    (_) => const AllGlassHomeApp(fake: false, framed: false),
  ),
  CaptureEntry('rings', (_) => captureOnWallpaper(const RingsScreen())),
  CaptureEntry(
    'wallet_stack',
    (_) => captureOnWallpaper(const WalletStackScreen()),
  ),
  CaptureEntry('envelopes', (_) => captureOnWallpaper(const EnvelopesScreen())),
  CaptureEntry('habits', (_) => captureOnWallpaper(const HabitsScreen())),
  CaptureEntry(
    'month_lens',
    (_) => captureOnWallpaper(const MonthLensScreen()),
  ),
  CaptureEntry(
    'focus_timer',
    (_) => captureOnWallpaper(const FocusTimerScreen()),
  ),
  CaptureEntry(
    'quick_entry',
    (_) => captureOnWallpaper(const QuickEntryScreen()),
  ),
  CaptureEntry(
    'season_forecast',
    (_) => captureOnWallpaper(const SeasonForecastScreen()),
  ),
];
