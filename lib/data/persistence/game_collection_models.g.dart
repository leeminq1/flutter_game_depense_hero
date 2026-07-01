// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'game_collection_models.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetPlayerProfileCollection on Isar {
  IsarCollection<PlayerProfile> get playerProfiles => this.collection();
}

const PlayerProfileSchema = CollectionSchema(
  name: r'PlayerProfile',
  id: -7715882953709164590,
  properties: {
    r'accountLevel': PropertySchema(
      id: 0,
      name: r'accountLevel',
      type: IsarType.long,
    ),
    r'createdAt': PropertySchema(
      id: 1,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'lastPlayedAt': PropertySchema(
      id: 2,
      name: r'lastPlayedAt',
      type: IsarType.dateTime,
    ),
    r'premiumCurrency': PropertySchema(
      id: 3,
      name: r'premiumCurrency',
      type: IsarType.long,
    ),
    r'softCurrency': PropertySchema(
      id: 4,
      name: r'softCurrency',
      type: IsarType.long,
    ),
    r'totalXp': PropertySchema(id: 5, name: r'totalXp', type: IsarType.long),
  },

  estimateSize: _playerProfileEstimateSize,
  serialize: _playerProfileSerialize,
  deserialize: _playerProfileDeserialize,
  deserializeProp: _playerProfileDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {},
  embeddedSchemas: {},

  getId: _playerProfileGetId,
  getLinks: _playerProfileGetLinks,
  attach: _playerProfileAttach,
  version: '3.3.2',
);

int _playerProfileEstimateSize(
  PlayerProfile object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  return bytesCount;
}

void _playerProfileSerialize(
  PlayerProfile object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeLong(offsets[0], object.accountLevel);
  writer.writeDateTime(offsets[1], object.createdAt);
  writer.writeDateTime(offsets[2], object.lastPlayedAt);
  writer.writeLong(offsets[3], object.premiumCurrency);
  writer.writeLong(offsets[4], object.softCurrency);
  writer.writeLong(offsets[5], object.totalXp);
}

PlayerProfile _playerProfileDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = PlayerProfile();
  object.accountLevel = reader.readLong(offsets[0]);
  object.createdAt = reader.readDateTime(offsets[1]);
  object.id = id;
  object.lastPlayedAt = reader.readDateTime(offsets[2]);
  object.premiumCurrency = reader.readLong(offsets[3]);
  object.softCurrency = reader.readLong(offsets[4]);
  object.totalXp = reader.readLong(offsets[5]);
  return object;
}

P _playerProfileDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readLong(offset)) as P;
    case 1:
      return (reader.readDateTime(offset)) as P;
    case 2:
      return (reader.readDateTime(offset)) as P;
    case 3:
      return (reader.readLong(offset)) as P;
    case 4:
      return (reader.readLong(offset)) as P;
    case 5:
      return (reader.readLong(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _playerProfileGetId(PlayerProfile object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _playerProfileGetLinks(PlayerProfile object) {
  return [];
}

void _playerProfileAttach(
  IsarCollection<dynamic> col,
  Id id,
  PlayerProfile object,
) {
  object.id = id;
}

extension PlayerProfileQueryWhereSort
    on QueryBuilder<PlayerProfile, PlayerProfile, QWhere> {
  QueryBuilder<PlayerProfile, PlayerProfile, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension PlayerProfileQueryWhere
    on QueryBuilder<PlayerProfile, PlayerProfile, QWhereClause> {
  QueryBuilder<PlayerProfile, PlayerProfile, QAfterWhereClause> idEqualTo(
    Id id,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<PlayerProfile, PlayerProfile, QAfterWhereClause> idNotEqualTo(
    Id id,
  ) {
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

  QueryBuilder<PlayerProfile, PlayerProfile, QAfterWhereClause> idGreaterThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<PlayerProfile, PlayerProfile, QAfterWhereClause> idLessThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<PlayerProfile, PlayerProfile, QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.between(
          lower: lowerId,
          includeLower: includeLower,
          upper: upperId,
          includeUpper: includeUpper,
        ),
      );
    });
  }
}

extension PlayerProfileQueryFilter
    on QueryBuilder<PlayerProfile, PlayerProfile, QFilterCondition> {
  QueryBuilder<PlayerProfile, PlayerProfile, QAfterFilterCondition>
  accountLevelEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'accountLevel', value: value),
      );
    });
  }

  QueryBuilder<PlayerProfile, PlayerProfile, QAfterFilterCondition>
  accountLevelGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'accountLevel',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<PlayerProfile, PlayerProfile, QAfterFilterCondition>
  accountLevelLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'accountLevel',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<PlayerProfile, PlayerProfile, QAfterFilterCondition>
  accountLevelBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'accountLevel',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<PlayerProfile, PlayerProfile, QAfterFilterCondition>
  createdAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'createdAt', value: value),
      );
    });
  }

  QueryBuilder<PlayerProfile, PlayerProfile, QAfterFilterCondition>
  createdAtGreaterThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'createdAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<PlayerProfile, PlayerProfile, QAfterFilterCondition>
  createdAtLessThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'createdAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<PlayerProfile, PlayerProfile, QAfterFilterCondition>
  createdAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'createdAt',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<PlayerProfile, PlayerProfile, QAfterFilterCondition> idEqualTo(
    Id value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: value),
      );
    });
  }

  QueryBuilder<PlayerProfile, PlayerProfile, QAfterFilterCondition>
  idGreaterThan(Id value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'id',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<PlayerProfile, PlayerProfile, QAfterFilterCondition> idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'id',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<PlayerProfile, PlayerProfile, QAfterFilterCondition> idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'id',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<PlayerProfile, PlayerProfile, QAfterFilterCondition>
  lastPlayedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'lastPlayedAt', value: value),
      );
    });
  }

  QueryBuilder<PlayerProfile, PlayerProfile, QAfterFilterCondition>
  lastPlayedAtGreaterThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'lastPlayedAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<PlayerProfile, PlayerProfile, QAfterFilterCondition>
  lastPlayedAtLessThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'lastPlayedAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<PlayerProfile, PlayerProfile, QAfterFilterCondition>
  lastPlayedAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'lastPlayedAt',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<PlayerProfile, PlayerProfile, QAfterFilterCondition>
  premiumCurrencyEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'premiumCurrency', value: value),
      );
    });
  }

  QueryBuilder<PlayerProfile, PlayerProfile, QAfterFilterCondition>
  premiumCurrencyGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'premiumCurrency',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<PlayerProfile, PlayerProfile, QAfterFilterCondition>
  premiumCurrencyLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'premiumCurrency',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<PlayerProfile, PlayerProfile, QAfterFilterCondition>
  premiumCurrencyBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'premiumCurrency',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<PlayerProfile, PlayerProfile, QAfterFilterCondition>
  softCurrencyEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'softCurrency', value: value),
      );
    });
  }

  QueryBuilder<PlayerProfile, PlayerProfile, QAfterFilterCondition>
  softCurrencyGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'softCurrency',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<PlayerProfile, PlayerProfile, QAfterFilterCondition>
  softCurrencyLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'softCurrency',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<PlayerProfile, PlayerProfile, QAfterFilterCondition>
  softCurrencyBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'softCurrency',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<PlayerProfile, PlayerProfile, QAfterFilterCondition>
  totalXpEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'totalXp', value: value),
      );
    });
  }

  QueryBuilder<PlayerProfile, PlayerProfile, QAfterFilterCondition>
  totalXpGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'totalXp',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<PlayerProfile, PlayerProfile, QAfterFilterCondition>
  totalXpLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'totalXp',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<PlayerProfile, PlayerProfile, QAfterFilterCondition>
  totalXpBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'totalXp',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }
}

extension PlayerProfileQueryObject
    on QueryBuilder<PlayerProfile, PlayerProfile, QFilterCondition> {}

extension PlayerProfileQueryLinks
    on QueryBuilder<PlayerProfile, PlayerProfile, QFilterCondition> {}

extension PlayerProfileQuerySortBy
    on QueryBuilder<PlayerProfile, PlayerProfile, QSortBy> {
  QueryBuilder<PlayerProfile, PlayerProfile, QAfterSortBy>
  sortByAccountLevel() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'accountLevel', Sort.asc);
    });
  }

  QueryBuilder<PlayerProfile, PlayerProfile, QAfterSortBy>
  sortByAccountLevelDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'accountLevel', Sort.desc);
    });
  }

  QueryBuilder<PlayerProfile, PlayerProfile, QAfterSortBy> sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<PlayerProfile, PlayerProfile, QAfterSortBy>
  sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<PlayerProfile, PlayerProfile, QAfterSortBy>
  sortByLastPlayedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastPlayedAt', Sort.asc);
    });
  }

  QueryBuilder<PlayerProfile, PlayerProfile, QAfterSortBy>
  sortByLastPlayedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastPlayedAt', Sort.desc);
    });
  }

  QueryBuilder<PlayerProfile, PlayerProfile, QAfterSortBy>
  sortByPremiumCurrency() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'premiumCurrency', Sort.asc);
    });
  }

  QueryBuilder<PlayerProfile, PlayerProfile, QAfterSortBy>
  sortByPremiumCurrencyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'premiumCurrency', Sort.desc);
    });
  }

  QueryBuilder<PlayerProfile, PlayerProfile, QAfterSortBy>
  sortBySoftCurrency() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'softCurrency', Sort.asc);
    });
  }

  QueryBuilder<PlayerProfile, PlayerProfile, QAfterSortBy>
  sortBySoftCurrencyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'softCurrency', Sort.desc);
    });
  }

  QueryBuilder<PlayerProfile, PlayerProfile, QAfterSortBy> sortByTotalXp() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalXp', Sort.asc);
    });
  }

  QueryBuilder<PlayerProfile, PlayerProfile, QAfterSortBy> sortByTotalXpDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalXp', Sort.desc);
    });
  }
}

