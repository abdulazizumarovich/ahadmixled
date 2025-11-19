// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'playlist_status_model.dart';

// **************************************************************************
// IsarEmbeddedGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

const PlaylistStatusModelSchema = Schema(
  name: r'PlaylistStatusModel',
  id: 5501134236741106012,
  properties: {
    r'allDownloaded': PropertySchema(
      id: 0,
      name: r'allDownloaded',
      type: IsarType.bool,
    ),
    r'isReady': PropertySchema(
      id: 1,
      name: r'isReady',
      type: IsarType.bool,
    ),
    r'lastVerified': PropertySchema(
      id: 2,
      name: r'lastVerified',
      type: IsarType.dateTime,
    ),
    r'missingFiles': PropertySchema(
      id: 3,
      name: r'missingFiles',
      type: IsarType.stringList,
    )
  },
  estimateSize: _playlistStatusModelEstimateSize,
  serialize: _playlistStatusModelSerialize,
  deserialize: _playlistStatusModelDeserialize,
  deserializeProp: _playlistStatusModelDeserializeProp,
);

int _playlistStatusModelEstimateSize(
  PlaylistStatusModel object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.missingFiles.length * 3;
  {
    for (var i = 0; i < object.missingFiles.length; i++) {
      final value = object.missingFiles[i];
      bytesCount += value.length * 3;
    }
  }
  return bytesCount;
}

void _playlistStatusModelSerialize(
  PlaylistStatusModel object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeBool(offsets[0], object.allDownloaded);
  writer.writeBool(offsets[1], object.isReady);
  writer.writeDateTime(offsets[2], object.lastVerified);
  writer.writeStringList(offsets[3], object.missingFiles);
}

PlaylistStatusModel _playlistStatusModelDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = PlaylistStatusModel(
    allDownloaded: reader.readBoolOrNull(offsets[0]) ?? false,
    isReady: reader.readBoolOrNull(offsets[1]) ?? false,
    lastVerified: reader.readDateTimeOrNull(offsets[2]),
    missingFiles: reader.readStringList(offsets[3]) ?? const [],
  );
  return object;
}

P _playlistStatusModelDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readBoolOrNull(offset) ?? false) as P;
    case 1:
      return (reader.readBoolOrNull(offset) ?? false) as P;
    case 2:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 3:
      return (reader.readStringList(offset) ?? const []) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

extension PlaylistStatusModelQueryFilter on QueryBuilder<PlaylistStatusModel,
    PlaylistStatusModel, QFilterCondition> {
  QueryBuilder<PlaylistStatusModel, PlaylistStatusModel, QAfterFilterCondition>
      allDownloadedEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'allDownloaded',
        value: value,
      ));
    });
  }

  QueryBuilder<PlaylistStatusModel, PlaylistStatusModel, QAfterFilterCondition>
      isReadyEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isReady',
        value: value,
      ));
    });
  }

  QueryBuilder<PlaylistStatusModel, PlaylistStatusModel, QAfterFilterCondition>
      lastVerifiedIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'lastVerified',
      ));
    });
  }

  QueryBuilder<PlaylistStatusModel, PlaylistStatusModel, QAfterFilterCondition>
      lastVerifiedIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'lastVerified',
      ));
    });
  }

  QueryBuilder<PlaylistStatusModel, PlaylistStatusModel, QAfterFilterCondition>
      lastVerifiedEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lastVerified',
        value: value,
      ));
    });
  }

  QueryBuilder<PlaylistStatusModel, PlaylistStatusModel, QAfterFilterCondition>
      lastVerifiedGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'lastVerified',
        value: value,
      ));
    });
  }

  QueryBuilder<PlaylistStatusModel, PlaylistStatusModel, QAfterFilterCondition>
      lastVerifiedLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'lastVerified',
        value: value,
      ));
    });
  }

  QueryBuilder<PlaylistStatusModel, PlaylistStatusModel, QAfterFilterCondition>
      lastVerifiedBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'lastVerified',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<PlaylistStatusModel, PlaylistStatusModel, QAfterFilterCondition>
      missingFilesElementEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'missingFiles',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PlaylistStatusModel, PlaylistStatusModel, QAfterFilterCondition>
      missingFilesElementGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'missingFiles',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PlaylistStatusModel, PlaylistStatusModel, QAfterFilterCondition>
      missingFilesElementLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'missingFiles',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PlaylistStatusModel, PlaylistStatusModel, QAfterFilterCondition>
      missingFilesElementBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'missingFiles',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PlaylistStatusModel, PlaylistStatusModel, QAfterFilterCondition>
      missingFilesElementStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'missingFiles',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PlaylistStatusModel, PlaylistStatusModel, QAfterFilterCondition>
      missingFilesElementEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'missingFiles',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PlaylistStatusModel, PlaylistStatusModel, QAfterFilterCondition>
      missingFilesElementContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'missingFiles',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PlaylistStatusModel, PlaylistStatusModel, QAfterFilterCondition>
      missingFilesElementMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'missingFiles',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PlaylistStatusModel, PlaylistStatusModel, QAfterFilterCondition>
      missingFilesElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'missingFiles',
        value: '',
      ));
    });
  }

  QueryBuilder<PlaylistStatusModel, PlaylistStatusModel, QAfterFilterCondition>
      missingFilesElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'missingFiles',
        value: '',
      ));
    });
  }

  QueryBuilder<PlaylistStatusModel, PlaylistStatusModel, QAfterFilterCondition>
      missingFilesLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'missingFiles',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<PlaylistStatusModel, PlaylistStatusModel, QAfterFilterCondition>
      missingFilesIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'missingFiles',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<PlaylistStatusModel, PlaylistStatusModel, QAfterFilterCondition>
      missingFilesIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'missingFiles',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<PlaylistStatusModel, PlaylistStatusModel, QAfterFilterCondition>
      missingFilesLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'missingFiles',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<PlaylistStatusModel, PlaylistStatusModel, QAfterFilterCondition>
      missingFilesLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'missingFiles',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<PlaylistStatusModel, PlaylistStatusModel, QAfterFilterCondition>
      missingFilesLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'missingFiles',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }
}

extension PlaylistStatusModelQueryObject on QueryBuilder<PlaylistStatusModel,
    PlaylistStatusModel, QFilterCondition> {}
