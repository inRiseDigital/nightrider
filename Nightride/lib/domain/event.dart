// lib/domain/event.dart
//
// Typed model for `events/{eventId}` matching the decided schema in
// docs/FIRESTORE_SCHEMA.md. `fromFirestore`/`fromMap` are defensive: a legacy
// or malformed document degrades field-by-field instead of throwing, so a bad
// read never crashes a list. `toFirestore` emits the exact schema shape,
// because the Firestore rules validate that shape on every create AND update.
import 'package:cloud_firestore/cloud_firestore.dart';

const List<String> kEventStatuses = ['draft', 'published', 'archived'];
const List<String> kEventSources = ['organizer', 'admin', 'scraped'];
const List<String> kPerformerTypes = ['DJ', 'Band', 'Comedian', 'LiveAct', 'Other'];

String _asString(Map<String, dynamic> d, String key, [String fallback = '']) {
  final v = d[key];
  return v is String ? v : fallback;
}

/// A single performer/lineup entry.
class Performer {
  const Performer({this.name = '', this.type = 'Other', this.bio = ''});

  final String name;
  final String type;
  final String bio;

  factory Performer.fromMap(Map<String, dynamic> m) => Performer(
        name: _asString(m, 'name'),
        type: kPerformerTypes.contains(m['type']) ? m['type'] as String : 'Other',
        bio: _asString(m, 'bio'),
      );

  Map<String, dynamic> toMap() => {'name': name, 'type': type, 'bio': bio};
}

/// `events/{eventId}.policies`
class EventPolicies {
  const EventPolicies({
    this.ageRestriction = 0,
    this.refundPolicy = '',
    this.reEntryAllowed = false,
    this.wheelchairAccessible = false,
    this.allowPets = false,
  });

  final int ageRestriction;
  final String refundPolicy;
  final bool reEntryAllowed;
  final bool wheelchairAccessible;
  final bool allowPets;

  factory EventPolicies.fromMap(Map<String, dynamic> m) => EventPolicies(
        ageRestriction: (m['ageRestriction'] as num?)?.toInt() ?? 0,
        refundPolicy: _asString(m, 'refundPolicy'),
        reEntryAllowed: m['reEntryAllowed'] == true,
        wheelchairAccessible: m['wheelchairAccessible'] == true,
        allowPets: m['allowPets'] == true,
      );

  Map<String, dynamic> toMap() => {
        'ageRestriction': ageRestriction,
        'refundPolicy': refundPolicy,
        'reEntryAllowed': reEntryAllowed,
        'wheelchairAccessible': wheelchairAccessible,
        'allowPets': allowPets,
      };
}

/// `events/{eventId}.price` — the old free-text `price_hint` no longer exists.
class EventPrice {
  const EventPrice({
    this.min = 0,
    this.max = 0,
    this.currency = '',
    this.isFree = true,
  });

  final num min;
  final num max;
  final String currency;
  final bool isFree;

  factory EventPrice.fromMap(Map<String, dynamic> m) => EventPrice(
        min: (m['min'] as num?) ?? 0,
        max: (m['max'] as num?) ?? 0,
        currency: _asString(m, 'currency'),
        isFree: m['isFree'] == true,
      );

  /// Best-effort parse of legacy free-text price hints (e.g. "$15", "Free"),
  /// used only when reading a pre-migration document that never had a `price`
  /// map — never used for writes.
  factory EventPrice.parseLegacyHint(String hint) {
    final t = hint.trim();
    if (t.isEmpty || t.toLowerCase() == 'free') {
      return const EventPrice(min: 0, max: 0, currency: '', isFree: true);
    }
    final match = RegExp(r'([^\d.\s]*)\s*([\d.]+)').firstMatch(t);
    if (match != null) {
      final amount = double.tryParse(match.group(2) ?? '') ?? 0;
      return EventPrice(
        min: amount,
        max: amount,
        currency: match.group(1) ?? '',
        isFree: false,
      );
    }
    return const EventPrice(min: 0, max: 0, currency: '', isFree: false);
  }

  /// Best-effort parse of a single free-text "Ticket Price" field from the
  /// organizer create/edit sheet into the structured shape the rules require.
  factory EventPrice.parseInput(String raw) => EventPrice.parseLegacyHint(raw);

  Map<String, dynamic> toMap() => {
        'min': min,
        'max': max,
        'currency': currency,
        'isFree': isFree,
      };

  String _fmtNum(num n) => n == n.roundToDouble() ? n.toInt().toString() : n.toString();

  /// Short display string for cards/badges (e.g. "Free", "$15", "$15-$30").
  String get hintText {
    if (isFree) return 'Free';
    if (min <= 0 && max <= 0) return 'Tickets';
    if (min == max) return '$currency${_fmtNum(min)}';
    return '$currency${_fmtNum(min)}-$currency${_fmtNum(max)}';
  }
}

