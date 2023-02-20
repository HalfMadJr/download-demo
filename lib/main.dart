import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FlutterDownloader.initialize(debug: true, ignoreSsl: true);
  await Permission.storage.request();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
        debugShowCheckedModeBanner: false,
        themeMode: ThemeMode.system,
        title: 'Download Demo',
        home: Home());
  }
}

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  bool _loading = true;
  bool get loading => _loading;
  bool _error = false;
  bool _pageNavigationLoading = false;
  double _progress = 0.0;
  final _key = UniqueKey();
  String url = "https://editor-8f407.web.app";
  final urlController = TextEditingController();
  static late InAppWebViewController _controller;

  late bool check;

  late PullToRefreshController _pullToRefreshController;
  @override
  void initState() {
    check = false;
    super.initState();

    _pullToRefreshController = PullToRefreshController(
      options: PullToRefreshOptions(color: const Color(0xff1CCCD2)),
      onRefresh: () async {
        if (Platform.isAndroid) {
          _controller.reload();
        } else if (Platform.isIOS) {
          _controller.loadUrl(
              urlRequest: URLRequest(url: await _controller.getUrl()));
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (await _controller.canGoBack()) {
          _controller.goBack();
          setState(() {
            _error = false;
          });
          return false;
        } else {
          return true;
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xff1CCCD2),
        body: SafeArea(
          child: Stack(
            children: [
              InAppWebView(
                key: _key,
                pullToRefreshController: _pullToRefreshController,
                initialUrlRequest: URLRequest(url: Uri.parse(url)),
                initialOptions: InAppWebViewGroupOptions(
                  crossPlatform: InAppWebViewOptions(
                    javaScriptEnabled: true,
                    allowFileAccessFromFileURLs: true,
                    useShouldOverrideUrlLoading: true,
                    userAgent: Platform.isIOS
                        ? 'Mozilla/5.0 (iPhone; CPU iPhone OS 13_1_2 like Mac OS X) AppleWebKit/605.1.15' +
                            ' (KHTML, like Gecko) Version/13.0.1 Mobile/15E148 Safari/604.1'
                        : 'Mozilla/5.0 (Linux; Android 6.0; Nexus 5 Build/MRA58N) ' +
                            'AppleWebKit/537.36 (KHTML, like Gecko) Chrome/62.0.3202.94 Mobile Safari/537.36',
                  ),
                  android: AndroidInAppWebViewOptions(
                    allowContentAccess: true,
                    thirdPartyCookiesEnabled: true,
                    allowFileAccess: true,
                    useHybridComposition: true,
                  ),
                  ios: IOSInAppWebViewOptions(
                    applePayAPIEnabled: true,
                    allowsInlineMediaPlayback: true,
                  ),
                ),
                onWebViewCreated: (controller) {
                  _controller = controller;
                },
                onProgressChanged: (controller, progress) {
                  setState(() {
                    _progress = progress / 100;
                  });
                  if (progress == 100) {
                    setState(() {
                      _loading = false;
                      _pullToRefreshController.endRefreshing();
                      urlController.text = url;
                    });
                  }
                },
                onLoadStart: (controller, url) {
                  setState(() {
                    this.url = url.toString();
                    _pageNavigationLoading = true;
                    _pullToRefreshController.isRefreshing();
                    _loading = true;
                  });
                },
                onLoadStop: (controller, url) {
                  setState(() {
                    this.url = url.toString();
                    urlController.text = this.url;
                    _pageNavigationLoading = false;
                    _loading = false;
                  });
                },
                onLoadError: (controller, url, code, message) {
                  setState(() {
                    _error = true;
                  });
                },
                onUpdateVisitedHistory: (controller, url, androidIsReload) {
                  setState(() {
                    this.url = url.toString();
                    urlController.text = this.url;
                  });
                },
                onDownloadStartRequest:
                    (controller, downloadStartRequest) async {
                  await downloadFile(downloadStartRequest.url.toString(),
                      downloadStartRequest.suggestedFilename);
                },
              ),
              if (_loading)
                Center(
                    child: CircularProgressIndicator(
                        strokeWidth: 5,
                        color: const Color(0xff1CCCD2),
                        // value: _progress,
                        backgroundColor:
                            const Color(0xff1CCCD2).withOpacity(0.4))),
              if (_error)
                Container(
                  height: double.infinity,
                  width: double.infinity,
                  color: Colors.white,
                  child: Center(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 10),
                          const Text(
                            'No Internet Connection',
                            style: TextStyle(
                              letterSpacing: 1.0,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(30),
                            child: Container(
                              width: double.infinity,
                              height: double.infinity,
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.fromLTRB(
                              40,
                              10,
                              40,
                              40,
                            ),
                            child: Text(
                              'Please check your connection again or connect to wifi',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                letterSpacing: 1.0,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              _controller.reload();
                              setState(() {
                                _error = false;
                                _loading = true;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.all(15),
                              width: double.infinity,
                              alignment: Alignment.center,
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 60),
                              decoration: BoxDecoration(
                                color: const Color(0xff313131),
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: const Text(
                                'Retry',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                        ],
                      ),
                    ),
                  ),
                ),
              if (_pageNavigationLoading && !_error && !_loading)
                Center(
                    child: CircularProgressIndicator(
                        strokeWidth: 5,
                        color: const Color(0xff1CCCD2),
                        // value: _progress,
                        backgroundColor:
                            const Color(0xff1CCCD2).withOpacity(0.4))),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> downloadFile(String url, [String? filename]) async {
    var hasStoragePermission = await Permission.storage.isGranted;
    if (!hasStoragePermission) {
      final status = await Permission.storage.request();
      hasStoragePermission = status.isGranted;
    }
    if (hasStoragePermission) {
      Directory? directory;
      if (Platform.isIOS) {
        directory = await getApplicationSupportDirectory();
      } else {
        directory = Directory('/storage/emulated/0/Download');
      }
      final taskId = await FlutterDownloader.enqueue(
        url: url,
        headers: {},
        savedDir: directory.path,
        saveInPublicStorage: true,
        showNotification: true,
        allowCellular: true,
        openFileFromNotification: true,
        fileName: filename,
      ).then((value) {
        print("download done");
        setState(() {
          _controller.goBack();
          print("go back is executed");
        });
      });
    }
  }
}
