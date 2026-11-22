// Runs the real Rust core through the real FFI bridge, inside the Flutter test runner:
//   xvfb-run flutter test integration_test -d linux
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:slys/src/rust/api/operations.dart';
import 'package:slys/src/rust/api/storage.dart';
import 'package:slys/src/rust/api/version.dart';
import 'package:slys/src/rust/frb_generated.dart';

Future<OperationEvent> finalEvent(Stream<OperationEvent> s) async {
  OperationEvent? last;
  await for (final e in s) {
    if (e is! OperationEvent_Progress) last = e;
  }
  return last!;
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async => await RustLib.init());

  test('version info comes from the core', () {
    final v = versionInfo();
    expect(v.version, matches(RegExp(r'^\d+\.\d+\.\d+')));
    expect(v.seedFormat, 2);
  });

  test('fragment -> recompose roundtrip through the bridge', () async {
    final tmp = await Directory.systemTemp.createTemp('slys_it_');
    addTearDown(() => tmp.delete(recursive: true));
    final data = Uint8List.fromList(List.generate(200000, (i) => (i * 31) % 251));
    final input = File('${tmp.path}/secret.bin')..writeAsBytesSync(data);

    final progress = <OperationEvent_Progress>[];
    final frag = fragment(
      req: FragmentRequest(
        inputPath: input.path,
        outputDir: '${tmp.path}/frags',
        password: 'correct horse',
        mode: EncryptionMode.full,
        parts: 6,
        deleteOriginal: DeletePolicy.wipe,
      ),
    );
    OperationEvent? last;
    await for (final e in frag) {
      if (e is OperationEvent_Progress) {
        progress.add(e);
      } else {
        last = e;
      }
    }
    expect(last, isA<OperationEvent_Fragmented>());
    final outcome = (last as OperationEvent_Fragmented).field0;
    expect(outcome.fragmentCount, 6);
    expect(outcome.originalDeleted, isTrue);
    expect(input.existsSync(), isFalse);
    expect(progress, isNotEmpty);
    expect(inspectSeed(text: outcome.seed), SeedKind.v2);

    // wrong password: clear error, nothing written, fragments still there
    final bad = await finalEvent(recompose(
      req: RecomposeRequest(
        seed: outcome.seed,
        password: 'wrong',
        fragmentsDir: '${tmp.path}/frags',
        outputDir: '${tmp.path}/out',
        overwrite: false,
        deleteFragments: DeletePolicy.wipe,
      ),
    ));
    expect(bad, isA<OperationEvent_Failed>());
    expect((bad as OperationEvent_Failed).field0.code, 'wrong_password');
    expect(Directory('${tmp.path}/frags').listSync().length, 6);

    final ok = await finalEvent(recompose(
      req: RecomposeRequest(
        seed: outcome.seed,
        password: 'correct horse',
        fragmentsDir: '${tmp.path}/frags',
        outputDir: '${tmp.path}/out',
        overwrite: false,
        deleteFragments: DeletePolicy.wipe,
      ),
    ));
    expect(ok, isA<OperationEvent_Recomposed>());
    final out = File((ok as OperationEvent_Recomposed).field0.outputPath);
    expect(out.readAsBytesSync(), data);
    expect(Directory('${tmp.path}/frags').listSync(), isEmpty);
  });

  test('a mistyped seed is rejected before any password is needed', () {
    expect(
      () => inspectSeed(text: 'SLYS2.AAAA.00000000'),
      throwsA(isA<SlysError>()),
    );
  });

  test('seed list add/list/remove', () async {
    final tmp = await Directory.systemTemp.createTemp('slys_cfg_');
    addTearDown(() => tmp.delete(recursive: true));
    // The vault honours SLYS_CONFIG_DIR only when set before the process starts,
    // so here we just exercise the default location non-destructively.
    final before = seedsList().length;
    final added = seedsAdd(seed: 'test-seed-${DateTime.now().microsecondsSinceEpoch}');
    expect(seedsList().length, before + 1);
    expect(seedsRemove(id: added.id), isTrue);
    expect(seedsList().length, before);
  });
}
