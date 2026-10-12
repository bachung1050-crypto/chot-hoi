import '../models/image_search_result.dart';

abstract interface class ImageSearchRepository {
  Future<List<String>> getSampleImages();

  Future<List<String>> getQuickRequests();

  Future<ImageSearchResult> analyzeImage({required String imageUrl, required String request});
}