extension PlayerProfileQuerySortThenBy
    on QueryBuilder<PlayerProfile, PlayerProfile, QSortThenBy> {
  QueryBuilder<PlayerProfile, PlayerProfile, QAfterSortBy>
  thenByAccountLevel() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'accountLevel', Sort.asc);
    });
  }

  QueryBuilder<PlayerProfile, PlayerProfile, QAfterSortBy>
  thenByAccountLevelDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'accountLevel', Sort.desc);
    });
  }

  QueryBuilder<PlayerProfile, PlayerProfile, QAfterSortBy> thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<PlayerProfile, PlayerProfile, QAfterSortBy>
  thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<PlayerProfile, PlayerProfile, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<PlayerProfile, PlayerProfile, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<PlayerProfile, PlayerProfile, QAfterSortBy>
  thenByLastPlayedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastPlayedAt', Sort.asc);
    });
  }

  QueryBuilder<PlayerProfile, PlayerProfile, QAfterSortBy>
  thenByLastPlayedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastPlayedAt', Sort.desc);
    });
  }

  QueryBuilder<PlayerProfile, PlayerProfile, QAfterSortBy>
  thenByPremiumCurrency() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'premiumCurrency', Sort.asc);
    });
  }

  QueryBuilder<PlayerProfile, PlayerProfile, QAfterSortBy>
  thenByPremiumCurrencyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'premiumCurrency', Sort.desc);
    });
  }

  QueryBuilder<PlayerProfile, PlayerProfile, QAfterSortBy>
  thenBySoftCurrency() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'softCurrency', Sort.asc);
    });
  }

  QueryBuilder<PlayerProfile, PlayerProfile, QAfterSortBy>
  thenBySoftCurrencyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'softCurrency', Sort.desc);
    });
  }

  QueryBuilder<PlayerProfile, PlayerProfile, QAfterSortBy> thenByTotalXp() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalXp', Sort.asc);
    });
  }

  QueryBuilder<PlayerProfile, PlayerProfile, QAfterSortBy> thenByTotalXpDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalXp', Sort.desc);
    });
  }
}

extension PlayerProfileQueryWhereDistinct
    on QueryBuilder<PlayerProfile, PlayerProfile, QDistinct> {
  QueryBuilder<PlayerProfile, PlayerProfile, QDistinct>
  distinctByAccountLevel() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'accountLevel');
    });
  }

  QueryBuilder<PlayerProfile, PlayerProfile, QDistinct> distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<PlayerProfile, PlayerProfile, QDistinct>
  distinctByLastPlayedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lastPlayedAt');
    });
  }

  QueryBuilder<PlayerProfile, PlayerProfile, QDistinct>
  distinctByPremiumCurrency() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'premiumCurrency');
    });
  }

  QueryBuilder<PlayerProfile, PlayerProfile, QDistinct>
  distinctBySoftCurrency() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'softCurrency');
    });
  }

  QueryBuilder<PlayerProfile, PlayerProfile, QDistinct> distinctByTotalXp() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'totalXp');
    });
  }
}

extension PlayerProfileQueryProperty
    on QueryBuilder<PlayerProfile, PlayerProfile, QQueryProperty> {
  QueryBuilder<PlayerProfile, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<PlayerProfile, int, QQueryOperations> accountLevelProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'accountLevel');
    });
  }

  QueryBuilder<PlayerProfile, DateTime, QQueryOperations> createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<PlayerProfile, DateTime, QQueryOperations>
  lastPlayedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastPlayedAt');
    });
  }

  QueryBuilder<PlayerProfile, int, QQueryOperations> premiumCurrencyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'premiumCurrency');
    });
  }

  QueryBuilder<PlayerProfile, int, QQueryOperations> softCurrencyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'softCurrency');
    });
  }

  QueryBuilder<PlayerProfile, int, QQueryOperations> totalXpProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'totalXp');
    });
  }
}

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetStageProgressRecordCollection on Isar {
  IsarCollection<StageProgressRecord> get stageProgressRecords =>
      this.collection();
}

const StageProgressRecordSchema = CollectionSchema(
  name: r'StageProgressRecord',
  id: -4752680980915453452,
  properties: {
    r'firstClearedAt': PropertySchema(
      id: 0,
      name: r'firstClearedAt',
      type: IsarType.dateTime,
    ),
    r'lastClearedAt': PropertySchema(
      id: 1,
      name: r'lastClearedAt',
      type: IsarType.dateTime,
    ),
    r'stageNumber': PropertySchema(
      id: 2,
      name: r'stageNumber',
      type: IsarType.long,
    ),
    r'stars': PropertySchema(id: 3, name: r'stars', type: IsarType.long),
    r'unlocked': PropertySchema(id: 4, name: r'unlocked', type: IsarType.bool),
  },

  estimateSize: _stageProgressRecordEstimateSize,
  serialize: _stageProgressRecordSerialize,
  deserialize: _stageProgressRecordDeserialize,
  deserializeProp: _stageProgressRecordDeserializeProp,
  idName: r'id',
  indexes: {
    r'stageNumber': IndexSchema(
      id: -9111739378591519906,
      name: r'stageNumber',
      unique: true,
      replace: true,
      properties: [
        IndexPropertySchema(
          name: r'stageNumber',
          type: IndexType.value,
          caseSensitive: false,
        ),
      ],
    ),
  },
  links: {},
  embeddedSchemas: {},

  getId: _stageProgressRecordGetId,
  getLinks: _stageProgressRecordGetLinks,
  attach: _stageProgressRecordAttach,
  version: '3.3.2',
);

int _stageProgressRecordEstimateSize(
  StageProgressRecord object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  return bytesCount;
}

void _stageProgressRecordSerialize(
  StageProgressRecord object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDateTime(offsets[0], object.firstClearedAt);
  writer.writeDateTime(offsets[1], object.lastClearedAt);
  writer.writeLong(offsets[2], object.stageNumber);
  writer.writeLong(offsets[3], object.stars);
  writer.writeBool(offsets[4], object.unlocked);
}

StageProgressRecord _stageProgressRecordDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = StageProgressRecord();
  object.firstClearedAt = reader.readDateTimeOrNull(offsets[0]);
  object.id = id;
  object.lastClearedAt = reader.readDateTimeOrNull(offsets[1]);
  object.stageNumber = reader.readLong(offsets[2]);
  object.stars = reader.readLong(offsets[3]);
  object.unlocked = reader.readBool(offsets[4]);
  return object;
}

P _stageProgressRecordDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 1:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 2:
      return (reader.readLong(offset)) as P;
    case 3:
      return (reader.readLong(offset)) as P;
    case 4:
      return (reader.readBool(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _stageProgressRecordGetId(StageProgressRecord object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _stageProgressRecordGetLinks(
  StageProgressRecord object,
) {
  return [];
}

void _stageProgressRecordAttach(
  IsarCollection<dynamic> col,
  Id id,
  StageProgressRecord object,
) {
  object.id = id;
}

extension StageProgressRecordByIndex on IsarCollection<StageProgressRecord> {
  Future<StageProgressRecord?> getByStageNumber(int stageNumber) {
    return getByIndex(r'stageNumber', [stageNumber]);
  }

  StageProgressRecord? getByStageNumberSync(int stageNumber) {
    return getByIndexSync(r'stageNumber', [stageNumber]);
  }

  Future<bool> deleteByStageNumber(int stageNumber) {
    return deleteByIndex(r'stageNumber', [stageNumber]);
  }

  bool deleteByStageNumberSync(int stageNumber) {
    return deleteByIndexSync(r'stageNumber', [stageNumber]);
  }

  Future<List<StageProgressRecord?>> getAllByStageNumber(
    List<int> stageNumberValues,
  ) {
    final values = stageNumberValues.map((e) => [e]).toList();
    return getAllByIndex(r'stageNumber', values);
  }

  List<StageProgressRecord?> getAllByStageNumberSync(
    List<int> stageNumberValues,
  ) {
    final values = stageNumberValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'stageNumber', values);
  }

  Future<int> deleteAllByStageNumber(List<int> stageNumberValues) {
    final values = stageNumberValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'stageNumber', values);
  }

  int deleteAllByStageNumberSync(List<int> stageNumberValues) {
    final values = stageNumberValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'stageNumber', values);
  }

  Future<Id> putByStageNumber(StageProgressRecord object) {
    return putByIndex(r'stageNumber', object);
  }

  Id putByStageNumberSync(StageProgressRecord object, {bool saveLinks = true}) {
    return putByIndexSync(r'stageNumber', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByStageNumber(List<StageProgressRecord> objects) {
    return putAllByIndex(r'stageNumber', objects);
  }

  List<Id> putAllByStageNumberSync(
    List<StageProgressRecord> objects, {
    bool saveLinks = true,
  }) {
    return putAllByIndexSync(r'stageNumber', objects, saveLinks: saveLinks);
  }
}

extension StageProgressRecordQueryWhereSort
    on QueryBuilder<StageProgressRecord, StageProgressRecord, QWhere> {
  QueryBuilder<StageProgressRecord, StageProgressRecord, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<StageProgressRecord, StageProgressRecord, QAfterWhere>
  anyStageNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'stageNumber'),
      );
    });
  }
}

