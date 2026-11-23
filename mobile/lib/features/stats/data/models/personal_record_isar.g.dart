// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'personal_record_isar.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetPersonalRecordIsarCollection on Isar {
  IsarCollection<PersonalRecordIsar> get personalRecordIsars =>
      this.collection();
}

const PersonalRecordIsarSchema = CollectionSchema(
  name: r'PersonalRecordIsar',
  id: -7892834301775687248,
  properties: {
    r'achievedAt': PropertySchema(
      id: 0,
      name: r'achievedAt',
      type: IsarType.dateTime,
    ),
    r'category': PropertySchema(
      id: 1,
      name: r'category',
      type: IsarType.string,
    ),
    r'proofUrl': PropertySchema(
      id: 2,
      name: r'proofUrl',
      type: IsarType.string,
    ),
    r'rank': PropertySchema(
      id: 3,
      name: r'rank',
      type: IsarType.long,
    ),
    r'runId': PropertySchema(
      id: 4,
      name: r'runId',
      type: IsarType.string,
    ),
    r'source': PropertySchema(
      id: 5,
      name: r'source',
      type: IsarType.string,
    ),
    r'value': PropertySchema(
      id: 6,
      name: r'value',
      type: IsarType.double,
    )
  },
  estimateSize: _personalRecordIsarEstimateSize,
  serialize: _personalRecordIsarSerialize,
  deserialize: _personalRecordIsarDeserialize,
  deserializeProp: _personalRecordIsarDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {},
  embeddedSchemas: {},
  getId: _personalRecordIsarGetId,
  getLinks: _personalRecordIsarGetLinks,
  attach: _personalRecordIsarAttach,
  version: '3.1.0+1',
);

int _personalRecordIsarEstimateSize(
  PersonalRecordIsar object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.category;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.proofUrl;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.runId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.source;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _personalRecordIsarSerialize(
  PersonalRecordIsar object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDateTime(offsets[0], object.achievedAt);
  writer.writeString(offsets[1], object.category);
  writer.writeString(offsets[2], object.proofUrl);
  writer.writeLong(offsets[3], object.rank);
  writer.writeString(offsets[4], object.runId);
  writer.writeString(offsets[5], object.source);
  writer.writeDouble(offsets[6], object.value);
}

PersonalRecordIsar _personalRecordIsarDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = PersonalRecordIsar();
  object.achievedAt = reader.readDateTimeOrNull(offsets[0]);
  object.category = reader.readStringOrNull(offsets[1]);
  object.id = id;
  object.proofUrl = reader.readStringOrNull(offsets[2]);
  object.rank = reader.readLongOrNull(offsets[3]);
  object.runId = reader.readStringOrNull(offsets[4]);
  object.source = reader.readStringOrNull(offsets[5]);
  object.value = reader.readDoubleOrNull(offsets[6]);
  return object;
}

