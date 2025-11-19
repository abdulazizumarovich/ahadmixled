// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'media_layout_model.dart';

// **************************************************************************
// IsarEmbeddedGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

const MediaLayoutModelSchema = Schema(
  name: r'MediaLayoutModel',
  id: 2673219290430377131,
  properties: {
    r'height': PropertySchema(
      id: 0,
      name: r'height',
      type: IsarType.long,
    ),
    r'width': PropertySchema(
      id: 1,
      name: r'width',
      type: IsarType.long,
    ),
    r'x': PropertySchema(
      id: 2,
      name: r'x',
      type: IsarType.long,
    ),
    r'y': PropertySchema(
      id: 3,
      name: r'y',
      type: IsarType.long,
    ),
    r'zIndex': PropertySchema(
      id: 4,
      name: r'zIndex',
      type: IsarType.long,
    )
  },
  estimateSize: _mediaLayoutModelEstimateSize,
  serialize: _mediaLayoutModelSerialize,
  deserialize: _mediaLayoutModelDeserialize,
  deserializeProp: _mediaLayoutModelDeserializeProp,
);

int _mediaLayoutModelEstimateSize(
  MediaLayoutModel object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  return bytesCount;
}

void _mediaLayoutModelSerialize(
  MediaLayoutModel object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeLong(offsets[0], object.height);
  writer.writeLong(offsets[1], object.width);
  writer.writeLong(offsets[2], object.x);
  writer.writeLong(offsets[3], object.y);
  writer.writeLong(offsets[4], object.zIndex);
}

MediaLayoutModel _mediaLayoutModelDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = MediaLayoutModel(
    height: reader.readLongOrNull(offsets[0]) ?? 0,
    width: reader.readLongOrNull(offsets[1]) ?? 0,
    x: reader.readLongOrNull(offsets[2]) ?? 0,
    y: reader.readLongOrNull(offsets[3]) ?? 0,
    zIndex: reader.readLongOrNull(offsets[4]) ?? 0,
  );
  return object;
}

P _mediaLayoutModelDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readLongOrNull(offset) ?? 0) as P;
    case 1:
      return (reader.readLongOrNull(offset) ?? 0) as P;
    case 2:
      return (reader.readLongOrNull(offset) ?? 0) as P;
    case 3:
      return (reader.readLongOrNull(offset) ?? 0) as P;
    case 4:
      return (reader.readLongOrNull(offset) ?? 0) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

extension MediaLayoutModelQueryFilter
    on QueryBuilder<MediaLayoutModel, MediaLayoutModel, QFilterCondition> {
  QueryBuilder<MediaLayoutModel, MediaLayoutModel, QAfterFilterCondition>
      heightEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'height',
        value: value,
      ));
    });
  }

  QueryBuilder<MediaLayoutModel, MediaLayoutModel, QAfterFilterCondition>
      heightGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'height',
        value: value,
      ));
    });
  }

  QueryBuilder<MediaLayoutModel, MediaLayoutModel, QAfterFilterCondition>
      heightLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'height',
        value: value,
      ));
    });
  }

  QueryBuilder<MediaLayoutModel, MediaLayoutModel, QAfterFilterCondition>
      heightBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'height',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<MediaLayoutModel, MediaLayoutModel, QAfterFilterCondition>
      widthEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'width',
        value: value,
      ));
    });
  }

  QueryBuilder<MediaLayoutModel, MediaLayoutModel, QAfterFilterCondition>
      widthGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'width',
        value: value,
      ));
    });
  }

  QueryBuilder<MediaLayoutModel, MediaLayoutModel, QAfterFilterCondition>
      widthLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'width',
        value: value,
      ));
    });
  }

  QueryBuilder<MediaLayoutModel, MediaLayoutModel, QAfterFilterCondition>
      widthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'width',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<MediaLayoutModel, MediaLayoutModel, QAfterFilterCondition>
      xEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'x',
        value: value,
      ));
    });
  }

  QueryBuilder<MediaLayoutModel, MediaLayoutModel, QAfterFilterCondition>
      xGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'x',
        value: value,
      ));
    });
  }

  QueryBuilder<MediaLayoutModel, MediaLayoutModel, QAfterFilterCondition>
      xLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'x',
        value: value,
      ));
    });
  }

  QueryBuilder<MediaLayoutModel, MediaLayoutModel, QAfterFilterCondition>
      xBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'x',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<MediaLayoutModel, MediaLayoutModel, QAfterFilterCondition>
      yEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'y',
        value: value,
      ));
    });
  }

  QueryBuilder<MediaLayoutModel, MediaLayoutModel, QAfterFilterCondition>
      yGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'y',
        value: value,
      ));
    });
  }

  QueryBuilder<MediaLayoutModel, MediaLayoutModel, QAfterFilterCondition>
      yLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'y',
        value: value,
      ));
    });
  }

  QueryBuilder<MediaLayoutModel, MediaLayoutModel, QAfterFilterCondition>
      yBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'y',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<MediaLayoutModel, MediaLayoutModel, QAfterFilterCondition>
      zIndexEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'zIndex',
        value: value,
      ));
    });
  }

  QueryBuilder<MediaLayoutModel, MediaLayoutModel, QAfterFilterCondition>
      zIndexGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'zIndex',
        value: value,
      ));
    });
  }

  QueryBuilder<MediaLayoutModel, MediaLayoutModel, QAfterFilterCondition>
      zIndexLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'zIndex',
        value: value,
      ));
    });
  }

  QueryBuilder<MediaLayoutModel, MediaLayoutModel, QAfterFilterCondition>
      zIndexBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'zIndex',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension MediaLayoutModelQueryObject
    on QueryBuilder<MediaLayoutModel, MediaLayoutModel, QFilterCondition> {}
