import 'package:flutter/material.dart';
import 'package:flutter_webview/constants.dart';
import 'package:webview_flutter/webview_flutter.dart';

class LoadErrorWidget extends StatefulWidget {
  const LoadErrorWidget(
      {super.key, required this.isLoading, required this.webViewController});
  final bool isLoading;
  final WebViewController webViewController;

  @override
  State<LoadErrorWidget> createState() => _LoadErrorWidgetState();
}

class _LoadErrorWidgetState extends State<LoadErrorWidget> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Image.asset("assets/splash.png"),
            ),
            const SizedBox(height: 100),
            Text(
              "خطا در اتصال به اینترنت\nلطفاً از اتصال اینترنت خود مطمئن شوید و فیلترشکن خود را خاموش کنید",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 20),
            widget.isLoading
                ? CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: () async {
                      if (await widget.webViewController.currentUrl() == null) {
                        widget.webViewController
                            .loadRequest(Uri.parse(PWA_URL));
                      } else {
                        widget.webViewController.reload();
                      }
                    },
                    child: Text("تلاش مجدد"))
          ],
        ),
      ),
    );
  }
}
