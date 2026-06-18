class CategoryModel {
  final int id;
  final String name;
  final int order;
  final String? image;
  final bool status;
  final bool isDeleted;
  final String? localImagePath;

  CategoryModel({
    required this.id,
    required this.name,
    required this.order,
    required this.image,
    required this.status,
    required this.isDeleted,
    this.localImagePath,
  });

  CategoryModel copyWith({
    int? id,
    String? name,
    int? order,
    String? image,
    bool? status,
    bool? isDeleted,
    String? localImagePath,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      order: order ?? this.order,
      image: image ?? this.image,
      status: status ?? this.status,
      isDeleted: isDeleted ?? this.isDeleted,
      localImagePath: localImagePath ?? this.localImagePath,
    );
  }

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] is int ? json['id'] : int.tryParse('${json['id']}') ?? 0,
      name: json['name']?.toString() ?? '',
      order: json['order'] is int
          ? json['order']
          : int.tryParse('${json['order']}') ?? 0,
      image: json['image']?.toString(),
      status: json['status'] as bool? ?? false,
      isDeleted: json['isDeleted'] as bool? ?? false,
      localImagePath: json['localImagePath']?.toString(),
    );
  }

  Map<String, dynamic> toCacheJson() {
    return {
      'id': id,
      'name': name,
      'order': order,
      'image': image,
      'status': status,
      'isDeleted': isDeleted,
      'localImagePath': localImagePath,
    };
  }
}

class Chapter {
  final String id;
  final String categoryId;
  final String name;
  final int order;
  final String? image;
  final bool status;
  final bool isDeleted;

  Chapter({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.order,
    required this.image,
    required this.status,
    required this.isDeleted,
  });

  factory Chapter.fromJson(Map<String, dynamic> json) {
    return Chapter(
      id: json['id']?.toString() ?? '',
      categoryId: json['categoryId']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      order: json['order'] is int
          ? json['order']
          : int.tryParse('${json['order']}') ?? 0,
      image: json['image']?.toString(),
      status: json['status'] as bool? ?? false,
      isDeleted: json['isDeleted'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toCacheJson() {
    return {
      'id': id,
      'categoryId': categoryId,
      'name': name,
      'order': order,
      'image': image,
      'status': status,
      'isDeleted': isDeleted,
    };
  }
}

class TopicItem {
  final String id;
  final String subjectId;
  final String topicName;
  final String? imageUrl;
  final String? videoUrl;
  final String? thumbUrl;
  final String? description;
  final bool status;
  final bool isDeleted;
  final String? localImagePath;
  // Encryption fields
  final String? encryptedUrl;
  final String? iv;
  final String? tag;

  TopicItem({
    required this.id,
    required this.subjectId,
    required this.topicName,
    required this.imageUrl,
    this.videoUrl,
    this.thumbUrl,
    required this.description,
    required this.status,
    required this.isDeleted,
    this.localImagePath,
    this.encryptedUrl,
    this.iv,
    this.tag,
  });

  TopicItem copyWith({
    String? id,
    String? subjectId,
    String? topicName,
    String? imageUrl,
    String? videoUrl,
    String? thumbUrl,
    String? description,
    bool? status,
    bool? isDeleted,
    String? localImagePath,
    String? encryptedUrl,
    String? iv,
    String? tag,
  }) {
    return TopicItem(
      id: id ?? this.id,
      subjectId: subjectId ?? this.subjectId,
      topicName: topicName ?? this.topicName,
      imageUrl: imageUrl ?? this.imageUrl,
      videoUrl: videoUrl ?? this.videoUrl,
      thumbUrl: thumbUrl ?? this.thumbUrl,
      description: description ?? this.description,
      status: status ?? this.status,
      isDeleted: isDeleted ?? this.isDeleted,
      localImagePath: localImagePath ?? this.localImagePath,
      encryptedUrl: encryptedUrl ?? this.encryptedUrl,
      iv: iv ?? this.iv,
      tag: tag ?? this.tag,
    );
  }

  factory TopicItem.fromJson(Map<String, dynamic> json) {
    // Handle encrypted URL - will be decrypted in repository
    final encryptedUrl = json['encryptedUrl']?.toString();
    final iv = json['iv']?.toString();
    final tag = json['tag']?.toString();

    // videoUrl can come from either videoUrls (legacy) or will be set after decryption
    final videoUrl = json['videoUrls']?.toString();

    return TopicItem(
      id: json['id']?.toString() ?? '',
      subjectId: json['subjectId']?.toString() ?? '',
      topicName: json['name']?.toString() ?? '',
      imageUrl: json['imageUrls']?.toString(),
      videoUrl: videoUrl,
      thumbUrl: (json['thumbUrl'] ?? json['thumbUrls'])?.toString(),
      description: json['description']?.toString(),
      status: json['status'] as bool? ?? false,
      isDeleted: json['isDeleted'] as bool? ?? false,
      localImagePath: json['localImagePath']?.toString(),
      encryptedUrl: encryptedUrl,
      iv: iv,
      tag: tag,
    );
  }

  Map<String, dynamic> toCacheJson() {
    return {
      'id': id,
      'subjectId': subjectId,
      'name': topicName,
      'imageUrls': imageUrl,
      'videoUrls': videoUrl,
      'thumbUrl': thumbUrl,
      'description': description,
      'status': status,
      'isDeleted': isDeleted,
      'localImagePath': localImagePath,
      'encryptedUrl': encryptedUrl,
      'iv': iv,
      'tag': tag,
    };
  }
}
