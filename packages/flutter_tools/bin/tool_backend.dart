// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert'; // ignore: dart_convert_import.
import 'dart:io'; // ignore: dart_io_import.
import 'package:path/path.dart' as path; // ignore: package_path_import.

/// Executes the required flutter tasks for a desktop build.
Future<void> main(List<String> arguments) async {
  final String targetPlatform = arguments[0];
  final String buildMode = arguments[1].toLowerCase();

  final String dartDefines = Platform.environment['DART_DEFINES'];
  final bool dartObfuscation = Platform.environment['DART_OBFUSCATION'] == 'true';
  final String extraFrontEndOptions = Platform.environment['EXTRA_FRONT_END_OPTIONS'];
  final String extraGenSnapshotOptions = Platform.environment['EXTRA_GEN_SNAPSHOT_OPTIONS'];
  final String flutterEngine = Platform.environment['FLUTTER_ENGINE'];
  final String flutterRoot = Platform.environment['FLUTTER_ROOT'];
  final String flutterTarget = Platform.environment['FLUTTER_TARGET']
    ?? path.join('lib', 'main.dart');
  final String localEngine = Platform.environment['LOCAL_ENGINE'];
  final String projectDirectory = Platform.environment['PROJECT_DIR'];
  final String splitDebugInfo = Platform.environment['SPLIT_DEBUG_INFO'];
  final String bundleSkSLPath = Platform.environment['BUNDLE_SKSL_PATH'];
  final bool trackWidgetCreation = Platform.environment['TRACK_WIDGET_CREATION'] == 'true';
  final bool treeShakeIcons = Platform.environment['TREE_SHAKE_ICONS'] == 'true';
  final bool verbose = Platform.environment['VERBOSE_SCRIPT_LOGGING'] == 'true';

  Directory.current = projectDirectory;

  if (localEngine != null && !localEngine.contains(buildMode)) {
    stderr.write('''
ERROR: Requested build with Flutter local engine at '$localEngine'
This engine is not compatible with FLUTTER_BUILD_MODE: '$buildMode'.
You can fix this by updating the LOCAL_ENGINE environment variable, or
by running:
  flutter build <platform> --local-engine=host_$buildMode
or
  flutter build <platform> --local-engine=host_${buildMode}_unopt
========================================================================
''');
    exit(1);
  }

  final String flutterExecutable = path.join(
    flutterRoot, 'bin', Platform.isWindows ? 'flutter.bat' : 'flutter');
  final String bundlePlatform = targetPlatform == 'windows-x64' ? 'windows' : 'linux';
  final String target = '${buildMode}_bundle_${bundlePlatform}_assets';

  final Process assembleProcess = await Process.start(
    flutterExecutable,
    <String>[
      if (verbose)
        '--verbose',
      if (flutterEngine != null) '--local-engine-src-path=$flutterEngine',
      if (localEngine != null) '--local-engine=$localEngine',
      'assemble',
      '--output=build',
      '-dTargetPlatform=$targetPlatform',
      '-dTrackWidgetCreation=$trackWidgetCreation',
      '-dBuildMode=$buildMode',
      '-dTargetFile=$flutterTarget',
      '-dTreeShakeIcons="$treeShakeIcons"',
      '-dDartObfuscation=$dartObfuscation',
      if (bundleSkSLPath != null)
        '-iBundleSkSLPath=$bundleSkSLPath',
      if (splitDebugInfo != null)
        '-dSplitDebugInfo=$splitDebugInfo',
      if (dartDefines != null)
        '--DartDefines=$dartDefines',
      if (extraGenSnapshotOptions != null)
        '--ExtraGenSnapshotOptions=$extraGenSnapshotOptions',
      if (extraFrontEndOptions != null)
        '--ExtraFrontEndOptions=$extraFrontEndOptions',
      target,
    ],
  );
  assembleProcess.stdout
    .transform(utf8.decoder)
    .transform(const LineSplitter())
    .listen(stdout.writeln);
  assembleProcess.stderr
    .transform(utf8.decoder)
    .transform(const LineSplitter())
    .listen(stderr.writeln);

  if (await assembleProcess.exitCode != 0) {
    exit(1);
  }
}