P _personalRecordIsarDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 1:
      return (reader.readStringOrNull(offset)) as P;
    case 2:
      return (reader.readStringOrNull(offset)) as P;
    case 3:
      return (reader.readLongOrNull(offset)) as P;
    case 4:
      return (reader.readStringOrNull(offset)) as P;
    case 5:
      return (reader.readStringOrNull(offset)) as P;
    case 6:
      return (reader.readDoubleOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _personalRecordIsarGetId(PersonalRecordIsar object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _personalRecordIsarGetLinks(
    PersonalRecordIsar object) {
  return [];
}

void _personalRecordIsarAttach(
    IsarCollection<dynamic> col, Id id, PersonalRecordIsar object) {
  object.id = id;
}

extension PersonalRecordIsarQueryWhereSort
    on QueryBuilder<PersonalRecordIsar, PersonalRecordIsar, QWhere> {
  QueryBuilder<PersonalRecordIsar, PersonalRecordIsar, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension PersonalRecordIsarQueryWhere
    on QueryBuilder<PersonalRecordIsar, PersonalRecordIsar, QWhereClause> {
  QueryBuilder<PersonalRecordIsar, PersonalRecordIsar, QAfterWhereClause>
      idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<PersonalRecordIsar, PersonalRecordIsar, QAfterWhereClause>
      idNotEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<PersonalRecordIsar, PersonalRecordIsar, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<PersonalRecordIsar, PersonalRecordIsar, QAfterWhereClause>
      idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<PersonalRecordIsar, PersonalRecordIsar, QAfterWhereClause>
      idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerId,
        includeLower: includeLower,
        upper: upperId,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension PersonalRecordIsarQueryFilter
    on QueryBuilder<PersonalRecordIsar, PersonalRecordIsar, QFilterCondition> {
  QueryBuilder<PersonalRecordIsar, PersonalRecordIsar, QAfterFilterCondition>
      achievedAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'achievedAt',
      ));
    });
  }

  QueryBuilder<PersonalRecordIsar, PersonalRecordIsar, QAfterFilterCondition>
      achievedAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'achievedAt',
      ));
    });
  }

  QueryBuilder<PersonalRecordIsar, PersonalRecordIsar, QAfterFilterCondition>
      achievedAtEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'achievedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<PersonalRecordIsar, PersonalRecordIsar, QAfterFilterCondition>
      achievedAtGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'achievedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<PersonalRecordIsar, PersonalRecordIsar, QAfterFilterCondition>
      achievedAtLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'achievedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<PersonalRecordIsar, PersonalRecordIsar, QAfterFilterCondition>
      achievedAtBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'achievedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<PersonalRecordIsar, PersonalRecordIsar, QAfterFilterCondition>
      categoryIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'category',
      ));
    });
  }

  QueryBuilder<PersonalRecordIsar, PersonalRecordIsar, QAfterFilterCondition>
      categoryIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'category',
      ));
    });
  }

  QueryBuilder<PersonalRecordIsar, PersonalRecordIsar, QAfterFilterCondition>
      categoryEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'category',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PersonalRecordIsar, PersonalRecordIsar, QAfterFilterCondition>
      categoryGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'category',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PersonalRecordIsar, PersonalRecordIsar, QAfterFilterCondition>
      categoryLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'category',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PersonalRecordIsar, PersonalRecordIsar, QAfterFilterCondition>
      categoryBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'category',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PersonalRecordIsar, PersonalRecordIsar, QAfterFilterCondition>
      categoryStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'category',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PersonalRecordIsar, PersonalRecordIsar, QAfterFilterCondition>
      categoryEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'category',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PersonalRecordIsar, PersonalRecordIsar, QAfterFilterCondition>
      categoryContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'category',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PersonalRecordIsar, PersonalRecordIsar, QAfterFilterCondition>
      categoryMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'category',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PersonalRecordIsar, PersonalRecordIsar, QAfterFilterCondition>
      categoryIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'category',
        value: '',
      ));
    });
  }

  QueryBuilder<PersonalRecordIsar, PersonalRecordIsar, QAfterFilterCondition>
      categoryIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'category',
        value: '',
      ));
    });
  }

  QueryBuilder<PersonalRecordIsar, PersonalRecordIsar, QAfterFilterCondition>
      idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<PersonalRecordIsar, PersonalRecordIsar, QAfterFilterCondition>
      idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<PersonalRecordIsar, PersonalRecordIsar, QAfterFilterCondition>
      idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<PersonalRecordIsar, PersonalRecordIsar, QAfterFilterCondition>
      idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<PersonalRecordIsar, PersonalRecordIsar, QAfterFilterCondition>
      proofUrlIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'proofUrl',
      ));
    });
  }

  QueryBuilder<PersonalRecordIsar, PersonalRecordIsar, QAfterFilterCondition>
      proofUrlIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'proofUrl',
      ));
    });
  }

  QueryBuilder<PersonalRecordIsar, PersonalRecordIsar, QAfterFilterCondition>
      proofUrlEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'proofUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PersonalRecordIsar, PersonalRecordIsar, QAfterFilterCondition>
      proofUrlGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'proofUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PersonalRecordIsar, PersonalRecordIsar, QAfterFilterCondition>
      proofUrlLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'proofUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PersonalRecordIsar, PersonalRecordIsar, QAfterFilterCondition>
      proofUrlBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'proofUrl',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PersonalRecordIsar, PersonalRecordIsar, QAfterFilterCondition>
      proofUrlStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'proofUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PersonalRecordIsar, PersonalRecordIsar, QAfterFilterCondition>
      proofUrlEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'proofUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PersonalRecordIsar, PersonalRecordIsar, QAfterFilterCondition>
      proofUrlContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'proofUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PersonalRecordIsar, PersonalRecordIsar, QAfterFilterCondition>
      proofUrlMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'proofUrl',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PersonalRecordIsar, PersonalRecordIsar, QAfterFilterCondition>
      proofUrlIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'proofUrl',
        value: '',
      ));
    });
  }

  QueryBuilder<PersonalRecordIsar, PersonalRecordIsar, QAfterFilterCondition>
      proofUrlIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'proofUrl',
        value: '',
      ));
    });
  }

  QueryBuilder<PersonalRecordIsar, PersonalRecordIsar, QAfterFilterCondition>
      rankIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'rank',
      ));
    });
  }

  QueryBuilder<PersonalRecordIsar, PersonalRecordIsar, QAfterFilterCondition>
      rankIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'rank',
      ));
    });
  }

  QueryBuilder<PersonalRecordIsar, PersonalRecordIsar, QAfterFilterCondition>
      rankEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'rank',
        value: value,
      ));
    });
  }

  QueryBuilder<PersonalRecordIsar, PersonalRecordIsar, QAfterFilterCondition>
      rankGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'rank',
        value: value,
      ));
    });
  }

  QueryBuilder<PersonalRecordIsar, PersonalRecordIsar, QAfterFilterCondition>
      rankLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'rank',
        value: value,
      ));
    });
  }

  QueryBuilder<PersonalRecordIsar, PersonalRecordIsar, QAfterFilterCondition>
      rankBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'rank',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<PersonalRecordIsar, PersonalRecordIsar, QAfterFilterCondition>
      runIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'runId',
      ));
    });
  }

  QueryBuilder<PersonalRecordIsar, PersonalRecordIsar, QAfterFilterCondition>
      runIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'runId',
      ));
    });
  }

  QueryBuilder<PersonalRecordIsar, PersonalRecordIsar, QAfterFilterCondition>
      runIdEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'runId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PersonalRecordIsar, PersonalRecordIsar, QAfterFilterCondition>
      runIdGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'runId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PersonalRecordIsar, PersonalRecordIsar, QAfterFilterCondition>
      runIdLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'runId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PersonalRecordIsar, PersonalRecordIsar, QAfterFilterCondition>
      runIdBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'runId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PersonalRecordIsar, PersonalRecordIsar, QAfterFilterCondition>
      runIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'runId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PersonalRecordIsar, PersonalRecordIsar, QAfterFilterCondition>
      runIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'runId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PersonalRecordIsar, PersonalRecordIsar, QAfterFilterCondition>
      runIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'runId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PersonalRecordIsar, PersonalRecordIsar, QAfterFilterCondition>
      runIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'runId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PersonalRecordIsar, PersonalRecordIsar, QAfterFilterCondition>
      runIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'runId',
        value: '',
      ));
    });
  }

  QueryBuilder<PersonalRecordIsar, PersonalRecordIsar, QAfterFilterCondition>
      runIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'runId',
        value: '',
      ));
    });
  }

  QueryBuilder<PersonalRecordIsar, PersonalRecordIsar, QAfterFilterCondition>
      sourceIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'source',
      ));
    });
  }

  QueryBuilder<PersonalRecordIsar, PersonalRecordIsar, QAfterFilterCondition>
      sourceIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'source',
      ));
    });
  }

  QueryBuilder<PersonalRecordIsar, PersonalRecordIsar, QAfterFilterCondition>
      sourceEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'source',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PersonalRecordIsar, PersonalRecordIsar, QAfterFilterCondition>
      sourceGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'source',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PersonalRecordIsar, PersonalRecordIsar, QAfterFilterCondition>
      sourceLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'source',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PersonalRecordIsar, PersonalRecordIsar, QAfterFilterCondition>
      sourceBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'source',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PersonalRecordIsar, PersonalRecordIsar, QAfterFilterCondition>
      sourceStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'source',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PersonalRecordIsar, PersonalRecordIsar, QAfterFilterCondition>
      sourceEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'source',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PersonalRecordIsar, PersonalRecordIsar, QAfterFilterCondition>
      sourceContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'source',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PersonalRecordIsar, PersonalRecordIsar, QAfterFilterCondition>
      sourceMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'source',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PersonalRecordIsar, PersonalRecordIsar, QAfterFilterCondition>
      sourceIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'source',
        value: '',
      ));
    });
  }

  QueryBuilder<PersonalRecordIsar, PersonalRecordIsar, QAfterFilterCondition>
      sourceIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'source',
        value: '',
      ));
    });
  }

  QueryBuilder<PersonalRecordIsar, PersonalRecordIsar, QAfterFilterCondition>
      valueIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'value',
      ));
    });
  }

  QueryBuilder<PersonalRecordIsar, PersonalRecordIsar, QAfterFilterCondition>
      valueIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'value',
      ));
    });
  }

  QueryBuilder<PersonalRecordIsar, PersonalRecordIsar, QAfterFilterCondition>
      valueEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'value',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<PersonalRecordIsar, PersonalRecordIsar, QAfterFilterCondition>
      valueGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'value',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<PersonalRecordIsar, PersonalRecordIsar, QAfterFilterCondition>
      valueLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'value',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<PersonalRecordIsar, PersonalRecordIsar, QAfterFilterCondition>
      valueBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'value',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }
}

