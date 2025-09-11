// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'file_organizer_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FileItem _$FileItemFromJson(Map<String, dynamic> json) => FileItem(
  name: json['name'] as String,
  path: json['path'] as String,
  type: json['type'] as String,
  size: (json['size'] as num).toInt(),
  lastModified: DateTime.parse(json['lastModified'] as String),
  suggestedLocation: json['suggestedLocation'] as String?,
);

Map<String, dynamic> _$FileItemToJson(FileItem instance) => <String, dynamic>{
  'name': instance.name,
  'path': instance.path,
  'type': instance.type,
  'size': instance.size,
  'lastModified': instance.lastModified.toIso8601String(),
  'suggestedLocation': instance.suggestedLocation,
};

OrganizationRule _$OrganizationRuleFromJson(Map<String, dynamic> json) =>
    OrganizationRule(
      id: json['id'] as String,
      name: json['name'] as String,
      pattern: json['pattern'] as String,
      destination: json['destination'] as String,
      type: json['type'] as String,
      enabled: json['enabled'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$OrganizationRuleToJson(OrganizationRule instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'pattern': instance.pattern,
      'destination': instance.destination,
      'type': instance.type,
      'enabled': instance.enabled,
      'createdAt': instance.createdAt.toIso8601String(),
    };

OrganizationStats _$OrganizationStatsFromJson(Map<String, dynamic> json) =>
    OrganizationStats(
      totalFiles: (json['totalFiles'] as num).toInt(),
      organizedFiles: (json['organizedFiles'] as num).toInt(),
      rulesCount: (json['rulesCount'] as num).toInt(),
      fileTypeBreakdown: Map<String, int>.from(
        json['fileTypeBreakdown'] as Map,
      ),
      lastOrganized: DateTime.parse(json['lastOrganized'] as String),
    );

Map<String, dynamic> _$OrganizationStatsToJson(OrganizationStats instance) =>
    <String, dynamic>{
      'totalFiles': instance.totalFiles,
      'organizedFiles': instance.organizedFiles,
      'rulesCount': instance.rulesCount,
      'fileTypeBreakdown': instance.fileTypeBreakdown,
      'lastOrganized': instance.lastOrganized.toIso8601String(),
    };
