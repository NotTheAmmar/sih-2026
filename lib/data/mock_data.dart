import '../models/catalog_item.dart';
import '../models/craft_attributes.dart';
import '../models/pricing_corridor.dart';

/// Pre-configured artisan demo payloads for hackathon presentation.
/// These represent authentic craft clusters across India.
class MockData {
  MockData._();

  static final List<CatalogItem> catalogs = [
    _chanderSilk,
    _terracottaPot,
    _brassLamp,
  ];

  // ── Payload 1: Chanderi Silk Dupatta ──────────────────────────────────────
  static final CatalogItem _chanderSilk = CatalogItem(
    id: 'mock_chanderi_001',
    createdAt: DateTime(2026, 9, 1),
    titleEn: 'Handwoven Chanderi Silk Dupatta with Gold Zari Border',
    titleHi: 'हाथ से बुनी चंदेरी सिल्क दुपट्टा, सोने की ज़री बॉर्डर के साथ',
    descriptionEn:
        'An exquisite handwoven Chanderi silk dupatta crafted by master weavers of Chanderi, Madhya Pradesh. '
        'Featuring pure mulberry silk warp with gold zari weft, this piece embodies centuries of Chanderi weaving tradition. '
        'Each dupatta takes 5 days of skilled labor to complete. '
        'Ideal for festive occasions and bridal trousseaux.',
    descriptionHi:
        'चंदेरी, मध्य प्रदेश के कुशल बुनकरों द्वारा बनाई गई एक उत्कृष्ट हाथ से बुनी चंदेरी सिल्क दुपट्टा। '
        'शुद्ध मलबरी सिल्क के ताने और सोने की ज़री के बाने से सजी यह दुपट्टा चंदेरी बुनाई की सदियों पुरानी परंपरा को दर्शाती है।',
    craftAttributes: const CraftAttributes(
      category: 'Handloom Silk',
      materials: ['Pure Mulberry Silk', 'Gold Zari', 'Cotton Weft'],
      laborDays: 5,
      clusterLocation: 'Chanderi, Madhya Pradesh',
      artisanName: 'Ramesh Kumar',
    ),
    pricing: PricingCorridor.compute(
      rawMaterialCost: 1100,
      laborDays: 5,
      dailyWageRate: 500,
    ),
    status: CatalogStatus.draft,
  );

  // ── Payload 2: Terracotta Flower Pot ─────────────────────────────────────
  static final CatalogItem _terracottaPot = CatalogItem(
    id: 'mock_terracotta_002',
    createdAt: DateTime(2026, 9, 2),
    titleEn: 'Hand-Painted Terracotta Flower Pot — Bishnupur Craft',
    titleHi: 'हाथ से पेंट किया गया टेराकोटा फूलदान — बिष्णुपुर शिल्प',
    descriptionEn:
        'A vibrant hand-painted terracotta flower pot from the Bishnupur craft cluster, West Bengal. '
        'Crafted from local red clay and fired in traditional kilns, then hand-painted with natural mineral pigments '
        'depicting Bengal\'s folk art motifs. Takes 3 days of dedicated crafting.',
    descriptionHi:
        'पश्चिम बंगाल के बिष्णुपुर शिल्प केंद्र से एक जीवंत हाथ से पेंट किया गया टेराकोटा फूलदान। '
        'स्थानीय लाल मिट्टी से बना और पारंपरिक भट्ठों में पकाया गया, फिर प्राकृतिक खनिज रंगों से बंगाल के लोक कला रूपांकनों से सजाया गया।',
    craftAttributes: const CraftAttributes(
      category: 'Terracotta Pottery',
      materials: ['Red Clay', 'Natural Mineral Pigments', 'Kiln Fired'],
      laborDays: 3,
      clusterLocation: 'Bishnupur, West Bengal',
      artisanName: 'Sumitra Devi',
    ),
    pricing: PricingCorridor.compute(
      rawMaterialCost: 150,
      laborDays: 3,
      dailyWageRate: 450,
    ),
    status: CatalogStatus.draft,
  );

  // ── Payload 3: Brass Filigree Lamp ────────────────────────────────────────
  static final CatalogItem _brassLamp = CatalogItem(
    id: 'mock_brass_003',
    createdAt: DateTime(2026, 9, 3),
    titleEn: 'Dhokra Brass Filigree Table Lamp — Bastar Tribal Art',
    titleHi: 'ढोकरा पीतल जालीदार टेबल लैंप — बस्तर जनजातीय कला',
    descriptionEn:
        'A stunning Dhokra brass filigree table lamp handcrafted using the ancient lost-wax casting technique '
        'by tribal artisans of Bastar, Odisha. Each piece is unique, featuring intricate geometric and '
        'nature-inspired filigree patterns. 7 days of skilled metalwork.',
    descriptionHi:
        'ओडिशा के बस्तर के आदिवासी कारीगरों द्वारा प्राचीन लॉस्ट-वैक्स कास्टिंग तकनीक से हस्तनिर्मित एक शानदार ढोकरा पीतल की जालीदार टेबल लैंप। '
        'प्रत्येक टुकड़ा अनोखा है, जिसमें जटिल ज्यामितीय और प्रकृति से प्रेरित जाली के पैटर्न हैं।',
    craftAttributes: const CraftAttributes(
      category: 'Dhokra Metal Craft',
      materials: ['Brass', 'Beeswax', 'Clay Mold', 'Copper Wire'],
      laborDays: 7,
      clusterLocation: 'Bastar, Odisha',
      artisanName: 'Mangal Singh',
    ),
    pricing: PricingCorridor.compute(
      rawMaterialCost: 800,
      laborDays: 7,
      dailyWageRate: 550,
    ),
    status: CatalogStatus.draft,
  );
}
