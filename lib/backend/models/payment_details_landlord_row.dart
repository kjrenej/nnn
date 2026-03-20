/// Typed model for the `payment_details_lanlord` table.
class PaymentDetailsLandlordRow {
  final String id;
  String? accountHolderName;
  String? accountNumber;
  String? ifscCode;

  PaymentDetailsLandlordRow({
    required this.id,
    this.accountHolderName,
    this.accountNumber,
    this.ifscCode,
  });

  factory PaymentDetailsLandlordRow.fromJson(Map<String, dynamic> json) {
    return PaymentDetailsLandlordRow(
      id: json['id'] as String,
      accountHolderName: json['account_holder_name'] as String?,
      accountNumber: json['account_number']?.toString(),
      ifscCode: json['ifsc_code'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (accountHolderName != null) 'account_holder_name': accountHolderName,
      if (accountNumber != null) 'account_number': accountNumber,
      if (ifscCode != null) 'ifsc_code': ifscCode,
    };
  }
}
