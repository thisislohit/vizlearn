class ContactUsResponse {
  final bool success;
  final String message;
  final ContactUsData data;

  ContactUsResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory ContactUsResponse.fromJson(Map<String, dynamic> json) {
    late final ContactUsData dataList;
    
    if (json['data'] != null) {
      final dynamic dataValue = json['data'];
      if (dataValue is List) {
        dataList = ContactUsData.fromJson(dataValue.first);
      }
    }

    return ContactUsResponse(
      success: json['success'] ?? false,
      message: (json['message'] ?? '').toString(),
      data: dataList,
    );
  }
}

class ContactUsData {
  final int id;
  final String description;
  final String mobile;
  final String email;
  final String websiteLink;

  ContactUsData({
    required this.id,
    required this.description,
    required this.mobile,
    required this.email,
    required this.websiteLink,
  });

  factory ContactUsData.fromJson(Map<String, dynamic> json) {
    int parsedId = 0;
    final dynamic rawId = json['id'];
    if (rawId is int) {
      parsedId = rawId;
    } else if (rawId is String) {
      parsedId = int.tryParse(rawId) ?? 0;
    }

    return ContactUsData(
      id: parsedId,
      description: (json['description'] ?? '').toString(),
      mobile: (json['mobile'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      websiteLink: (json['websiteLink'] ?? '').toString(),
    );
  }
}

