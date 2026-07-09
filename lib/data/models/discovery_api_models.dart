import 'package:freezed_annotation/freezed_annotation.dart';

part 'discovery_api_models.freezed.dart';
part 'discovery_api_models.g.dart';

@freezed
abstract class PromoAppItem with _$PromoAppItem {
  const factory PromoAppItem({
    @JsonKey(fromJson: DiscoveryConverters.intFromJson) required int id,
    required String name,
    String? tagline,
    @JsonKey(name: 'icon_url') required String iconUrl,
    @JsonKey(name: 'banner_url') String? bannerUrl,
    @JsonKey(name: 'ios_url') String? iosUrl,
    @JsonKey(name: 'android_url') String? androidUrl,
    @JsonKey(name: 'web_url') String? webUrl,
  }) = _PromoAppItem;

  factory PromoAppItem.fromJson(Map<String, dynamic> json) => _$PromoAppItemFromJson(json);
}

@freezed
abstract class NewsItemModel with _$NewsItemModel {
  const factory NewsItemModel({
    @JsonKey(fromJson: DiscoveryConverters.intFromJson) required int id,
    required String title,
    required String excerpt,
    @JsonKey(name: 'image_url') String? imageUrl,
    @JsonKey(name: 'link_url') String? linkUrl,
    @JsonKey(name: 'published_at') DateTime? publishedAt,
  }) = _NewsItemModel;

  factory NewsItemModel.fromJson(Map<String, dynamic> json) => _$NewsItemModelFromJson(json);
}

class DiscoveryConverters {
  static List<PromoAppItem> promoApps(dynamic data) {
    return (data['apps'] as List).map((item) => PromoAppItem.fromJson(item)).toList();
  }

  static List<NewsItemModel> newsItems(dynamic data) {
    return (data['news'] as List).map((item) => NewsItemModel.fromJson(item)).toList();
  }

  static int intFromJson(dynamic data) {
    if (data is int) {
      return data;
    } else if (data is String) {
      return int.tryParse(data) ?? 0;
    }
    return 0;
  }
}