extension StageProgressRecordQueryWhere
    on QueryBuilder<StageProgressRecord, StageProgressRecord, QWhereClause> {
  QueryBuilder<StageProgressRecord, StageProgressRecord, QAfterWhereClause>
  idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<StageProgressRecord, StageProgressRecord, QAfterWhereClause>
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

  QueryBuilder<StageProgressRecord, StageProgressRecord, QAfterWhereClause>
  idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<StageProgressRecord, StageProgressRecord, QAfterWhereClause>
  idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<StageProgressRecord, StageProgressRecord, QAfterWhereClause>
  idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.between(
          lower: lowerId,
          includeLower: includeLower,
          upper: upperId,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<StageProgressRecord, StageProgressRecord, QAfterWhereClause>
  stageNumberEqualTo(int stageNumber) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(
          indexName: r'stageNumber',
          value: [stageNumber],
        ),
      );
    });
  }

  QueryBuilder<StageProgressRecord, StageProgressRecord, QAfterWhereClause>
  stageNumberNotEqualTo(int stageNumber) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'stageNumber',
                lower: [],
                upper: [stageNumber],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'stageNumber',
                lower: [stageNumber],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'stageNumber',
                lower: [stageNumber],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'stageNumber',
                lower: [],
                upper: [stageNumber],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<StageProgressRecord, StageProgressRecord, QAfterWhereClause>
  stageNumberGreaterThan(int stageNumber, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'stageNumber',
          lower: [stageNumber],
          includeLower: include,
          upper: [],
        ),
      );
    });
  }

  QueryBuilder<StageProgressRecord, StageProgressRecord, QAfterWhereClause>
  stageNumberLessThan(int stageNumber, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'stageNumber',
          lower: [],
          upper: [stageNumber],
          includeUpper: include,
        ),
      );
    });
  }

  QueryBuilder<StageProgressRecord, StageProgressRecord, QAfterWhereClause>
  stageNumberBetween(
    int lowerStageNumber,
    int upperStageNumber, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'stageNumber',
          lower: [lowerStageNumber],
          includeLower: includeLower,
          upper: [upperStageNumber],
          includeUpper: includeUpper,
        ),
      );
    });
  }
}

extension StageProgressRecordQueryFilter
    on
        QueryBuilder<
          StageProgressRecord,
          StageProgressRecord,
          QFilterCondition
        > {
  QueryBuilder<StageProgressRecord, StageProgressRecord, QAfterFilterCondition>
  firstClearedAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'firstClearedAt'),
      );
    });
  }

  QueryBuilder<StageProgressRecord, StageProgressRecord, QAfterFilterCondition>
  firstClearedAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'firstClearedAt'),
      );
    });
  }

  QueryBuilder<StageProgressRecord, StageProgressRecord, QAfterFilterCondition>
  firstClearedAtEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'firstClearedAt', value: value),
      );
    });
  }

  QueryBuilder<StageProgressRecord, StageProgressRecord, QAfterFilterCondition>
  firstClearedAtGreaterThan(DateTime? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'firstClearedAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<StageProgressRecord, StageProgressRecord, QAfterFilterCondition>
  firstClearedAtLessThan(DateTime? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'firstClearedAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<StageProgressRecord, StageProgressRecord, QAfterFilterCondition>
  firstClearedAtBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'firstClearedAt',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<StageProgressRecord, StageProgressRecord, QAfterFilterCondition>
  idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: value),
      );
    });
  }

  QueryBuilder<StageProgressRecord, StageProgressRecord, QAfterFilterCondition>
  idGreaterThan(Id value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'id',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<StageProgressRecord, StageProgressRecord, QAfterFilterCondition>
  idLessThan(Id value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'id',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<StageProgressRecord, StageProgressRecord, QAfterFilterCondition>
  idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'id',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<StageProgressRecord, StageProgressRecord, QAfterFilterCondition>
  lastClearedAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'lastClearedAt'),
      );
    });
  }

  QueryBuilder<StageProgressRecord, StageProgressRecord, QAfterFilterCondition>
  lastClearedAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'lastClearedAt'),
      );
    });
  }

  QueryBuilder<StageProgressRecord, StageProgressRecord, QAfterFilterCondition>
  lastClearedAtEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'lastClearedAt', value: value),
      );
    });
  }

  QueryBuilder<StageProgressRecord, StageProgressRecord, QAfterFilterCondition>
  lastClearedAtGreaterThan(DateTime? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'lastClearedAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<StageProgressRecord, StageProgressRecord, QAfterFilterCondition>
  lastClearedAtLessThan(DateTime? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'lastClearedAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<StageProgressRecord, StageProgressRecord, QAfterFilterCondition>
  lastClearedAtBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'lastClearedAt',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<StageProgressRecord, StageProgressRecord, QAfterFilterCondition>
  stageNumberEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'stageNumber', value: value),
      );
    });
  }

  QueryBuilder<StageProgressRecord, StageProgressRecord, QAfterFilterCondition>
  stageNumberGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'stageNumber',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<StageProgressRecord, StageProgressRecord, QAfterFilterCondition>
  stageNumberLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'stageNumber',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<StageProgressRecord, StageProgressRecord, QAfterFilterCondition>
  stageNumberBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'stageNumber',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<StageProgressRecord, StageProgressRecord, QAfterFilterCondition>
  starsEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'stars', value: value),
      );
    });
  }

  QueryBuilder<StageProgressRecord, StageProgressRecord, QAfterFilterCondition>
  starsGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'stars',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<StageProgressRecord, StageProgressRecord, QAfterFilterCondition>
  starsLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'stars',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<StageProgressRecord, StageProgressRecord, QAfterFilterCondition>
  starsBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'stars',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<StageProgressRecord, StageProgressRecord, QAfterFilterCondition>
  unlockedEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'unlocked', value: value),
      );
    });
  }
}

extension StageProgressRecordQueryObject
    on
        QueryBuilder<
          StageProgressRecord,
          StageProgressRecord,
          QFilterCondition
        > {}

extension StageProgressRecordQueryLinks
    on
        QueryBuilder<
          StageProgressRecord,
          StageProgressRecord,
          QFilterCondition
        > {}

extension StageProgressRecordQuerySortBy
    on QueryBuilder<StageProgressRecord, StageProgressRecord, QSortBy> {
  QueryBuilder<StageProgressRecord, StageProgressRecord, QAfterSortBy>
  sortByFirstClearedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'firstClearedAt', Sort.asc);
    });
  }

  QueryBuilder<StageProgressRecord, StageProgressRecord, QAfterSortBy>
  sortByFirstClearedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'firstClearedAt', Sort.desc);
    });
  }

  QueryBuilder<StageProgressRecord, StageProgressRecord, QAfterSortBy>
  sortByLastClearedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastClearedAt', Sort.asc);
    });
  }

  QueryBuilder<StageProgressRecord, StageProgressRecord, QAfterSortBy>
  sortByLastClearedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastClearedAt', Sort.desc);
    });
  }

  QueryBuilder<StageProgressRecord, StageProgressRecord, QAfterSortBy>
  sortByStageNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'stageNumber', Sort.asc);
    });
  }

  QueryBuilder<StageProgressRecord, StageProgressRecord, QAfterSortBy>
  sortByStageNumberDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'stageNumber', Sort.desc);
    });
  }

  QueryBuilder<StageProgressRecord, StageProgressRecord, QAfterSortBy>
  sortByStars() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'stars', Sort.asc);
    });
  }

  QueryBuilder<StageProgressRecord, StageProgressRecord, QAfterSortBy>
  sortByStarsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'stars', Sort.desc);
    });
  }

  QueryBuilder<StageProgressRecord, StageProgressRecord, QAfterSortBy>
  sortByUnlocked() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'unlocked', Sort.asc);
    });
  }

  QueryBuilder<StageProgressRecord, StageProgressRecord, QAfterSortBy>
  sortByUnlockedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'unlocked', Sort.desc);
    });
  }
}

