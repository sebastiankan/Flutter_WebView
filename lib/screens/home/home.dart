import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:async';
import 'package:double_back_to_close_app/double_back_to_close_app.dart';
import 'package:http/http.dart' as http;

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final Completer<WebViewController> _controller =
      Completer<WebViewController>();
  bool _showRetryButton = false;
  bool _didGetResponse = false;
  bool _isSplashWaiting = true;
  final client = new HttpClient();

  Future<int> getResponse() async {
    int timeout = 5;
    var url = 'https://app.brookliapp.com?pwa=false';

    try {
      http.Response response =
          await http.get(Uri.parse(url)).timeout(Duration(seconds: timeout));
      if (response.statusCode == 200) {
        // do something
        setState(() {
          _showRetryButton = false;
        });
        return 1;
      } else {
        // handle it
        onError();
        return 0;
      }
    } on TimeoutException catch (e) {
      print('Timeout Error: $e');
      onError();
      return 0;
    } on SocketException catch (e) {
      print('Socket Error: $e');
      onError();
      return 0;
    } on Error catch (e) {
      print('General Error: $e');
      onError();
      return 0;
    }
  }

  void onError() {
    setState(() {
      _showRetryButton = true;
    });
  }

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(seconds: 2)).then((value) {
      getResponse();
      setState(() {
        _isSplashWaiting = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: DoubleBackToCloseApp(
          snackBar: SnackBar(content: Text("برای خروج دو بار ضربه بزنید!")),
          child: Stack(children: [
            SafeArea(
                child: WebView(
              initialUrl: 'https://app.brookliapp.com?pwa=false',
              javascriptMode: JavascriptMode.unrestricted,
              onWebViewCreated: (WebViewController webViewController) {
                if (_controller.isCompleted == false)
                  _controller.complete(webViewController);
              },
              onProgress: (int progress) {
                print("WebView is loading (progress : $progress%)");
                if (progress == 100) {
                  setState(() {
                    _didGetResponse = true;
                  });
                }
              },
              javascriptChannels: <JavascriptChannel>{
                _toasterJavascriptChannel(context),
              },
              navigationDelegate: (NavigationRequest request) {
                if (request.url.startsWith('https://www.youtube.com/')) {
                  print('blocking navigation to $request}');
                  return NavigationDecision.prevent;
                }
                print('allowing navigation to $request');
                return NavigationDecision.navigate;
              },
              onPageStarted: (String url) {
                print('Page started loading: $url');
              },
              onPageFinished: (String url) {
                print('Page finished loading: $url');
              },
              gestureNavigationEnabled: true,
            )),
            Visibility(
              visible: !_didGetResponse || _isSplashWaiting,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _showRetryButton
                        ? Column(
                            children: [
                              SizedBox(
                                height: 24,
                              ),
                              Icon(
                                Icons.wifi_off,
                                size: 42,
                              ),
                              SizedBox(
                                height: 40,
                              ),
                              Text("  اتصال به اینترنت را بررسی کنید !"),
                              SizedBox(
                                height: 24,
                              ),
                              ElevatedButton(
                                  style: ButtonStyle(
                                    textStyle: MaterialStateProperty.all(
                                        TextStyle(color: Colors.white)),
                                    backgroundColor:
                                        MaterialStateProperty.all(Colors.green),
                                    foregroundColor:
                                        MaterialStateProperty.all(Colors.white),
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _showRetryButton = false;
                                    });
                                    getResponse();
                                  },
                                  child: Text("تلاش مجدد")),
                            ],
                          )
                        : splashView()
                  ],
                ),
              ),
            )
          ])),
      // appBar: AppBar(title: Text("WebView App"), backgroundColor: Colors.white,),
    );
  }

  Expanded splashView() {
    return Expanded(
      child: Container(
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 100),
          child: Image.asset(
            'assets/image/logo.png',
            scale: 1,
          ),
        ),
      ),
    );
  }
}

JavascriptChannel _toasterJavascriptChannel(BuildContext context) {
  return JavascriptChannel(
      name: 'Toaster',
      onMessageReceived: (JavascriptMessage message) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message.message)),
        );
      });
}
