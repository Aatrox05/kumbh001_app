import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

import 'widgets/hero_banner.dart';
import 'widgets/language_selector.dart';
import 'widgets/plan_my_visit_button.dart';
import 'widgets/latest_announcements_card.dart';
import 'widgets/place_to_explore_header.dart';
import 'widgets/place_horizontal_list.dart';
import 'widgets/todays_event_header.dart';
import 'widgets/todays_event_list.dart';
import 'widgets/spiritual_path_header.dart';
import 'widgets/spiritual_path_list.dart';
import 'widgets/bottom_nav_bar.dart';

import 'package:kumbh_app/features/explore/presentation/explore_screen.dart';
import 'package:kumbh_app/features/map/presentation/map_screen.dart';
import 'package:kumbh_app/features/emergency/presentation/emergency_screen.dart';
import 'package:kumbh_app/features/voice_assistant/presentation/voice_assistant_widget.dart';
import 'package:kumbh_app/features/more/presentation/more_screen.dart';
import 'package:kumbh_app/core/sync/sync_service.dart';
import 'package:kumbh_app/app/providers.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      // 0 — Home View
      const _HomeFeedView(),

      // 1 — Explore
      const ExploreScreen(),

      // 2 — Emergency (SOS)
      const EmergencyScreen(),

      // 3 — Map
      const MapScreen(),

      // 4 — More
      const MoreScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF6E9),
      body: SafeArea(
        top: true,
        child: Stack(
          children: [
            IndexedStack(
              index: _currentIndex,
              children: _screens,
            ),

            // Voice Assistant Modal FAB Overlay
            const Positioned(
              bottom: 80,
              right: 16,
              child: VoiceAssistantWidget(),
            ),
          ],
        ),
      ),
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: _currentIndex,
        onItemSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}

class _CalendarSection extends ConsumerStatefulWidget {
  const _CalendarSection();

  @override
  ConsumerState<_CalendarSection> createState() => _CalendarSectionState();
}

class _CalendarSectionState extends ConsumerState<_CalendarSection> {
  CalendarFormat _calendarFormat = CalendarFormat.week;
  DateTime _focusedDay = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final selectedDay = ref.watch(eventsSelectedDateProvider);

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: TableCalendar<dynamic>(
                firstDay: DateTime.utc(2026, 1, 1),
                lastDay: DateTime.utc(2028, 12, 31),
                focusedDay: _focusedDay,
                calendarFormat: _calendarFormat,
                selectedDayPredicate: (day) => isSameDay(selectedDay, day),
                onDaySelected: (day, focusedDay) {
                  setState(() {
                    _focusedDay = focusedDay;
                  });
                  ref.read(eventsSelectedDateProvider.notifier).state = day;
                  ref.invalidate(eventsListProvider);
                },
                onFormatChanged: (format) {
                  if (_calendarFormat != format) {
                    setState(() {
                      _calendarFormat = format;
                    });
                  }
                },
                onPageChanged: (focusedDay) {
                  _focusedDay = focusedDay;
                },
                headerStyle: const HeaderStyle(
                  titleCentered: true,
                  formatButtonVisible: true,
                  formatButtonShowsNext: false,
                ),
                calendarStyle: const CalendarStyle(
                  todayDecoration: BoxDecoration(
                    color: Color(0xFFFFCC80),
                    shape: BoxShape.circle,
                  ),
                  todayTextStyle: TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.bold,
                  ),
                  selectedDecoration: BoxDecoration(
                    color: Color(0xFFEA7A1A),
                    shape: BoxShape.circle,
                  ),
                  selectedTextStyle: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  defaultDecoration: BoxDecoration(shape: BoxShape.circle),
                  weekendDecoration: BoxDecoration(shape: BoxShape.circle),
                  outsideDecoration: BoxDecoration(shape: BoxShape.circle),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Chip(
              avatar: const Icon(Icons.calendar_today,
                  size: 16, color: Color(0xFFEA7A1A)),
              label: Text(
                'Selected: ${DateFormat('dd MMM yyyy').format(selectedDay)}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              backgroundColor: const Color(0xFFFFF3E0),
              side: const BorderSide(color: Color(0xFFEA7A1A), width: 0.5),
            ),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }
}

class _HomeFeedView extends ConsumerWidget {
  const _HomeFeedView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncState = ref.watch(syncServiceProvider);

    return RefreshIndicator(
      onRefresh: () async {
        await ref
            .read(syncServiceProvider.notifier)
            .triggerIncrementalSync(ref);
      },
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: _buildSyncBanner(context, syncState),
          ),
          const SliverToBoxAdapter(child: HeroBanner()),
          const SliverToBoxAdapter(child: SizedBox(height: 12)),
          const SliverToBoxAdapter(child: LanguageSelector()),
          const SliverToBoxAdapter(child: LatestAnnouncementsCard()),
          const SliverToBoxAdapter(child: PlanMyVisitButton()),
          const SliverToBoxAdapter(child: PlaceToExploreHeader()),
          const SliverToBoxAdapter(child: PlaceHorizontalList()),
          const _CalendarSection(),
          const SliverToBoxAdapter(child: TodaysEventHeader()),
          const TodaysEventList(),
          const SliverToBoxAdapter(child: SpiritualPathHeader()),
          const SpiritualPathList(),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildSyncBanner(BuildContext context, SyncState syncState) {
    if (syncState.status == SyncStatus.upToDate &&
        syncState.lastSyncTime != null) {
      return Container(
        color: Colors.green.shade700,
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, color: Colors.white, size: 14),
            SizedBox(width: 6),
            Text('Live Sync Active · System Up to Date',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold)),
          ],
        ),
      );
    } else if (syncState.status == SyncStatus.syncing) {
      return Container(
        color: Colors.blue.shade700,
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white)),
            SizedBox(width: 8),
            Text('Syncing incremental updates...',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold)),
          ],
        ),
      );
    } else if (syncState.status == SyncStatus.offline) {
      return Container(
        color: Colors.orange.shade800,
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.wifi_off, color: Colors.white, size: 14),
            SizedBox(width: 6),
            Text('Offline Mode · Displaying local SQLite records',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold)),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }
}
