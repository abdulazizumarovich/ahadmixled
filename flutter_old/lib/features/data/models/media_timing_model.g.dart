// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'media_timing_model.dart';

// **************************************************************************
// IsarEmbeddedGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

const MediaTimingModelSchema = Schema(
  name: r'MediaTimingModel',
  id: -17030511359252642,
  properties: {
    r'duration': PropertySchema(
      id: 0,
      name: r'duration',
      type: IsarType.long,
    ),
    r'loop': PropertySchema(
      id: 1,
      name: r'loop',
      type: IsarType.bool,
    ),
    r'startTime': PropertySchema(
      id: 2,
      name: r'startTime',
      type: IsarType.long,
    )
  },
  estimateSize: _mediaTimingModelEstimateSize,
  serialize: _mediaTimingModelSerialize,
  deserialize: _mediaTimingModelDeserialize,
  deserializeProp: _mediaTimingModelDeserializeProp,
);

int _mediaTimingModelEstimateSize(
  MediaTimingModel object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  return bytesCount;
}

void _mediaTimingModelSerialize(
  MediaTimingModel object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeLong(offsets[0], object.duration);
  writer.writeBool(offsets[1], object.loop);
  writer.writeLong(offsets[2], object.startTime);
}

MediaTimingModel _mediaTimingModelDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = MediaTimingModel(
    duration: reader.readLongOrNull(offsets[0]) ?? 0,
    loop: reader.readBoolOrNull(offsets[1]) ?? false,
    startTime: reader.readLongOrNull(offsets[2]) ?? 0,
  );
  return object;
}

P _mediaTimingModelDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readLongOrNull(offset) ?? 0) as P;
    case 1:
      return (reader.readBoolOrNull(offset) ?? false) as P;
    case 2:
      return (reader.readLongOrNull(offset) ?? 0) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

extension MediaTimingModelQueryFilter
    on QueryBuilder<MediaTimingModel, MediaTimingModel, QFilterCondition> {
  QueryBuilder<MediaTimingModel, MediaTimingModel, QAfterFilterCondition>
      durationEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'duration',
        value: value,
      ));
    });
  }

  QueryBuilder<MediaTimingModel, MediaTimingModel, QAfterFilterCondition>
      durationGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'duration',
        value: value,
      ));
    });
  }

  QueryBuilder<MediaTimingModel, MediaTimingModel, QAfterFilterCondition>
      durationLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'duration',
        value: value,
      ));
    });
  }

  QueryBuilder<MediaTimingModel, MediaTimingModel, QAfterFilterCondition>
      durationBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'duration',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<MediaTimingModel, MediaTimingModel, QAfterFilterCondition>
      loopEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'loop',
        value: value,
      ));
    });
  }

  QueryBuilder<MediaTimingModel, MediaTimingModel, QAfterFilterCondition>
      startTimeEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'startTime',
        value: value,
      ));
    });
  }

  QueryBuilder<MediaTimingModel, MediaTimingModel, QAfterFilterCondition>
      startTimeGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'startTime',
        value: value,
      ));
    });
  }

  QueryBuilder<MediaTimingModel, MediaTimingModel, QAfterFilterCondition>
      startTimeLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'startTime',
        value: value,
      ));
    });
  }

  QueryBuilder<MediaTimingModel, MediaTimingModel, QAfterFilterCondition>
      startTimeBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'startTime',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension MediaTimingModelQueryObject
    on QueryBuilder<MediaTimingModel, MediaTimingModel, QFilterCondition> {}