extension StageProgressRecordQuerySortThenBy
    on QueryBuilder<StageProgressRecord, StageProgressRecord, QSortThenBy> {
  QueryBuilder<StageProgressRecord, StageProgressRecord, QAfterSortBy>
  thenByFirstClearedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'firstClearedAt', Sort.asc);
    });
  }

  QueryBuilder<StageProgressRecord, StageProgressRecord, QAfterSortBy>
  thenByFirstClearedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'firstClearedAt', Sort.desc);
    });
  }

  QueryBuilder<StageProgressRecord, StageProgressRecord, QAfterSortBy>
  thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<StageProgressRecord, StageProgressRecord, QAfterSortBy>
  thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<StageProgressRecord, StageProgressRecord, QAfterSortBy>
  thenByLastClearedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastClearedAt', Sort.asc);
    });
  }

  QueryBuilder<StageProgressRecord, StageProgressRecord, QAfterSortBy>
  thenByLastClearedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastClearedAt', Sort.desc);
    });
  }

  QueryBuilder<StageProgressRecord, StageProgressRecord, QAfterSortBy>
  thenByStageNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'stageNumber', Sort.asc);
    });
  }

  QueryBuilder<StageProgressRecord, StageProgressRecord, QAfterSortBy>
  thenByStageNumberDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'stageNumber', Sort.desc);
    });
  }

  QueryBuilder<StageProgressRecord, StageProgressRecord, QAfterSortBy>
  thenByStars() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'stars', Sort.asc);
    });
  }

  QueryBuilder<StageProgressRecord, StageProgressRecord, QAfterSortBy>
  thenByStarsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'stars', Sort.desc);
    });
  }

  QueryBuilder<StageProgressRecord, StageProgressRecord, QAfterSortBy>
  thenByUnlocked() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'unlocked', Sort.asc);
    });
  }

  QueryBuilder<StageProgressRecord, StageProgressRecord, QAfterSortBy>
  thenByUnlockedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'unlocked', Sort.desc);
    });
  }
}

extension StageProgressRecordQueryWhereDistinct
    on QueryBuilder<StageProgressRecord, StageProgressRecord, QDistinct> {
  QueryBuilder<StageProgressRecord, StageProgressRecord, QDistinct>
  distinctByFirstClearedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'firstClearedAt');
    });
  }

  QueryBuilder<StageProgressRecord, StageProgressRecord, QDistinct>
  distinctByLastClearedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lastClearedAt');
    });
  }

  QueryBuilder<StageProgressRecord, StageProgressRecord, QDistinct>
  distinctByStageNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'stageNumber');
    });
  }

  QueryBuilder<StageProgressRecord, StageProgressRecord, QDistinct>
  distinctByStars() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'stars');
    });
  }

  QueryBuilder<StageProgressRecord, StageProgressRecord, QDistinct>
  distinctByUnlocked() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'unlocked');
    });
  }
}

extension StageProgressRecordQueryProperty
    on QueryBuilder<StageProgressRecord, StageProgressRecord, QQueryProperty> {
  QueryBuilder<StageProgressRecord, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<StageProgressRecord, DateTime?, QQueryOperations>
  firstClearedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'firstClearedAt');
    });
  }

  QueryBuilder<StageProgressRecord, DateTime?, QQueryOperations>
  lastClearedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastClearedAt');
    });
  }

  QueryBuilder<StageProgressRecord, int, QQueryOperations>
  stageNumberProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'stageNumber');
    });
  }

  QueryBuilder<StageProgressRecord, int, QQueryOperations> starsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'stars');
    });
  }

  QueryBuilder<StageProgressRecord, bool, QQueryOperations> unlockedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'unlocked');
    });
  }
}

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetGameSettingsRecordCollection on Isar {
  IsarCollection<GameSettingsRecord> get gameSettingsRecords =>
      this.collection();
}

const GameSettingsRecordSchema = CollectionSchema(
  name: r'GameSettingsRecord',
  id: 8464630917065620853,
  properties: {
    r'masterVolume': PropertySchema(
      id: 0,
      name: r'masterVolume',
      type: IsarType.double,
    ),
    r'musicVolume': PropertySchema(
      id: 1,
      name: r'musicVolume',
      type: IsarType.double,
    ),
    r'muted': PropertySchema(id: 2, name: r'muted', type: IsarType.bool),
    r'sfxVolume': PropertySchema(
      id: 3,
      name: r'sfxVolume',
      type: IsarType.double,
    ),
    r'tutorialDismissed': PropertySchema(
      id: 4,
      name: r'tutorialDismissed',
      type: IsarType.bool,
    ),
  },

  estimateSize: _gameSettingsRecordEstimateSize,
  serialize: _gameSettingsRecordSerialize,
  deserialize: _gameSettingsRecordDeserialize,
  deserializeProp: _gameSettingsRecordDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {},
  embeddedSchemas: {},

  getId: _gameSettingsRecordGetId,
  getLinks: _gameSettingsRecordGetLinks,
  attach: _gameSettingsRecordAttach,
  version: '3.3.2',
);

int _gameSettingsRecordEstimateSize(
  GameSettingsRecord object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  return bytesCount;
}

void _gameSettingsRecordSerialize(
  GameSettingsRecord object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDouble(offsets[0], object.masterVolume);
  writer.writeDouble(offsets[1], object.musicVolume);
  writer.writeBool(offsets[2], object.muted);
  writer.writeDouble(offsets[3], object.sfxVolume);
  writer.writeBool(offsets[4], object.tutorialDismissed);
}

GameSettingsRecord _gameSettingsRecordDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = GameSettingsRecord();
  object.id = id;
  object.masterVolume = reader.readDouble(offsets[0]);
  object.musicVolume = reader.readDouble(offsets[1]);
  object.muted = reader.readBool(offsets[2]);
  object.sfxVolume = reader.readDouble(offsets[3]);
  object.tutorialDismissed = reader.readBool(offsets[4]);
  return object;
}

P _gameSettingsRecordDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDouble(offset)) as P;
    case 1:
      return (reader.readDouble(offset)) as P;
    case 2:
      return (reader.readBool(offset)) as P;
    case 3:
      return (reader.readDouble(offset)) as P;
    case 4:
      return (reader.readBool(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _gameSettingsRecordGetId(GameSettingsRecord object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _gameSettingsRecordGetLinks(
  GameSettingsRecord object,
) {
  return [];
}

void _gameSettingsRecordAttach(
  IsarCollection<dynamic> col,
  Id id,
  GameSettingsRecord object,
) {
  object.id = id;
}

extension GameSettingsRecordQueryWhereSort
    on QueryBuilder<GameSettingsRecord, GameSettingsRecord, QWhere> {
  QueryBuilder<GameSettingsRecord, GameSettingsRecord, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension GameSettingsRecordQueryWhere
    on QueryBuilder<GameSettingsRecord, GameSettingsRecord, QWhereClause> {
  QueryBuilder<GameSettingsRecord, GameSettingsRecord, QAfterWhereClause>
  idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<GameSettingsRecord, GameSettingsRecord, QAfterWhereClause>
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

  QueryBuilder<GameSettingsRecord, GameSettingsRecord, QAfterWhereClause>
  idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<GameSettingsRecord, GameSettingsRecord, QAfterWhereClause>
  idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<GameSettingsRecord, GameSettingsRecord, QAfterWhereClause>
  idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.between(
          lower: lowerId,
          includeLower: includeLower,
          upper: upperId,
          includeUpper: includeUpper,
        ),
      );
    });
  }
}

extension GameSettingsRecordQueryFilter
    on QueryBuilder<GameSettingsRecord, GameSettingsRecord, QFilterCondition> {
  QueryBuilder<GameSettingsRecord, GameSettingsRecord, QAfterFilterCondition>
  idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: value),
      );
    });
  }

  QueryBuilder<GameSettingsRecord, GameSettingsRecord, QAfterFilterCondition>
  idGreaterThan(Id value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'id',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<GameSettingsRecord, GameSettingsRecord, QAfterFilterCondition>
  idLessThan(Id value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'id',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<GameSettingsRecord, GameSettingsRecord, QAfterFilterCondition>
  idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'id',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<GameSettingsRecord, GameSettingsRecord, QAfterFilterCondition>
  masterVolumeEqualTo(double value, {double epsilon = Query.epsilon}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'masterVolume',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<GameSettingsRecord, GameSettingsRecord, QAfterFilterCondition>
  masterVolumeGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'masterVolume',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<GameSettingsRecord, GameSettingsRecord, QAfterFilterCondition>
  masterVolumeLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'masterVolume',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<GameSettingsRecord, GameSettingsRecord, QAfterFilterCondition>
  masterVolumeBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'masterVolume',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<GameSettingsRecord, GameSettingsRecord, QAfterFilterCondition>
  musicVolumeEqualTo(double value, {double epsilon = Query.epsilon}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'musicVolume',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<GameSettingsRecord, GameSettingsRecord, QAfterFilterCondition>
  musicVolumeGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'musicVolume',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<GameSettingsRecord, GameSettingsRecord, QAfterFilterCondition>
  musicVolumeLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'musicVolume',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<GameSettingsRecord, GameSettingsRecord, QAfterFilterCondition>
  musicVolumeBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'musicVolume',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<GameSettingsRecord, GameSettingsRecord, QAfterFilterCondition>
  mutedEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'muted', value: value),
      );
    });
  }

  QueryBuilder<GameSettingsRecord, GameSettingsRecord, QAfterFilterCondition>
  sfxVolumeEqualTo(double value, {double epsilon = Query.epsilon}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'sfxVolume',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<GameSettingsRecord, GameSettingsRecord, QAfterFilterCondition>
  sfxVolumeGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'sfxVolume',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<GameSettingsRecord, GameSettingsRecord, QAfterFilterCondition>
  sfxVolumeLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'sfxVolume',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<GameSettingsRecord, GameSettingsRecord, QAfterFilterCondition>
  sfxVolumeBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'sfxVolume',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<GameSettingsRecord, GameSettingsRecord, QAfterFilterCondition>
  tutorialDismissedEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'tutorialDismissed', value: value),
      );
    });
  }
}

