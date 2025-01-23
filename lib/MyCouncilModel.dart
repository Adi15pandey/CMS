class CaseDetails {
  final String id;
  final String cnrNumber;
  final List<User> userId;
  final CaseDetail caseDetail;
  final List<List<String>> caseHistory;
  final List<List<String>> caseStatus;
  final List<IntrimOrder> intrimOrders;
  final List<List<String>> petitionerAndAdvocate; // Added field
  final List<List<String>> respondentAndAdvocate; // Added field

  CaseDetails({
    required this.id,
    required this.cnrNumber,
    required this.userId,
    required this.caseDetail,
    required this.caseHistory,
    required this.caseStatus,
    required this.intrimOrders,
    required this.petitionerAndAdvocate, // Added to constructor
    required this.respondentAndAdvocate, // Added to constructor
  });

  factory CaseDetails.fromJson(Map<String, dynamic> json) {
    return CaseDetails(
      id: json['_id'] ?? '',
      cnrNumber: json['cnrNumber'] ?? '',
      userId: (json['userId'] as List? ?? [])
          .map((e) => User.fromJson(e))
          .toList(),
      caseDetail: CaseDetail.fromJson(json['caseDetails'] ?? {}),
      caseHistory: (json['caseHistory'] as List? ?? [])
          .map((e) => List<String>.from(e ?? []))
          .toList(),
      caseStatus: (json['caseStatus'] as List? ?? [])
          .map((e) => List<String>.from(e ?? []))
          .toList(),
      intrimOrders: (json['intrimOrders'] as List? ?? [])
          .map((e) => IntrimOrder.fromJson(e ?? {}))
          .toList(),
      petitionerAndAdvocate: (json['petitionerAndAdvocate'] as List? ?? [])
          .map((e) => List<String>.from(e ?? []))
          .toList(),
      respondentAndAdvocate: (json['respondentAndAdvocate'] as List? ?? [])
          .map((e) => List<String>.from(e ?? []))
          .toList(),
    );
  }
}

class User {
  final String userId;
  final String externalUserName;

  User({required this.userId, required this.externalUserName});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      userId: json['userId'] ?? '',
      externalUserName: json['externalUserName'] ?? '',
    );
  }
}

class CaseDetail {
  final String caseType;
  final String filingDate; // Consider using DateTime
  final String registrationNumber;

  CaseDetail({
    required this.caseType,
    required this.filingDate,
    required this.registrationNumber,
  });

  factory CaseDetail.fromJson(Map<String, dynamic> json) {
    return CaseDetail(
      caseType: json['Case Type'] ?? '',
      filingDate: json['Filing Date'] ?? '',
      registrationNumber: json['Registration Number:'] ?? '',
    );
  }
}

class IntrimOrder {
  final String orderDate; // Consider using DateTime
  final String s3Url;

  IntrimOrder({required this.orderDate, required this.s3Url});

  factory IntrimOrder.fromJson(Map<String, dynamic> json) {
    return IntrimOrder(
      orderDate: json['order_date'] ?? '',
      s3Url: json['s3_url'] ?? '',
    );
  }
}
