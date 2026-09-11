class CraftAttributes {
  final String? category;
  final List<String> materials;
  final int? laborDays;
  final String? clusterLocation;
  final String? artisanName;
  final String? dimensions; // e.g. "6.2 meters"

  // ONDC Mandatory Critical
  final String? categoryId;
  final String? fulfillmentId;
  final String? locationId;
  final int quantity;
  final String? timeToShip;
  final bool returnable;
  final bool cancellable;
  final bool availableOnCod;
  final String? returnWindow;

  // ONDC Mandatory Informational
  final String? countryOfOrigin;
  final String? netQuantity;
  final String? genericName;

  const CraftAttributes({
    this.category,
    this.materials = const [],
    this.laborDays,
    this.clusterLocation,
    this.artisanName,
    this.dimensions,
    this.categoryId,
    this.fulfillmentId,
    this.locationId,
    this.quantity = 1,
    this.timeToShip,
    this.returnable = true,
    this.cancellable = true,
    this.availableOnCod = true,
    this.returnWindow,
    this.countryOfOrigin,
    this.netQuantity,
    this.genericName,
  });

  CraftAttributes copyWith({
    String? category,
    List<String>? materials,
    int? laborDays,
    String? clusterLocation,
    String? artisanName,
    String? dimensions,
    String? categoryId,
    String? fulfillmentId,
    String? locationId,
    int? quantity,
    String? timeToShip,
    bool? returnable,
    bool? cancellable,
    bool? availableOnCod,
    String? returnWindow,
    String? countryOfOrigin,
    String? netQuantity,
    String? genericName,
  }) {
    return CraftAttributes(
      category: category ?? this.category,
      materials: materials ?? this.materials,
      laborDays: laborDays ?? this.laborDays,
      clusterLocation: clusterLocation ?? this.clusterLocation,
      artisanName: artisanName ?? this.artisanName,
      dimensions: dimensions ?? this.dimensions,
      categoryId: categoryId ?? this.categoryId,
      fulfillmentId: fulfillmentId ?? this.fulfillmentId,
      locationId: locationId ?? this.locationId,
      quantity: quantity ?? this.quantity,
      timeToShip: timeToShip ?? this.timeToShip,
      returnable: returnable ?? this.returnable,
      cancellable: cancellable ?? this.cancellable,
      availableOnCod: availableOnCod ?? this.availableOnCod,
      returnWindow: returnWindow ?? this.returnWindow,
      countryOfOrigin: countryOfOrigin ?? this.countryOfOrigin,
      netQuantity: netQuantity ?? this.netQuantity,
      genericName: genericName ?? this.genericName,
    );
  }

  Map<String, dynamic> toJson() => {
        'category': category,
        'materials': materials,
        'laborDays': laborDays,
        'clusterLocation': clusterLocation,
        'artisanName': artisanName,
        'dimensions': dimensions,
        'categoryId': categoryId,
        'fulfillmentId': fulfillmentId,
        'locationId': locationId,
        'quantity': quantity,
        'timeToShip': timeToShip,
        'returnable': returnable,
        'cancellable': cancellable,
        'availableOnCod': availableOnCod,
        'returnWindow': returnWindow,
        'countryOfOrigin': countryOfOrigin,
        'netQuantity': netQuantity,
        'genericName': genericName,
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
        dimensions: json['dimensions'] as String?,
        categoryId: json['categoryId'] as String?,
        fulfillmentId: json['fulfillmentId'] as String?,
        locationId: json['locationId'] as String?,
        quantity: json['quantity'] as int? ?? 1,
        timeToShip: json['timeToShip'] as String?,
        returnable: json['returnable'] as bool? ?? true,
        cancellable: json['cancellable'] as bool? ?? true,
        availableOnCod: json['availableOnCod'] as bool? ?? true,
        returnWindow: json['returnWindow'] as String?,
        countryOfOrigin: json['countryOfOrigin'] as String?,
        netQuantity: json['netQuantity'] as String?,
        genericName: json['genericName'] as String?,
      );
}
