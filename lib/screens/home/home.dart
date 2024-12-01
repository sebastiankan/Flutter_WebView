import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_webview/constants.dart';
import 'package:flutter_webview/screens/home/load_error_widget.dart';
import 'package:webview_flutter/webview_flutter.dart';

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  late WebViewController _webController;
  bool _error = false;
  bool _loading = false;
  double _progress = 0;

  @override
  void initState() {
    super.initState();
    _webController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            setState(() {
              _progress = progress / 100;
              if (_progress == 1) _progress = 0;
            });
            debugPrint("Progress: $_progress");
          },
          onPageStarted: (String url) {
            debugPrint("Start loading: $url");
            _loading = true;
            if (mounted) setState(() {});
          },
          onPageFinished: (String url) {
            debugPrint("Loaded: $url");
            _loading = false;
            _error = false;
            _progress = 0;
            _webController.runJavaScript(
                "document.querySelectorAll('a[href*=\"/pwa\"]').forEach(element => element.parentElement.style.display = 'none');");
            FlutterNativeSplash.remove();
            if (mounted) setState(() {});
          },
          onHttpError: (HttpResponseError error) {
            debugPrint(error.toString());
            FlutterNativeSplash.remove();
            _loading = false;
            _error = true;
            if (mounted) setState(() {});
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint(error.description);
            FlutterNativeSplash.remove();
            _loading = false;
            _error = error.errorCode != -999;
            if (mounted) setState(() {});
          },
          onNavigationRequest: (NavigationRequest request) {
            if (request.url.contains('/pwa')) {
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(PWA_URL));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Colors.white,
        child: SafeArea(
          child: Column(
            children: [
              Opacity(
                  opacity: _progress == 0 ? 0 : 1,
                  child: TweenAnimationBuilder(
                    duration: const Duration(milliseconds: 250),
                    tween: Tween<double>(begin: 0, end: _progress),
                    builder: (context, double value, child) {
                      return LinearProgressIndicator(
                        value: value,
                        minHeight: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                            Theme.of(context).primaryColor),
                      );
                    },
                  )),
              Expanded(
                  child: _error
                      ? LoadErrorWidget(
                          isLoading: _loading,
                          webViewController: _webController,
                        )
                      : WebViewWidget(controller: _webController)),
            ],
          ),
        ),
      ),
      // appBar: AppBar(title: Text("WebView App"), backgroundColor: Colors.white,),
    );
  }
}
