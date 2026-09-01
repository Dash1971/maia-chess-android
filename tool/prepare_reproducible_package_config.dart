import 'dart:convert';
import 'dart:io';

const _generatedPackageName = 'mobile_maia_generated';

void main(List<String> arguments) {
  if (arguments.length != 1) {
    stderr.writeln(
      'Usage: dart tool/prepare_reproducible_package_config.dart '
      '<package_config.json>',
    );
    exitCode = 64;
    return;
  }

  final configFile = File(arguments.single);
  final decoded = jsonDecode(configFile.readAsStringSync());
  if (decoded is! Map<String, dynamic> || decoded['configVersion'] != 2) {
    throw const FormatException('Expected package_config.json version 2');
  }

  final rawPackages = decoded['packages'];
  if (rawPackages is! List<dynamic>) {
    throw const FormatException('Missing packages list');
  }

  final packages = rawPackages.whereType<Map<String, dynamic>>().toList();
  if (packages.length != rawPackages.length) {
    throw const FormatException('Invalid package entry');
  }

  final appPackage = packages.cast<Map<String, dynamic>?>().firstWhere(
    (package) => package?['name'] == 'maia_chess',
    orElse: () => null,
  );
  if (appPackage == null || appPackage['languageVersion'] is! String) {
    throw const FormatException('Missing maia_chess package entry');
  }

  packages.removeWhere((package) => package['name'] == _generatedPackageName);
  packages.add(<String, dynamic>{
    'name': _generatedPackageName,
    'rootUri': 'flutter_build/',
    'packageUri': './',
    'languageVersion': appPackage['languageVersion'],
  });
  decoded['packages'] = packages;

  configFile.writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert(decoded)}\n',
  );
}
