// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'media_item_model.dart';

// **************************************************************************
// IsarEmbeddedGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

const MediaItemModelSchema = Schema(
  name: r'MediaItemModel',
  id: 2871752563331528645,
  properties: {
    r'checksum': PropertySchema(
      id: 0,
      name: r'checksum',
      type: IsarType.string,
    ),
    r'downloadDate': PropertySchema(
      id: 1,
      name: r'downloadDate',
      type: IsarType.dateTime,
    ),
    r'downloaded': PropertySchema(
      id: 2,
      name: r'downloaded',
      type: IsarType.bool,
    ),
    r'effects': PropertySchema(
      id: 3,
      name: r'effects',
      type: IsarType.object,
      target: r'MediaEffectsModel',
    ),
    r'fileSize': PropertySchema(
      id: 4,
      name: r'fileSize',
      type: IsarType.long,
    ),
    r'layout': PropertySchema(
      id: 5,
      name: r'layout',
      type: IsarType.object,
      target: r'MediaLayoutModel',
    ),
    r'localPath': PropertySchema(
      id: 6,
      name: r'localPath',
      type: IsarType.string,
    ),
    r'mediaId': PropertySchema(
      id: 7,
      name: r'mediaId',
      type: IsarType.long,
    ),
    r'mediaName': PropertySchema(
      id: 8,
      name: r'mediaName',
      type: IsarType.string,
    ),
    r'mediaType': PropertySchema(
      id: 9,
      name: r'mediaType',
      type: IsarType.string,
    ),
    r'mediaUrl': PropertySchema(
      id: 10,
      name: r'mediaUrl',
      type: IsarType.string,
    ),
    r'mimetype': PropertySchema(
      id: 11,
      name: r'mimetype',
      type: IsarType.string,
    ),
    r'nTimePlay': PropertySchema(
      id: 12,
      name: r'nTimePlay',
      type: IsarType.long,
    ),
    r'order': PropertySchema(
      id: 13,
      name: r'order',
      type: IsarType.long,
    ),
    r'timing': PropertySchema(
      id: 14,
      name: r'timing',
      type: IsarType.object,
      target: r'MediaTimingModel',
    )
  },
  estimateSize: _mediaItemModelEstimateSize,
  serialize: _mediaItemModelSerialize,
  deserialize: _mediaItemModelDeserialize,
  deserializeProp: _mediaItemModelDeserializeProp,
);

int _mediaItemModelEstimateSize(
  MediaItemModel object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.checksum.length * 3;
  {
    final value = object.effects;
    if (value != null) {
      bytesCount += 3 +
          MediaEffectsModelSchema.estimateSize(
              value, allOffsets[MediaEffectsModel]!, allOffsets);
    }
  }
  {
    final value = object.layout;
    if (value != null) {
      bytesCount += 3 +
          MediaLayoutModelSchema.estimateSize(
              value, allOffsets[MediaLayoutModel]!, allOffsets);
    }
  }
  {
    final value = object.localPath;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.mediaName.length * 3;
  bytesCount += 3 + object.mediaType.length * 3;
  bytesCount += 3 + object.mediaUrl.length * 3;
  bytesCount += 3 + object.mimetype.length * 3;
  {
    final value = object.timing;
    if (value != null) {
      bytesCount += 3 +
          MediaTimingModelSchema.estimateSize(
              value, allOffsets[MediaTimingModel]!, allOffsets);
    }
  }
  return bytesCount;
}

void _mediaItemModelSerialize(
  MediaItemModel object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.checksum);
  writer.writeDateTime(offsets[1], object.downloadDate);
  writer.writeBool(offsets[2], object.downloaded);
  writer.writeObject<MediaEffectsModel>(
    offsets[3],
    allOffsets,
    MediaEffectsModelSchema.serialize,
    object.effects,
  );
  writer.writeLong(offsets[4], object.fileSize);
  writer.writeObject<MediaLayoutModel>(
    offsets[5],
    allOffsets,
    MediaLayoutModelSchema.serialize,
    object.layout,
  );
  writer.writeString(offsets[6], object.localPath);
  writer.writeLong(offsets[7], object.mediaId);
  writer.writeString(offsets[8], object.mediaName);
  writer.writeString(offsets[9], object.mediaType);
  writer.writeString(offsets[10], object.mediaUrl);
  writer.writeString(offsets[11], object.mimetype);
  writer.writeLong(offsets[12], object.nTimePlay);
  writer.writeLong(offsets[13], object.order);
  writer.writeObject<MediaTimingModel>(
    offsets[14],
    allOffsets,
    MediaTimingModelSchema.serialize,
    object.timing,
  );
}