/// `events/{eventId}` — see docs/FIRESTORE_SCHEMA.md for the authoritative shape.
class Event {
  const Event({
    this.id = '',
    required this.name,
    this.description = '',
    this.venueId,
    this.venueName = '',
    this.city = '',
    this.countryCode = '',
    this.geo,
    this.startAt,
    this.endAt,
    this.price = const EventPrice(),
    this.ticketUrl = '',
    this.coverImage = '',
    this.genre = '',
    this.category = '',
    this.vibe = '',
    this.language = '',
    this.performers = const [],
    this.policies = const EventPolicies(),
    this.interestedCount = 0,
    this.popularityScore = 0,
    this.status = 'draft',
    this.source = 'organizer',
    this.organizerUid,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String name;
  final String description;
  final String? venueId;
  final String venueName;
  final String city;
  final String countryCode;
  final GeoPoint? geo;

  /// Nullable in the model even though the schema requires it, so a document
  /// that is missing/malformed on `startAt` degrades instead of throwing.
  /// [toFirestore] still writes whatever value is set here — a null `startAt`
  /// on write is caught by the rules, by design.
  final Timestamp? startAt;
  final Timestamp? endAt;

  final EventPrice price;
  final String ticketUrl;
  final String coverImage;
  final String genre;
  final String category;
  final String vibe;
  final String language;
  final List<Performer> performers;
  final EventPolicies policies;

  /// Marker-subcollection increments only — never set this directly from a
  /// create/update path. See [FirestoreService.registerInterest].
  final int interestedCount;

  /// Admin SDK ingest only, 0 for hand-entered events. Never write this from
  /// the client.
  final num popularityScore;

  final String status; // 'draft' | 'published' | 'archived'
  final String source; // 'organizer' | 'admin' | 'scraped'
  final String? organizerUid;
  final Timestamp? createdAt;
  final Timestamp? updatedAt;

  bool get isPublished => status == 'published';

  DateTime? get startDateTime => startAt?.toDate();

  /// `YYYY-MM-DD`, empty when there is no [startAt].
  String get isoDate {
    final dt = startDateTime;
    if (dt == null) return '';
    return '${dt.year.toString().padLeft(4, '0')}-'
        '${dt.month.toString().padLeft(2, '0')}-'
        '${dt.day.toString().padLeft(2, '0')}';
  }

  /// `HH:mm` (24h), empty when there is no [startAt].
  String get isoTime {
    final dt = startDateTime;
    if (dt == null) return '';
    return '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
  }

  factory Event.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    return Event.fromMap(doc.id, doc.data());
  }

  /// Defensive on read: never throws. Missing/mistyped fields fall back to
  /// safe defaults (or, for a handful of renamed fields, the old legacy key)
  /// rather than blowing up the whole list this document is part of.
  factory Event.fromMap(String id, Map<String, dynamic>? data) {
    final d = data ?? const <String, dynamic>{};

    GeoPoint? geo;
    final rawGeo = d['geo'];
    if (rawGeo is GeoPoint) {
      geo = rawGeo;
    } else if (d['lat'] is num && d['lng'] is num) {
      geo = GeoPoint((d['lat'] as num).toDouble(), (d['lng'] as num).toDouble());
    }

    Timestamp? startAt;
    final rawStartAt = d['startAt'];
    if (rawStartAt is Timestamp) {
      startAt = rawStartAt;
    } else {
      // Legacy shape: separate `date` + `start_time` strings.
      final legacyDate = _asString(d, 'date');
      final legacyTime = _asString(d, 'start_time');
      if (legacyDate.isNotEmpty) {
        final parsed = DateTime.tryParse(
          legacyTime.isNotEmpty ? '${legacyDate}T$legacyTime' : legacyDate,
        );
        if (parsed != null) startAt = Timestamp.fromDate(parsed);
      }
    }

    Timestamp? endAt;
    if (d['endAt'] is Timestamp) endAt = d['endAt'] as Timestamp;

    EventPrice price;
    if (d['price'] is Map) {
      price = EventPrice.fromMap(Map<String, dynamic>.from(d['price'] as Map));
    } else {
      price = EventPrice.parseLegacyHint(_asString(d, 'price_hint'));
    }

    List<Performer> performers = const [];
    final rawPerformers = d['performers'];
    if (rawPerformers is List) {
      performers = rawPerformers
          .whereType<Map>()
          .map((p) => Performer.fromMap(Map<String, dynamic>.from(p)))
          .toList();
    }

    EventPolicies policies = const EventPolicies();
    if (d['policies'] is Map) {
      policies = EventPolicies.fromMap(Map<String, dynamic>.from(d['policies'] as Map));
    }

    final rawStatus = (_asString(d, 'status', 'draft')).toLowerCase();
    final status = kEventStatuses.contains(rawStatus) ? rawStatus : 'draft';

    final rawSource = _asString(d, 'source', 'organizer');
    final source = kEventSources.contains(rawSource) ? rawSource : 'organizer';

    return Event(
      id: id,
      name: _asString(d, 'name', _asString(d, 'title')),
      description: _asString(d, 'description'),
      venueId: d['venueId'] as String?,
      venueName: _asString(d, 'venueName', _asString(d, 'venue_name')),
      city: _asString(d, 'city'),
      countryCode: _asString(d, 'countryCode', _asString(d, 'country_code')).toUpperCase(),
      geo: geo,
      startAt: startAt,
      endAt: endAt,
      price: price,
      ticketUrl: _asString(d, 'ticketUrl', _asString(d, 'ticket_url')),
      coverImage: _asString(d, 'coverImage', _asString(d, 'cover_image')),
      genre: _asString(d, 'genre'),
      category: _asString(d, 'category'),
      vibe: _asString(d, 'vibe'),
      language: _asString(d, 'language'),
      performers: performers,
      policies: policies,
      interestedCount: (d['interestedCount'] as num?)?.toInt() ?? 0,
      popularityScore: (d['popularityScore'] as num?) ?? 0,
      status: status,
      source: source,
      organizerUid: d['organizerUid'] as String?,
      createdAt: d['createdAt'] as Timestamp?,
      updatedAt: d['updatedAt'] as Timestamp?,
    );
  }

  /// Emits the exact schema shape. The rules validate this on every create
  /// AND update, so nothing here may be renamed or omitted casually.
  ///
  /// When [forCreate] is false (an update), `interestedCount`, `popularityScore`
  /// and `createdAt` are deliberately left out of the map entirely rather than
  /// echoing back their current value: `DocumentReference.update` only touches
  /// the keys present in the map, so omitting them means the rules see the
  /// existing pinned values unchanged. Never write those three fields from an
  /// organizer create/update path.
  Map<String, dynamic> toFirestore({required bool forCreate}) {
    final map = <String, dynamic>{
      'name': name,
      'description': description,
      'venueId': venueId,
      'venueName': venueName,
      'city': city,
      'countryCode': countryCode,
      'geo': geo,
      'startAt': startAt,
      'endAt': endAt,
      'price': price.toMap(),
      'ticketUrl': ticketUrl,
      'coverImage': coverImage,
      'genre': genre,
      'category': category,
      'vibe': vibe,
      'language': language,
      'performers': performers.map((p) => p.toMap()).toList(),
      'policies': policies.toMap(),
      'status': status,
      'source': source,
      'organizerUid': organizerUid,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (forCreate) {
      map['interestedCount'] = 0;
      map['popularityScore'] = 0;
      map['createdAt'] = FieldValue.serverTimestamp();
    }
    return map;
  }

  /// Reshapes this event back into the legacy snake_case detail map that
  /// `event_detail_page.dart` (out of this migration's scope) still reads,
  /// so that screen keeps working unmodified.
  Map<String, dynamic> toLegacyDetailMap() => {
        'id': id,
        'name': name,
        'cover_image': coverImage,
        'genre': genre,
        'date': isoDate,
        'start_time': isoTime,
        'venue_name': venueName,
        'address': '',
        'city': city,
        'country': countryCode,
        'price_hint': price.hintText,
        'description': description,
        'ticket_url': ticketUrl,
        'language': language,
        'lat': geo?.latitude ?? 0,
        'lng': geo?.longitude ?? 0,
        'artists': performers.map((p) => p.name).where((n) => n.isNotEmpty).toList(),
        'performers': performers.map((p) => p.toMap()).toList(),
        'policies': {
          'age_restriction': policies.ageRestriction,
          'refund_policy': policies.refundPolicy,
          're_entry_allowed': policies.reEntryAllowed,
          'wheelchair_accessible': policies.wheelchairAccessible,
          'allow_pets': policies.allowPets,
        },
        'attendee_count': interestedCount,
      };

  Event copyWith({
    String? name,
    String? description,
    String? venueId,
    String? venueName,
    String? city,
    String? countryCode,
    GeoPoint? geo,
    Timestamp? startAt,
    Timestamp? endAt,
    EventPrice? price,
    String? ticketUrl,
    String? coverImage,
    String? genre,
    String? category,
    String? vibe,
    String? language,
    List<Performer>? performers,
    EventPolicies? policies,
    String? status,
    String? source,
    String? organizerUid,
  }) {
    return Event(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      venueId: venueId ?? this.venueId,
      venueName: venueName ?? this.venueName,
      city: city ?? this.city,
      countryCode: countryCode ?? this.countryCode,
      geo: geo ?? this.geo,
      startAt: startAt ?? this.startAt,
      endAt: endAt ?? this.endAt,
      price: price ?? this.price,
      ticketUrl: ticketUrl ?? this.ticketUrl,
      coverImage: coverImage ?? this.coverImage,
      genre: genre ?? this.genre,
      category: category ?? this.category,
      vibe: vibe ?? this.vibe,
      language: language ?? this.language,
      performers: performers ?? this.performers,
      policies: policies ?? this.policies,
      interestedCount: interestedCount,
      popularityScore: popularityScore,
      status: status ?? this.status,
      source: source ?? this.source,
      organizerUid: organizerUid ?? this.organizerUid,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
