/// Plain data models mapping the Supabase schema.
library;

enum SermonKind { audio, video, series }

class Sermon {
  const Sermon({
    required this.id,
    required this.title,
    required this.shortTitle,
    required this.series,
    required this.speaker,
    required this.kind,
    required this.preachedOn,
    required this.durationSecs,
    this.sizeBytes,
    this.audioPath,
    this.youtubeId,
    this.artworkPath,
    this.scripture,
    this.scriptureRef,
  });

  final int id;
  final String title;
  final String shortTitle;
  final String series;
  final String speaker;
  final SermonKind kind;
  final DateTime preachedOn;
  final int durationSecs;
  final int? sizeBytes;
  final String? audioPath;
  final String? youtubeId;
  final String? artworkPath;
  final String? scripture;
  final String? scriptureRef;

  factory Sermon.fromJson(Map<String, dynamic> j) => Sermon(
        id: j['id'] as int,
        title: j['title'] as String,
        shortTitle: j['short_title'] as String,
        series: j['series'] as String,
        speaker: j['speaker'] as String,
        kind: SermonKind.values.byName(j['kind'] as String),
        preachedOn: DateTime.parse(j['preached_on'] as String),
        durationSecs: j['duration_secs'] as int,
        sizeBytes: j['size_bytes'] as int?,
        audioPath: j['audio_path'] as String?,
        youtubeId: j['youtube_id'] as String?,
        artworkPath: j['artwork_path'] as String?,
        scripture: j['scripture'] as String?,
        scriptureRef: j['scripture_ref'] as String?,
      );
}

class Devotional {
  const Devotional({
    required this.id,
    required this.forDate,
    required this.title,
    required this.verse,
    required this.verseRef,
    required this.tag,
    required this.body,
    this.prayer,
    this.imagePath,
  });

  final int id;
  final DateTime forDate;
  final String title;
  final String verse;
  final String verseRef;
  final String tag;
  final List<String> body;
  final String? prayer;
  final String? imagePath;

  factory Devotional.fromJson(Map<String, dynamic> j) => Devotional(
        id: j['id'] as int,
        forDate: DateTime.parse(j['for_date'] as String),
        title: j['title'] as String,
        verse: j['verse'] as String,
        verseRef: j['verse_ref'] as String,
        tag: j['tag'] as String,
        body: (j['body'] as List).cast<String>(),
        prayer: j['prayer'] as String?,
        imagePath: j['image_path'] as String?,
      );
}

enum EventCta { register, remind, volunteer }

class ChurchEvent {
  const ChurchEvent({
    required this.id,
    required this.name,
    required this.startsAt,
    required this.location,
    required this.blurb,
    required this.ctaType,
    this.spotsNote,
    this.flyerPath,
  });

  final int id;
  final String name;
  final DateTime startsAt;
  final String location;
  final String blurb;
  final EventCta ctaType;
  final String? spotsNote;
  final String? flyerPath;

  factory ChurchEvent.fromJson(Map<String, dynamic> j) => ChurchEvent(
        id: j['id'] as int,
        name: j['name'] as String,
        startsAt: DateTime.parse(j['starts_at'] as String).toLocal(),
        location: j['location'] as String,
        blurb: j['blurb'] as String,
        ctaType: EventCta.values.byName(j['cta_type'] as String),
        spotsNote: j['spots_note'] as String?,
        flyerPath: j['flyer_path'] as String?,
      );
}

class Testimony {
  const Testimony({
    required this.id,
    required this.displayName,
    required this.initials,
    required this.locationTag,
    required this.category,
    required this.body,
    required this.amensBase,
    this.amens = 0,
  });

  final int id;
  final String displayName;
  final String initials;
  final String locationTag;
  final String category;
  final String body;
  final int amensBase;

  /// Community amens from testimony_amen_counts (added to amensBase).
  final int amens;

  Testimony withAmens(int count) => Testimony(
        id: id,
        displayName: displayName,
        initials: initials,
        locationTag: locationTag,
        category: category,
        body: body,
        amensBase: amensBase,
        amens: count,
      );

  factory Testimony.fromJson(Map<String, dynamic> j) => Testimony(
        id: j['id'] as int,
        displayName: j['display_name'] as String,
        initials: j['initials'] as String,
        locationTag: j['location_tag'] as String,
        category: j['category'] as String,
        body: j['body'] as String,
        amensBase: j['amens_base'] as int? ?? 0,
      );
}

class JournalArticle {
  const JournalArticle({
    required this.id,
    required this.issueNo,
    required this.title,
    required this.dek,
    required this.readMins,
    this.body,
    this.coverPath,
  });

  final int id;
  final int issueNo;
  final String title;
  final String dek;
  final int readMins;
  final String? body;
  final String? coverPath;

  factory JournalArticle.fromJson(Map<String, dynamic> j) => JournalArticle(
        id: j['id'] as int,
        issueNo: j['issue_no'] as int,
        title: j['title'] as String,
        dek: j['dek'] as String,
        readMins: j['read_mins'] as int,
        body: j['body'] as String?,
        coverPath: j['cover_path'] as String?,
      );
}

class ChurchUpdate {
  const ChurchUpdate({
    required this.id,
    required this.title,
    required this.body,
    required this.publishedAt,
  });

  final int id;
  final String title;
  final String body;
  final DateTime publishedAt;

  factory ChurchUpdate.fromJson(Map<String, dynamic> j) => ChurchUpdate(
        id: j['id'] as int,
        title: j['title'] as String,
        body: j['body'] as String,
        publishedAt: DateTime.parse(j['published_at'] as String),
      );
}

class BroadcastPlatform {
  const BroadcastPlatform({
    required this.kind,
    required this.name,
    required this.scheduleText,
    this.url,
  });

