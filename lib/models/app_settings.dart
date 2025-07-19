import 'package:json_annotation/json_annotation.dart';

part 'app_settings.g.dart';

@JsonSerializable()
class AppSettings {
  final String storageLocation;
  final bool useCustomLocation;
  final String customPath;
  final String themeMode; // 'system', 'light', 'dark'
  final bool encryptionEnabled;
  final String? passwordHash; // Store hashed password, not plain text

  AppSettings({
    this.storageLocation = 'shared_preferences',
    this.useCustomLocation = false,
    this.customPath = '',
    this.themeMode = 'system',
    this.encryptionEnabled = false,
    this.passwordHash,
  });

  AppSettings copyWith({
    String? storageLocation,
    bool? useCustomLocation,
    String? customPath,
    String? themeMode,
    bool? encryptionEnabled,
    String? passwordHash,
  }) {
    return AppSettings(
      storageLocation: storageLocation ?? this.storageLocation,
      useCustomLocation: useCustomLocation ?? this.useCustomLocation,
      customPath: customPath ?? this.customPath,
      themeMode: themeMode ?? this.themeMode,
      encryptionEnabled: encryptionEnabled ?? this.encryptionEnabled,
      passwordHash: passwordHash ?? this.passwordHash,
    );
  }

  factory AppSettings.fromJson(Map<String, dynamic> json) =>
      _$AppSettingsFromJson(json);
  Map<String, dynamic> toJson() => _$AppSettingsToJson(this);
}
