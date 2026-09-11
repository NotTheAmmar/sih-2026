import 'dart:io';

void main() {
  final file = File('lib/services/api_service.dart');
  String content = file.readAsStringSync();

  // Add abstract method
  content = content.replaceFirst(
    '  factory ApiService() {',
    '''  Future<Map<String, dynamic>> publishToOndc({
    required CatalogItem item,
    required PricingCorridor pricing,
    required int availableQuantity,
  });

  factory ApiService() {'''
  );

  // Add mock method
  content = content.replaceFirst(
    'class MockApiService implements ApiService {',
    '''class MockApiService implements ApiService {
  @override
  Future<Map<String, dynamic>> publishToOndc({
    required CatalogItem item,
    required PricingCorridor pricing,
    required int availableQuantity,
  }) async {
    await Future.delayed(const Duration(seconds: 1, milliseconds: 500));
    return {
      'status': 'PUBLISHED',
      'catalog_id': item.id,
      'message': 'Mock successful publish'
    };
  }
'''
  );

  // Add import to top
  content = content.replaceFirst(
    'import \'../models/pricing_corridor.dart\';',
    '''import '../models/pricing_corridor.dart';
import '../models/catalog_item.dart';'''
  );
  
  // Add live method
  content = content.replaceFirst(
    'class LiveApiService implements ApiService {',
    '''class LiveApiService implements ApiService {
  @override
  Future<Map<String, dynamic>> publishToOndc({
    required CatalogItem item,
    required PricingCorridor pricing,
    required int availableQuantity,
  }) async {
    final uri = Uri.parse('\${AppConstants.bppBackendUrl}/api/v1/bpp/publish');
    
    final body = {
      'catalog_id': item.id,
      'artisan_name': item.craftAttributes?.artisanName ?? 'KalaKriti Artisan',
      'cluster_name': item.craftAttributes?.clusterLocation ?? 'Chanderi Handloom Cluster',
      'title_en': item.titleEn ?? '',
      'title_hi': item.titleHi ?? '',
      'description_en': item.descriptionEn ?? '',
      'description_hi': item.descriptionHi ?? '',
      'craft_category': item.craftAttributes?.category ?? 'Handloom Silk',
      'category_id': 'ONDC:RET12',
      'materials': item.craftAttributes?.materials ?? [],
      'dimensions': item.craftAttributes?.dimensions ?? '1 unit',
      'floor_price': pricing.floorPrice.toDouble(),
      'fair_price': pricing.fairPrice.toDouble(),
      'premium_price': pricing.premiumPrice.toDouble(),
      'studio_image_url': item.studioImagePath ?? 'https://images.unsplash.com/photo-1610030469983-98e550d6193c',
      'available_qty': availableQuantity,
    };

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json', 'bypass-tunnel-reminder': 'true'},
      body: jsonEncode(body),
    ).timeout(AppConstants.apiTimeout);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Publish failed (\${response.statusCode}): \${response.body}');
    }
  }
'''
  );

  file.writeAsStringSync(content);
}
