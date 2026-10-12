import '../models/marketplace.dart';

abstract final class MockMarketplaces {
  static const Marketplace shopee = Marketplace(id: 'mk-shopee', code: MarketplaceCode.shopee, name: 'Shopee');

  static const Marketplace tiktokShop = Marketplace(
    id: 'mk-tiktok',
    code: MarketplaceCode.tiktokShop,
    name: 'TikTok Shop',
  );

  static const Marketplace lazada = Marketplace(id: 'mk-lazada', code: MarketplaceCode.lazada, name: 'Lazada');

  static const Marketplace tiki = Marketplace(id: 'mk-tiki', code: MarketplaceCode.tiki, name: 'Tiki');

  static const List<Marketplace> all = [shopee, tiktokShop, lazada, tiki];

  static Marketplace byCode(MarketplaceCode code) => all.firstWhere((m) => m.code == code);
}
