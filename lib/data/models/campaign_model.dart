/// Model data kampanye donasi (Bab 8.2 — tabel `campaigns`).
class CampaignModel {
  final String id;
  final String title;
  final String description;
  final String category; // 'Panti Asuhan', 'Bencana', 'Pendidikan', 'Kesehatan'
  final double targetAmount;
  final double collectedAmount;
  final double latitude;
  final double longitude;
  final String locationLabel;
  final String endsAt; // ISO 8601
  final String? imageUrl;
  final String createdAt;

  const CampaignModel({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.targetAmount,
    this.collectedAmount = 0.0,
    required this.latitude,
    required this.longitude,
    required this.locationLabel,
    required this.endsAt,
    this.imageUrl,
    required this.createdAt,
  });

  /// Persentase pencapaian donasi (0.0 sampai 1.0+).
  double get progressPercentage {
    if (targetAmount <= 0) return 0.0;
    final progress = collectedAmount / targetAmount;
    return progress > 1.0 ? 1.0 : progress;
  }

  /// Status apakah kampanye sudah mencapai target.
  bool get isFunded => collectedAmount >= targetAmount;

  factory CampaignModel.fromMap(Map<String, dynamic> map) {
    return CampaignModel(
      id: (map['id'] ?? map['campaign_id']).toString(),
      title: map['title'] as String,
      description: map['description'] as String? ?? '',
      category: map['category'] as String,
      targetAmount: (map['target_amount'] as num).toDouble(),
      collectedAmount: (map['collected_amount'] as num?)?.toDouble() ?? 0.0,
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0.0,
      locationLabel: map['location_label'] as String? ?? '',
      endsAt: map['ends_at'] as String? ?? DateTime.now().toIso8601String(),
      imageUrl: map['image_url'] as String?,
      createdAt: map['created_at'] as String? ?? DateTime.now().toIso8601String(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'target_amount': targetAmount,
      'collected_amount': collectedAmount,
      'latitude': latitude,
      'longitude': longitude,
      'location_label': locationLabel,
      'ends_at': endsAt,
      'image_url': imageUrl,
      'created_at': createdAt,
    };
  }

  CampaignModel copyWith({
    String? id,
    String? title,
    String? description,
    String? category,
    double? targetAmount,
    double? collectedAmount,
    double? latitude,
    double? longitude,
    String? locationLabel,
    String? endsAt,
    String? imageUrl,
    String? createdAt,
  }) {
    return CampaignModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      targetAmount: targetAmount ?? this.targetAmount,
      collectedAmount: collectedAmount ?? this.collectedAmount,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      locationLabel: locationLabel ?? this.locationLabel,
      endsAt: endsAt ?? this.endsAt,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
