// Splits a combined templates JSON array into one file per template.
//
// Usage: dart run tool/split_templates.dart [input] [outputDir]
// Defaults: tool/templates.json -> assets/data/templates/
//
// Writes <slug>.json per template plus index.json (ordered list of file
// names) which TemplateService reads at runtime.
import 'dart:convert';
import 'dart:io';

void main(List<String> args) {
  final input = File(args.isNotEmpty ? args[0] : 'tool/templates.json');
  final outDir = Directory(args.length > 1 ? args[1] : 'assets/data/templates');

  if (!input.existsSync()) {
    stderr.writeln('Input not found: ${input.path}');
    exit(1);
  }

  final list = json.decode(input.readAsStringSync()) as List<dynamic>;
  if (outDir.existsSync()) {
    for (final f in outDir.listSync().whereType<File>().where((f) => f.path.endsWith('.json'))) {
      f.deleteSync();
    }
  }
  outDir.createSync(recursive: true);

  final used = <String>{};
  final files = <String>[];
  for (final item in list) {
    final template = item as Map<String, dynamic>;
    final base = _slug(template['name'] as String);
    var slug = base;
    for (var i = 2; !used.add(slug); i++) {
      slug = '${base}_$i';
    }
    final fileName = '$slug.json';
    File('${outDir.path}/$fileName').writeAsStringSync(json.encode(template));
    files.add(fileName);
  }

  File('${outDir.path}/index.json').writeAsStringSync(const JsonEncoder.withIndent(' ').convert(files));
  stdout.writeln('Wrote ${files.length} templates to ${outDir.path}');
}

String _slug(String name) {
  final s = name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_').replaceAll(RegExp(r'^_+|_+$'), '');
  return s.isEmpty ? 'template' : s;
}
