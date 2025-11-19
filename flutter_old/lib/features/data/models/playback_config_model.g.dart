// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'playback_config_model.dart';

// **************************************************************************
// IsarEmbeddedGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

const PlaybackConfigModelSchema = Schema(
  name: r'PlaybackConfigModel',
  id: 6564559442004947682,
  properties: {
    r'backgroundColor': PropertySchema(
      id: 0,
      name: r'backgroundColor',
      type: IsarType.string,
    ),
    r'repeat': PropertySchema(
      id: 1,
      name: r'repeat',
      type: IsarType.bool,
    ),
    r'repeatCount': PropertySchema(
      id: 2,
      name: r'repeatCount',
      type: IsarType.long,
    )
  },
  estimateSize: _playbackConfigModelEstimateSize,
  serialize: _playbackConfigModelSerialize,
  deserialize: _playbackConfigModelDeserialize,
  deserializeProp: _playbackConfigModelDeserializeProp,
);

int _playbackConfigModelEstimateSize(
  PlaybackConfigModel object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.backgroundColor.length * 3;
  return bytesCount;
}

void _playbackConfigModelSerialize(
  PlaybackConfigModel object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.backgroundColor);
  writer.writeBool(offsets[1], object.repeat);
  writer.writeLong(offsets[2], object.repeatCount);
}

PlaybackConfigModel _playbackConfigModelDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = PlaybackConfigModel(
    backgroundColor: reader.readStringOrNull(offsets[0]) ?? '#000000',
    repeat: reader.readBoolOrNull(offsets[1]) ?? true,
    repeatCount: reader.readLongOrNull(offsets[2]) ?? 1,
  );
  return object;
}

P _playbackConfigModelDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readStringOrNull(offset) ?? '#000000') as P;
    case 1:
      return (reader.readBoolOrNull(offset) ?? true) as P;
    case 2:
      return (reader.readLongOrNull(offset) ?? 1) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

extension PlaybackConfigModelQueryFilter on QueryBuilder<PlaybackConfigModel,
    PlaybackConfigModel, QFilterCondition> {
  QueryBuilder<PlaybackConfigModel, PlaybackConfigModel, QAfterFilterCondition>
      backgroundColorEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'backgroundColor',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PlaybackConfigModel, PlaybackConfigModel, QAfterFilterCondition>
      backgroundColorGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'backgroundColor',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PlaybackConfigModel, PlaybackConfigModel, QAfterFilterCondition>
      backgroundColorLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'backgroundColor',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PlaybackConfigModel, PlaybackConfigModel, QAfterFilterCondition>
      backgroundColorBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'backgroundColor',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PlaybackConfigModel, PlaybackConfigModel, QAfterFilterCondition>
      backgroundColorStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'backgroundColor',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PlaybackConfigModel, PlaybackConfigModel, QAfterFilterCondition>
      backgroundColorEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'backgroundColor',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PlaybackConfigModel, PlaybackConfigModel, QAfterFilterCondition>
      backgroundColorContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'backgroundColor',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PlaybackConfigModel, PlaybackConfigModel, QAfterFilterCondition>
      backgroundColorMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'backgroundColor',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PlaybackConfigModel, PlaybackConfigModel, QAfterFilterCondition>
      backgroundColorIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'backgroundColor',
        value: '',
      ));
    });
  }

  QueryBuilder<PlaybackConfigModel, PlaybackConfigModel, QAfterFilterCondition>
      backgroundColorIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'backgroundColor',
        value: '',
      ));
    });
  }

  QueryBuilder<PlaybackConfigModel, PlaybackConfigModel, QAfterFilterCondition>
      repeatEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'repeat',
        value: value,
      ));
    });
  }

  QueryBuilder<PlaybackConfigModel, PlaybackConfigModel, QAfterFilterCondition>
      repeatCountEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'repeatCount',
        value: value,
      ));
    });
  }

  QueryBuilder<PlaybackConfigModel, PlaybackConfigModel, QAfterFilterCondition>
      repeatCountGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'repeatCount',
        value: value,
      ));
    });
  }

  QueryBuilder<PlaybackConfigModel, PlaybackConfigModel, QAfterFilterCondition>
      repeatCountLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'repeatCount',
        value: value,
      ));
    });
  }

  QueryBuilder<PlaybackConfigModel, PlaybackConfigModel, QAfterFilterCondition>
      repeatCountBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'repeatCount',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension PlaybackConfigModelQueryObject on QueryBuilder<PlaybackConfigModel,
    PlaybackConfigModel, QFilterCondition> {}
