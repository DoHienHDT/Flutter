// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../rendering/mock_canvas.dart';
import '../widgets/semantics_tester.dart';

Widget buildSliverAppBarApp({
  bool floating,
  bool pinned,
  double collapsedHeight,
  double expandedHeight,
  bool snap = false,
  double toolbarHeight = kToolbarHeight,
}) {
  return Localizations(
    locale: const Locale('en', 'US'),
    delegates: const <LocalizationsDelegate<dynamic>>[
      DefaultMaterialLocalizations.delegate,
      DefaultWidgetsLocalizations.delegate,
    ],
    child: Directionality(
      textDirection: TextDirection.ltr,
      child: MediaQuery(
        data: const MediaQueryData(),
        child: Scaffold(
          body: DefaultTabController(
            length: 3,
            child: CustomScrollView(
              primary: true,
              slivers: <Widget>[
                SliverAppBar(
                  title: const Text('AppBar Title'),
                  floating: floating,
                  pinned: pinned,
                  collapsedHeight: collapsedHeight,
                  expandedHeight: expandedHeight,
                  toolbarHeight: toolbarHeight,
                  snap: snap,
                  bottom: TabBar(
                    tabs: <String>['A','B','C'].map<Widget>((String t) => Tab(text: 'TAB $t')).toList(),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Container(
                    height: 1200.0,
                    color: Colors.orange[400],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

ScrollController primaryScrollController(WidgetTester tester) {
  return PrimaryScrollController.of(tester.element(find.byType(CustomScrollView)));
}

double appBarHeight(WidgetTester tester) => tester.getSize(find.byType(AppBar, skipOffstage: false)).height;
double appBarTop(WidgetTester tester) => tester.getTopLeft(find.byType(AppBar, skipOffstage: false)).dy;
double appBarBottom(WidgetTester tester) => tester.getBottomLeft(find.byType(AppBar, skipOffstage: false)).dy;

double tabBarHeight(WidgetTester tester) => tester.getSize(find.byType(TabBar, skipOffstage: false)).height;

void main() {
  setUp(() {
    debugResetSemanticsIdCounter();
  });

  testWidgets('AppBar centers title on iOS', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(platform: TargetPlatform.android),
        home: Scaffold(
          appBar: AppBar(
            title: const Text('X'),
          ),
        ),
      ),
    );

    final Finder title = find.text('X');
    Offset center = tester.getCenter(title);
    Size size = tester.getSize(title);
    expect(center.dx, lessThan(400 - size.width / 2.0));

    for (final TargetPlatform platform in <TargetPlatform>[TargetPlatform.iOS, TargetPlatform.macOS]) {
      // Clear the widget tree to avoid animating between platforms.
      await tester.pumpWidget(Container(key: UniqueKey()));

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(platform: platform),
          home: Scaffold(
            appBar: AppBar(
              title: const Text('X'),
            ),
          ),
        ),
      );

      center = tester.getCenter(title);
      size = tester.getSize(title);
      expect(center.dx, greaterThan(400 - size.width / 2.0), reason: 'on ${describeEnum(platform)}');
      expect(center.dx, lessThan(400 + size.width / 2.0), reason: 'on ${describeEnum(platform)}');

      // One action is still centered.

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(platform: platform),
          home: Scaffold(
            appBar: AppBar(
              title: const Text('X'),
              actions: const <Widget>[
                Icon(Icons.thumb_up),
              ],
            ),
          ),
        ),
      );

      center = tester.getCenter(title);
      size = tester.getSize(title);
      expect(center.dx, greaterThan(400 - size.width / 2.0), reason: 'on ${describeEnum(platform)}');
      expect(center.dx, lessThan(400 + size.width / 2.0), reason: 'on ${describeEnum(platform)}');

      // Two actions is left aligned again.

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(platform: platform),
          home: Scaffold(
            appBar: AppBar(
              title: const Text('X'),
              actions: const <Widget>[
                Icon(Icons.thumb_up),
                Icon(Icons.thumb_up),
              ],
            ),
          ),
        ),
      );

      center = tester.getCenter(title);
      size = tester.getSize(title);
      expect(center.dx, lessThan(400 - size.width / 2.0), reason: 'on ${describeEnum(platform)}');
    }
  });

  testWidgets('AppBar centerTitle:true centers on Android', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(platform: TargetPlatform.android),
        home: Scaffold(
          appBar: AppBar(
            centerTitle: true,
            title: const Text('X'),
          ),
        ),
      ),
    );

    final Finder title = find.text('X');
    final Offset center = tester.getCenter(title);
    final Size size = tester.getSize(title);
    expect(center.dx, greaterThan(400 - size.width / 2.0));
    expect(center.dx, lessThan(400 + size.width / 2.0));
  });

  testWidgets('AppBar centerTitle:false title start edge is 16.0 (LTR)', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          appBar: AppBar(
            centerTitle: false,
            title: const Placeholder(key: Key('X')),
          ),
        ),
      ),
    );

    final Finder titleWidget = find.byKey(const Key('X'));
    expect(tester.getTopLeft(titleWidget).dx, 16.0);
    expect(tester.getTopRight(titleWidget).dx, 800 - 16.0);
  });

  testWidgets('AppBar centerTitle:false title start edge is 16.0 (RTL)', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            appBar: AppBar(
              centerTitle: false,
              title: const Placeholder(key: Key('X')),
            ),
          ),
        ),
      ),
    );

    final Finder titleWidget = find.byKey(const Key('X'));
    expect(tester.getTopRight(titleWidget).dx, 800.0 - 16.0);
    expect(tester.getTopLeft(titleWidget).dx, 16.0);
  });

  testWidgets('AppBar titleSpacing:32 title start edge is 32.0 (LTR)', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          appBar: AppBar(
            centerTitle: false,
            titleSpacing: 32.0,
            title: const Placeholder(key: Key('X')),
          ),
        ),
      ),
    );

    final Finder titleWidget = find.byKey(const Key('X'));
    expect(tester.getTopLeft(titleWidget).dx, 32.0);
    expect(tester.getTopRight(titleWidget).dx, 800 - 32.0);
  });

  testWidgets('AppBar titleSpacing:32 title start edge is 32.0 (RTL)', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            appBar: AppBar(
              centerTitle: false,
              titleSpacing: 32.0,
              title: const Placeholder(key: Key('X')),
            ),
          ),
        ),
      ),
    );

    final Finder titleWidget = find.byKey(const Key('X'));
    expect(tester.getTopRight(titleWidget).dx, 800.0 - 32.0);
    expect(tester.getTopLeft(titleWidget).dx, 32.0);
  });

  testWidgets(
    'AppBar centerTitle:false leading button title left edge is 72.0 (LTR)',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: AppBar(
              centerTitle: false,
              title: const Text('X'),
            ),
            // A drawer causes a leading hamburger.
            drawer: const Drawer(),
          ),
        ),
      );

      expect(tester.getTopLeft(find.text('X')).dx, 72.0);
    });

  testWidgets(
    'AppBar centerTitle:false leading button title left edge is 72.0 (RTL)',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
              appBar: AppBar(
                centerTitle: false,
                title: const Text('X'),
              ),
              // A drawer causes a leading hamburger.
              drawer: const Drawer(),
            ),
          ),
        ),
      );

      expect(tester.getTopRight(find.text('X')).dx, 800.0 - 72.0);
    });

  testWidgets('AppBar centerTitle:false title overflow OK', (WidgetTester tester) async {
    // The app bar's title should be constrained to fit within the available space
    // between the leading and actions widgets.

    final Key titleKey = UniqueKey();
    Widget leading = Container();
    List<Widget> actions;

    Widget buildApp() {
      return MaterialApp(
        home: Scaffold(
          appBar: AppBar(
            leading: leading,
            centerTitle: false,
            title: Container(
              key: titleKey,
              constraints: BoxConstraints.loose(const Size(1000.0, 1000.0)),
            ),
            actions: actions,
          ),
        ),
      );
    }

    await tester.pumpWidget(buildApp());

    final Finder title = find.byKey(titleKey);
    expect(tester.getTopLeft(title).dx, 72.0);
    expect(tester.getSize(title).width, equals(
        800.0 // Screen width.
        - 56.0 // Leading button width.
        - 16.0 // Leading button to title padding.
        - 16.0)); // Title right side padding.

    actions = <Widget>[
      const SizedBox(width: 100.0),
      const SizedBox(width: 100.0),
    ];
    await tester.pumpWidget(buildApp());

    expect(tester.getTopLeft(title).dx, 72.0);
    // The title shrinks by 200.0 to allow for the actions widgets.
    expect(tester.getSize(title).width, equals(
        800.0 // Screen width.
        - 56.0 // Leading button width.
        - 16.0 // Leading button to title padding.
        - 16.0 // Title to actions padding
        - 200.0)); // Actions' width.

    leading = Container(); // AppBar will constrain the width to 24.0
    await tester.pumpWidget(buildApp());
    expect(tester.getTopLeft(title).dx, 72.0);
    // Adding a leading widget shouldn't effect the title's size
    expect(tester.getSize(title).width, equals(800.0 - 56.0 - 16.0 - 16.0 - 200.0));
  });

  testWidgets('AppBar centerTitle:true title overflow OK (LTR)', (WidgetTester tester) async {
    // The app bar's title should be constrained to fit within the available space
    // between the leading and actions widgets. When it's also centered it may
    // also be start or end justified if it doesn't fit in the overall center.

    final Key titleKey = UniqueKey();
    double titleWidth = 700.0;
    Widget leading = Container();
    List<Widget> actions;

    Widget buildApp() {
      return MaterialApp(
        home: Scaffold(
          appBar: AppBar(
            leading: leading,
            centerTitle: true,
            title: Container(
              key: titleKey,
              constraints: BoxConstraints.loose(Size(titleWidth, 1000.0)),
            ),
            actions: actions,
          ),
        ),
      );
    }

    // Centering a title with width 700 within the 800 pixel wide test widget
    // would mean that its start edge would have to be 50. The material spec says
    // that the start edge of the title must be at least 72.
    await tester.pumpWidget(buildApp());

    final Finder title = find.byKey(titleKey);
    expect(tester.getTopLeft(title).dx, 72.0);
    expect(tester.getSize(title).width, equals(700.0));

    // Centering a title with width 620 within the 800 pixel wide test widget
    // would mean that its start edge would have to be 90. We reserve 72
    // on the start and the padded actions occupy 96 on the end. That
    // leaves 632, so the title is end justified but its width isn't changed.

    await tester.pumpWidget(buildApp());
    leading = null;
    titleWidth = 620.0;
    actions = <Widget>[
      const SizedBox(width: 48.0),
      const SizedBox(width: 48.0),
    ];
    await tester.pumpWidget(buildApp());
    expect(tester.getTopLeft(title).dx, 800 - 620 - 48 - 48);
    expect(tester.getSize(title).width, equals(620.0));
  });

  testWidgets('AppBar centerTitle:true title overflow OK (RTL)', (WidgetTester tester) async {
    // The app bar's title should be constrained to fit within the available space
    // between the leading and actions widgets. When it's also centered it may
    // also be start or end justified if it doesn't fit in the overall center.

    final Key titleKey = UniqueKey();
    double titleWidth = 700.0;
    Widget leading = Container();
    List<Widget> actions;

    Widget buildApp() {
      return MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            appBar: AppBar(
              leading: leading,
              centerTitle: true,
              title: Container(
                key: titleKey,
                constraints: BoxConstraints.loose(Size(titleWidth, 1000.0)),
              ),
              actions: actions,
            ),
          ),
        ),
      );
    }

    // Centering a title with width 700 within the 800 pixel wide test widget
    // would mean that its start edge would have to be 50. The material spec says
    // that the start edge of the title must be at least 72.
    await tester.pumpWidget(buildApp());

    final Finder title = find.byKey(titleKey);
    expect(tester.getTopRight(title).dx, 800.0 - 72.0);
    expect(tester.getSize(title).width, equals(700.0));

    // Centering a title with width 620 within the 800 pixel wide test widget
    // would mean that its start edge would have to be 90. We reserve 72
    // on the start and the padded actions occupy 96 on the end. That
    // leaves 632, so the title is end justified but its width isn't changed.

    await tester.pumpWidget(buildApp());
    leading = null;
    titleWidth = 620.0;
    actions = <Widget>[
      const SizedBox(width: 48.0),
      const SizedBox(width: 48.0),
    ];
    await tester.pumpWidget(buildApp());
    expect(tester.getTopRight(title).dx, 620 + 48 + 48);
    expect(tester.getSize(title).width, equals(620.0));
  });

  testWidgets('AppBar with no Scaffold', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          height: kToolbarHeight,
          child: AppBar(
            leading: const Text('L'),
            title: const Text('No Scaffold'),
            actions: const <Widget>[Text('A1'), Text('A2')],
          ),
        ),
      ),
    );

    expect(find.text('L'), findsOneWidget);
    expect(find.text('No Scaffold'), findsOneWidget);
    expect(find.text('A1'), findsOneWidget);
    expect(find.text('A2'), findsOneWidget);
  });

  testWidgets('AppBar render at zero size', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: Container(
            height: 0.0,
            width: 0.0,
            child: Scaffold(
              appBar: AppBar(
                title: const Text('X'),
              ),
            ),
          ),
        ),
      ),
    );

    final Finder title = find.text('X');
    expect(tester.getSize(title).isEmpty, isTrue);
  });

  testWidgets('AppBar actions are vertically centered', (WidgetTester tester) async {
    final UniqueKey appBarKey = UniqueKey();
    final UniqueKey leadingKey = UniqueKey();
    final UniqueKey titleKey = UniqueKey();
    final UniqueKey action0Key = UniqueKey();
    final UniqueKey action1Key = UniqueKey();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          appBar: AppBar(
            key: appBarKey,
            leading: SizedBox(key: leadingKey, height: 50.0),
            title: SizedBox(key: titleKey, height: 40.0),
            actions: <Widget>[
              SizedBox(key: action0Key, height: 20.0),
              SizedBox(key: action1Key, height: 30.0),
            ],
          ),
        ),
      ),
    );

    // The vertical center of the widget with key, in global coordinates.
    double yCenter(Key key) => tester.getCenter(find.byKey(key)).dy;

    expect(yCenter(appBarKey), equals(yCenter(leadingKey)));
    expect(yCenter(appBarKey), equals(yCenter(titleKey)));
    expect(yCenter(appBarKey), equals(yCenter(action0Key)));
    expect(yCenter(appBarKey), equals(yCenter(action1Key)));
  });

  testWidgets('leading button extends to edge and is square', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(platform: TargetPlatform.android),
        home: Scaffold(
          appBar: AppBar(
            title: const Text('X'),
          ),
          drawer: Column(), // Doesn't really matter. Triggers a hamburger regardless.
        ),
      ),
    );

    final Finder hamburger = find.byTooltip('Open navigation menu');
    expect(tester.getTopLeft(hamburger), const Offset(0.0, 0.0));
    expect(tester.getSize(hamburger), const Size(56.0, 56.0));
  });

  testWidgets('test action is 4dp from edge and 48dp min', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(platform: TargetPlatform.android),
        home: Scaffold(
          appBar: AppBar(
            title: const Text('X'),
            actions: const <Widget> [
              IconButton(
                icon: Icon(Icons.share),
                onPressed: null,
                tooltip: 'Share',
                iconSize: 20.0,
              ),
              IconButton(
                icon: Icon(Icons.add),
                onPressed: null,
                tooltip: 'Add',
                iconSize: 60.0,
              ),
            ],
          ),
        ),
      ),
    );

    final Finder addButton = find.byTooltip('Add');
    expect(tester.getTopRight(addButton), const Offset(800.0, 0.0));
    // It's still the size it was plus the 2 * 8dp padding from IconButton.
    expect(tester.getSize(addButton), const Size(60.0 + 2 * 8.0, 56.0));

    final Finder shareButton = find.byTooltip('Share');
    // The 20dp icon is expanded to fill the IconButton's touch target to 48dp.
    expect(tester.getSize(shareButton), const Size(48.0, 56.0));
  });

  testWidgets('SliverAppBar default configuration', (WidgetTester tester) async {
    await tester.pumpWidget(buildSliverAppBarApp(
      floating: false,
      pinned: false,
      expandedHeight: null,
    ));

    final ScrollController controller = primaryScrollController(tester);
    expect(controller.offset, 0.0);
    expect(find.byType(SliverAppBar), findsOneWidget);

    final double initialAppBarHeight = appBarHeight(tester);
    final double initialTabBarHeight = tabBarHeight(tester);

    // Scroll the not-pinned appbar partially out of view
    controller.jumpTo(50.0);
    await tester.pump();
    expect(find.byType(SliverAppBar), findsOneWidget);
    expect(appBarHeight(tester), initialAppBarHeight);
    expect(tabBarHeight(tester), initialTabBarHeight);

    // Scroll the not-pinned appbar out of view
    controller.jumpTo(600.0);
    await tester.pump();
    expect(find.byType(SliverAppBar), findsNothing);
    expect(appBarHeight(tester), initialAppBarHeight);
    expect(tabBarHeight(tester), initialTabBarHeight);

    // Scroll the not-pinned appbar back into view
    controller.jumpTo(0.0);
    await tester.pump();
    expect(find.byType(SliverAppBar), findsOneWidget);
    expect(appBarHeight(tester), initialAppBarHeight);
    expect(tabBarHeight(tester), initialTabBarHeight);
  });

  testWidgets('SliverAppBar expandedHeight, pinned', (WidgetTester tester) async {

    await tester.pumpWidget(buildSliverAppBarApp(
      floating: false,
      pinned: true,
      expandedHeight: 128.0,
    ));

    final ScrollController controller = primaryScrollController(tester);
    expect(controller.offset, 0.0);
    expect(find.byType(SliverAppBar), findsOneWidget);
    expect(appBarHeight(tester), 128.0);

    const double initialAppBarHeight = 128.0;
    final double initialTabBarHeight = tabBarHeight(tester);

    // Scroll the not-pinned appbar, collapsing the expanded height. At this
    // point both the toolbar and the tabbar are visible.
    controller.jumpTo(600.0);
    await tester.pump();
    expect(find.byType(SliverAppBar), findsOneWidget);
    expect(tabBarHeight(tester), initialTabBarHeight);
    expect(appBarHeight(tester), lessThan(initialAppBarHeight));
    expect(appBarHeight(tester), greaterThan(initialTabBarHeight));

    // Scroll the not-pinned appbar back into view
    controller.jumpTo(0.0);
    await tester.pump();
    expect(find.byType(SliverAppBar), findsOneWidget);
    expect(appBarHeight(tester), initialAppBarHeight);
    expect(tabBarHeight(tester), initialTabBarHeight);
  });

  testWidgets('SliverAppBar expandedHeight, pinned and floating', (WidgetTester tester) async {

    await tester.pumpWidget(buildSliverAppBarApp(
      floating: true,
      pinned: true,
      expandedHeight: 128.0,
    ));

    final ScrollController controller = primaryScrollController(tester);
    expect(controller.offset, 0.0);
    expect(find.byType(SliverAppBar), findsOneWidget);
    expect(appBarHeight(tester), 128.0);

    const double initialAppBarHeight = 128.0;
    final double initialTabBarHeight = tabBarHeight(tester);

    // Scroll the floating-pinned appbar, collapsing the expanded height. At this
    // point only the tabBar is visible.
    controller.jumpTo(600.0);
    await tester.pump();
    expect(find.byType(SliverAppBar), findsOneWidget);
    expect(tabBarHeight(tester), initialTabBarHeight);
    expect(appBarHeight(tester), lessThan(initialAppBarHeight));
    expect(appBarHeight(tester), initialTabBarHeight);

    // Scroll the floating-pinned appbar back into view
    controller.jumpTo(0.0);
    await tester.pump();
    expect(find.byType(SliverAppBar), findsOneWidget);
    expect(appBarHeight(tester), initialAppBarHeight);
    expect(tabBarHeight(tester), initialTabBarHeight);
  });

  testWidgets('SliverAppBar expandedHeight, floating with snap:true', (WidgetTester tester) async {
    await tester.pumpWidget(buildSliverAppBarApp(
      floating: true,
      pinned: false,
      snap: true,
      expandedHeight: 128.0,
    ));
    expect(find.byType(SliverAppBar), findsOneWidget);
    expect(appBarTop(tester), 0.0);
    expect(appBarHeight(tester), 128.0);
    expect(appBarBottom(tester), 128.0);

    // Scroll to the middle of the list. The (floating) appbar is no longer visible.
    final ScrollPosition position = tester.state<ScrollableState>(find.byType(Scrollable)).position;
    position.jumpTo(256.00);
    await tester.pumpAndSettle();
    expect(find.byType(SliverAppBar), findsNothing);
    expect(appBarTop(tester), lessThanOrEqualTo(-128.0));

    // Drag the scrollable up and down. The app bar should not snap open, its
    // height should just track the drag offset.
    TestGesture gesture = await tester.startGesture(const Offset(50.0, 256.0));
    await gesture.moveBy(const Offset(0.0, 128.0)); // drag the appbar all the way open
    await tester.pump();
    expect(appBarTop(tester), 0.0);
    expect(appBarHeight(tester), 128.0);

    await gesture.moveBy(const Offset(0.0, -50.0));
    await tester.pump();
    expect(appBarBottom(tester), 78.0); // 78 == 128 - 50

    // Trigger the snap open animation: drag down and release
    await gesture.moveBy(const Offset(0.0, 10.0));
    await gesture.up();

    // Now verify that the appbar is animating open
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    double bottom = appBarBottom(tester);
    expect(bottom, greaterThan(88.0)); // 88 = 78 + 10

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(appBarBottom(tester), greaterThan(bottom));

    // The animation finishes when the appbar is full height.
    await tester.pumpAndSettle();
    expect(appBarHeight(tester), 128.0);

    // Now that the app bar is open, perform the same drag scenario
    // in reverse: drag the appbar up and down and then trigger the
    // snap closed animation.
    gesture = await tester.startGesture(const Offset(50.0, 256.0));
    await gesture.moveBy(const Offset(0.0, -128.0)); // drag the appbar closed
    await tester.pump();
    expect(appBarBottom(tester), 0.0);

    await gesture.moveBy(const Offset(0.0, 100.0));
    await tester.pump();
    expect(appBarBottom(tester), 100.0);

    // Trigger the snap close animation: drag upwards and release
    await gesture.moveBy(const Offset(0.0, -10.0));
    await gesture.up();

    // Now verify that the appbar is animating closed
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    bottom = appBarBottom(tester);
    expect(bottom, lessThan(90.0));

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(appBarBottom(tester), lessThan(bottom));

    // The animation finishes when the appbar is off screen.
    await tester.pumpAndSettle();
    expect(appBarTop(tester), lessThanOrEqualTo(0.0));
    expect(appBarBottom(tester), lessThanOrEqualTo(0.0));
  });

  testWidgets('SliverAppBar expandedHeight, floating and pinned with snap:true', (WidgetTester tester) async {
    await tester.pumpWidget(buildSliverAppBarApp(
      floating: true,
      pinned: true,
      snap: true,
      expandedHeight: 128.0,
    ));
    expect(find.byType(SliverAppBar), findsOneWidget);
    expect(appBarTop(tester), 0.0);
    expect(appBarHeight(tester), 128.0);
    expect(appBarBottom(tester), 128.0);

    // Scroll to the middle of the list. The only the tab bar is visible
    // because this is a pinned appbar.
    final ScrollPosition position = tester.state<ScrollableState>(find.byType(Scrollable)).position;
    position.jumpTo(256.0);
    await tester.pumpAndSettle();
    expect(find.byType(SliverAppBar), findsOneWidget);
    expect(appBarTop(tester), 0.0);
    expect(appBarHeight(tester), kTextTabBarHeight);

    // Drag the scrollable up and down. The app bar should not snap open, the
    // bottom of the appbar should just track the drag offset.
    TestGesture gesture = await tester.startGesture(const Offset(50.0, 200.0));
    await gesture.moveBy(const Offset(0.0, 100.0));
    await tester.pump();
    expect(appBarHeight(tester), 100.0);

    await gesture.moveBy(const Offset(0.0, -25.0));
    await tester.pump();
    expect(appBarHeight(tester), 75.0);

    // Trigger the snap animation: drag down and release
    await gesture.moveBy(const Offset(0.0, 10.0));
    await gesture.up();

    // Now verify that the appbar is animating open
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    final double height = appBarHeight(tester);
    expect(height, greaterThan(85.0));
    expect(height, lessThan(128.0));

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(appBarHeight(tester), greaterThan(height));
    expect(appBarHeight(tester), lessThan(128.0));

    // The animation finishes when the appbar is fully expanded
    await tester.pumpAndSettle();
    expect(appBarTop(tester), 0.0);
    expect(appBarHeight(tester), 128.0);
    expect(appBarBottom(tester), 128.0);

    // Now that the appbar is fully expanded, Perform the same drag
    // scenario in reverse: drag the appbar up and down and then trigger
    // the snap closed animation.
    gesture = await tester.startGesture(const Offset(50.0, 256.0));
    await gesture.moveBy(const Offset(0.0, -128.0));
    await tester.pump();
    expect(appBarBottom(tester), kTextTabBarHeight);

    await gesture.moveBy(const Offset(0.0, 100.0));
    await tester.pump();
    expect(appBarBottom(tester), 100.0);

    // Trigger the snap close animation: drag upwards and release
    await gesture.moveBy(const Offset(0.0, -10.0));
    await gesture.up();

    // Now verify that the appbar is animating closed
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    final double bottom = appBarBottom(tester);
    expect(bottom, lessThan(90.0));

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(appBarBottom(tester), lessThan(bottom));

    // The animation finishes when the appbar shrinks back to its pinned height
    await tester.pumpAndSettle();
    expect(appBarTop(tester), lessThanOrEqualTo(0.0));
    expect(appBarBottom(tester), kTextTabBarHeight);
  });

  testWidgets('SliverAppBar expandedHeight, collapsedHeight', (WidgetTester tester) async {
    const double expandedAppBarHeight = 400.0;
    const double collapsedAppBarHeight = 200.0;

    await tester.pumpWidget(buildSliverAppBarApp(
      floating: false,
      pinned: false,
      collapsedHeight: collapsedAppBarHeight,
      expandedHeight: expandedAppBarHeight,
    ));

    final ScrollController controller = primaryScrollController(tester);
    expect(controller.offset, 0.0);
    expect(find.byType(SliverAppBar), findsOneWidget);
    expect(appBarHeight(tester), expandedAppBarHeight);

    final double initialTabBarHeight = tabBarHeight(tester);

    // Scroll the not-pinned appbar partially out of view.
    controller.jumpTo(50.0);
    await tester.pump();
    expect(find.byType(SliverAppBar), findsOneWidget);
    expect(appBarHeight(tester), expandedAppBarHeight - 50.0);
    expect(tabBarHeight(tester), initialTabBarHeight);

    // Scroll the not-pinned appbar out of view, to its collapsed height.
    controller.jumpTo(600.0);
    await tester.pump();
    expect(find.byType(SliverAppBar), findsNothing);
    expect(appBarHeight(tester), collapsedAppBarHeight + initialTabBarHeight);
    expect(tabBarHeight(tester), initialTabBarHeight);

    // Scroll the not-pinned appbar back into view.
    controller.jumpTo(0.0);
    await tester.pump();
    expect(find.byType(SliverAppBar), findsOneWidget);
    expect(appBarHeight(tester), expandedAppBarHeight);
    expect(tabBarHeight(tester), initialTabBarHeight);
  });

  testWidgets('SliverAppBar rebuilds when forceElevated changes', (WidgetTester tester) async {
    // Regression test for https://github.com/flutter/flutter/issues/59158.
    Widget buildSliverAppBar(bool forceElevated) {
      return MaterialApp(
        home: CustomScrollView(
          slivers: <Widget>[
            SliverAppBar(
              title: const Text('Title'),
              forceElevated: forceElevated,
            ),
          ],
        ),
      );
    }

    final Finder appBarFinder = find.byType(AppBar);
    AppBar getAppBarWidget(Finder finder) => tester.widget<AppBar>(finder);

    await tester.pumpWidget(buildSliverAppBar(false));
    expect(getAppBarWidget(appBarFinder).elevation, 0.0);

    await tester.pumpWidget(buildSliverAppBar(true));
    expect(getAppBarWidget(appBarFinder).elevation, 4.0);
  });

  testWidgets('AppBar dimensions, with and without bottom, primary', (WidgetTester tester) async {
    const MediaQueryData topPadding100 = MediaQueryData(padding: EdgeInsets.only(top: 100.0));

    await tester.pumpWidget(
      Localizations(
        locale: const Locale('en', 'US'),
        delegates: const <LocalizationsDelegate<dynamic>>[
          DefaultMaterialLocalizations.delegate,
          DefaultWidgetsLocalizations.delegate,
        ],
        child: Directionality(
        textDirection: TextDirection.ltr,
        child: MediaQuery(
          data: topPadding100,
          child: Scaffold(
            primary: false,
            appBar: AppBar(),
          ),
        ),
      ),
    ));
    expect(appBarTop(tester), 0.0);
    expect(appBarHeight(tester), kToolbarHeight);

    await tester.pumpWidget(
      Localizations(
        locale: const Locale('en', 'US'),
        delegates: const <LocalizationsDelegate<dynamic>>[
          DefaultMaterialLocalizations.delegate,
          DefaultWidgetsLocalizations.delegate,
        ],
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: MediaQuery(
            data: topPadding100,
            child: Scaffold(
              primary: true,
              appBar: AppBar(title: const Text('title')),
          ),
        ),
      ),
    ));
    expect(appBarTop(tester), 0.0);
    expect(tester.getTopLeft(find.text('title')).dy, greaterThan(100.0));
    expect(appBarHeight(tester), kToolbarHeight + 100.0);

    await tester.pumpWidget(
      Localizations(
        locale: const Locale('en', 'US'),
        delegates: const <LocalizationsDelegate<dynamic>>[
          DefaultMaterialLocalizations.delegate,
          DefaultWidgetsLocalizations.delegate,
        ],
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: MediaQuery(
            data: topPadding100,
            child: Scaffold(
              primary: false,
              appBar: AppBar(
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(200.0),
                  child: Container(),
              ),
            ),
          ),
        ),
      ),
    ));
    expect(appBarTop(tester), 0.0);
    expect(appBarHeight(tester), kToolbarHeight + 200.0);

    await tester.pumpWidget(
      Localizations(
        locale: const Locale('en', 'US'),
        delegates: const <LocalizationsDelegate<dynamic>>[
          DefaultMaterialLocalizations.delegate,
          DefaultWidgetsLocalizations.delegate,
        ],
        child: Directionality(
        textDirection: TextDirection.ltr,
        child: MediaQuery(
          data: topPadding100,
          child: Scaffold(
            primary: true,
            appBar: AppBar(
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(200.0),
                child: Container(),
              ),
            ),
          ),
        ),
      ),
    ));
    expect(appBarTop(tester), 0.0);
    expect(appBarHeight(tester), kToolbarHeight + 100.0 + 200.0);

    await tester.pumpWidget(
      Localizations(
        locale: const Locale('en', 'US'),
        delegates: const <LocalizationsDelegate<dynamic>>[
          DefaultMaterialLocalizations.delegate,
          DefaultWidgetsLocalizations.delegate,
        ],
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: MediaQuery(
            data: topPadding100,
            child: AppBar(
              primary: false,
              title: const Text('title'),
            ),
          ),
        ),
      ),
    );
    expect(appBarTop(tester), 0.0);
    expect(tester.getTopLeft(find.text('title')).dy, lessThan(100.0));
  });

  testWidgets('AppBar in body excludes bottom SafeArea padding', (WidgetTester tester) async {
    // Regression test for https://github.com/flutter/flutter/issues/26163
    await tester.pumpWidget(
      Localizations(
        locale: const Locale('en', 'US'),
        delegates: const <LocalizationsDelegate<dynamic>>[
          DefaultMaterialLocalizations.delegate,
          DefaultWidgetsLocalizations.delegate,
        ],
        child: Directionality(
        textDirection: TextDirection.ltr,
        child: MediaQuery(
          data: const MediaQueryData(padding: EdgeInsets.symmetric(vertical: 100.0)),
          child: Scaffold(
            primary: true,
            body: Column(
              children: <Widget>[
                AppBar(
                  title: const Text('title'),
                ),
              ],
            ),
          ),
        ),
      ),
    ));
    expect(appBarTop(tester), 0.0);
    expect(appBarHeight(tester), kToolbarHeight + 100.0);
  });

  testWidgets('AppBar updates when you add a drawer', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          appBar: AppBar(),
        ),
      ),
    );
    expect(find.byIcon(Icons.menu), findsNothing);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          drawer: const Drawer(),
          appBar: AppBar(),
        ),
      ),
    );
    expect(find.byIcon(Icons.menu), findsOneWidget);
  });

  testWidgets('AppBar does not draw menu for drawer if automaticallyImplyLeading is false', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          drawer: const Drawer(),
          appBar: AppBar(automaticallyImplyLeading: false),
        ),
      ),
    );
    expect(find.byIcon(Icons.menu), findsNothing);
  });

  testWidgets('AppBar ink splash draw on the correct canvas', (WidgetTester tester) async {
    // This is a regression test for https://github.com/flutter/flutter/issues/58665
    final Key key = UniqueKey();
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: AppBar(
            title: const Text('Abc'),
            actions: <Widget>[
              IconButton(
                key: key,
                icon: const Icon(Icons.add_circle),
                tooltip: 'First button',
                onPressed: () {},
              ),
            ],
            flexibleSpace: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: const Alignment(0.0, -1.0),
                  end: const Alignment(-0.04, 1.0),
                  colors: <Color>[Colors.blue.shade500, Colors.blue.shade800],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    final RenderObject painter = tester.renderObject(
      find.descendant(
        of: find.descendant(
          of: find.byType(AppBar),
          matching: find.byType(Stack),
        ),
        matching: find.byType(Material)
      )
    );
    await tester.tap(find.byKey(key));
    expect(painter, paints..save()..translate()..save()..translate()..circle(x: 24.0, y: 28.0));
  });

  testWidgets('AppBar handles loose children 0', (WidgetTester tester) async {
    final GlobalKey key = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: AppBar(
            leading: Placeholder(key: key),
            title: const Text('Abc'),
            actions: const <Widget>[
              Placeholder(fallbackWidth: 10.0),
              Placeholder(fallbackWidth: 10.0),
              Placeholder(fallbackWidth: 10.0),
            ],
          ),
        ),
      ),
    );
    expect(tester.renderObject<RenderBox>(find.byKey(key)).localToGlobal(Offset.zero), const Offset(0.0, 0.0));
    expect(tester.renderObject<RenderBox>(find.byKey(key)).size, const Size(56.0, 56.0));
  });

  testWidgets('AppBar handles loose children 1', (WidgetTester tester) async {
    final GlobalKey key = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: AppBar(
            leading: Placeholder(key: key),
            title: const Text('Abc'),
            actions: const <Widget>[
              Placeholder(fallbackWidth: 10.0),
              Placeholder(fallbackWidth: 10.0),
              Placeholder(fallbackWidth: 10.0),
            ],
            flexibleSpace: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: const Alignment(0.0, -1.0),
                  end: const Alignment(-0.04, 1.0),
                  colors: <Color>[Colors.blue.shade500, Colors.blue.shade800],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    expect(tester.renderObject<RenderBox>(find.byKey(key)).localToGlobal(Offset.zero), const Offset(0.0, 0.0));
    expect(tester.renderObject<RenderBox>(find.byKey(key)).size, const Size(56.0, 56.0));
  });

  testWidgets('AppBar handles loose children 2', (WidgetTester tester) async {
    final GlobalKey key = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: AppBar(
            leading: Placeholder(key: key),
            title: const Text('Abc'),
            actions: const <Widget>[
              Placeholder(fallbackWidth: 10.0),
              Placeholder(fallbackWidth: 10.0),
              Placeholder(fallbackWidth: 10.0),
            ],
            flexibleSpace: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: const Alignment(0.0, -1.0),
                  end: const Alignment(-0.04, 1.0),
                  colors: <Color>[Colors.blue.shade500, Colors.blue.shade800],
                ),
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size(0.0, kToolbarHeight),
              child: Container(
                height: 50.0,
                padding: const EdgeInsets.all(4.0),
                child: const Placeholder(
                  strokeWidth: 2.0,
                  color: Color(0xFFFFFFFF),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    expect(tester.renderObject<RenderBox>(find.byKey(key)).localToGlobal(Offset.zero), const Offset(0.0, 0.0));
    expect(tester.renderObject<RenderBox>(find.byKey(key)).size, const Size(56.0, 56.0));
  });

  testWidgets('AppBar handles loose children 3', (WidgetTester tester) async {
    final GlobalKey key = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: AppBar(
            leading: Placeholder(key: key),
            title: const Text('Abc'),
            actions: const <Widget>[
              Placeholder(fallbackWidth: 10.0),
              Placeholder(fallbackWidth: 10.0),
              Placeholder(fallbackWidth: 10.0),
            ],
            bottom: PreferredSize(
              preferredSize: const Size(0.0, kToolbarHeight),
              child: Container(
                height: 50.0,
                padding: const EdgeInsets.all(4.0),
                child: const Placeholder(
                  strokeWidth: 2.0,
                  color: Color(0xFFFFFFFF),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    expect(tester.renderObject<RenderBox>(find.byKey(key)).localToGlobal(Offset.zero), const Offset(0.0, 0.0));
    expect(tester.renderObject<RenderBox>(find.byKey(key)).size, const Size(56.0, 56.0));
  });

  testWidgets('AppBar positioning of leading and trailing widgets with top padding', (WidgetTester tester) async {
    const MediaQueryData topPadding100 = MediaQueryData(padding: EdgeInsets.only(top: 100));

    final Key leadingKey = UniqueKey();
    final Key titleKey = UniqueKey();
    final Key trailingKey = UniqueKey();

    await tester.pumpWidget(
      Localizations(
        locale: const Locale('en', 'US'),
        delegates: const <LocalizationsDelegate<dynamic>>[
          DefaultMaterialLocalizations.delegate,
          DefaultWidgetsLocalizations.delegate,
        ],
        child: Directionality(
        textDirection: TextDirection.rtl,
        child: MediaQuery(
          data: topPadding100,
          child: Scaffold(
            primary: false,
            appBar: AppBar(
              leading: Placeholder(key: leadingKey), // Forced to 56x56, see _kLeadingWidth in app_bar.dart.
              title: Placeholder(key: titleKey, fallbackHeight: kToolbarHeight),
              actions: <Widget>[ Placeholder(key: trailingKey, fallbackWidth: 10) ],
            ),
          ),
        ),
      ),
    ));
    expect(tester.getTopLeft(find.byType(AppBar)), const Offset(0, 0));
    expect(tester.getTopLeft(find.byKey(leadingKey)), const Offset(800.0 - 56.0, 100));
    expect(tester.getTopLeft(find.byKey(trailingKey)), const Offset(0.0, 100));

    // Because the topPadding eliminates the vertical space for the
    // NavigationToolbar within the AppBar, the toolbar is constrained
    // with minHeight=maxHeight=0. The _AppBarTitle widget vertically centers
    // the title, so its Y coordinate relative to the toolbar is -kToolbarHeight / 2
    // (-28). The top of the toolbar is at (screen coordinates) y=100, so the
    // top of the title is 100 + -28 = 72. The toolbar clips its contents
    // so the title isn't actually visible.
    expect(tester.getTopLeft(find.byKey(titleKey)), const Offset(10 + NavigationToolbar.kMiddleSpacing, 72));
  });

  testWidgets('SliverAppBar positioning of leading and trailing widgets with top padding', (WidgetTester tester) async {
    const MediaQueryData topPadding100 = MediaQueryData(padding: EdgeInsets.only(top: 100.0));

    final Key leadingKey = UniqueKey();
    final Key titleKey = UniqueKey();
    final Key trailingKey = UniqueKey();

    await tester.pumpWidget(
      Localizations(
        locale: const Locale('en', 'US'),
        delegates: const <LocalizationsDelegate<dynamic>>[
          DefaultMaterialLocalizations.delegate,
          DefaultWidgetsLocalizations.delegate,
        ],
        child: Directionality(
        textDirection: TextDirection.rtl,
        child: MediaQuery(
          data: topPadding100,
          child: CustomScrollView(
            primary: true,
            slivers: <Widget>[
              SliverAppBar(
                leading: Placeholder(key: leadingKey),
                title: Placeholder(key: titleKey, fallbackHeight: kToolbarHeight),
                actions: <Widget>[ Placeholder(key: trailingKey) ],
              ),
            ],
          ),
        ),
      ),
    ));
    expect(tester.getTopLeft(find.byType(AppBar)), const Offset(0.0, 0.0));
    expect(tester.getTopLeft(find.byKey(leadingKey)), const Offset(800.0 - 56.0, 100.0));
    expect(tester.getTopLeft(find.byKey(titleKey)), const Offset(416.0, 100.0));
    expect(tester.getTopLeft(find.byKey(trailingKey)), const Offset(0.0, 100.0));
  });

  testWidgets('SliverAppBar positioning of leading and trailing widgets with bottom padding', (WidgetTester tester) async {
    const MediaQueryData topPadding100 = MediaQueryData(padding: EdgeInsets.only(top: 100.0, bottom: 50.0));

    final Key leadingKey = UniqueKey();
    final Key titleKey = UniqueKey();
    final Key trailingKey = UniqueKey();

    await tester.pumpWidget(
      Localizations(
        locale: const Locale('en', 'US'),
        delegates: const <LocalizationsDelegate<dynamic>>[
          DefaultMaterialLocalizations.delegate,
          DefaultWidgetsLocalizations.delegate,
        ],
        child: Directionality(
        textDirection: TextDirection.rtl,
        child: MediaQuery(
          data: topPadding100,
          child: CustomScrollView(
            primary: true,
            slivers: <Widget>[
              SliverAppBar(
                leading: Placeholder(key: leadingKey),
                title: Placeholder(key: titleKey),
                actions: <Widget>[ Placeholder(key: trailingKey) ],
              ),
            ],
          ),
        ),
      ),
    ));
    expect(tester.getRect(find.byType(AppBar)), const Rect.fromLTRB(0.0, 0.0, 800.00, 100.0 + 56.0));
    expect(tester.getRect(find.byKey(leadingKey)), const Rect.fromLTRB(800.0 - 56.0, 100.0, 800.0, 100.0 + 56.0));
    expect(tester.getRect(find.byKey(trailingKey)), const Rect.fromLTRB(0.0, 100.0, 400.0, 100.0 + 56.0));
  });

  testWidgets('SliverAppBar provides correct semantics in LTR', (WidgetTester tester) async {
    final SemanticsTester semantics = SemanticsTester(tester);

    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: AppBar(
            leading: const Text('Leading'),
            title: const Text('Title'),
            actions: const <Widget>[
              Text('Action 1'),
              Text('Action 2'),
              Text('Action 3'),
            ],
            bottom: const PreferredSize(
              preferredSize: Size(0.0, kToolbarHeight),
              child: Text('Bottom'),
            ),
          ),
        ),
      ),
    );

    expect(semantics, hasSemantics(
      TestSemantics.root(
        children: <TestSemantics>[
          TestSemantics(
            children: <TestSemantics>[
              TestSemantics(
                children: <TestSemantics> [
                  TestSemantics(
                    flags: <SemanticsFlag>[SemanticsFlag.scopesRoute],
                    children: <TestSemantics>[
                      TestSemantics(
                        children: <TestSemantics>[
                          TestSemantics(
                            label: 'Leading',
                            textDirection: TextDirection.ltr,
                          ),
                          TestSemantics(
                            flags: <SemanticsFlag>[
                              SemanticsFlag.namesRoute,
                              SemanticsFlag.isHeader,
                            ],
                            label: 'Title',
                            textDirection: TextDirection.ltr,
                          ),
                          TestSemantics(
                            label: 'Action 1',
                            textDirection: TextDirection.ltr,
                          ),
                          TestSemantics(
                            label: 'Action 2',
                            textDirection: TextDirection.ltr,
                          ),
                          TestSemantics(
                            label: 'Action 3',
                            textDirection: TextDirection.ltr,
                          ),
                          TestSemantics(
                            label: 'Bottom',
                            textDirection: TextDirection.ltr,
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      ignoreRect: true,
      ignoreTransform: true,
      ignoreId: true,
    ));

    semantics.dispose();
  });

  testWidgets('SliverAppBar provides correct semantics in RTL', (WidgetTester tester) async {
    final SemanticsTester semantics = SemanticsTester(tester);

    await tester.pumpWidget(
      MaterialApp(
        home: Semantics(
          textDirection: TextDirection.rtl,
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Center(
              child: AppBar(
                leading: const Text('Leading'),
                title: const Text('Title'),
                actions: const <Widget>[
                  Text('Action 1'),
                  Text('Action 2'),
                  Text('Action 3'),
                ],
                bottom: const PreferredSize(
                  preferredSize: Size(0.0, kToolbarHeight),
                  child: Text('Bottom'),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    expect(semantics, hasSemantics(
      TestSemantics.root(
        children: <TestSemantics>[
          TestSemantics(
            children: <TestSemantics>[
              TestSemantics(
                children: <TestSemantics>[
                  TestSemantics(
                    flags: <SemanticsFlag>[SemanticsFlag.scopesRoute],
                    children: <TestSemantics>[
                      TestSemantics(
                        textDirection: TextDirection.rtl,
                        children: <TestSemantics>[
                          TestSemantics(
                            children: <TestSemantics>[
                              TestSemantics(
                                label: 'Leading',
                                textDirection: TextDirection.rtl,
                              ),
                              TestSemantics(
                                flags: <SemanticsFlag>[
                                  SemanticsFlag.namesRoute,
                                  SemanticsFlag.isHeader,
                                ],
                                label: 'Title',
                                textDirection: TextDirection.rtl,
                              ),
                              TestSemantics(
                                label: 'Action 1',
                                textDirection: TextDirection.rtl,
                              ),
                              TestSemantics(
                                label: 'Action 2',
                                textDirection: TextDirection.rtl,
                              ),
                              TestSemantics(
                                label: 'Action 3',
                                textDirection: TextDirection.rtl,
                              ),
                              TestSemantics(
                                label: 'Bottom',
                                textDirection: TextDirection.rtl,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      ignoreRect: true,
      ignoreTransform: true,
      ignoreId: true,
    ));

    semantics.dispose();
  });

  testWidgets('AppBar excludes header semantics correctly', (WidgetTester tester) async {
    final SemanticsTester semantics = SemanticsTester(tester);

    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: AppBar(
            leading: const Text('Leading'),
            title: const ExcludeSemantics(child: Text('Title')),
            excludeHeaderSemantics: true,
            actions: const <Widget>[
              Text('Action 1'),
            ],
          ),
        ),
      ),
    );

    expect(semantics, hasSemantics(
      TestSemantics.root(
        children: <TestSemantics>[
          TestSemantics(
            children: <TestSemantics>[
              TestSemantics(
                children: <TestSemantics>[
                  TestSemantics(
                    flags: <SemanticsFlag>[SemanticsFlag.scopesRoute],
                    children: <TestSemantics>[
                      TestSemantics(
                        children: <TestSemantics>[
                          TestSemantics(
                            label: 'Leading',
                            textDirection: TextDirection.ltr,
                          ),
                          TestSemantics(
                            label: 'Action 1',
                            textDirection: TextDirection.ltr,
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      ignoreRect: true,
      ignoreTransform: true,
      ignoreId: true,
    ));

    semantics.dispose();
  });

  testWidgets('SliverAppBar excludes header semantics correctly', (WidgetTester tester) async {
    final SemanticsTester semantics = SemanticsTester(tester);

    await tester.pumpWidget(
      const MaterialApp(
        home: CustomScrollView(
          slivers: <Widget>[
            SliverAppBar(
              leading: Text('Leading'),
              flexibleSpace: ExcludeSemantics(child: Text('Title')),
              actions: <Widget>[Text('Action 1')],
              excludeHeaderSemantics: true,
            ),
          ],
        ),
      ),
    );

    expect(semantics, hasSemantics(
      TestSemantics.root(
        children: <TestSemantics>[
          TestSemantics(
            textDirection: TextDirection.ltr,
            children: <TestSemantics>[
              TestSemantics(
                children: <TestSemantics>[
                  TestSemantics(
                    flags: <SemanticsFlag>[SemanticsFlag.scopesRoute],
                    children: <TestSemantics>[
                      TestSemantics(
                        children: <TestSemantics>[
                          TestSemantics(
                            children: <TestSemantics>[
                              TestSemantics(
                                label: 'Leading',
                                textDirection: TextDirection.ltr,
                              ),
                              TestSemantics(
                                label: 'Action 1',
                                textDirection: TextDirection.ltr,
                              ),
                            ],
                          ),
                          TestSemantics(
                            flags: <SemanticsFlag>[SemanticsFlag.hasImplicitScrolling],
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      ignoreRect: true,
      ignoreTransform: true,
      ignoreId: true,
    ));

    semantics.dispose();
  });

  testWidgets('AppBar draws a light system bar for a dark background', (WidgetTester tester) async {
    final ThemeData darkTheme = ThemeData.dark();
    await tester.pumpWidget(MaterialApp(
      theme: darkTheme,
      home: Scaffold(
        appBar: AppBar(title: const Text('test')),
      ),
    ));

    expect(darkTheme.primaryColorBrightness, Brightness.dark);
    expect(SystemChrome.latestStyle, const SystemUiOverlayStyle(
      statusBarBrightness: Brightness.dark,
      statusBarIconBrightness: Brightness.light,
    ));
  });

  testWidgets('AppBar draws a dark system bar for a light background', (WidgetTester tester) async {
    final ThemeData lightTheme = ThemeData(primaryColor: Colors.white);
    await tester.pumpWidget(MaterialApp(
      theme: lightTheme,
      home: Scaffold(
        appBar: AppBar(title: const Text('test')),
      ),
    ));

    expect(lightTheme.primaryColorBrightness, Brightness.light);
    expect(SystemChrome.latestStyle, const SystemUiOverlayStyle(
      statusBarBrightness: Brightness.light,
      statusBarIconBrightness: Brightness.dark,
    ));
  });

  testWidgets('Changing SliverAppBar snap from true to false', (WidgetTester tester) async {
    // Regression test for https://github.com/flutter/flutter/issues/17598
    const double appBarHeight = 256.0;
    bool snap = true;

    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Scaffold(
              body: CustomScrollView(
                slivers: <Widget>[
                  SliverAppBar(
                    expandedHeight: appBarHeight,
                    pinned: false,
                    floating: true,
                    snap: snap,
                    actions: <Widget>[
                      FlatButton(
                        child: const Text('snap=false'),
                        onPressed: () {
                          setState(() {
                            snap = false;
                          });
                        },
                      ),
                    ],
                    flexibleSpace: FlexibleSpaceBar(
                      background: Container(
                        height: appBarHeight,
                        color: Colors.orange,
                      ),
                    ),
                  ),
                  SliverList(
                    delegate: SliverChildListDelegate(
                      <Widget>[
                        Container(height: 1200.0, color: Colors.teal),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );

    TestGesture gesture = await tester.startGesture(const Offset(50.0, 400.0));
    await gesture.moveBy(const Offset(0.0, -100.0));
    await gesture.up();

    await tester.tap(find.text('snap=false'));
    await tester.pumpAndSettle();

    gesture = await tester.startGesture(const Offset(50.0, 400.0));
    await gesture.moveBy(const Offset(0.0, -100.0));
    await gesture.up();
    await tester.pump();
  });

  testWidgets('AppBar shape default', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AppBar(
          leading: const Text('L'),
          title: const Text('No Scaffold'),
          actions: const <Widget>[Text('A1'), Text('A2')],
        ),
      ),
    );

    final Finder appBarFinder = find.byType(AppBar);
    AppBar getAppBarWidget(Finder finder) => tester.widget<AppBar>(finder);
    expect(getAppBarWidget(appBarFinder).shape, null);

    final Finder materialFinder = find.byType(Material);
    Material getMaterialWidget(Finder finder) => tester.widget<Material>(finder);
    expect(getMaterialWidget(materialFinder).shape, null);
  });

  testWidgets('AppBar with shape', (WidgetTester tester) async {
    const RoundedRectangleBorder roundedRectangleBorder = RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(15.0))
    );
    await tester.pumpWidget(
      MaterialApp(
        home: AppBar(
          leading: const Text('L'),
          title: const Text('No Scaffold'),
          actions: const <Widget>[Text('A1'), Text('A2')],
          shape: roundedRectangleBorder,
        ),
      ),
    );

    final Finder appBarFinder = find.byType(AppBar);
    AppBar getAppBarWidget(Finder finder) => tester.widget<AppBar>(finder);
    expect(getAppBarWidget(appBarFinder).shape, roundedRectangleBorder);

    final Finder materialFinder = find.byType(Material);
    Material getMaterialWidget(Finder finder) => tester.widget<Material>(finder);
    expect(getMaterialWidget(materialFinder).shape, roundedRectangleBorder);
  });

  testWidgets('SliverAppBar shape default', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: CustomScrollView(
          slivers: <Widget>[
            SliverAppBar(
              leading: Text('L'),
              title: Text('No Scaffold'),
              actions: <Widget>[Text('A1'), Text('A2')],
            ),
          ],
        ),
      ),
    );

    final Finder sliverAppBarFinder = find.byType(SliverAppBar);
    SliverAppBar getSliverAppBarWidget(Finder finder) => tester.widget<SliverAppBar>(finder);
    expect(getSliverAppBarWidget(sliverAppBarFinder).shape, null);

    final Finder materialFinder = find.byType(Material);
    Material getMaterialWidget(Finder finder) => tester.widget<Material>(finder);
    expect(getMaterialWidget(materialFinder).shape, null);
  });

  testWidgets('SliverAppBar with shape', (WidgetTester tester) async {
    const RoundedRectangleBorder roundedRectangleBorder = RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(15.0)),
    );
    await tester.pumpWidget(
      const MaterialApp(
        home: CustomScrollView(
          slivers: <Widget>[
            SliverAppBar(
              leading: Text('L'),
              title: Text('No Scaffold'),
              actions: <Widget>[Text('A1'), Text('A2')],
              shape: roundedRectangleBorder,
            ),
          ],
        ),
      ),
    );

    final Finder sliverAppBarFinder = find.byType(SliverAppBar);
    SliverAppBar getSliverAppBarWidget(Finder finder) => tester.widget<SliverAppBar>(finder);
    expect(getSliverAppBarWidget(sliverAppBarFinder).shape, roundedRectangleBorder);

    final Finder materialFinder = find.byType(Material);
    Material getMaterialWidget(Finder finder) => tester.widget<Material>(finder);
    expect(getMaterialWidget(materialFinder).shape, roundedRectangleBorder);
  });

  testWidgets('AppBars title has upper limit on text scaling, textScaleFactor = 1, 1.34, 2', (WidgetTester tester) async {
    double textScaleFactor;

    Widget buildFrame() {
      return MaterialApp(
        home: Builder(
          builder: (BuildContext context) {
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(textScaleFactor: textScaleFactor),
              child: Scaffold(
                appBar: AppBar(
                  centerTitle: false,
                  title: const Text('Jumbo', style: TextStyle(fontSize: 18)),
                ),
              ),
            );
          },
        ),
      );
    }

    final Finder appBarTitle = find.text('Jumbo');

    textScaleFactor = 1;
    await tester.pumpWidget(buildFrame());
    expect(tester.getRect(appBarTitle).height, 18);

    textScaleFactor = 1.34;
    await tester.pumpWidget(buildFrame());
    expect(tester.getRect(appBarTitle).height, 24);

    textScaleFactor = 2;
    await tester.pumpWidget(buildFrame());
    expect(tester.getRect(appBarTitle).height, 24);
  });

  testWidgets('AppBars with jumbo titles, textScaleFactor = 3, 3.5, 4', (WidgetTester tester) async {
    double textScaleFactor;
    TextDirection textDirection;
    bool centerTitle;

    Widget buildFrame() {
      return MaterialApp(
        home: Builder(
          builder: (BuildContext context) {
            return Directionality(
              textDirection: textDirection,
              child: Builder(
                builder: (BuildContext context) {
                  return Scaffold(
                    appBar: AppBar(
                      centerTitle: centerTitle,
                      title: MediaQuery(
                        data: MediaQuery.of(context).copyWith(textScaleFactor: textScaleFactor),
                        child: const Text('Jumbo'),
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      );
    }

    final Finder appBarTitle = find.text('Jumbo');
    final Finder toolbar = find.byType(NavigationToolbar);

    // Overall screen size is 800x600
    // Left or right justified title is padded by 16 on the "start" side.
    // Toolbar height is 56.

    textScaleFactor = 1; // "Jumbo" title is 100x20.
    textDirection = TextDirection.ltr;
    centerTitle = false;
    await tester.pumpWidget(buildFrame());
    expect(tester.getRect(appBarTitle), const Rect.fromLTRB(16, 18, 116, 38));
    expect(tester.getCenter(appBarTitle).dy, tester.getCenter(toolbar).dy);

    textScaleFactor = 3; // "Jumbo" title is 300x60.
    await tester.pumpWidget(buildFrame());
    expect(tester.getRect(appBarTitle), const Rect.fromLTRB(16, -2, 316, 58));
    expect(tester.getCenter(appBarTitle).dy, tester.getCenter(toolbar).dy);

    textScaleFactor = 3.5; // "Jumbo" title is 350x70.
    await tester.pumpWidget(buildFrame());
    expect(tester.getRect(appBarTitle), const Rect.fromLTRB(16, -7, 366, 63));
    expect(tester.getCenter(appBarTitle).dy, tester.getCenter(toolbar).dy);

    textScaleFactor = 4; // "Jumbo" title is 400x80.
    await tester.pumpWidget(buildFrame());
    expect(tester.getRect(appBarTitle), const Rect.fromLTRB(16, -12, 416, 68));
    expect(tester.getCenter(appBarTitle).dy, tester.getCenter(toolbar).dy);

    textDirection = TextDirection.rtl; // Changed to rtl. "Jumbo" title is still 400x80.
    await tester.pumpWidget(buildFrame());
    expect(tester.getRect(appBarTitle), const Rect.fromLTRB(800.0 - 400.0 - 16.0, -12, 800.0 - 16.0, 68));
    expect(tester.getCenter(appBarTitle).dy, tester.getCenter(toolbar).dy);

    centerTitle = true; // Changed to true. "Jumbo" title is still 400x80.
    await tester.pumpWidget(buildFrame());
    expect(tester.getRect(appBarTitle), const Rect.fromLTRB(200, -12, 800.0 - 200.0, 68));
    expect(tester.getCenter(appBarTitle).dy, tester.getCenter(toolbar).dy);
  });

  testWidgets('AppBar respects toolbarHeight', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          appBar: AppBar(
            title: const Text('Title'),
            toolbarHeight: 48,
          ),
          body: Container(),
        ),
      )
    );

    expect(appBarHeight(tester), 48);
  });

  testWidgets('SliverAppBar default collapsedHeight with respect to toolbarHeight', (WidgetTester tester) async {
    const double toolbarHeight = 100.0;

    await tester.pumpWidget(buildSliverAppBarApp(
      floating: false,
      pinned: false,
      toolbarHeight: toolbarHeight,
    ));

    final ScrollController controller = primaryScrollController(tester);
    final double initialTabBarHeight = tabBarHeight(tester);

    // Scroll the not-pinned appbar out of view, to its collapsed height.
    controller.jumpTo(300.0);
    await tester.pump();
    expect(find.byType(SliverAppBar), findsNothing);
    // By default, the collapsedHeight is toolbarHeight + bottom.preferredSize.height,
    // in this case initialTabBarHeight.
    expect(appBarHeight(tester), toolbarHeight + initialTabBarHeight);
  });

  testWidgets('SliverAppBar collapsedHeight with toolbarHeight', (WidgetTester tester) async {
    const double toolbarHeight = 100.0;
    const double collapsedHeight = 150.0;

    await tester.pumpWidget(buildSliverAppBarApp(
      floating: false,
      pinned: false,
      toolbarHeight: toolbarHeight,
      collapsedHeight: collapsedHeight
    ));

    final ScrollController controller = primaryScrollController(tester);
    final double initialTabBarHeight = tabBarHeight(tester);

    // Scroll the not-pinned appbar out of view, to its collapsed height.
    controller.jumpTo(300.0);
    await tester.pump();
    expect(find.byType(SliverAppBar), findsNothing);
    expect(appBarHeight(tester), collapsedHeight + initialTabBarHeight);
  });

  test('SliverApp toolbarHeight cannot be null', () {
    try{
       SliverAppBar(
        toolbarHeight: null,
      );
    } on AssertionError catch (error) {
      expect(error.toString(), contains('toolbarHeight != null'));
      expect(error.toString(), contains('is not true'));
    }
  });

  testWidgets('AppBar respects leadingWidth', (WidgetTester tester) async {
    const Key key = Key('leading');
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          leading: const Placeholder(key: key),
          leadingWidth: 100,
          title: const Text('Title'),
        ),
      ),
    ));

    // By default toolbarHeight is 56.0.
    expect(tester.getRect(find.byKey(key)), const Rect.fromLTRB(0, 0, 100, 56));
  });

  testWidgets('SliverAppBar respects leadingWidth', (WidgetTester tester) async {
    const Key key = Key('leading');
    await tester.pumpWidget( const MaterialApp(
      home: CustomScrollView(
        slivers: <Widget>[
          SliverAppBar(
            leading: Placeholder(key: key),
            leadingWidth: 100,
            title: Text('Title'),
          ),
        ],
      )
    ));

    // By default toolbarHeight is 56.0.
    expect(tester.getRect(find.byKey(key)), const Rect.fromLTRB(0, 0, 100, 56));
  });
}
