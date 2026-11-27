import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rutinitasku/features/documents/data/services/document_file_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late DocumentFileService service;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('document_file_service_');
    service = DocumentFileService(baseDir: tempDir.path);
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  Future<File> createSourceFile(String name, String content) async {
    final dir = await Directory.systemTemp.createTemp('document_source_');
    addTearDown(() async {
      if (await dir.exists()) await dir.delete(recursive: true);
    });
    final file = File('${dir.path}/$name');
    await file.writeAsString(content);
    return file;
  }

  group('listFiles', () {
    test(
      'membuat direktori group dan hanya mengembalikan berkas non-JSON',
      () async {
        final dir = await service.ensureGroupDirectory('g1');
        await File('${dir.path}/catatan.txt').writeAsString('hello');
        await File('${dir.path}/metadata.json').writeAsString('{}');
        await Directory('${dir.path}/subfolder').create();

        final files = await service.listFiles('g1');

        expect(files.map((f) => service.fileName(f)), ['catatan.txt']);
        expect(await service.countFiles('g1'), 1);
      },
    );

    test(
      'group tanpa direktori mengembalikan daftar kosong dan membuat direktori',
      () async {
        final files = await service.listFiles('baru');

        expect(files, isEmpty);
        expect(await service.groupDirectory('baru').exists(), isTrue);
      },
    );

    test('countFiles tidak membuat direktori group yang belum ada', () async {
      expect(await service.countFiles('belum_ada'), 0);
      expect(await service.groupDirectory('belum_ada').exists(), isFalse);
    });
  });

  group('path relatif dan absolut', () {
    test(
      'relativePath menghasilkan path dengan pemisah / dan resolve mengembalikan berkas yang sama',
      () async {
        final dir = await service.ensureGroupDirectory('g1');
        final file = File('${dir.path}/laporan.pdf');
        await file.writeAsString('pdf');

        final relative = service.relativePath('g1', file);

        expect(relative, 'laporan.pdf');
        expect(service.resolveRelativePath('g1', relative).path, file.path);
        expect(service.resolvePath('g1', 'laporan.pdf').path, file.path);
        expect(service.resolvePath('g1', file.path).path, file.path);
      },
    );
  });

  group('importFile', () {
    test(
      'impor biasa menyalin berkas dan mempertahankan waktu modifikasi',
      () async {
        final source = await createSourceFile('catatan.txt', 'isi awal');
        final modified = DateTime(2024, 1, 2, 3, 4, 5);
        await source.setLastModified(modified);

        final imported = await service.importFile(
          groupId: 'g1',
          sourceFile: source,
          fileName: 'catatan.txt',
        );

        expect(imported, isNotNull);
        expect(await imported!.readAsString(), 'isi awal');
        expect(
          (await imported.lastModified()).millisecondsSinceEpoch,
          modified.millisecondsSinceEpoch,
        );
        expect(await source.exists(), isTrue);
      },
    );

    test(
      'nama bentrok dengan keepBoth menghasilkan akhiran (1) lalu (2)',
      () async {
        final source = await createSourceFile('catatan.txt', 'isi');
        final first = await service.importFile(
          groupId: 'g1',
          sourceFile: source,
          fileName: 'catatan.txt',
        );
        final second = await service.importFile(
          groupId: 'g1',
          sourceFile: source,
          fileName: 'catatan.txt',
        );
        final third = await service.importFile(
          groupId: 'g1',
          sourceFile: source,
          fileName: 'catatan.txt',
        );

        expect(service.fileName(first!), 'catatan.txt');
        expect(service.fileName(second!), 'catatan (1).txt');
        expect(service.fileName(third!), 'catatan (2).txt');
      },
    );

    test('nama bentrok dengan overwrite menimpa berkas lama', () async {
      final firstSource = await createSourceFile('catatan.txt', 'lama');
      final secondSource = await createSourceFile('catatan.txt', 'baru');
      await service.importFile(
        groupId: 'g1',
        sourceFile: firstSource,
        fileName: 'catatan.txt',
      );

      final imported = await service.importFile(
        groupId: 'g1',
        sourceFile: secondSource,
        fileName: 'catatan.txt',
        conflictPolicy: DocumentNameConflictPolicy.overwrite,
      );

      expect(service.fileName(imported!), 'catatan.txt');
      expect(await imported.readAsString(), 'baru');
      expect(await service.countFiles('g1'), 1);
    });

    test('nama bentrok dengan cancel tidak menyalin apa pun', () async {
      final firstSource = await createSourceFile('catatan.txt', 'lama');
      final secondSource = await createSourceFile('catatan.txt', 'baru');
      await service.importFile(
        groupId: 'g1',
        sourceFile: firstSource,
        fileName: 'catatan.txt',
      );

      final imported = await service.importFile(
        groupId: 'g1',
        sourceFile: secondSource,
        fileName: 'catatan.txt',
        conflictPolicy: DocumentNameConflictPolicy.cancel,
      );

      expect(imported, isNull);
      expect(await service.countFiles('g1'), 1);
      final remaining = await service.listFiles('g1');
      expect(await remaining.single.readAsString(), 'lama');
    });
  });

  group('renameFile', () {
    test('mengubah nama berkas di group', () async {
      final dir = await service.ensureGroupDirectory('g1');
      final file = File('${dir.path}/lama.txt');
      await file.writeAsString('isi');

      final renamed = await service.renameFile(
        groupId: 'g1',
        file: file,
        newFileName: 'baru.txt',
      );

      expect(renamed, isNotNull);
      expect(service.fileName(renamed!), 'baru.txt');
      expect(await file.exists(), isFalse);
      expect(await renamed.exists(), isTrue);
    });

    test('nama tujuan yang sudah dipakai tidak ditimpa', () async {
      final dir = await service.ensureGroupDirectory('g1');
      final file = File('${dir.path}/lama.txt');
      final existing = File('${dir.path}/baru.txt');
      await file.writeAsString('lama');
      await existing.writeAsString('baru');

      final renamed = await service.renameFile(
        groupId: 'g1',
        file: file,
        newFileName: 'baru.txt',
      );

      expect(renamed, isNull);
      expect(await file.readAsString(), 'lama');
      expect(await existing.readAsString(), 'baru');
    });
  });

  group('moveFile', () {
    test(
      'memindahkan berkas ke group lain dan membuat direktori tujuan',
      () async {
        final dir = await service.ensureGroupDirectory('g1');
        final file = File('${dir.path}/catatan.txt');
        await file.writeAsString('isi');

        final moved = await service.moveFile(file: file, targetGroupId: 'g2');

        expect(moved, isNotNull);
        expect(moved!.parent.path, service.groupDirectory('g2').path);
        expect(await moved.exists(), isTrue);
        expect(await file.exists(), isFalse);
        expect(await moved.readAsString(), 'isi');
      },
    );

    test(
      'nama bentrok di tujuan tidak menimpa berkas yang sudah ada',
      () async {
        final sourceDir = await service.ensureGroupDirectory('g1');
        final targetDir = await service.ensureGroupDirectory('g2');
        final source = File('${sourceDir.path}/catatan.txt');
        final existing = File('${targetDir.path}/catatan.txt');
        await source.writeAsString('pindah');
        await existing.writeAsString('tetap');

        final moved = await service.moveFile(file: source, targetGroupId: 'g2');

        expect(moved, isNotNull);
        expect(service.fileName(moved!), isNot('catatan.txt'));
        expect(await existing.readAsString(), 'tetap');
        expect(await moved.readAsString(), 'pindah');
        expect(await service.countFiles('g2'), 2);
      },
    );
  });

  group('delete', () {
    test('deleteFile dan deleteFiles menghapus berkas fisik', () async {
      final dir = await service.ensureGroupDirectory('g1');
      final a = File('${dir.path}/a.txt');
      final b = File('${dir.path}/b.txt');
      await a.writeAsString('a');
      await b.writeAsString('b');

      expect(await service.deleteFile(a), isTrue);
      expect(await a.exists(), isFalse);
      expect(await service.deleteFiles([b, File('${dir.path}/hilang.txt')]), 1);
      expect(await service.countFiles('g1'), 0);
    });

    test(
      'deleteGroupDirectory menghapus seluruh isi secara rekursif',
      () async {
        final dir = await service.ensureGroupDirectory('g1');
        final nested = Directory('${dir.path}/sub');
        await nested.create();
        await File('${nested.path}/dalam.txt').writeAsString('x');
        await File('${dir.path}/root.txt').writeAsString('y');

        await service.deleteGroupDirectory('g1');

        expect(await dir.exists(), isFalse);
      },
    );
  });
}
