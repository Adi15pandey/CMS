class CaseResponse {
  final bool success;
  final CaseData data;

  CaseResponse({
    required this.success,
    required this.data,
  });

  factory CaseResponse.fromJson(Map<String, dynamic> json) {
    return CaseResponse(
      success: json['success'] as bool,
      data: CaseData.fromJson(json['data'] as Map<String, dynamic>),
    );
  }
}

class CaseData {
  final String id;
  final String cnrNumber;
  final List<UserId> userId;
  final List<List<String>>? acts;
  final List<dynamic> subUserId;
  final CaseDetails caseDetails;
  final List<List<String>>? caseHistory;
  final List<List<String>>? caseStatus;
  final String status;
  final List<dynamic> caseTransferDetails;
  final List<List<String>>? petitionerAndAdvocate;
  final List<List<String>>? respondentAndAdvocate;
  final List<IntrimOrder> intrimOrders;
  final List<dynamic> archive;

  CaseData({
    required this.id,
    required this.cnrNumber,
    required this.userId,
    this.acts,
    required this.subUserId,
    required this.caseDetails,
    this.caseHistory,
    this.caseStatus,
    required this.status,
    required this.caseTransferDetails,
    this.petitionerAndAdvocate,
    this.respondentAndAdvocate,
    required this.intrimOrders,
    required this.archive,
  });

  factory CaseData.fromJson(Map<String, dynamic> json) {
    List<List<String>>? parseNestedList(dynamic data) {
      if (data is List) {
        return data.map<List<String>>((innerList) {
          if (innerList is List) {
            return innerList.map((item) => item.toString()).toList();
          }
          return [];
        }).toList();
      }
      return null;
    }

    return CaseData(
      id: json['_id'] as String,
      cnrNumber: json['cnrNumber'] as String,
      userId: (json['userId'] as List<dynamic>)
          .map((e) => UserId.fromJson(e as Map<String, dynamic>))
          .toList(),
      acts: parseNestedList(json['acts']),
      subUserId: json['subUserId'] as List<dynamic>,
      caseDetails: CaseDetails.fromJson(json['caseDetails'] as Map<String, dynamic>),
      caseHistory: parseNestedList(json['caseHistory']),
      caseStatus: parseNestedList(json['caseStatus']),
      status: json['status'] as String,
      caseTransferDetails: json['caseTransferDetails'] as List<dynamic>,
      petitionerAndAdvocate: parseNestedList(json['petitionerAndAdvocate']),
      respondentAndAdvocate: parseNestedList(json['respondentAndAdvocate']),
      intrimOrders: (json['intrimOrders'] as List<dynamic>)
          .map((e) => IntrimOrder.fromJson(e as Map<String, dynamic>))
          .toList(),
      archive: json['archive'] as List<dynamic>,
    );
  }
}

class UserId {
  final String userId;
  final String externalUserName;
  final String externalUserId;

  UserId({
    required this.userId,
    required this.externalUserName,
    required this.externalUserId,
  });

  factory UserId.fromJson(Map<String, dynamic> json) {
    return UserId(
      userId: json['userId'] as String,
      externalUserName: json['externalUserName'] as String,
      externalUserId: json['externalUserId'] as String,
    );
  }
}

class CaseDetails {
  final String cnrNumber;
  final String caseType;
  final String filingDate;
  final String filingNumber;
  final String registrationDate;
  final String registrationNumber;

  CaseDetails({
    required this.cnrNumber,
    required this.caseType,
    required this.filingDate,
    required this.filingNumber,
    required this.registrationDate,
    required this.registrationNumber,
  });

  factory CaseDetails.fromJson(Map<String, dynamic> json) {
    return CaseDetails(
      cnrNumber: json['CNR Number'] as String,
      caseType: json['Case Type'] as String,
      filingDate: json['Filing Date'] as String,
      filingNumber: json['Filing Number'] as String,
      registrationDate: json['Registration Date:'] as String,
      registrationNumber: json['Registration Number'] as String,
    );
  }
}

class IntrimOrder {
  final String orderDate;
  final String s3Url;

  IntrimOrder({
    required this.orderDate,
    required this.s3Url,
  });

  factory IntrimOrder.fromJson(Map<String, dynamic> json) {
    return IntrimOrder(
      orderDate: json['order_date'] as String,
      s3Url: json['s3_url'] as String,
    );
  }
}
