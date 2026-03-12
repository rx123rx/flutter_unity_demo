import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_embed_unity/flutter_embed_unity.dart';
import 'package:intl/intl.dart';
import '../pages/chat_page.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  static final _fixedLocaleNumberFormatter = NumberFormat.decimalPatternDigits(
    locale: 'en_gb',
    decimalDigits: 2,
  );

  bool? _isUnityArSupportedOnDevice;
  bool _isArSceneActive = false;
  double _rotationSpeed = 30;
  int _numberOfTaps = 0;
  bool _isUnityLoaded = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Flutter Unity Demo')),
      body: SafeArea(
        child: Builder(
          builder: (context) {
            final theme = Theme.of(context);
            final bool? isUnityArSupportedOnDevice =
                _isUnityArSupportedOnDevice;
            final String arStatusMessage;

            if (isUnityArSupportedOnDevice == null) {
              arStatusMessage = "checking...";
            } else if (isUnityArSupportedOnDevice) {
              arStatusMessage = "supported";
            } else {
              arStatusMessage = "not supported on this device";
            }

            return Column(
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      // Unity 始终在底层
                      EmbedUnity(
                        onMessageFromUnity: onMessageFromUnity,
                      ),

                      // 手动控制的 placeholder - 在 Unity 加载完成前显示
                      if (!_isUnityLoaded)
                        Positioned.fill(
                          child: Container(
                            color: Colors.grey[900],
                            child: const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    'Loading Unity...',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    "Flutter logo has been touched $_numberOfTaps times",
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Text("Activate AR ($arStatusMessage)"),
                      Switch(
                        value: _isArSceneActive,
                        onChanged:
                            isUnityArSupportedOnDevice != null &&
                                isUnityArSupportedOnDevice
                            ? (value) {
                                sendToUnity(
                                  "SceneSwitcher",
                                  "SwitchToScene",
                                  _isArSceneActive
                                      ? "FlutterEmbedExampleScene"
                                      : "FlutterEmbedExampleSceneAR",
                                );
                                setState(() {
                                  _isArSceneActive = value;
                                });
                              }
                            : null,
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(left: 16),
                      child: Text("Speed"),
                    ),
                    Expanded(
                      child: Slider(
                        min: -200,
                        max: 200,
                        value: _rotationSpeed,
                        onChanged: (value) {
                          setState(() {
                            _rotationSpeed = value;
                          });
                          _sendRotationSpeedToUnity(value);
                        },
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: ElevatedButton(
                          onPressed: () {
                            // Pause is not available in EmbedUnity
                          },
                          child: const Text("Pause"),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: ElevatedButton(
                          onPressed: () {
                            // Resume is not available in EmbedUnity
                          },
                          child: const Text("Resume"),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ChatPage(),
                              ),
                            );
                          },
                          child: const Text(
                            "Chat",
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void onMessageFromUnity(String message) {
    if (kDebugMode) {
      debugPrint('Received message from Unity: $message');
    }
    if (message == "touch") {
      if (kDebugMode) {
        debugPrint('Unity logo touched, tap count: $_numberOfTaps');
      }
      setState(() {
        _numberOfTaps += 1;
      });
    } else if (message == "scene_loaded") {
      if (kDebugMode) {
        debugPrint('Unity scene loaded');
        debugPrint('Unity loaded, hiding placeholder');
      }
      setState(() {
        _isUnityLoaded = true;
      });
      _sendRotationSpeedToUnity(_rotationSpeed);
    } else if (message == "ar:true") {
      if (kDebugMode) {
        debugPrint('AR is supported on this device');
      }
      setState(() {
        _isUnityArSupportedOnDevice = true;
      });
    } else if (message == "ar:false") {
      if (kDebugMode) {
        debugPrint('AR is not supported on this device');
      }
      setState(() {
        _isUnityArSupportedOnDevice = false;
      });
    }
  }

  void _sendRotationSpeedToUnity(double rotationSpeed) {
    if (kDebugMode) {
      debugPrint('Sending rotation speed to Unity: $rotationSpeed');
    }
    sendToUnity(
      "FlutterLogo",
      "SetRotationSpeed",
      _fixedLocaleNumberFormatter.format(rotationSpeed),
    );
  }
}
