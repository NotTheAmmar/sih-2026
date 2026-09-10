class CraftAttributes {
  final String? category; // e.g. "Handloom Silk Sarees"
  final List<String> materials; // e.g. ["Pure Mulberry Silk", "Gold Zari"]
  final int? laborDays; // Parsed from voice
  final String? clusterLocation; // e.g. "Chanderi, Madhya Pradesh"
  final String? artisanName;

  const CraftAttributes({
    this.category,
    this.materials = const [],
    this.laborDays,
    this.clusterLocation,
    this.artisanName,
  });

  CraftAttributes copyWith({
    String? category,
    List<String>? materials,
    int? laborDays,
    String? clusterLocation,
    String? artisanName,
  }) {
    return CraftAttributes(
      category: category ?? this.category,
      materials: materials ?? this.materials,
      laborDays: laborDays ?? this.laborDays,
      clusterLocation: clusterLocation ?? this.clusterLocation,
      artisanName: artisanName ?? this.artisanName,
    );
  }

  Map<String, dynamic> toJson() => {
        'category': category,
        'materials': materials,
        'laborDays': laborDays,
        'clusterLocation': clusterLocation,
        'artisanName': artisanName,
      };

  factory CraftAttributes.fromJson(Map<String, dynamic> json) =>
      CraftAttributes(
        category: json['category'] as String?,
        materials: (json['materials'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            [],
        laborDays: json['laborDays'] as int?,
        clusterLocation: json['clusterLocation'] as String?,
        artisanName: json['artisanName'] as String?,
      );
}
