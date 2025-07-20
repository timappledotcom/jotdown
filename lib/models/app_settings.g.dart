// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_settings.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AppSettings _$AppSettingsFromJson(Map<String, dynamic> json) => AppSettings(
      storageLocation:
          json['storageLocation'] as String? ?? 'shared_preferences',
      useCustomLocation: json['useCustomLocation'] as bool? ?? false,
      customPath: json['customPath'] as String? ?? '',
      themeMode: json['themeMode'] as String? ?? 'system',
      encryptionEnabled: json['encryptionEnabled'] as bool? ?? false,
      passwordHash: json['passwordHash'] as String?,
    );

Map<String, dynamic> _$AppSettingsToJson(AppSettings instance) =>
    <String, dynamic>{
      'storageLocation': instance.storageLocation,
      'useCustomLocation': instance.useCustomLocation,
      'customPath': instance.customPath,
      'themeMode': instance.themeMode,
      'encryptionEnabled': instance.encryptionEnabled,
      'passwordHash': instance.passwordHash,
    };