extension GameSettingsRecordQueryObject
    on QueryBuilder<GameSettingsRecord, GameSettingsRecord, QFilterCondition> {}

extension GameSettingsRecordQueryLinks
    on QueryBuilder<GameSettingsRecord, GameSettingsRecord, QFilterCondition> {}

extension GameSettingsRecordQuerySortBy
    on QueryBuilder<GameSettingsRecord, GameSettingsRecord, QSortBy> {
  QueryBuilder<GameSettingsRecord, GameSettingsRecord, QAfterSortBy>
  sortByMasterVolume() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'masterVolume', Sort.asc);
    });
  }

  QueryBuilder<GameSettingsRecord, GameSettingsRecord, QAfterSortBy>
  sortByMasterVolumeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'masterVolume', Sort.desc);
    });
  }

  QueryBuilder<GameSettingsRecord, GameSettingsRecord, QAfterSortBy>
  sortByMusicVolume() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'musicVolume', Sort.asc);
    });
  }

  QueryBuilder<GameSettingsRecord, GameSettingsRecord, QAfterSortBy>
  sortByMusicVolumeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'musicVolume', Sort.desc);
    });
  }

  QueryBuilder<GameSettingsRecord, GameSettingsRecord, QAfterSortBy>
  sortByMuted() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'muted', Sort.asc);
    });
  }

  QueryBuilder<GameSettingsRecord, GameSettingsRecord, QAfterSortBy>
  sortByMutedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'muted', Sort.desc);
    });
  }

  QueryBuilder<GameSettingsRecord, GameSettingsRecord, QAfterSortBy>
  sortBySfxVolume() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sfxVolume', Sort.asc);
    });
  }

  QueryBuilder<GameSettingsRecord, GameSettingsRecord, QAfterSortBy>
  sortBySfxVolumeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sfxVolume', Sort.desc);
    });
  }

  QueryBuilder<GameSettingsRecord, GameSettingsRecord, QAfterSortBy>
  sortByTutorialDismissed() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tutorialDismissed', Sort.asc);
    });
  }

  QueryBuilder<GameSettingsRecord, GameSettingsRecord, QAfterSortBy>
  sortByTutorialDismissedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tutorialDismissed', Sort.desc);
    });
  }
}

extension GameSettingsRecordQuerySortThenBy
    on QueryBuilder<GameSettingsRecord, GameSettingsRecord, QSortThenBy> {
  QueryBuilder<GameSettingsRecord, GameSettingsRecord, QAfterSortBy>
  thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<GameSettingsRecord, GameSettingsRecord, QAfterSortBy>
  thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<GameSettingsRecord, GameSettingsRecord, QAfterSortBy>
  thenByMasterVolume() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'masterVolume', Sort.asc);
    });
  }

  QueryBuilder<GameSettingsRecord, GameSettingsRecord, QAfterSortBy>
  thenByMasterVolumeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'masterVolume', Sort.desc);
    });
  }

  QueryBuilder<GameSettingsRecord, GameSettingsRecord, QAfterSortBy>
  thenByMusicVolume() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'musicVolume', Sort.asc);
    });
  }

  QueryBuilder<GameSettingsRecord, GameSettingsRecord, QAfterSortBy>
  thenByMusicVolumeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'musicVolume', Sort.desc);
    });
  }

  QueryBuilder<GameSettingsRecord, GameSettingsRecord, QAfterSortBy>
  thenByMuted() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'muted', Sort.asc);
    });
  }

  QueryBuilder<GameSettingsRecord, GameSettingsRecord, QAfterSortBy>
  thenByMutedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'muted', Sort.desc);
    });
  }

  QueryBuilder<GameSettingsRecord, GameSettingsRecord, QAfterSortBy>
  thenBySfxVolume() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sfxVolume', Sort.asc);
    });
  }

  QueryBuilder<GameSettingsRecord, GameSettingsRecord, QAfterSortBy>
  thenBySfxVolumeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sfxVolume', Sort.desc);
    });
  }

  QueryBuilder<GameSettingsRecord, GameSettingsRecord, QAfterSortBy>
  thenByTutorialDismissed() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tutorialDismissed', Sort.asc);
    });
  }

  QueryBuilder<GameSettingsRecord, GameSettingsRecord, QAfterSortBy>
  thenByTutorialDismissedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tutorialDismissed', Sort.desc);
    });
  }
}

extension GameSettingsRecordQueryWhereDistinct
    on QueryBuilder<GameSettingsRecord, GameSettingsRecord, QDistinct> {
  QueryBuilder<GameSettingsRecord, GameSettingsRecord, QDistinct>
  distinctByMasterVolume() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'masterVolume');
    });
  }

  QueryBuilder<GameSettingsRecord, GameSettingsRecord, QDistinct>
  distinctByMusicVolume() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'musicVolume');
    });
  }

  QueryBuilder<GameSettingsRecord, GameSettingsRecord, QDistinct>
  distinctByMuted() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'muted');
    });
  }

  QueryBuilder<GameSettingsRecord, GameSettingsRecord, QDistinct>
  distinctBySfxVolume() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'sfxVolume');
    });
  }

  QueryBuilder<GameSettingsRecord, GameSettingsRecord, QDistinct>
  distinctByTutorialDismissed() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'tutorialDismissed');
    });
  }
}

extension GameSettingsRecordQueryProperty
    on QueryBuilder<GameSettingsRecord, GameSettingsRecord, QQueryProperty> {
  QueryBuilder<GameSettingsRecord, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<GameSettingsRecord, double, QQueryOperations>
  masterVolumeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'masterVolume');
    });
  }

  QueryBuilder<GameSettingsRecord, double, QQueryOperations>
  musicVolumeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'musicVolume');
    });
  }

  QueryBuilder<GameSettingsRecord, bool, QQueryOperations> mutedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'muted');
    });
  }

  QueryBuilder<GameSettingsRecord, double, QQueryOperations>
  sfxVolumeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'sfxVolume');
    });
  }

  QueryBuilder<GameSettingsRecord, bool, QQueryOperations>
  tutorialDismissedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'tutorialDismissed');
    });
  }
}

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetRewardClaimRecordCollection on Isar {
  IsarCollection<RewardClaimRecord> get rewardClaimRecords => this.collection();
}

const RewardClaimRecordSchema = CollectionSchema(
  name: r'RewardClaimRecord',
  id: -8177666808373992614,
  properties: {
    r'amount': PropertySchema(id: 0, name: r'amount', type: IsarType.long),
    r'claimKey': PropertySchema(
      id: 1,
      name: r'claimKey',
      type: IsarType.string,
    ),
    r'grantedAt': PropertySchema(
      id: 2,
      name: r'grantedAt',
      type: IsarType.dateTime,
    ),
    r'sourceType': PropertySchema(
      id: 3,
      name: r'sourceType',
      type: IsarType.string,
    ),
    r'stageNumber': PropertySchema(
      id: 4,
      name: r'stageNumber',
      type: IsarType.long,
    ),
  },

  estimateSize: _rewardClaimRecordEstimateSize,
  serialize: _rewardClaimRecordSerialize,
  deserialize: _rewardClaimRecordDeserialize,
  deserializeProp: _rewardClaimRecordDeserializeProp,
  idName: r'id',
  indexes: {
    r'claimKey': IndexSchema(
      id: -5261430419270012723,
      name: r'claimKey',
      unique: true,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'claimKey',
          type: IndexType.hash,
          caseSensitive: true,
        ),
      ],
    ),
  },
  links: {},
  embeddedSchemas: {},

  getId: _rewardClaimRecordGetId,
  getLinks: _rewardClaimRecordGetLinks,
  attach: _rewardClaimRecordAttach,
  version: '3.3.2',
);

