// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'media_effects_model.dart';

// **************************************************************************
// IsarEmbeddedGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

const MediaEffectsModelSchema = Schema(
  name: r'MediaEffectsModel',
  id: -7458300453689919210,
  properties: {
    r'fadeDuration': PropertySchema(
      id: 0,
      name: r'fadeDuration',
      type: IsarType.long,
    ),
    r'transition': PropertySchema(
      id: 1,
      name: r'transition',
      type: IsarType.string,
    )
  },
  estimateSize: _mediaEffectsModelEstimateSize,
  serialize: _mediaEffectsModelSerialize,
  deserialize: _mediaEffectsModelDeserialize,
  deserializeProp: _mediaEffectsModelDeserializeProp,
);

int _mediaEffectsModelEstimateSize(
  MediaEffectsModel object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.transition.length * 3;
  return bytesCount;
}

void _mediaEffectsModelSerialize(
  MediaEffectsModel object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeLong(offsets[0], object.fadeDuration);
  writer.writeString(offsets[1], object.transition);
}

MediaEffectsModel _mediaEffectsModelDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = MediaEffectsModel(
    fadeDuration: reader.readLongOrNull(offsets[0]) ?? 1000,
    transition: reader.readStringOrNull(offsets[1]) ?? 'none',
  );
  return object;
}

P _mediaEffectsModelDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readLongOrNull(offset) ?? 1000) as P;
    case 1:
      return (reader.readStringOrNull(offset) ?? 'none') as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

extension MediaEffectsModelQueryFilter
    on QueryBuilder<MediaEffectsModel, MediaEffectsModel, QFilterCondition> {
  QueryBuilder<MediaEffectsModel, MediaEffectsModel, QAfterFilterCondition>
      fadeDurationEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'fadeDuration',
        value: value,
      ));
    });
  }

  QueryBuilder<MediaEffectsModel, MediaEffectsModel, QAfterFilterCondition>
      fadeDurationGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'fadeDuration',
        value: value,
      ));
    });
  }

  QueryBuilder<MediaEffectsModel, MediaEffectsModel, QAfterFilterCondition>
      fadeDurationLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'fadeDuration',
        value: value,
      ));
    });
  }

  QueryBuilder<MediaEffectsModel, MediaEffectsModel, QAfterFilterCondition>
      fadeDurationBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'fadeDuration',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<MediaEffectsModel, MediaEffectsModel, QAfterFilterCondition>
      transitionEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'transition',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MediaEffectsModel, MediaEffectsModel, QAfterFilterCondition>
      transitionGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'transition',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MediaEffectsModel, MediaEffectsModel, QAfterFilterCondition>
      transitionLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'transition',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MediaEffectsModel, MediaEffectsModel, QAfterFilterCondition>
      transitionBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'transition',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MediaEffectsModel, MediaEffectsModel, QAfterFilterCondition>
      transitionStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'transition',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MediaEffectsModel, MediaEffectsModel, QAfterFilterCondition>
      transitionEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'transition',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MediaEffectsModel, MediaEffectsModel, QAfterFilterCondition>
      transitionContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'transition',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MediaEffectsModel, MediaEffectsModel, QAfterFilterCondition>
      transitionMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'transition',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MediaEffectsModel, MediaEffectsModel, QAfterFilterCondition>
      transitionIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'transition',
        value: '',
      ));
    });
  }

  QueryBuilder<MediaEffectsModel, MediaEffectsModel, QAfterFilterCondition>
      transitionIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'transition',
        value: '',
      ));
    });
  }
}

extension MediaEffectsModelQueryObject
    on QueryBuilder<MediaEffectsModel, MediaEffectsModel, QFilterCondition> {}