extension PersonalRecordIsarQueryObject
    on QueryBuilder<PersonalRecordIsar, PersonalRecordIsar, QFilterCondition> {}

extension PersonalRecordIsarQueryLinks
    on QueryBuilder<PersonalRecordIsar, PersonalRecordIsar, QFilterCondition> {}

extension PersonalRecordIsarQuerySortBy
    on QueryBuilder<PersonalRecordIsar, PersonalRecordIsar, QSortBy> {
  QueryBuilder<PersonalRecordIsar, PersonalRecordIsar, QAfterSortBy>
      sortByAchievedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'achievedAt', Sort.asc);
    });
  }

  QueryBuilder<PersonalRecordIsar, PersonalRecordIsar, QAfterSortBy>
      sortByAchievedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'achievedAt', Sort.desc);
    });
  }

  QueryBuilder<PersonalRecordIsar, PersonalRecordIsar, QAfterSortBy>
      sortByCategory() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'category', Sort.asc);
    });
  }

  QueryBuilder<PersonalRecordIsar, PersonalRecordIsar, QAfterSortBy>
      sortByCategoryDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'category', Sort.desc);
    });
  }

  QueryBuilder<PersonalRecordIsar, PersonalRecordIsar, QAfterSortBy>
      sortByProofUrl() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'proofUrl', Sort.asc);
    });
  }

  QueryBuilder<PersonalRecordIsar, PersonalRecordIsar, QAfterSortBy>
      sortByProofUrlDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'proofUrl', Sort.desc);
    });
  }

  QueryBuilder<PersonalRecordIsar, PersonalRecordIsar, QAfterSortBy>
      sortByRank() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rank', Sort.asc);
    });
  }

  QueryBuilder<PersonalRecordIsar, PersonalRecordIsar, QAfterSortBy>
      sortByRankDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rank', Sort.desc);
    });
  }

  QueryBuilder<PersonalRecordIsar, PersonalRecordIsar, QAfterSortBy>
      sortByRunId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'runId', Sort.asc);
    });
  }

  QueryBuilder<PersonalRecordIsar, PersonalRecordIsar, QAfterSortBy>
      sortByRunIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'runId', Sort.desc);
    });
  }

  QueryBuilder<PersonalRecordIsar, PersonalRecordIsar, QAfterSortBy>
      sortBySource() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'source', Sort.asc);
    });
  }

  QueryBuilder<PersonalRecordIsar, PersonalRecordIsar, QAfterSortBy>
      sortBySourceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'source', Sort.desc);
    });
  }

  QueryBuilder<PersonalRecordIsar, PersonalRecordIsar, QAfterSortBy>
      sortByValue() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'value', Sort.asc);
    });
  }

  QueryBuilder<PersonalRecordIsar, PersonalRecordIsar, QAfterSortBy>
      sortByValueDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'value', Sort.desc);
    });
  }
}

