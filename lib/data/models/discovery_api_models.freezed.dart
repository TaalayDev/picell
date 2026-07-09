// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'discovery_api_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

PromoAppItem _$PromoAppItemFromJson(Map<String, dynamic> json) {
  return _PromoAppItem.fromJson(json);
}

/// @nodoc
mixin _$PromoAppItem {
  @JsonKey(fromJson: DiscoveryConverters.intFromJson)
  int get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String? get tagline => throw _privateConstructorUsedError;
  @JsonKey(name: 'icon_url')
  String get iconUrl => throw _privateConstructorUsedError;
  @JsonKey(name: 'banner_url')
  String? get bannerUrl => throw _privateConstructorUsedError;
  @JsonKey(name: 'ios_url')
  String? get iosUrl => throw _privateConstructorUsedError;
  @JsonKey(name: 'android_url')
  String? get androidUrl => throw _privateConstructorUsedError;
  @JsonKey(name: 'web_url')
  String? get webUrl => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $PromoAppItemCopyWith<PromoAppItem> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PromoAppItemCopyWith<$Res> {
  factory $PromoAppItemCopyWith(
          PromoAppItem value, $Res Function(PromoAppItem) then) =
      _$PromoAppItemCopyWithImpl<$Res, PromoAppItem>;
  @useResult
  $Res call(
      {@JsonKey(fromJson: DiscoveryConverters.intFromJson) int id,
      String name,
      String? tagline,
      @JsonKey(name: 'icon_url') String iconUrl,
      @JsonKey(name: 'banner_url') String? bannerUrl,
      @JsonKey(name: 'ios_url') String? iosUrl,
      @JsonKey(name: 'android_url') String? androidUrl,
      @JsonKey(name: 'web_url') String? webUrl});
}

/// @nodoc
class _$PromoAppItemCopyWithImpl<$Res, $Val extends PromoAppItem>
    implements $PromoAppItemCopyWith<$Res> {
  _$PromoAppItemCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? tagline = freezed,
    Object? iconUrl = null,
    Object? bannerUrl = freezed,
    Object? iosUrl = freezed,
    Object? androidUrl = freezed,
    Object? webUrl = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      tagline: freezed == tagline
          ? _value.tagline
          : tagline // ignore: cast_nullable_to_non_nullable
              as String?,
      iconUrl: null == iconUrl
          ? _value.iconUrl
          : iconUrl // ignore: cast_nullable_to_non_nullable
              as String,
      bannerUrl: freezed == bannerUrl
          ? _value.bannerUrl
          : bannerUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      iosUrl: freezed == iosUrl
          ? _value.iosUrl
          : iosUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      androidUrl: freezed == androidUrl
          ? _value.androidUrl
          : androidUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      webUrl: freezed == webUrl
          ? _value.webUrl
          : webUrl // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$PromoAppItemImplCopyWith<$Res>
    implements $PromoAppItemCopyWith<$Res> {
  factory _$$PromoAppItemImplCopyWith(
          _$PromoAppItemImpl value, $Res Function(_$PromoAppItemImpl) then) =
      __$$PromoAppItemImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(fromJson: DiscoveryConverters.intFromJson) int id,
      String name,
      String? tagline,
      @JsonKey(name: 'icon_url') String iconUrl,
      @JsonKey(name: 'banner_url') String? bannerUrl,
      @JsonKey(name: 'ios_url') String? iosUrl,
      @JsonKey(name: 'android_url') String? androidUrl,
      @JsonKey(name: 'web_url') String? webUrl});
}

