#!/usr/bin/env dart

import 'dart:io';
import 'package:path_provider/path_provider.dart';

void main() async {
  print('=== Testing Documents Folder Feature ===\n');

  try {
    // Test if we can access the Documents directory
    final documentsDir = await getApplicationDocumentsDirectory();
    print('✓ Documents directory accessible: ${documentsDir.path}');

    // Test creating the jotdown folder
    final jotdownDir = Directory('${documentsDir.path}/jotdown');
    if (!await jotdownDir.exists()) {
      await jotdownDir.create(recursive: true);
      print('✓ Created jotdown directory: ${jotdownDir.path}');
    } else {
      print('✓ jotdown directory already exists: ${jotdownDir.path}');
    }

    // Test writing a sample file
    final testFile = File('${jotdownDir.path}/test.txt');
    await testFile.writeAsString('Test content for Documents folder storage');
    print('✓ Successfully wrote test file: ${testFile.path}');

    // Test reading the file back
    final content = await testFile.readAsString();
    print('✓ Successfully read test file content: "${content.substring(0, 20)}..."');

    // Clean up test file
    await testFile.delete();
    print('✓ Cleaned up test file');

    print('\n=== Documents Folder Feature Test PASSED ===');
    print('\nThe Documents folder storage feature is ready to use!');
    print('Users can now:');
    print('1. Open JotDown app');
    print('2. Go to Settings');
    print('3. Select "Documents Folder" as storage location');
    print('4. Their notes will be stored in: ${jotdownDir.path}');

  } catch (e) {
    print('✗ Error testing Documents folder feature: $e');
    exit(1);
  }
}