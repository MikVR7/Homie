import 'package:json_annotation/json_annotation.dart';

part 'file_organizer_models.g.dart';

@JsonSerializable()
class FileItem {
  final String name;
  final String path;
  final String type;
  final int size;
  final DateTime lastModified;
  final String? suggestedLocation;

  FileItem({
    required this.name,
    required this.path,
    required this.type,
    required this.size,
    required this.lastModified,
    this.suggestedLocation,
  });

  factory FileItem.fromJson(Map<String, dynamic> json) => _$FileItemFromJson(json);
  Map<String, dynamic> toJson() => _$FileItemToJson(this);
}

@JsonSerializable()
class OrganizationRule {
  final String id;
  final String name;
  final String pattern;
  final String destination;
  final String type;
  final bool enabled;
  final DateTime createdAt;

  OrganizationRule({
    required this.id,
    required this.name,
    required this.pattern,
    required this.destination,
    required this.type,
    required this.enabled,
    required this.createdAt,
  });

  factory OrganizationRule.fromJson(Map<String, dynamic> json) => _$OrganizationRuleFromJson(json);
  Map<String, dynamic> toJson() => _$OrganizationRuleToJson(this);
}

@JsonSerializable()
class OrganizationStats {
  final int totalFiles;
  final int organizedFiles;
  final int rulesCount;
  final Map<String, int> fileTypeBreakdown;
  final DateTime lastOrganized;

  OrganizationStats({
    required this.totalFiles,
    required this.organizedFiles,
    required this.rulesCount,
    required this.fileTypeBreakdown,
    required this.lastOrganized,
  });

  factory OrganizationStats.fromJson(Map<String, dynamic> json) => _$OrganizationStatsFromJson(json);
  Map<String, dynamic> toJson() => _$OrganizationStatsToJson(this);
} 