int _rewardClaimRecordEstimateSize(
  RewardClaimRecord object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.claimKey.length * 3;
  bytesCount += 3 + object.sourceType.length * 3;
  return bytesCount;
}

void _rewardClaimRecordSerialize(
  RewardClaimRecord object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeLong(offsets[0], object.amount);
  writer.writeString(offsets[1], object.claimKey);
  writer.writeDateTime(offsets[2], object.grantedAt);
  writer.writeString(offsets[3], object.sourceType);
  writer.writeLong(offsets[4], object.stageNumber);
}

RewardClaimRecord _rewardClaimRecordDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = RewardClaimRecord();
  object.amount = reader.readLong(offsets[0]);
  object.claimKey = reader.readString(offsets[1]);
  object.grantedAt = reader.readDateTime(offsets[2]);
  object.id = id;
  object.sourceType = reader.readString(offsets[3]);
  object.stageNumber = reader.readLong(offsets[4]);
  return object;
}

P _rewardClaimRecordDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readLong(offset)) as P;
    case 1:
      return (reader.readString(offset)) as P;
    case 2:
      return (reader.readDateTime(offset)) as P;
    case 3:
      return (reader.readString(offset)) as P;
    case 4:
      return (reader.readLong(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _rewardClaimRecordGetId(RewardClaimRecord object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _rewardClaimRecordGetLinks(
  RewardClaimRecord object,
) {
  return [];
}

void _rewardClaimRecordAttach(
  IsarCollection<dynamic> col,
  Id id,
  RewardClaimRecord object,
) {
  object.id = id;
}

extension RewardClaimRecordByIndex on IsarCollection<RewardClaimRecord> {
  Future<RewardClaimRecord?> getByClaimKey(String claimKey) {
    return getByIndex(r'claimKey', [claimKey]);
  }

  RewardClaimRecord? getByClaimKeySync(String claimKey) {
    return getByIndexSync(r'claimKey', [claimKey]);
  }

  Future<bool> deleteByClaimKey(String claimKey) {
    return deleteByIndex(r'claimKey', [claimKey]);
  }

  bool deleteByClaimKeySync(String claimKey) {
    return deleteByIndexSync(r'claimKey', [claimKey]);
  }

  Future<List<RewardClaimRecord?>> getAllByClaimKey(
    List<String> claimKeyValues,
  ) {
    final values = claimKeyValues.map((e) => [e]).toList();
    return getAllByIndex(r'claimKey', values);
  }

  List<RewardClaimRecord?> getAllByClaimKeySync(List<String> claimKeyValues) {
    final values = claimKeyValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'claimKey', values);
  }

  Future<int> deleteAllByClaimKey(List<String> claimKeyValues) {
    final values = claimKeyValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'claimKey', values);
  }

  int deleteAllByClaimKeySync(List<String> claimKeyValues) {
    final values = claimKeyValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'claimKey', values);
  }

  Future<Id> putByClaimKey(RewardClaimRecord object) {
    return putByIndex(r'claimKey', object);
  }

  Id putByClaimKeySync(RewardClaimRecord object, {bool saveLinks = true}) {
    return putByIndexSync(r'claimKey', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByClaimKey(List<RewardClaimRecord> objects) {
    return putAllByIndex(r'claimKey', objects);
  }

  List<Id> putAllByClaimKeySync(
    List<RewardClaimRecord> objects, {
    bool saveLinks = true,
  }) {
    return putAllByIndexSync(r'claimKey', objects, saveLinks: saveLinks);
  }
}

extension RewardClaimRecordQueryWhereSort
    on QueryBuilder<RewardClaimRecord, RewardClaimRecord, QWhere> {
  QueryBuilder<RewardClaimRecord, RewardClaimRecord, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension RewardClaimRecordQueryWhere
    on QueryBuilder<RewardClaimRecord, RewardClaimRecord, QWhereClause> {
  QueryBuilder<RewardClaimRecord, RewardClaimRecord, QAfterWhereClause>
  idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<RewardClaimRecord, RewardClaimRecord, QAfterWhereClause>
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

  QueryBuilder<RewardClaimRecord, RewardClaimRecord, QAfterWhereClause>
  idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<RewardClaimRecord, RewardClaimRecord, QAfterWhereClause>
  idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<RewardClaimRecord, RewardClaimRecord, QAfterWhereClause>
  idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.between(
          lower: lowerId,
          includeLower: includeLower,
          upper: upperId,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<RewardClaimRecord, RewardClaimRecord, QAfterWhereClause>
  claimKeyEqualTo(String claimKey) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'claimKey', value: [claimKey]),
      );
    });
  }

  QueryBuilder<RewardClaimRecord, RewardClaimRecord, QAfterWhereClause>
  claimKeyNotEqualTo(String claimKey) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'claimKey',
                lower: [],
                upper: [claimKey],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'claimKey',
                lower: [claimKey],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'claimKey',
                lower: [claimKey],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'claimKey',
                lower: [],
                upper: [claimKey],
                includeUpper: false,
              ),
            );
      }
    });
  }
}

extension RewardClaimRecordQueryFilter
    on QueryBuilder<RewardClaimRecord, RewardClaimRecord, QFilterCondition> {
  QueryBuilder<RewardClaimRecord, RewardClaimRecord, QAfterFilterCondition>
  amountEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'amount', value: value),
      );
    });
  }

  QueryBuilder<RewardClaimRecord, RewardClaimRecord, QAfterFilterCondition>
  amountGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'amount',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<RewardClaimRecord, RewardClaimRecord, QAfterFilterCondition>
  amountLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'amount',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<RewardClaimRecord, RewardClaimRecord, QAfterFilterCondition>
  amountBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'amount',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<RewardClaimRecord, RewardClaimRecord, QAfterFilterCondition>
  claimKeyEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'claimKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<RewardClaimRecord, RewardClaimRecord, QAfterFilterCondition>
  claimKeyGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'claimKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<RewardClaimRecord, RewardClaimRecord, QAfterFilterCondition>
  claimKeyLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'claimKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<RewardClaimRecord, RewardClaimRecord, QAfterFilterCondition>
  claimKeyBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'claimKey',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<RewardClaimRecord, RewardClaimRecord, QAfterFilterCondition>
  claimKeyStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'claimKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<RewardClaimRecord, RewardClaimRecord, QAfterFilterCondition>
  claimKeyEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'claimKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<RewardClaimRecord, RewardClaimRecord, QAfterFilterCondition>
  claimKeyContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'claimKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<RewardClaimRecord, RewardClaimRecord, QAfterFilterCondition>
  claimKeyMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'claimKey',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<RewardClaimRecord, RewardClaimRecord, QAfterFilterCondition>
  claimKeyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'claimKey', value: ''),
      );
    });
  }

  QueryBuilder<RewardClaimRecord, RewardClaimRecord, QAfterFilterCondition>
  claimKeyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'claimKey', value: ''),
      );
    });
  }

  QueryBuilder<RewardClaimRecord, RewardClaimRecord, QAfterFilterCondition>
  grantedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'grantedAt', value: value),
      );
    });
  }

  QueryBuilder<RewardClaimRecord, RewardClaimRecord, QAfterFilterCondition>
  grantedAtGreaterThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'grantedAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<RewardClaimRecord, RewardClaimRecord, QAfterFilterCondition>
  grantedAtLessThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'grantedAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<RewardClaimRecord, RewardClaimRecord, QAfterFilterCondition>
  grantedAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'grantedAt',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<RewardClaimRecord, RewardClaimRecord, QAfterFilterCondition>
  idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: value),
      );
    });
  }

  QueryBuilder<RewardClaimRecord, RewardClaimRecord, QAfterFilterCondition>
  idGreaterThan(Id value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'id',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<RewardClaimRecord, RewardClaimRecord, QAfterFilterCondition>
  idLessThan(Id value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'id',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<RewardClaimRecord, RewardClaimRecord, QAfterFilterCondition>
  idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'id',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<RewardClaimRecord, RewardClaimRecord, QAfterFilterCondition>
  sourceTypeEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'sourceType',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<RewardClaimRecord, RewardClaimRecord, QAfterFilterCondition>
  sourceTypeGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'sourceType',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<RewardClaimRecord, RewardClaimRecord, QAfterFilterCondition>
  sourceTypeLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'sourceType',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<RewardClaimRecord, RewardClaimRecord, QAfterFilterCondition>
  sourceTypeBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'sourceType',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<RewardClaimRecord, RewardClaimRecord, QAfterFilterCondition>
  sourceTypeStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'sourceType',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<RewardClaimRecord, RewardClaimRecord, QAfterFilterCondition>
  sourceTypeEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'sourceType',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<RewardClaimRecord, RewardClaimRecord, QAfterFilterCondition>
  sourceTypeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'sourceType',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<RewardClaimRecord, RewardClaimRecord, QAfterFilterCondition>
  sourceTypeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'sourceType',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<RewardClaimRecord, RewardClaimRecord, QAfterFilterCondition>
  sourceTypeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'sourceType', value: ''),
      );
    });
  }

  QueryBuilder<RewardClaimRecord, RewardClaimRecord, QAfterFilterCondition>
  sourceTypeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'sourceType', value: ''),
      );
    });
  }

  QueryBuilder<RewardClaimRecord, RewardClaimRecord, QAfterFilterCondition>
  stageNumberEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'stageNumber', value: value),
      );
    });
  }

  QueryBuilder<RewardClaimRecord, RewardClaimRecord, QAfterFilterCondition>
  stageNumberGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'stageNumber',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<RewardClaimRecord, RewardClaimRecord, QAfterFilterCondition>
  stageNumberLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'stageNumber',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<RewardClaimRecord, RewardClaimRecord, QAfterFilterCondition>
  stageNumberBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'stageNumber',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }
}