MediaItemModel _mediaItemModelDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = MediaItemModel(
    checksum: reader.readStringOrNull(offsets[0]) ?? '',
    downloadDate: reader.readDateTimeOrNull(offsets[1]),
    downloaded: reader.readBoolOrNull(offsets[2]) ?? false,
    effects: reader.readObjectOrNull<MediaEffectsModel>(
      offsets[3],
      MediaEffectsModelSchema.deserialize,
      allOffsets,
    ),
    fileSize: reader.readLongOrNull(offsets[4]) ?? 0,
    layout: reader.readObjectOrNull<MediaLayoutModel>(
      offsets[5],
      MediaLayoutModelSchema.deserialize,
      allOffsets,
    ),
    localPath: reader.readStringOrNull(offsets[6]),
    mediaId: reader.readLongOrNull(offsets[7]) ?? 0,
    mediaName: reader.readStringOrNull(offsets[8]) ?? '',
    mediaType: reader.readStringOrNull(offsets[9]) ?? '',
    mediaUrl: reader.readStringOrNull(offsets[10]) ?? '',
    mimetype: reader.readStringOrNull(offsets[11]) ?? '',
    nTimePlay: reader.readLongOrNull(offsets[12]) ?? 1,
    order: reader.readLongOrNull(offsets[13]) ?? 0,
    timing: reader.readObjectOrNull<MediaTimingModel>(
      offsets[14],
      MediaTimingModelSchema.deserialize,
      allOffsets,
    ),
  );
  return object;
}

P _mediaItemModelDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readStringOrNull(offset) ?? '') as P;
    case 1:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 2:
      return (reader.readBoolOrNull(offset) ?? false) as P;
    case 3:
      return (reader.readObjectOrNull<MediaEffectsModel>(
        offset,
        MediaEffectsModelSchema.deserialize,
        allOffsets,
      )) as P;
    case 4:
      return (reader.readLongOrNull(offset) ?? 0) as P;
    case 5:
      return (reader.readObjectOrNull<MediaLayoutModel>(
        offset,
        MediaLayoutModelSchema.deserialize,
        allOffsets,
      )) as P;
    case 6:
      return (reader.readStringOrNull(offset)) as P;
    case 7:
      return (reader.readLongOrNull(offset) ?? 0) as P;
    case 8:
      return (reader.readStringOrNull(offset) ?? '') as P;
    case 9:
      return (reader.readStringOrNull(offset) ?? '') as P;
    case 10:
      return (reader.readStringOrNull(offset) ?? '') as P;
    case 11:
      return (reader.readStringOrNull(offset) ?? '') as P;
    case 12:
      return (reader.readLongOrNull(offset) ?? 1) as P;
    case 13:
      return (reader.readLongOrNull(offset) ?? 0) as P;
    case 14:
      return (reader.readObjectOrNull<MediaTimingModel>(
        offset,
        MediaTimingModelSchema.deserialize,
        allOffsets,
      )) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

