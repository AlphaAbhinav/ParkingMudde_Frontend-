import 'dart:async';
import 'dart:html' as html;
import 'dart:js' as js;

typedef RazorpayWebSuccess = void Function(Map<String, dynamic> response);
typedef RazorpayWebFailure = void Function(String message);
typedef RazorpayWebDismiss = void Function();

const String _checkoutScriptUrl = 'https://checkout.razorpay.com/v1/checkout.js';
Completer<void>? _scriptLoadCompleter;

Future<void> _ensureCheckoutScript() async {
  if (js.context.hasProperty('Razorpay')) return;

  if (_scriptLoadCompleter != null) {
    return _scriptLoadCompleter!.future;
  }

  _scriptLoadCompleter = Completer<void>();
  final script = html.ScriptElement()
    ..src = _checkoutScriptUrl
    ..async = true;

  script.onLoad.first.then((_) {
    if (!_scriptLoadCompleter!.isCompleted) {
      _scriptLoadCompleter!.complete();
    }
  });

  script.onError.first.then((_) {
    if (!_scriptLoadCompleter!.isCompleted) {
      _scriptLoadCompleter!.completeError(
        Exception('Unable to load Razorpay Checkout.js'),
      );
    }
  });

  html.document.head!.append(script);
  return _scriptLoadCompleter!.future;
}

Future<void> openRazorpayWebCheckout(
  Map<String, dynamic> options, {
  required RazorpayWebSuccess onSuccess,
  required RazorpayWebFailure onFailure,
  required RazorpayWebDismiss onDismiss,
}) async {
  await _ensureCheckoutScript();

  final webOptions = Map<String, dynamic>.from(options);
  webOptions['handler'] = js.allowInterop((dynamic response) {
    onSuccess({
      'razorpay_payment_id': _readJsString(response, 'razorpay_payment_id'),
      'razorpay_order_id': _readJsString(response, 'razorpay_order_id'),
      'razorpay_signature': _readJsString(response, 'razorpay_signature'),
    });
  });

  final modal = Map<String, dynamic>.from(
    (webOptions['modal'] as Map?) ?? <String, dynamic>{},
  );
  modal['ondismiss'] = js.allowInterop(() {
    onDismiss();
  });
  webOptions['modal'] = modal;

  final razorpayConstructor = js.context['Razorpay'];
  if (razorpayConstructor == null) {
    throw Exception('Razorpay Checkout.js did not initialize.');
  }

  final checkout = js.JsObject(razorpayConstructor, [js.JsObject.jsify(webOptions)]);
  checkout.callMethod('on', [
    'payment.failed',
    js.allowInterop((dynamic response) {
      onFailure(_readPaymentError(response));
    }),
  ]);
  checkout.callMethod('open');
}

String _readJsString(dynamic source, String key) {
  if (source is js.JsObject && source.hasProperty(key)) {
    return source[key]?.toString() ?? '';
  }
  if (source is Map && source.containsKey(key)) {
    return source[key]?.toString() ?? '';
  }
  return '';
}

String _readPaymentError(dynamic response) {
  if (response is js.JsObject && response.hasProperty('error')) {
    final error = response['error'];
    final description = _readJsString(error, 'description');
    if (description.isNotEmpty) return description;
  }
  return 'Payment failed. Please try again.';
}