  final String kind;
  final String name;
  final String scheduleText;
  final String? url;

  factory BroadcastPlatform.fromJson(Map<String, dynamic> j) =>
      BroadcastPlatform(
        kind: j['kind'] as String,
        name: j['name'] as String,
        scheduleText: j['schedule_text'] as String,
        url: j['url'] as String?,
      );
}

class LiveStatus {
  const LiveStatus({
    required this.isLive,
    required this.youtubeId,
    required this.serviceName,
    required this.serviceNo,
    required this.title,
    required this.speaker,
    this.startedAt,
    this.watching,
  });

  final bool isLive;
  final String youtubeId;
  final String serviceName;
  final int serviceNo;
  final String title;
  final String speaker;
  final DateTime? startedAt;
  final int? watching;

  factory LiveStatus.fromJson(Map<String, dynamic> j) => LiveStatus(
        isLive: j['is_live'] as bool? ?? false,
        youtubeId: j['youtube_id'] as String? ?? '',
        serviceName: j['service_name'] as String? ?? 'Service',
        serviceNo: j['service_no'] as int? ?? 0,
        title: j['title'] as String? ?? '',
        speaker: j['speaker'] as String? ?? '',
        startedAt: j['started_at'] == null
            ? null
            : DateTime.parse(j['started_at'] as String).toLocal(),
        watching: j['watching'] as int?,
      );
}

class GivingConfig {
  const GivingConfig({
    required this.purposes,
    required this.presets,
    required this.currency,
    required this.bank,
    required this.mobileMoney,
    required this.note,
  });

  final List<String> purposes;
  final List<int> presets;
  final String currency;
  final Map<String, dynamic> bank;
  final Map<String, dynamic> mobileMoney;
  final String note;

  factory GivingConfig.fromJson(Map<String, dynamic> j) => GivingConfig(
        purposes: (j['purposes'] as List).cast<String>(),
        presets: (j['presets'] as List).cast<int>(),
        currency: j['currency'] as String? ?? '₦',
        bank: (j['bank'] as Map).cast<String, dynamic>(),
        mobileMoney: (j['mobile_money'] as Map).cast<String, dynamic>(),
        note: j['note'] as String? ?? '',
      );
}

class PrayerConfig {
  const PrayerConfig({required this.categories, required this.promise});
  final List<String> categories;
  final String promise;

  factory PrayerConfig.fromJson(Map<String, dynamic> j) => PrayerConfig(
        categories: (j['categories'] as List).cast<String>(),
        promise: j['promise'] as String? ?? '',
      );
}

/// Church identity plus the legal/contact URLs the stores require.
///
/// Every URL is nullable on purpose: the About screen hides any row whose
/// URL is unset, so a half-configured deployment shows fewer rows rather than
/// shipping dead links (App Review 2.1 treats those as incomplete).
class AboutConfig {
  const AboutConfig({
    required this.churchName,
    this.blurb,
    this.websiteUrl,
    this.contactEmail,
    this.privacyPolicyUrl,
    this.termsUrl,
    this.deleteAccountUrl,
  });

  final String churchName;
  final String? blurb;
  final String? websiteUrl;
  final String? contactEmail;
  final String? privacyPolicyUrl;
  final String? termsUrl;

  /// Google Play additionally requires a web-reachable deletion route, not
  /// just the in-app one. Surfaced here so reviewers can find it.
  final String? deleteAccountUrl;

  static String? _url(Object? v) {
    final s = (v as String?)?.trim();
    return s == null || s.isEmpty ? null : s;
  }

  factory AboutConfig.fromJson(Map<String, dynamic> j) => AboutConfig(
        churchName: j['church_name'] as String? ?? 'WordFeast Gospel Network',
        blurb: _url(j['blurb']),
        websiteUrl: _url(j['website_url']),
        contactEmail: _url(j['contact_email']),
        privacyPolicyUrl: _url(j['privacy_policy_url']),
        termsUrl: _url(j['terms_url']),
        deleteAccountUrl: _url(j['delete_account_url']),
      );
}

class PrayerRequest {
  const PrayerRequest({
    required this.id,
    required this.body,
    required this.tags,
    required this.anonymous,
    required this.status,
    required this.createdAt,
  });

  final int id;
  final String body;
  final List<String> tags;
  final bool anonymous;
  final String status;
  final DateTime createdAt;

  factory PrayerRequest.fromJson(Map<String, dynamic> j) => PrayerRequest(
        id: j['id'] as int,
        body: j['body'] as String,
        tags: (j['tags'] as List).cast<String>(),
        anonymous: j['anonymous'] as bool,
        status: j['status'] as String,
        createdAt: DateTime.parse(j['created_at'] as String).toLocal(),
      );
}

class Profile {
  const Profile({
    required this.id,
    this.fullName,
    this.email,
    this.branch,
    this.memberCode,
    this.createdAt,
  });

  final String id;
  final String? fullName;
  final String? email;
  final String? branch;
  final String? memberCode;
  final DateTime? createdAt;

  factory Profile.fromJson(Map<String, dynamic> j) => Profile(
        id: j['id'] as String,
        fullName: j['full_name'] as String?,
        email: j['email'] as String?,
        branch: j['branch'] as String?,
        memberCode: j['member_code'] as String?,
        createdAt: j['created_at'] == null
            ? null
            : DateTime.parse(j['created_at'] as String),
      );

  String get initials {
    final n = (fullName ?? '').trim();
    if (n.isEmpty) return 'WG';
    final parts = n.split(RegExp(r'\s+'));
    return parts.length == 1
        ? parts.first.substring(0, 1).toUpperCase()
        : (parts.first[0] + parts.last[0]).toUpperCase();
  }
}
