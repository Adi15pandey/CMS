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
          .map((e) => e is Map<String, dynamic> ? User.fromJson(e) : User(userId: '', externalUserName: ''))
          .toList(),
      caseDetail: json['caseDetails'] is Map<String, dynamic>
          ? CaseDetail.fromJson(json['caseDetails'])
          : CaseDetail(caseType: '', filingDate: '', registrationNumber: ''),
      caseHistory: (json['caseHistory'] as List? ?? [])
          .map((e) => e is List ? e.map((i) => i.toString()).toList() : <String>[])
          .toList(),
      caseStatus: (json['caseStatus'] as List? ?? [])
          .map((e) => e is List ? e.map((i) => i.toString()).toList() : <String>[])
          .toList(),
      intrimOrders: (json['intrimOrders'] as List? ?? [])
          .map((e) => e is Map<String, dynamic> ? IntrimOrder.fromJson(e) : IntrimOrder(orderDate: '', s3Url: ''))
          .toList(),
      petitionerAndAdvocate: (json['petitionerAndAdvocate'] as List? ?? [])
          .map((e) => e is List ? e.map((i) => i.toString()).toList() : <String>[])
          .toList(),
      respondentAndAdvocate: (json['respondentAndAdvocate'] as List? ?? [])
          .map((e) => e is List ? e.map((i) => i.toString()).toList() : <String>[])
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
