import '../../core/config/app_config.dart';
import '../../mock/mock_data.dart';
import '../../mock/mock_image_search.dart';
import '../../models/image_search_result.dart';
import '../image_search_repository.dart';

/// Always "recognises" the demo product, whatever photo is picked.
class MockImageSearchRepository implements ImageSearchRepository {
  MockImageSearchRepository({this.latency = AppConfig.mockLatency});

  final Duration latency;

  Future<T> _delay<T>(T value) => Future<T>.delayed(latency, () => value);

  @override
  Future<List<String>> getSampleImages() => _delay(MockImageSearch.sampleImages);

  @override
  Future<List<String>> getQuickRequests() => _delay(MockImageSearch.quickRequests);

  @override
  Future<ImageSearchResult> analyzeImage({required String imageUrl, required String request}) {
    final product = MockProducts.all.firstWhere((p) => p.id == MockImageSearch.recognizedProductId);
    final similar = MockProducts.all.where((p) => p.categoryId == product.categoryId && p.id != product.id).toList();
    return _delay(
      ImageSearchResult(
        imageUrl: imageUrl,
        request: request,
        product: product,
        accuracyPercent: MockImageSearch.accuracyPercent,
        tags: MockImageSearch.recognizedTags,
        similarProducts: similar,
        reasons: MockImageSearch.reasons,
      ),
    );
  }
}