extension RewardClaimRecordQueryObject
    on QueryBuilder<RewardClaimRecord, RewardClaimRecord, QFilterCondition> {}

extension RewardClaimRecordQueryLinks
    on QueryBuilder<RewardClaimRecord, RewardClaimRecord, QFilterCondition> {}

extension RewardClaimRecordQuerySortBy
    on QueryBuilder<RewardClaimRecord, RewardClaimRecord, QSortBy> {
  QueryBuilder<RewardClaimRecord, RewardClaimRecord, QAfterSortBy>
  sortByAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'amount', Sort.asc);
    });
  }

  QueryBuilder<RewardClaimRecord, RewardClaimRecord, QAfterSortBy>
  sortByAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'amount', Sort.desc);
    });
  }

  QueryBuilder<RewardClaimRecord, RewardClaimRecord, QAfterSortBy>
  sortByClaimKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'claimKey', Sort.asc);
    });
  }

  QueryBuilder<RewardClaimRecord, RewardClaimRecord, QAfterSortBy>
  sortByClaimKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'claimKey', Sort.desc);
    });
  }

  QueryBuilder<RewardClaimRecord, RewardClaimRecord, QAfterSortBy>
  sortByGrantedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'grantedAt', Sort.asc);
    });
  }

  QueryBuilder<RewardClaimRecord, RewardClaimRecord, QAfterSortBy>
  sortByGrantedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'grantedAt', Sort.desc);
    });
  }

  QueryBuilder<RewardClaimRecord, RewardClaimRecord, QAfterSortBy>
  sortBySourceType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceType', Sort.asc);
    });
  }

  QueryBuilder<RewardClaimRecord, RewardClaimRecord, QAfterSortBy>
  sortBySourceTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceType', Sort.desc);
    });
  }

  QueryBuilder<RewardClaimRecord, RewardClaimRecord, QAfterSortBy>
  sortByStageNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'stageNumber', Sort.asc);
    });
  }

  QueryBuilder<RewardClaimRecord, RewardClaimRecord, QAfterSortBy>
  sortByStageNumberDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'stageNumber', Sort.desc);
    });
  }
}

extension RewardClaimRecordQuerySortThenBy
    on QueryBuilder<RewardClaimRecord, RewardClaimRecord, QSortThenBy> {
  QueryBuilder<RewardClaimRecord, RewardClaimRecord, QAfterSortBy>
  thenByAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'amount', Sort.asc);
    });
  }

  QueryBuilder<RewardClaimRecord, RewardClaimRecord, QAfterSortBy>
  thenByAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'amount', Sort.desc);
    });
  }

  QueryBuilder<RewardClaimRecord, RewardClaimRecord, QAfterSortBy>
  thenByClaimKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'claimKey', Sort.asc);
    });
  }

  QueryBuilder<RewardClaimRecord, RewardClaimRecord, QAfterSortBy>
  thenByClaimKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'claimKey', Sort.desc);
    });
  }

  QueryBuilder<RewardClaimRecord, RewardClaimRecord, QAfterSortBy>
  thenByGrantedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'grantedAt', Sort.asc);
    });
  }

  QueryBuilder<RewardClaimRecord, RewardClaimRecord, QAfterSortBy>
  thenByGrantedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'grantedAt', Sort.desc);
    });
  }

  QueryBuilder<RewardClaimRecord, RewardClaimRecord, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<RewardClaimRecord, RewardClaimRecord, QAfterSortBy>
  thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<RewardClaimRecord, RewardClaimRecord, QAfterSortBy>
  thenBySourceType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceType', Sort.asc);
    });
  }

  QueryBuilder<RewardClaimRecord, RewardClaimRecord, QAfterSortBy>
  thenBySourceTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceType', Sort.desc);
    });
  }

  QueryBuilder<RewardClaimRecord, RewardClaimRecord, QAfterSortBy>
  thenByStageNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'stageNumber', Sort.asc);
    });
  }

  QueryBuilder<RewardClaimRecord, RewardClaimRecord, QAfterSortBy>
  thenByStageNumberDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'stageNumber', Sort.desc);
    });
  }
}

extension RewardClaimRecordQueryWhereDistinct
    on QueryBuilder<RewardClaimRecord, RewardClaimRecord, QDistinct> {
  QueryBuilder<RewardClaimRecord, RewardClaimRecord, QDistinct>
  distinctByAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'amount');
    });
  }

  QueryBuilder<RewardClaimRecord, RewardClaimRecord, QDistinct>
  distinctByClaimKey({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'claimKey', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<RewardClaimRecord, RewardClaimRecord, QDistinct>
  distinctByGrantedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'grantedAt');
    });
  }

  QueryBuilder<RewardClaimRecord, RewardClaimRecord, QDistinct>
  distinctBySourceType({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'sourceType', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<RewardClaimRecord, RewardClaimRecord, QDistinct>
  distinctByStageNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'stageNumber');
    });
  }
}

extension RewardClaimRecordQueryProperty
    on QueryBuilder<RewardClaimRecord, RewardClaimRecord, QQueryProperty> {
  QueryBuilder<RewardClaimRecord, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<RewardClaimRecord, int, QQueryOperations> amountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'amount');
    });
  }

  QueryBuilder<RewardClaimRecord, String, QQueryOperations> claimKeyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'claimKey');
    });
  }

  QueryBuilder<RewardClaimRecord, DateTime, QQueryOperations>
  grantedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'grantedAt');
    });
  }

  QueryBuilder<RewardClaimRecord, String, QQueryOperations>
  sourceTypeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'sourceType');
    });
  }

  QueryBuilder<RewardClaimRecord, int, QQueryOperations> stageNumberProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'stageNumber');
    });
  }
}

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetUpgradeNodeRecordCollection on Isar {
  IsarCollection<UpgradeNodeRecord> get upgradeNodeRecords => this.collection();
}

const UpgradeNodeRecordSchema = CollectionSchema(
  name: r'UpgradeNodeRecord',
  id: -3650676845128618711,
  properties: {
    r'level': PropertySchema(id: 0, name: r'level', type: IsarType.long),
    r'nodeId': PropertySchema(id: 1, name: r'nodeId', type: IsarType.string),
  },

  estimateSize: _upgradeNodeRecordEstimateSize,
  serialize: _upgradeNodeRecordSerialize,
  deserialize: _upgradeNodeRecordDeserialize,
  deserializeProp: _upgradeNodeRecordDeserializeProp,
  idName: r'id',
  indexes: {
    r'nodeId': IndexSchema(
      id: -6491850230428693976,
      name: r'nodeId',
      unique: true,
      replace: true,
      properties: [
        IndexPropertySchema(
          name: r'nodeId',
          type: IndexType.hash,
          caseSensitive: true,
        ),
      ],
    ),
  },
  links: {},
  embeddedSchemas: {},

  getId: _upgradeNodeRecordGetId,
  getLinks: _upgradeNodeRecordGetLinks,
  attach: _upgradeNodeRecordAttach,
  version: '3.3.2',
);

int _upgradeNodeRecordEstimateSize(
  UpgradeNodeRecord object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.nodeId.length * 3;
  return bytesCount;
}

void _upgradeNodeRecordSerialize(
  UpgradeNodeRecord object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeLong(offsets[0], object.level);
  writer.writeString(offsets[1], object.nodeId);
}

UpgradeNodeRecord _upgradeNodeRecordDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = UpgradeNodeRecord();
  object.id = id;
  object.level = reader.readLong(offsets[0]);
  object.nodeId = reader.readString(offsets[1]);
  return object;
}

