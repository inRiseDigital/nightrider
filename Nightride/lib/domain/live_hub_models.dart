// lib/domain/live_hub_models.dart

enum CrowdLevel { empty, quiet, moderate, busy, packed }

enum ClubStatus { open, closed, vipOnly, soldOut }

enum QueueStatus { noQueue, short, moderate, long, closed }

extension CrowdLevelX on CrowdLevel {
  String toValue() => name;
  static CrowdLevel fromValue(String? v) =>
      CrowdLevel.values.firstWhere((e) => e.name == v, orElse: () => CrowdLevel.moderate);
}

extension ClubStatusX on ClubStatus {
  String toValue() => name;
  static ClubStatus fromValue(String? v) =>
      ClubStatus.values.firstWhere((e) => e.name == v, orElse: () => ClubStatus.open);
}

extension QueueStatusX on QueueStatus {
  String toValue() => name;
  static QueueStatus fromValue(String? v) =>
      QueueStatus.values.firstWhere((e) => e.name == v, orElse: () => QueueStatus.noQueue);
}

class ClubUpdate {
  final String id;
  final String clubName;
  final String city;
  final String country;
  final String imageUrl;
  final ClubStatus status;
  final CrowdLevel crowdLevel;
  final QueueStatus queueStatus;
  final bool ticketsAvailable;
  final bool tablesAvailable;
  final String? tonightDj;
  final String? offer;
  final String lastUpdated;

  const ClubUpdate({
    required this.id,
    required this.clubName,
    required this.city,
    required this.country,
    required this.imageUrl,
    required this.status,
    required this.crowdLevel,
    required this.queueStatus,
    required this.ticketsAvailable,
    required this.tablesAvailable,
    this.tonightDj,
    this.offer,
    required this.lastUpdated,
  });

  factory ClubUpdate.fromJson(Map<String, dynamic> d) => ClubUpdate(
    id: d['id'] as String? ?? '',
    clubName: d['clubName'] as String? ?? '',
    city: d['city'] as String? ?? '',
    country: d['country'] as String? ?? '',
    imageUrl: d['imageUrl'] as String? ?? '',
    status: ClubStatusX.fromValue(d['status'] as String?),
    crowdLevel: CrowdLevelX.fromValue(d['crowdLevel'] as String?),
    queueStatus: QueueStatusX.fromValue(d['queueStatus'] as String?),
    ticketsAvailable: d['ticketsAvailable'] as bool? ?? false,
    tablesAvailable: d['tablesAvailable'] as bool? ?? false,
    tonightDj: d['tonightDj'] as String?,
    offer: d['offer'] as String?,
    lastUpdated: d['lastUpdated'] as String? ?? 'Just now',
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'clubName': clubName,
    'city': city,
    'country': country,
    'imageUrl': imageUrl,
    'status': status.toValue(),
    'crowdLevel': crowdLevel.toValue(),
    'queueStatus': queueStatus.toValue(),
    'ticketsAvailable': ticketsAvailable,
    'tablesAvailable': tablesAvailable,
    if (tonightDj != null) 'tonightDj': tonightDj,
    if (offer != null) 'offer': offer,
    'lastUpdated': lastUpdated,
  };
}

class UserReport {
  final String id;
  final String clubName;
  final String city;
  final String country;
  final String username;
  final String avatarUrl;
  final String tag;
  final int vibeRating;
  final String? comment;
  final int upvotes;
  final String timeAgo;

  const UserReport({
    required this.id,
    required this.clubName,
    required this.city,
    required this.country,
    required this.username,
    required this.avatarUrl,
    required this.tag,
    required this.vibeRating,
    this.comment,
    required this.upvotes,
    required this.timeAgo,
  });

  factory UserReport.fromJson(Map<String, dynamic> d) => UserReport(
    id: d['id'] as String? ?? '',
    clubName: d['clubName'] as String? ?? '',
    city: d['city'] as String? ?? '',
    country: d['country'] as String? ?? '',
    username: d['username'] as String? ?? '',
    avatarUrl: d['avatarUrl'] as String? ?? '',
    tag: d['tag'] as String? ?? '',
    vibeRating: (d['vibeRating'] as num?)?.toInt() ?? 3,
    comment: d['comment'] as String?,
    upvotes: (d['upvotes'] as num?)?.toInt() ?? 0,
    timeAgo: d['timeAgo'] as String? ?? 'Just now',
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'clubName': clubName,
    'city': city,
    'country': country,
    'username': username,
    'avatarUrl': avatarUrl,
    'tag': tag,
    'vibeRating': vibeRating,
    if (comment != null) 'comment': comment,
    'upvotes': upvotes,
    'timeAgo': timeAgo,
  };
}

class SocialEvent {
  final String id;
  final String title;
  final String clubName;
  final String city;
  final String country;
  final String? imageUrl;
  final String? djName;
  final String date;
  final String time;
  final String? ticketUrl;
  final String source;
  final int popularityScore;
  final bool isTrending;

  const SocialEvent({
    required this.id,
    required this.title,
    required this.clubName,
    required this.city,
    required this.country,
    this.imageUrl,
    this.djName,
    required this.date,
    required this.time,
    this.ticketUrl,
    required this.source,
    required this.popularityScore,
    required this.isTrending,
  });

  factory SocialEvent.fromJson(Map<String, dynamic> d) => SocialEvent(
    id: d['id'] as String? ?? '',
    title: d['title'] as String? ?? '',
    clubName: d['clubName'] as String? ?? '',
    city: d['city'] as String? ?? '',
    country: d['country'] as String? ?? '',
    imageUrl: d['imageUrl'] as String?,
    djName: d['djName'] as String?,
    date: d['date'] as String? ?? '',
    time: d['time'] as String? ?? '',
    ticketUrl: d['ticketUrl'] as String?,
    source: d['source'] as String? ?? '',
    popularityScore: (d['popularityScore'] as num?)?.toInt() ?? 0,
    isTrending: d['isTrending'] as bool? ?? false,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'clubName': clubName,
    'city': city,
    'country': country,
    if (imageUrl != null) 'imageUrl': imageUrl,
    if (djName != null) 'djName': djName,
    'date': date,
    'time': time,
    if (ticketUrl != null) 'ticketUrl': ticketUrl,
    'source': source,
    'popularityScore': popularityScore,
    'isTrending': isTrending,
  };
}