extension PersonalRecordIsarQuerySortThenBy
    on QueryBuilder<PersonalRecordIsar, PersonalRecordIsar, QSortThenBy> {
  QueryBuilder<PersonalRecordIsar, PersonalRecordIsar, QAfterSortBy>
      thenByAchievedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'achievedAt', Sort.asc);
    });
  }

  QueryBuilder<PersonalRecordIsar, PersonalRecordIsar, QAfterSortBy>
      thenByAchievedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'achievedAt', Sort.desc);
    });
  }

  QueryBuilder<PersonalRecordIsar, PersonalRecordIsar, QAfterSortBy>
      thenByCategory() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'category', Sort.asc);
    });
  }

  QueryBuilder<PersonalRecordIsar, PersonalRecordIsar, QAfterSortBy>
      thenByCategoryDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'category', Sort.desc);
    });
  }

  QueryBuilder<PersonalRecordIsar, PersonalRecordIsar, QAfterSortBy>
      thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<PersonalRecordIsar, PersonalRecordIsar, QAfterSortBy>
      thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<PersonalRecordIsar, PersonalRecordIsar, QAfterSortBy>
      thenByProofUrl() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'proofUrl', Sort.asc);
    });
  }

  QueryBuilder<PersonalRecordIsar, PersonalRecordIsar, QAfterSortBy>
      thenByProofUrlDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'proofUrl', Sort.desc);
    });
  }

  QueryBuilder<PersonalRecordIsar, PersonalRecordIsar, QAfterSortBy>
      thenByRank() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rank', Sort.asc);
    });
  }

  QueryBuilder<PersonalRecordIsar, PersonalRecordIsar, QAfterSortBy>
      thenByRankDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rank', Sort.desc);
    });
  }

  QueryBuilder<PersonalRecordIsar, PersonalRecordIsar, QAfterSortBy>
      thenByRunId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'runId', Sort.asc);
    });
  }

  QueryBuilder<PersonalRecordIsar, PersonalRecordIsar, QAfterSortBy>
      thenByRunIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'runId', Sort.desc);
    });
  }

  QueryBuilder<PersonalRecordIsar, PersonalRecordIsar, QAfterSortBy>
      thenBySource() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'source', Sort.asc);
    });
  }

  QueryBuilder<PersonalRecordIsar, PersonalRecordIsar, QAfterSortBy>
      thenBySourceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'source', Sort.desc);
    });
  }

  QueryBuilder<PersonalRecordIsar, PersonalRecordIsar, QAfterSortBy>
      thenByValue() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'value', Sort.asc);
    });
  }

  QueryBuilder<PersonalRecordIsar, PersonalRecordIsar, QAfterSortBy>
      thenByValueDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'value', Sort.desc);
    });
  }
}