extension MediaItemModelQueryFilter
    on QueryBuilder<MediaItemModel, MediaItemModel, QFilterCondition> {
  QueryBuilder<MediaItemModel, MediaItemModel, QAfterFilterCondition>
      checksumEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'checksum',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MediaItemModel, MediaItemModel, QAfterFilterCondition>
      checksumGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'checksum',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MediaItemModel, MediaItemModel, QAfterFilterCondition>
      checksumLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'checksum',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MediaItemModel, MediaItemModel, QAfterFilterCondition>
      checksumBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'checksum',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MediaItemModel, MediaItemModel, QAfterFilterCondition>
      checksumStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'checksum',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MediaItemModel, MediaItemModel, QAfterFilterCondition>
      checksumEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'checksum',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MediaItemModel, MediaItemModel, QAfterFilterCondition>
      checksumContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'checksum',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MediaItemModel, MediaItemModel, QAfterFilterCondition>
      checksumMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'checksum',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MediaItemModel, MediaItemModel, QAfterFilterCondition>
      checksumIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'checksum',
        value: '',
      ));
    });
  }

  QueryBuilder<MediaItemModel, MediaItemModel, QAfterFilterCondition>
      checksumIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'checksum',
        value: '',
      ));
    });
  }

  QueryBuilder<MediaItemModel, MediaItemModel, QAfterFilterCondition>
      downloadDateIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'downloadDate',
      ));
    });
  }

  QueryBuilder<MediaItemModel, MediaItemModel, QAfterFilterCondition>
      downloadDateIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'downloadDate',
      ));
    });
  }

  QueryBuilder<MediaItemModel, MediaItemModel, QAfterFilterCondition>
      downloadDateEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'downloadDate',
        value: value,
      ));
    });
  }

  QueryBuilder<MediaItemModel, MediaItemModel, QAfterFilterCondition>
      downloadDateGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'downloadDate',
        value: value,
      ));
    });
  }

  QueryBuilder<MediaItemModel, MediaItemModel, QAfterFilterCondition>
      downloadDateLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'downloadDate',
        value: value,
      ));
    });
  }

  QueryBuilder<MediaItemModel, MediaItemModel, QAfterFilterCondition>
      downloadDateBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'downloadDate',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<MediaItemModel, MediaItemModel, QAfterFilterCondition>
      downloadedEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'downloaded',
        value: value,
      ));
    });
  }

  QueryBuilder<MediaItemModel, MediaItemModel, QAfterFilterCondition>
      effectsIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'effects',
      ));
    });
  }

  QueryBuilder<MediaItemModel, MediaItemModel, QAfterFilterCondition>
      effectsIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'effects',
      ));
    });
  }

  QueryBuilder<MediaItemModel, MediaItemModel, QAfterFilterCondition>
      fileSizeEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'fileSize',
        value: value,
      ));
    });
  }

  QueryBuilder<MediaItemModel, MediaItemModel, QAfterFilterCondition>
      fileSizeGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'fileSize',
        value: value,
      ));
    });
  }

  QueryBuilder<MediaItemModel, MediaItemModel, QAfterFilterCondition>
      fileSizeLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'fileSize',
        value: value,
      ));
    });
  }

  QueryBuilder<MediaItemModel, MediaItemModel, QAfterFilterCondition>
      fileSizeBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'fileSize',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<MediaItemModel, MediaItemModel, QAfterFilterCondition>
      layoutIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'layout',
      ));
    });
  }

  QueryBuilder<MediaItemModel, MediaItemModel, QAfterFilterCondition>
      layoutIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'layout',
      ));
    });
  }

  QueryBuilder<MediaItemModel, MediaItemModel, QAfterFilterCondition>
      localPathIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'localPath',
      ));
    });
  }

  QueryBuilder<MediaItemModel, MediaItemModel, QAfterFilterCondition>
      localPathIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'localPath',
      ));
    });
  }

  QueryBuilder<MediaItemModel, MediaItemModel, QAfterFilterCondition>
      localPathEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'localPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MediaItemModel, MediaItemModel, QAfterFilterCondition>
      localPathGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'localPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MediaItemModel, MediaItemModel, QAfterFilterCondition>
      localPathLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'localPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MediaItemModel, MediaItemModel, QAfterFilterCondition>
      localPathBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'localPath',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MediaItemModel, MediaItemModel, QAfterFilterCondition>
      localPathStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'localPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MediaItemModel, MediaItemModel, QAfterFilterCondition>
      localPathEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'localPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MediaItemModel, MediaItemModel, QAfterFilterCondition>
      localPathContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'localPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MediaItemModel, MediaItemModel, QAfterFilterCondition>
      localPathMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'localPath',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MediaItemModel, MediaItemModel, QAfterFilterCondition>
      localPathIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'localPath',
        value: '',
      ));
    });
  }

  QueryBuilder<MediaItemModel, MediaItemModel, QAfterFilterCondition>
      localPathIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'localPath',
        value: '',
      ));
    });
  }

  QueryBuilder<MediaItemModel, MediaItemModel, QAfterFilterCondition>
      mediaIdEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'mediaId',
        value: value,
      ));
    });
  }

  QueryBuilder<MediaItemModel, MediaItemModel, QAfterFilterCondition>
      mediaIdGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'mediaId',
        value: value,
      ));
    });
  }

  QueryBuilder<MediaItemModel, MediaItemModel, QAfterFilterCondition>
      mediaIdLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'mediaId',
        value: value,
      ));
    });
  }

  QueryBuilder<MediaItemModel, MediaItemModel, QAfterFilterCondition>
      mediaIdBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'mediaId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<MediaItemModel, MediaItemModel, QAfterFilterCondition>
      mediaNameEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'mediaName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MediaItemModel, MediaItemModel, QAfterFilterCondition>
      mediaNameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'mediaName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MediaItemModel, MediaItemModel, QAfterFilterCondition>
      mediaNameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'mediaName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MediaItemModel, MediaItemModel, QAfterFilterCondition>
      mediaNameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'mediaName',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MediaItemModel, MediaItemModel, QAfterFilterCondition>
      mediaNameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'mediaName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MediaItemModel, MediaItemModel, QAfterFilterCondition>
      mediaNameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'mediaName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MediaItemModel, MediaItemModel, QAfterFilterCondition>
      mediaNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'mediaName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MediaItemModel, MediaItemModel, QAfterFilterCondition>
      mediaNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'mediaName',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MediaItemModel, MediaItemModel, QAfterFilterCondition>
      mediaNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'mediaName',
        value: '',
      ));
    });
  }

  QueryBuilder<MediaItemModel, MediaItemModel, QAfterFilterCondition>
      mediaNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'mediaName',
        value: '',
      ));
    });
  }

  QueryBuilder<MediaItemModel, MediaItemModel, QAfterFilterCondition>
      mediaTypeEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'mediaType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MediaItemModel, MediaItemModel, QAfterFilterCondition>
      mediaTypeGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'mediaType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MediaItemModel, MediaItemModel, QAfterFilterCondition>
      mediaTypeLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'mediaType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MediaItemModel, MediaItemModel, QAfterFilterCondition>
      mediaTypeBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'mediaType',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MediaItemModel, MediaItemModel, QAfterFilterCondition>
      mediaTypeStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'mediaType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MediaItemModel, MediaItemModel, QAfterFilterCondition>
      mediaTypeEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'mediaType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MediaItemModel, MediaItemModel, QAfterFilterCondition>
      mediaTypeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'mediaType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MediaItemModel, MediaItemModel, QAfterFilterCondition>
      mediaTypeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'mediaType',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MediaItemModel, MediaItemModel, QAfterFilterCondition>
      mediaTypeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'mediaType',
        value: '',
      ));
    });
  }

  QueryBuilder<MediaItemModel, MediaItemModel, QAfterFilterCondition>
      mediaTypeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'mediaType',
        value: '',
      ));
    });
  }

  QueryBuilder<MediaItemModel, MediaItemModel, QAfterFilterCondition>
      mediaUrlEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'mediaUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MediaItemModel, MediaItemModel, QAfterFilterCondition>
      mediaUrlGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'mediaUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MediaItemModel, MediaItemModel, QAfterFilterCondition>
      mediaUrlLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'mediaUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MediaItemModel, MediaItemModel, QAfterFilterCondition>
      mediaUrlBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'mediaUrl',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MediaItemModel, MediaItemModel, QAfterFilterCondition>
      mediaUrlStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'mediaUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MediaItemModel, MediaItemModel, QAfterFilterCondition>
      mediaUrlEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'mediaUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MediaItemModel, MediaItemModel, QAfterFilterCondition>
      mediaUrlContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'mediaUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MediaItemModel, MediaItemModel, QAfterFilterCondition>
      mediaUrlMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'mediaUrl',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MediaItemModel, MediaItemModel, QAfterFilterCondition>
      mediaUrlIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'mediaUrl',
        value: '',
      ));
    });
  }

  QueryBuilder<MediaItemModel, MediaItemModel, QAfterFilterCondition>
      mediaUrlIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'mediaUrl',
        value: '',
      ));
    });
  }

  QueryBuilder<MediaItemModel, MediaItemModel, QAfterFilterCondition>
      mimetypeEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'mimetype',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MediaItemModel, MediaItemModel, QAfterFilterCondition>
      mimetypeGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'mimetype',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MediaItemModel, MediaItemModel, QAfterFilterCondition>
      mimetypeLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'mimetype',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MediaItemModel, MediaItemModel, QAfterFilterCondition>
      mimetypeBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'mimetype',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MediaItemModel, MediaItemModel, QAfterFilterCondition>
      mimetypeStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'mimetype',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MediaItemModel, MediaItemModel, QAfterFilterCondition>
      mimetypeEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'mimetype',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MediaItemModel, MediaItemModel, QAfterFilterCondition>
      mimetypeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'mimetype',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MediaItemModel, MediaItemModel, QAfterFilterCondition>
      mimetypeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'mimetype',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MediaItemModel, MediaItemModel, QAfterFilterCondition>
      mimetypeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'mimetype',
        value: '',
      ));
    });
  }

  QueryBuilder<MediaItemModel, MediaItemModel, QAfterFilterCondition>
      mimetypeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'mimetype',
        value: '',
      ));
    });
  }

  QueryBuilder<MediaItemModel, MediaItemModel, QAfterFilterCondition>
      nTimePlayEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'nTimePlay',
        value: value,
      ));
    });
  }

  QueryBuilder<MediaItemModel, MediaItemModel, QAfterFilterCondition>
      nTimePlayGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'nTimePlay',
        value: value,
      ));
    });
  }

  QueryBuilder<MediaItemModel, MediaItemModel, QAfterFilterCondition>
      nTimePlayLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'nTimePlay',
        value: value,
      ));
    });
  }

  QueryBuilder<MediaItemModel, MediaItemModel, QAfterFilterCondition>
      nTimePlayBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'nTimePlay',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<MediaItemModel, MediaItemModel, QAfterFilterCondition>
      orderEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'order',
        value: value,
      ));
    });
  }

  QueryBuilder<MediaItemModel, MediaItemModel, QAfterFilterCondition>
      orderGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'order',
        value: value,
      ));
    });
  }

  QueryBuilder<MediaItemModel, MediaItemModel, QAfterFilterCondition>
      orderLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'order',
        value: value,
      ));
    });
  }

  QueryBuilder<MediaItemModel, MediaItemModel, QAfterFilterCondition>
      orderBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'order',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<MediaItemModel, MediaItemModel, QAfterFilterCondition>
      timingIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'timing',
      ));
    });
  }

  QueryBuilder<MediaItemModel, MediaItemModel, QAfterFilterCondition>
      timingIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'timing',
      ));
    });
  }
}

extension MediaItemModelQueryObject
    on QueryBuilder<MediaItemModel, MediaItemModel, QFilterCondition> {
  QueryBuilder<MediaItemModel, MediaItemModel, QAfterFilterCondition> effects(
      FilterQuery<MediaEffectsModel> q) {
    return QueryBuilder.apply(this, (query) {
      return query.object(q, r'effects');
    });
  }

  QueryBuilder<MediaItemModel, MediaItemModel, QAfterFilterCondition> layout(
      FilterQuery<MediaLayoutModel> q) {
    return QueryBuilder.apply(this, (query) {
      return query.object(q, r'layout');
    });
  }

  QueryBuilder<MediaItemModel, MediaItemModel, QAfterFilterCondition> timing(
      FilterQuery<MediaTimingModel> q) {
    return QueryBuilder.apply(this, (query) {
      return query.object(q, r'timing');
    });
  }
}
