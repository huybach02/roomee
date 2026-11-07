import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roomee/core/localization/app_localizations.dart';
import 'package:roomee/core/network/network_sentinel.dart';
import 'package:roomee/core/widgets/app_mini_banner.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await AppLocalizations.preload();
  });

  Widget wrapWithMaterial(Widget child) {
    return MaterialApp(
      home: Scaffold(
        body: child,
      ),
    );
  }

  group('AppMiniBanner', () {
    testWidgets('renders AppMiniBanner.info with info icon', (tester) async {
      await tester.pumpWidget(
        wrapWithMaterial(
          AppMiniBanner.info(message: 'Info notification'),
        ),
      );

      expect(find.text('Info notification'), findsOneWidget);
      expect(find.byIcon(Icons.info_outline_rounded), findsOneWidget);
    });

    testWidgets('renders AppMiniBanner.warning with warning icon', (tester) async {
      await tester.pumpWidget(
        wrapWithMaterial(
          AppMiniBanner.warning(message: 'Warning notification'),
        ),
      );

      expect(find.text('Warning notification'), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
    });

    testWidgets('renders AppMiniBanner.success with success icon', (tester) async {
      await tester.pumpWidget(
        wrapWithMaterial(
          AppMiniBanner.success(message: 'Success notification'),
        ),
      );

      expect(find.text('Success notification'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
    });

    testWidgets('renders AppMiniBanner.error with error icon', (tester) async {
      await tester.pumpWidget(
        wrapWithMaterial(
          AppMiniBanner.error(message: 'Error notification'),
        ),
      );

      expect(find.text('Error notification'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
    });

    testWidgets('renders AppMiniBanner.syncing with progress indicator', (tester) async {
      await tester.pumpWidget(
        wrapWithMaterial(
          AppMiniBanner.syncing(message: 'Custom syncing...'),
        ),
      );

      expect(find.text('Custom syncing...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('renders AppMiniBanner.offline with formatted time', (tester) async {
      await tester.pumpWidget(
        wrapWithMaterial(
          AppMiniBanner.offline(
            lastFetchedAt: DateTime(2026, 11, 7, 14, 30),
          ),
        ),
      );

      expect(find.byIcon(Icons.wifi_off_rounded), findsOneWidget);
      expect(find.textContaining('14:30 07/11'), findsOneWidget);
    });

    testWidgets('triggers onTap callback when tapped', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        wrapWithMaterial(
          AppMiniBanner.info(
            message: 'Tappable',
            onTap: () => tapped = true,
          ),
        ),
      );

      await tester.tap(find.text('Tappable'));
      expect(tapped, isTrue);
    });

    group('AppMiniBanner.syncStatus', () {
      testWidgets('renders nothing when idle and online', (tester) async {
        await tester.pumpWidget(
          wrapWithMaterial(
            AppMiniBanner.syncStatus(
              isSyncing: false,
              isOffline: false,
            ),
          ),
        );

        expect(find.byType(CircularProgressIndicator), findsNothing);
        expect(find.byIcon(Icons.wifi_off_rounded), findsNothing);
      });

      testWidgets('renders syncing state with indicator and message',
          (tester) async {
        await tester.pumpWidget(
          wrapWithMaterial(
            AppMiniBanner.syncStatus(
              isSyncing: true,
              isOffline: false,
            ),
          ),
        );

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });

      testWidgets('renders offline state with wifi_off icon and message',
          (tester) async {
        await tester.pumpWidget(
          wrapWithMaterial(
            AppMiniBanner.syncStatus(
              isSyncing: false,
              isOffline: true,
              networkStatusListenable:
                  ValueNotifier<NetworkStatus>(NetworkStatus.offline),
              lastFetchedAt: DateTime(2026, 11, 7, 14, 30),
            ),
          ),
        );

        expect(find.byIcon(Icons.wifi_off_rounded), findsOneWidget);
        expect(find.textContaining('14:30 07/11'), findsOneWidget);
      });

      testWidgets('updates dynamically via isSyncingListenable', (tester) async {
        final syncingNotifier = ValueNotifier<bool>(false);

        await tester.pumpWidget(
          wrapWithMaterial(
            AppMiniBanner.syncStatus(
              isSyncingListenable: syncingNotifier,
              networkStatusListenable:
                  ValueNotifier<NetworkStatus>(NetworkStatus.offline),
              isOffline: true,
            ),
          ),
        );

        expect(find.byIcon(Icons.wifi_off_rounded), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsNothing);

        syncingNotifier.value = true;
        await tester.pump();

        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        syncingNotifier.value = false;
        await tester.pump();

        expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);

        await tester.pump(const Duration(milliseconds: 1600));
        expect(find.byIcon(Icons.check_circle_rounded), findsNothing);
      });

      testWidgets(
          'shows offline banner immediately when network status changes to offline',
          (tester) async {
        final networkStatus =
            ValueNotifier<NetworkStatus>(NetworkStatus.online);

        await tester.pumpWidget(
          wrapWithMaterial(
            AppMiniBanner.syncStatus(
              isSyncing: false,
              isOffline: false,
              networkStatusListenable: networkStatus,
            ),
          ),
        );

        // Ban đầu đang online -> không hiển thị gì
        expect(find.byIcon(Icons.wifi_off_rounded), findsNothing);

        // Thiết bị chuyển sang offline
        networkStatus.value = NetworkStatus.offline;
        await tester.pump();

        // Hiển thị ngay lập tức không cần kéo load
        expect(find.byIcon(Icons.wifi_off_rounded), findsOneWidget);
        expect(find.text(t('common.offlineModeNotice')), findsOneWidget);
      });
    });
  });
}