extension PersonalRecordIsarQueryWhereDistinct
    on QueryBuilder<PersonalRecordIsar, PersonalRecordIsar, QDistinct> {
  QueryBuilder<PersonalRecordIsar, PersonalRecordIsar, QDistinct>
      distinctByAchievedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'achievedAt');
    });
  }

  QueryBuilder<PersonalRecordIsar, PersonalRecordIsar, QDistinct>
      distinctByCategory({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'category', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PersonalRecordIsar, PersonalRecordIsar, QDistinct>
      distinctByProofUrl({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'proofUrl', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PersonalRecordIsar, PersonalRecordIsar, QDistinct>
      distinctByRank() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'rank');
    });
  }

  QueryBuilder<PersonalRecordIsar, PersonalRecordIsar, QDistinct>
      distinctByRunId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'runId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PersonalRecordIsar, PersonalRecordIsar, QDistinct>
      distinctBySource({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'source', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PersonalRecordIsar, PersonalRecordIsar, QDistinct>
      distinctByValue() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'value');
    });
  }
}

extension PersonalRecordIsarQueryProperty
    on QueryBuilder<PersonalRecordIsar, PersonalRecordIsar, QQueryProperty> {
  QueryBuilder<PersonalRecordIsar, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<PersonalRecordIsar, DateTime?, QQueryOperations>
      achievedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'achievedAt');
    });
  }

  QueryBuilder<PersonalRecordIsar, String?, QQueryOperations>
      categoryProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'category');
    });
  }

  QueryBuilder<PersonalRecordIsar, String?, QQueryOperations>
      proofUrlProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'proofUrl');
    });
  }

  QueryBuilder<PersonalRecordIsar, int?, QQueryOperations> rankProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'rank');
    });
  }

  QueryBuilder<PersonalRecordIsar, String?, QQueryOperations> runIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'runId');
    });
  }

  QueryBuilder<PersonalRecordIsar, String?, QQueryOperations> sourceProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'source');
    });
  }

  QueryBuilder<PersonalRecordIsar, double?, QQueryOperations> valueProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'value');
    });
  }
}
