typedef RazorpayWebSuccess = void Function(Map<String, dynamic> response);
typedef RazorpayWebFailure = void Function(String message);
typedef RazorpayWebDismiss = void Function();

Future<void> openRazorpayWebCheckout(
  Map<String, dynamic> options, {
  required RazorpayWebSuccess onSuccess,
  required RazorpayWebFailure onFailure,
  required RazorpayWebDismiss onDismiss,
}) {
  throw UnsupportedError('Razorpay web checkout is only available on Flutter web.');
}