/// @nodoc
class __$$PromoAppItemImplCopyWithImpl<$Res>
    extends _$PromoAppItemCopyWithImpl<$Res, _$PromoAppItemImpl>
    implements _$$PromoAppItemImplCopyWith<$Res> {
  __$$PromoAppItemImplCopyWithImpl(
      _$PromoAppItemImpl _value, $Res Function(_$PromoAppItemImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? tagline = freezed,
    Object? iconUrl = null,
    Object? bannerUrl = freezed,
    Object? iosUrl = freezed,
    Object? androidUrl = freezed,
    Object? webUrl = freezed,
  }) {
    return _then(_$PromoAppItemImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      tagline: freezed == tagline
          ? _value.tagline
          : tagline // ignore: cast_nullable_to_non_nullable
              as String?,
      iconUrl: null == iconUrl
          ? _value.iconUrl
          : iconUrl // ignore: cast_nullable_to_non_nullable
              as String,
      bannerUrl: freezed == bannerUrl
          ? _value.bannerUrl
          : bannerUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      iosUrl: freezed == iosUrl
          ? _value.iosUrl
          : iosUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      androidUrl: freezed == androidUrl
          ? _value.androidUrl
          : androidUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      webUrl: freezed == webUrl
          ? _value.webUrl
          : webUrl // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$PromoAppItemImpl implements _PromoAppItem {
  const _$PromoAppItemImpl(
      {@JsonKey(fromJson: DiscoveryConverters.intFromJson) required this.id,
      required this.name,
      this.tagline,
      @JsonKey(name: 'icon_url') required this.iconUrl,
      @JsonKey(name: 'banner_url') this.bannerUrl,
      @JsonKey(name: 'ios_url') this.iosUrl,
      @JsonKey(name: 'android_url') this.androidUrl,
      @JsonKey(name: 'web_url') this.webUrl});

  factory _$PromoAppItemImpl.fromJson(Map<String, dynamic> json) =>
      _$$PromoAppItemImplFromJson(json);

  @override
  @JsonKey(fromJson: DiscoveryConverters.intFromJson)
  final int id;
  @override
  final String name;
  @override
  final String? tagline;
  @override
  @JsonKey(name: 'icon_url')
  final String iconUrl;
  @override
  @JsonKey(name: 'banner_url')
  final String? bannerUrl;
  @override
  @JsonKey(name: 'ios_url')
  final String? iosUrl;
  @override
  @JsonKey(name: 'android_url')
  final String? androidUrl;
  @override
  @JsonKey(name: 'web_url')
  final String? webUrl;

  @override
  String toString() {
    return 'PromoAppItem(id: $id, name: $name, tagline: $tagline, iconUrl: $iconUrl, bannerUrl: $bannerUrl, iosUrl: $iosUrl, androidUrl: $androidUrl, webUrl: $webUrl)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PromoAppItemImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.tagline, tagline) || other.tagline == tagline) &&
            (identical(other.iconUrl, iconUrl) || other.iconUrl == iconUrl) &&
            (identical(other.bannerUrl, bannerUrl) ||
                other.bannerUrl == bannerUrl) &&
            (identical(other.iosUrl, iosUrl) || other.iosUrl == iosUrl) &&
            (identical(other.androidUrl, androidUrl) ||
                other.androidUrl == androidUrl) &&
            (identical(other.webUrl, webUrl) || other.webUrl == webUrl));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, id, name, tagline, iconUrl,
      bannerUrl, iosUrl, androidUrl, webUrl);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$PromoAppItemImplCopyWith<_$PromoAppItemImpl> get copyWith =>
      __$$PromoAppItemImplCopyWithImpl<_$PromoAppItemImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PromoAppItemImplToJson(
      this,
    );
  }
}

abstract class _PromoAppItem implements PromoAppItem {
  const factory _PromoAppItem(
      {@JsonKey(fromJson: DiscoveryConverters.intFromJson)
      required final int id,
      required final String name,
      final String? tagline,
      @JsonKey(name: 'icon_url') required final String iconUrl,
      @JsonKey(name: 'banner_url') final String? bannerUrl,
      @JsonKey(name: 'ios_url') final String? iosUrl,
      @JsonKey(name: 'android_url') final String? androidUrl,
      @JsonKey(name: 'web_url') final String? webUrl}) = _$PromoAppItemImpl;

  factory _PromoAppItem.fromJson(Map<String, dynamic> json) =
      _$PromoAppItemImpl.fromJson;

