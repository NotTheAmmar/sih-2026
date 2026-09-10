import 'craft_attributes.dart';
import 'pricing_corridor.dart';

enum CatalogStatus {
  draft,
  storedLocally,
  published,
}

class CatalogItem {
  final String id;
  final DateTime createdAt;

  // Media
  final String? rawImagePath;
  final String? studioImagePath; // teammate's model output will go here
  final String? audioPath;

  // Bilingual descriptors
  final String? titleEn;
  final String? titleHi;
  final String? descriptionEn;
  final String? descriptionHi;

  // Craft attributes
  final CraftAttributes? craftAttributes;

  // Pricing
  final PricingCorridor? pricing;

  // TTS readback URL/path (from Bhashini or flutter_tts)
  final String? audioReadbackPath;

  // Status
  final CatalogStatus status;

  const CatalogItem({
    required this.id,
    required this.createdAt,
    this.rawImagePath,
    this.studioImagePath,
    this.audioPath,
    this.titleEn,
    this.titleHi,
    this.descriptionEn,
    this.descriptionHi,
    this.craftAttributes,
    this.pricing,
    this.audioReadbackPath,
    this.status = CatalogStatus.draft,
  });

  CatalogItem copyWith({
    String? id,
    DateTime? createdAt,
    String? rawImagePath,
    String? studioImagePath,
    String? audioPath,
    String? titleEn,
    String? titleHi,
    String? descriptionEn,
    String? descriptionHi,
    CraftAttributes? craftAttributes,
    PricingCorridor? pricing,
    String? audioReadbackPath,
    CatalogStatus? status,
  }) {
    return CatalogItem(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      rawImagePath: rawImagePath ?? this.rawImagePath,
      studioImagePath: studioImagePath ?? this.studioImagePath,
      audioPath: audioPath ?? this.audioPath,
      titleEn: titleEn ?? this.titleEn,
      titleHi: titleHi ?? this.titleHi,
      descriptionEn: descriptionEn ?? this.descriptionEn,
      descriptionHi: descriptionHi ?? this.descriptionHi,
      craftAttributes: craftAttributes ?? this.craftAttributes,
      pricing: pricing ?? this.pricing,
      audioReadbackPath: audioReadbackPath ?? this.audioReadbackPath,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'createdAt': createdAt.toIso8601String(),
        'rawImagePath': rawImagePath,
        'studioImagePath': studioImagePath,
        'audioPath': audioPath,
        'titleEn': titleEn,
        'titleHi': titleHi,
        'descriptionEn': descriptionEn,
        'descriptionHi': descriptionHi,
        'craftAttributes': craftAttributes?.toJson(),
        'pricing': pricing?.toJson(),
        'audioReadbackPath': audioReadbackPath,
        'status': status.name,
      };

  factory CatalogItem.fromJson(Map<String, dynamic> json) => CatalogItem(
        id: json['id'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        rawImagePath: json['rawImagePath'] as String?,
        studioImagePath: json['studioImagePath'] as String?,
        audioPath: json['audioPath'] as String?,
        titleEn: json['titleEn'] as String?,
        titleHi: json['titleHi'] as String?,
        descriptionEn: json['descriptionEn'] as String?,
        descriptionHi: json['descriptionHi'] as String?,
        craftAttributes: json['craftAttributes'] != null
            ? CraftAttributes.fromJson(
                json['craftAttributes'] as Map<String, dynamic>)
            : null,
        pricing: json['pricing'] != null
            ? PricingCorridor.fromJson(json['pricing'] as Map<String, dynamic>)
            : null,
        audioReadbackPath: json['audioReadbackPath'] as String?,
        status: CatalogStatus.values.byName(
            (json['status'] as String?) ?? CatalogStatus.draft.name),
      );
}
