// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'discovery_api_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PromoAppItemImpl _$$PromoAppItemImplFromJson(Map<String, dynamic> json) =>
    _$PromoAppItemImpl(
      id: DiscoveryConverters.intFromJson(json['id']),
      name: json['name'] as String,
      tagline: json['tagline'] as String?,
      iconUrl: json['icon_url'] as String,
      bannerUrl: json['banner_url'] as String?,
      iosUrl: json['ios_url'] as String?,
      androidUrl: json['android_url'] as String?,
      webUrl: json['web_url'] as String?,
    );

Map<String, dynamic> _$$PromoAppItemImplToJson(_$PromoAppItemImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'tagline': instance.tagline,
      'icon_url': instance.iconUrl,
      'banner_url': instance.bannerUrl,
      'ios_url': instance.iosUrl,
      'android_url': instance.androidUrl,
      'web_url': instance.webUrl,
    };

_$NewsItemModelImpl _$$NewsItemModelImplFromJson(Map<String, dynamic> json) =>
    _$NewsItemModelImpl(
      id: DiscoveryConverters.intFromJson(json['id']),
      title: json['title'] as String,
      excerpt: json['excerpt'] as String,
      imageUrl: json['image_url'] as String?,
      linkUrl: json['link_url'] as String?,
      publishedAt: json['published_at'] == null
          ? null
          : DateTime.parse(json['published_at'] as String),
    );

Map<String, dynamic> _$$NewsItemModelImplToJson(_$NewsItemModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'excerpt': instance.excerpt,
      'image_url': instance.imageUrl,
      'link_url': instance.linkUrl,
      'published_at': instance.publishedAt?.toIso8601String(),
    };