  @override
  @JsonKey(fromJson: DiscoveryConverters.intFromJson)
  int get id;
  @override
  String get name;
  @override
  String? get tagline;
  @override
  @JsonKey(name: 'icon_url')
  String get iconUrl;
  @override
  @JsonKey(name: 'banner_url')
  String? get bannerUrl;
  @override
  @JsonKey(name: 'ios_url')
  String? get iosUrl;
  @override
  @JsonKey(name: 'android_url')
  String? get androidUrl;
  @override
  @JsonKey(name: 'web_url')
  String? get webUrl;
  @override
  @JsonKey(ignore: true)
  _$$PromoAppItemImplCopyWith<_$PromoAppItemImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

NewsItemModel _$NewsItemModelFromJson(Map<String, dynamic> json) {
  return _NewsItemModel.fromJson(json);
}

/// @nodoc
mixin _$NewsItemModel {
  @JsonKey(fromJson: DiscoveryConverters.intFromJson)
  int get id => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String get excerpt => throw _privateConstructorUsedError;
  @JsonKey(name: 'image_url')
  String? get imageUrl => throw _privateConstructorUsedError;
  @JsonKey(name: 'link_url')
  String? get linkUrl => throw _privateConstructorUsedError;
  @JsonKey(name: 'published_at')
  DateTime? get publishedAt => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $NewsItemModelCopyWith<NewsItemModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $NewsItemModelCopyWith<$Res> {
  factory $NewsItemModelCopyWith(
          NewsItemModel value, $Res Function(NewsItemModel) then) =
      _$NewsItemModelCopyWithImpl<$Res, NewsItemModel>;
  @useResult
  $Res call(
      {@JsonKey(fromJson: DiscoveryConverters.intFromJson) int id,
      String title,
      String excerpt,
      @JsonKey(name: 'image_url') String? imageUrl,
      @JsonKey(name: 'link_url') String? linkUrl,
      @JsonKey(name: 'published_at') DateTime? publishedAt});
}

/// @nodoc
class _$NewsItemModelCopyWithImpl<$Res, $Val extends NewsItemModel>
    implements $NewsItemModelCopyWith<$Res> {
  _$NewsItemModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? excerpt = null,
    Object? imageUrl = freezed,
    Object? linkUrl = freezed,
    Object? publishedAt = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      excerpt: null == excerpt
          ? _value.excerpt
          : excerpt // ignore: cast_nullable_to_non_nullable
              as String,
      imageUrl: freezed == imageUrl
          ? _value.imageUrl
          : imageUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      linkUrl: freezed == linkUrl
          ? _value.linkUrl
          : linkUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      publishedAt: freezed == publishedAt
          ? _value.publishedAt
          : publishedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$NewsItemModelImplCopyWith<$Res>
    implements $NewsItemModelCopyWith<$Res> {
  factory _$$NewsItemModelImplCopyWith(
          _$NewsItemModelImpl value, $Res Function(_$NewsItemModelImpl) then) =
      __$$NewsItemModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(fromJson: DiscoveryConverters.intFromJson) int id,
      String title,
      String excerpt,
      @JsonKey(name: 'image_url') String? imageUrl,
      @JsonKey(name: 'link_url') String? linkUrl,
      @JsonKey(name: 'published_at') DateTime? publishedAt});
}

/// @nodoc
class __$$NewsItemModelImplCopyWithImpl<$Res>
    extends _$NewsItemModelCopyWithImpl<$Res, _$NewsItemModelImpl>
    implements _$$NewsItemModelImplCopyWith<$Res> {
  __$$NewsItemModelImplCopyWithImpl(
      _$NewsItemModelImpl _value, $Res Function(_$NewsItemModelImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? excerpt = null,
    Object? imageUrl = freezed,
    Object? linkUrl = freezed,
    Object? publishedAt = freezed,
  }) {
    return _then(_$NewsItemModelImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      excerpt: null == excerpt
          ? _value.excerpt
          : excerpt // ignore: cast_nullable_to_non_nullable
              as String,
      imageUrl: freezed == imageUrl
          ? _value.imageUrl
          : imageUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      linkUrl: freezed == linkUrl
          ? _value.linkUrl
          : linkUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      publishedAt: freezed == publishedAt
          ? _value.publishedAt
          : publishedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$NewsItemModelImpl implements _NewsItemModel {
  const _$NewsItemModelImpl(
      {@JsonKey(fromJson: DiscoveryConverters.intFromJson) required this.id,
      required this.title,
      required this.excerpt,
      @JsonKey(name: 'image_url') this.imageUrl,
      @JsonKey(name: 'link_url') this.linkUrl,
      @JsonKey(name: 'published_at') this.publishedAt});

  factory _$NewsItemModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$NewsItemModelImplFromJson(json);

  @override
  @JsonKey(fromJson: DiscoveryConverters.intFromJson)
  final int id;
  @override
  final String title;
  @override
  final String excerpt;
  @override
  @JsonKey(name: 'image_url')
  final String? imageUrl;
  @override
  @JsonKey(name: 'link_url')
  final String? linkUrl;
  @override
  @JsonKey(name: 'published_at')
  final DateTime? publishedAt;

  @override
  String toString() {
    return 'NewsItemModel(id: $id, title: $title, excerpt: $excerpt, imageUrl: $imageUrl, linkUrl: $linkUrl, publishedAt: $publishedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$NewsItemModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.excerpt, excerpt) || other.excerpt == excerpt) &&
            (identical(other.imageUrl, imageUrl) ||
                other.imageUrl == imageUrl) &&
            (identical(other.linkUrl, linkUrl) || other.linkUrl == linkUrl) &&
            (identical(other.publishedAt, publishedAt) ||
                other.publishedAt == publishedAt));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType, id, title, excerpt, imageUrl, linkUrl, publishedAt);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$NewsItemModelImplCopyWith<_$NewsItemModelImpl> get copyWith =>
      __$$NewsItemModelImplCopyWithImpl<_$NewsItemModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$NewsItemModelImplToJson(
      this,
    );
  }
}

abstract class _NewsItemModel implements NewsItemModel {
  const factory _NewsItemModel(
          {@JsonKey(fromJson: DiscoveryConverters.intFromJson)
          required final int id,
          required final String title,
          required final String excerpt,
          @JsonKey(name: 'image_url') final String? imageUrl,
          @JsonKey(name: 'link_url') final String? linkUrl,
          @JsonKey(name: 'published_at') final DateTime? publishedAt}) =
      _$NewsItemModelImpl;

  factory _NewsItemModel.fromJson(Map<String, dynamic> json) =
      _$NewsItemModelImpl.fromJson;

  @override
  @JsonKey(fromJson: DiscoveryConverters.intFromJson)
  int get id;
  @override
  String get title;
  @override
  String get excerpt;
  @override
  @JsonKey(name: 'image_url')
  String? get imageUrl;
  @override
  @JsonKey(name: 'link_url')
  String? get linkUrl;
  @override
  @JsonKey(name: 'published_at')
  DateTime? get publishedAt;
  @override
  @JsonKey(ignore: true)
  _$$NewsItemModelImplCopyWith<_$NewsItemModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