P _upgradeNodeRecordDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readLong(offset)) as P;
    case 1:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _upgradeNodeRecordGetId(UpgradeNodeRecord object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _upgradeNodeRecordGetLinks(
  UpgradeNodeRecord object,
) {
  return [];
}

void _upgradeNodeRecordAttach(
  IsarCollection<dynamic> col,
  Id id,
  UpgradeNodeRecord object,
) {
  object.id = id;
}

extension UpgradeNodeRecordByIndex on IsarCollection<UpgradeNodeRecord> {
  Future<UpgradeNodeRecord?> getByNodeId(String nodeId) {
    return getByIndex(r'nodeId', [nodeId]);
  }

  UpgradeNodeRecord? getByNodeIdSync(String nodeId) {
    return getByIndexSync(r'nodeId', [nodeId]);
  }

  Future<bool> deleteByNodeId(String nodeId) {
    return deleteByIndex(r'nodeId', [nodeId]);
  }

  bool deleteByNodeIdSync(String nodeId) {
    return deleteByIndexSync(r'nodeId', [nodeId]);
  }

  Future<List<UpgradeNodeRecord?>> getAllByNodeId(List<String> nodeIdValues) {
    final values = nodeIdValues.map((e) => [e]).toList();
    return getAllByIndex(r'nodeId', values);
  }

  List<UpgradeNodeRecord?> getAllByNodeIdSync(List<String> nodeIdValues) {
    final values = nodeIdValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'nodeId', values);
  }

  Future<int> deleteAllByNodeId(List<String> nodeIdValues) {
    final values = nodeIdValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'nodeId', values);
  }

  int deleteAllByNodeIdSync(List<String> nodeIdValues) {
    final values = nodeIdValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'nodeId', values);
  }

  Future<Id> putByNodeId(UpgradeNodeRecord object) {
    return putByIndex(r'nodeId', object);
  }

  Id putByNodeIdSync(UpgradeNodeRecord object, {bool saveLinks = true}) {
    return putByIndexSync(r'nodeId', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByNodeId(List<UpgradeNodeRecord> objects) {
    return putAllByIndex(r'nodeId', objects);
  }

  List<Id> putAllByNodeIdSync(
    List<UpgradeNodeRecord> objects, {
    bool saveLinks = true,
  }) {
    return putAllByIndexSync(r'nodeId', objects, saveLinks: saveLinks);
  }
}

extension UpgradeNodeRecordQueryWhereSort
    on QueryBuilder<UpgradeNodeRecord, UpgradeNodeRecord, QWhere> {
  QueryBuilder<UpgradeNodeRecord, UpgradeNodeRecord, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension UpgradeNodeRecordQueryWhere
    on QueryBuilder<UpgradeNodeRecord, UpgradeNodeRecord, QWhereClause> {
  QueryBuilder<UpgradeNodeRecord, UpgradeNodeRecord, QAfterWhereClause>
  idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<UpgradeNodeRecord, UpgradeNodeRecord, QAfterWhereClause>
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

  QueryBuilder<UpgradeNodeRecord, UpgradeNodeRecord, QAfterWhereClause>
  idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<UpgradeNodeRecord, UpgradeNodeRecord, QAfterWhereClause>
  idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<UpgradeNodeRecord, UpgradeNodeRecord, QAfterWhereClause>
  idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.between(
          lower: lowerId,
          includeLower: includeLower,
          upper: upperId,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<UpgradeNodeRecord, UpgradeNodeRecord, QAfterWhereClause>
  nodeIdEqualTo(String nodeId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'nodeId', value: [nodeId]),
      );
    });
  }

  QueryBuilder<UpgradeNodeRecord, UpgradeNodeRecord, QAfterWhereClause>
  nodeIdNotEqualTo(String nodeId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'nodeId',
                lower: [],
                upper: [nodeId],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'nodeId',
                lower: [nodeId],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'nodeId',
                lower: [nodeId],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'nodeId',
                lower: [],
                upper: [nodeId],
                includeUpper: false,
              ),
            );
      }
    });
  }
}

extension UpgradeNodeRecordQueryFilter
    on QueryBuilder<UpgradeNodeRecord, UpgradeNodeRecord, QFilterCondition> {
  QueryBuilder<UpgradeNodeRecord, UpgradeNodeRecord, QAfterFilterCondition>
  idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: value),
      );
    });
  }

  QueryBuilder<UpgradeNodeRecord, UpgradeNodeRecord, QAfterFilterCondition>
  idGreaterThan(Id value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'id',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<UpgradeNodeRecord, UpgradeNodeRecord, QAfterFilterCondition>
  idLessThan(Id value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'id',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<UpgradeNodeRecord, UpgradeNodeRecord, QAfterFilterCondition>
  idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'id',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<UpgradeNodeRecord, UpgradeNodeRecord, QAfterFilterCondition>
  levelEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'level', value: value),
      );
    });
  }

  QueryBuilder<UpgradeNodeRecord, UpgradeNodeRecord, QAfterFilterCondition>
  levelGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'level',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<UpgradeNodeRecord, UpgradeNodeRecord, QAfterFilterCondition>
  levelLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'level',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<UpgradeNodeRecord, UpgradeNodeRecord, QAfterFilterCondition>
  levelBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'level',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<UpgradeNodeRecord, UpgradeNodeRecord, QAfterFilterCondition>
  nodeIdEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'nodeId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<UpgradeNodeRecord, UpgradeNodeRecord, QAfterFilterCondition>
  nodeIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'nodeId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<UpgradeNodeRecord, UpgradeNodeRecord, QAfterFilterCondition>
  nodeIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'nodeId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<UpgradeNodeRecord, UpgradeNodeRecord, QAfterFilterCondition>
  nodeIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'nodeId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<UpgradeNodeRecord, UpgradeNodeRecord, QAfterFilterCondition>
  nodeIdStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'nodeId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<UpgradeNodeRecord, UpgradeNodeRecord, QAfterFilterCondition>
  nodeIdEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'nodeId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<UpgradeNodeRecord, UpgradeNodeRecord, QAfterFilterCondition>
  nodeIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'nodeId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<UpgradeNodeRecord, UpgradeNodeRecord, QAfterFilterCondition>
  nodeIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'nodeId',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<UpgradeNodeRecord, UpgradeNodeRecord, QAfterFilterCondition>
  nodeIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'nodeId', value: ''),
      );
    });
  }

  QueryBuilder<UpgradeNodeRecord, UpgradeNodeRecord, QAfterFilterCondition>
  nodeIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'nodeId', value: ''),
      );
    });
  }
}

extension UpgradeNodeRecordQueryObject
    on QueryBuilder<UpgradeNodeRecord, UpgradeNodeRecord, QFilterCondition> {}

extension UpgradeNodeRecordQueryLinks
    on QueryBuilder<UpgradeNodeRecord, UpgradeNodeRecord, QFilterCondition> {}

extension UpgradeNodeRecordQuerySortBy
    on QueryBuilder<UpgradeNodeRecord, UpgradeNodeRecord, QSortBy> {
  QueryBuilder<UpgradeNodeRecord, UpgradeNodeRecord, QAfterSortBy>
  sortByLevel() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'level', Sort.asc);
    });
  }

  QueryBuilder<UpgradeNodeRecord, UpgradeNodeRecord, QAfterSortBy>
  sortByLevelDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'level', Sort.desc);
    });
  }

  QueryBuilder<UpgradeNodeRecord, UpgradeNodeRecord, QAfterSortBy>
  sortByNodeId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nodeId', Sort.asc);
    });
  }

  QueryBuilder<UpgradeNodeRecord, UpgradeNodeRecord, QAfterSortBy>
  sortByNodeIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nodeId', Sort.desc);
    });
  }
}

extension UpgradeNodeRecordQuerySortThenBy
    on QueryBuilder<UpgradeNodeRecord, UpgradeNodeRecord, QSortThenBy> {
  QueryBuilder<UpgradeNodeRecord, UpgradeNodeRecord, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<UpgradeNodeRecord, UpgradeNodeRecord, QAfterSortBy>
  thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<UpgradeNodeRecord, UpgradeNodeRecord, QAfterSortBy>
  thenByLevel() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'level', Sort.asc);
    });
  }

  QueryBuilder<UpgradeNodeRecord, UpgradeNodeRecord, QAfterSortBy>
  thenByLevelDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'level', Sort.desc);
    });
  }

  QueryBuilder<UpgradeNodeRecord, UpgradeNodeRecord, QAfterSortBy>
  thenByNodeId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nodeId', Sort.asc);
    });
  }

  QueryBuilder<UpgradeNodeRecord, UpgradeNodeRecord, QAfterSortBy>
  thenByNodeIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nodeId', Sort.desc);
    });
  }
}

extension UpgradeNodeRecordQueryWhereDistinct
    on QueryBuilder<UpgradeNodeRecord, UpgradeNodeRecord, QDistinct> {
  QueryBuilder<UpgradeNodeRecord, UpgradeNodeRecord, QDistinct>
  distinctByLevel() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'level');
    });
  }

  QueryBuilder<UpgradeNodeRecord, UpgradeNodeRecord, QDistinct>
  distinctByNodeId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'nodeId', caseSensitive: caseSensitive);
    });
  }
}

extension UpgradeNodeRecordQueryProperty
    on QueryBuilder<UpgradeNodeRecord, UpgradeNodeRecord, QQueryProperty> {
  QueryBuilder<UpgradeNodeRecord, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<UpgradeNodeRecord, int, QQueryOperations> levelProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'level');
    });
  }

  QueryBuilder<UpgradeNodeRecord, String, QQueryOperations> nodeIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'nodeId');
    });
  }
}
