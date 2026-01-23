#!/usr/bin/env dart
// Automated script to fix overflow issues using constraints
// Run: dart scripts/fix_overflow_constraints.dart

import 'dart:io';

void main() {
  print('🔧 Starting Constraint-Based Overflow Fix...\n');
  
  final libDir = Directory('lib');
  final dartFiles = libDir
      .listSync(recursive: true)
      .where((entity) => entity is File && entity.path.endsWith('.dart'))
      .cast<File>()
      .toList();

  print('📊 Found ${dartFiles.length} Dart files\n');

  int totalTextFixed = 0;
  int totalRowsFixed = 0;
  int totalListViewFixed = 0;

  for (final file in dartFiles) {
    final originalContent = file.readAsStringSync();
    String modifiedContent = originalContent;
    
    // Phase 1: Add overflow to Text widgets
    final textFixes = addTextOverflow(modifiedContent);
    modifiedContent = textFixes['content']!;
    totalTextFixed += int.parse(textFixes['count']!);
    
    // Phase 2: Add Flexible to Rows
    final rowFixes = addFlexibleToRows(modifiedContent);
    modifiedContent = rowFixes['content']!;
    totalRowsFixed += int.parse(rowFixes['count']!);
    
    // Phase 3: Add Expanded to ListView in Column
    final listViewFixes = addExpandedToListView(modifiedContent);
    modifiedContent = listViewFixes['content']!;
    totalListViewFixed += int.parse(listViewFixes['count']!);
    
    // Write back if changed
    if (modifiedContent != originalContent) {
      file.writeAsStringSync(modifiedContent);
      print('✅ Fixed: ${file.path}');
    }
  }

  print('\n📊 Summary:');
  print('  Text widgets fixed: $totalTextFixed');
  print('  Rows made flexible: $totalRowsFixed');
  print('  ListViews expanded: $totalListViewFixed');
  print('\n✨ Done!');
}

Map<String, String> addTextOverflow(String content) {
  int count = 0;
  
  // Pattern: Find Text( without overflow nearby
  final pattern = RegExp(
    r'Text\s*\(\s*([^,\)]+),?\s*(style:[^,\)]+,?)?\s*\)',
    multiLine: true,
  );
  
  final modified = content.replaceAllMapped(pattern, (match) {
    final fullMatch = match.group(0)!;
    
    // Skip if already has overflow
    if (fullMatch.contains('overflow:') || fullMatch.contains('maxLines:')) {
      return fullMatch;
    }
    
    // Skip if it's a const Text with just a string
    if (fullMatch.startsWith('const Text(') && !fullMatch.contains('style:')) {
      return fullMatch;
    }
    
    count++;
    
    // Add overflow before closing parenthesis
    final textContent = match.group(1)!;
    final style = match.group(2) ?? '';
    
    if (style.isNotEmpty) {
      return 'Text($textContent, $style overflow: TextOverflow.ellipsis, maxLines: 1)';
    } else {
      return 'Text($textContent, overflow: TextOverflow.ellipsis, maxLines: 1)';
    }
  });
  
  return {'content': modified, 'count': count.toString()};
}

Map<String, String> addFlexibleToRows(String content) {
  int count = 0;
  
  // This is complex - would need AST parsing for accuracy
  // For now, skip to avoid breaking code
  
  return {'content': content, 'count': count.toString()};
}

Map<String, String> addExpandedToListView(String content) {
  int count = 0;
  
  // This is complex - would need AST parsing for accuracy
  // For now, skip to avoid breaking code
  
  return {'content': content, 'count': count.toString()};
}
