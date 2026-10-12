import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_strings.dart';
import '../../../models/image_search_result.dart';
import '../../../repositories/repository_providers.dart';

enum ImageSearchStatus { idle, analyzing, success, error }

class ImageSearchState {
  const ImageSearchState({
    this.imageUrl,
    this.note = '',
    this.quickRequests = const {},
    this.status = ImageSearchStatus.idle,
    this.completedSteps = 0,
    this.result,
    this.errorMessage,
  });

  final String? imageUrl;
  final String note;
  final Set<String> quickRequests;
  final ImageSearchStatus status;

  /// Number of finished steps in [AppStrings.imageSearchSteps].
  final int completedSteps;
  final ImageSearchResult? result;
  final String? errorMessage;

  /// Free text and selected quick chips combined, e.g. "màu trắng, Chính hãng".
  String get request => [if (note.trim().isNotEmpty) note.trim(), ...quickRequests].join(', ');

  ImageSearchState copyWith({
    String? imageUrl,
    String? note,
    Set<String>? quickRequests,
    ImageSearchStatus? status,
    int? completedSteps,
    ImageSearchResult? result,
    String? errorMessage,
  }) {
    return ImageSearchState(
      imageUrl: imageUrl ?? this.imageUrl,
      note: note ?? this.note,
      quickRequests: quickRequests ?? this.quickRequests,
      status: status ?? this.status,
      completedSteps: completedSteps ?? this.completedSteps,
      result: result ?? this.result,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class ImageSearchController extends Notifier<ImageSearchState> {
  static const Duration stepDuration = Duration(milliseconds: 450);

  int _requestId = 0;

  @override
  ImageSearchState build() => const ImageSearchState();

  void selectImage(String imageUrl) {
    _requestId++;
    state = ImageSearchState(imageUrl: imageUrl, note: state.note, quickRequests: state.quickRequests);
  }

  void setNote(String note) => state = state.copyWith(note: note);

  void toggleQuickRequest(String label) {
    final selected = {...state.quickRequests};
    if (!selected.remove(label)) selected.add(label);
    state = state.copyWith(quickRequests: selected);
  }

  Future<void> analyze() async {
    final imageUrl = state.imageUrl;
    if (imageUrl == null) return;

    final requestId = ++_requestId;
    state = ImageSearchState(
      imageUrl: imageUrl,
      note: state.note,
      quickRequests: state.quickRequests,
      status: ImageSearchStatus.analyzing,
    );

    final pending = AsyncValue.guard(
      () => ref.read(imageSearchRepositoryProvider).analyzeImage(imageUrl: imageUrl, request: state.request),
    );

    for (var step = 1; step < AppStrings.imageSearchSteps.length; step++) {
      await Future<void>.delayed(stepDuration);
      if (requestId != _requestId) return;
      state = state.copyWith(completedSteps: step);
    }

    final outcome = await pending;
    if (requestId != _requestId) return;

    final result = outcome.value;
    if (outcome.hasError || result == null) {
      state = state.copyWith(
        status: ImageSearchStatus.error,
        errorMessage: outcome.error?.toString() ?? 'Không thể phân tích hình ảnh.',
      );
      return;
    }
    await Future<void>.delayed(stepDuration);
    if (requestId != _requestId) return;
    state = state.copyWith(
      status: ImageSearchStatus.success,
      completedSteps: AppStrings.imageSearchSteps.length,
      result: result,
    );
  }

  void reset() {
    _requestId++;
    state = const ImageSearchState();
  }
}

final imageSearchProvider = NotifierProvider<ImageSearchController, ImageSearchState>(ImageSearchController.new);

final imageSampleImagesProvider = FutureProvider<List<String>>(
  (ref) => ref.watch(imageSearchRepositoryProvider).getSampleImages(),
);

final imageQuickRequestsProvider = FutureProvider<List<String>>(
  (ref) => ref.watch(imageSearchRepositoryProvider).getQuickRequests(),
);
