class ProfileModel {
  final int id;
  final String name;
  final String email;
  final String mobile;
  final String? imageUrl;
  final String address;
  final String pincode;
  final bool isDeleted;
  final String createdAt;
  final String updatedAt;

  ProfileModel({
    required this.id,
    required this.name,
    required this.email,
    required this.mobile,
    this.imageUrl,
    required this.address,
    required this.pincode,
    required this.isDeleted,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id'] as int? ?? 0,
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      mobile: json['mobile']?.toString() ?? '',
      imageUrl: json['imageUrl']?.toString(),
      address: json['address']?.toString() ?? '',
      pincode: json['pincode']?.toString() ?? '',
      isDeleted: json['isDeleted'] as bool? ?? false,
      createdAt: json['createdAt']?.toString() ?? '',
      updatedAt: json['updatedAt']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'mobile': mobile,
      'imageUrl': imageUrl,
      'address': address,
      'pincode': pincode,
      'isDeleted': isDeleted,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  ProfileModel copyWith({
    int? id,
    String? name,
    String? email,
    String? mobile,
    String? imageUrl,
    String? address,
    String? pincode,
    bool? isDeleted,
    String? createdAt,
    String? updatedAt,
  }) {
    return ProfileModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      mobile: mobile ?? this.mobile,
      imageUrl: imageUrl ?? this.imageUrl,
      address: address ?? this.address,
      pincode: pincode ?? this.pincode,
      isDeleted: isDeleted ?? this.isDeleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

