// import 'package:flutter/material.dart';
// import 'package:geolocator/geolocator.dart';
//
// void main() {
//   runApp(const DashboardScreen());
// }
//
// class DashboardScreen extends StatefulWidget {
//   const DashboardScreen({Key? key}) : super(key: key);
//
//   @override
//   _DashboardState createState() => _DashboardState();
// }
//
// class _DashboardState extends State<DashboardScreen> {
//   final Geolocator geolocator = Geolocator()..forceAndroidLocationManager;
//   late Position _currentPosition;
//   late String _currentAddress;
//
//   @override
//   void initState() {
//     super.initState();
//     _getCurrentLocation();
//   }
//
//   _getCurrentLocation() {
//     geolocator
//         .getCurrentPosition(desiredAccuracy: LocationAccuracy.best)
//         .then((Position position) {
//       setState(() {
//         _currentPosition = position;
//       });
//
//       _getAddressFromLatLng();
//     }).catchError((e) {
//       print(e);
//     });
//   }
//
//   _getAddressFromLatLng() async {
//     try {
//       List<Placemark> p = await geolocator.placemarkFromCoordinates(
//           _currentPosition.latitude, _currentPosition.longitude);
//
//       Placemark place = p[0];
//
//       setState(() {
//         _currentAddress =
//             "${place.locality}, ${place.postalCode}, ${place.country}";
//       });
//     } catch (e) {
//       print(e);
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("DASHBOARD"),
//       ),
//       body: SingleChildScrollView(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: <Widget>[
//             Container(
//                 decoration: BoxDecoration(
//                   color: Theme.of(context).canvasColor,
//                 ),
//                 padding:
//                     const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//                 child: Column(
//                   children: <Widget>[
//                     Row(
//                       children: <Widget>[
//                         const Icon(Icons.location_on),
//                         const SizedBox(
//                           width: 8,
//                         ),
//                         Expanded(
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: <Widget>[
//                               Text(
//                                 'Location',
//                                 style: Theme.of(context).textTheme.caption,
//                               ),
//                               if (_currentPosition != null &&
//                                   _currentAddress != null)
//                                 Text(_currentAddress,
//                                     style:
//                                         Theme.of(context).textTheme.bodyText2),
//                             ],
//                           ),
//                         ),
//                         const SizedBox(width: 8),
//                       ],
//                     ),
//                   ],
//                 ))
//           ],
//         ),
//       ),
//     );
//   }
// }

import 'dart:async';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:flutter_background_service_ios/flutter_background_service_ios.dart';
import 'package:location/location.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeService();
  // FlutterBackgroundService.initialize(initializeService, foreground: false);
  runApp(const MyApp());
}

Future<void> initializeService() async {
  final service = FlutterBackgroundService();
  await service.configure(
    androidConfiguration: AndroidConfiguration(
      // this will executed when app is in foreground or background in separated isolate
      onStart: onStart,
      // auto start service
      autoStart: true,
      isForegroundMode: true,
    ),
    iosConfiguration: IosConfiguration(
      // auto start service
      autoStart: true,
      // this will executed when app is in foreground in separated isolate
      onForeground: onStart,
      // you have to enable background fetch capability on xcode project
      onBackground: onIosBackground,
    ),
  );
}

void onIosBackground() {
  WidgetsFlutterBinding.ensureInitialized();
  debugPrint('FLUTTER BACKGROUND FETCH');
}

void onStart() {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isIOS) FlutterBackgroundServiceIOS.registerWith();
  if (Platform.isAndroid) FlutterBackgroundServiceAndroid.registerWith();

  final service = FlutterBackgroundService();
  service.onDataReceived.listen((event) {
    if (event!["action"] == "setAsForeground") {
      service.setAsForegroundService();
      return;
    }

    if (event["action"] == "setAsBackground") {
      service.setAsBackgroundService();
    }

    if (event["action"] == "stopService") {
      service.stopService();
    }
  });

  // bring to foreground
  service.setAsForegroundService();
  Timer.periodic(const Duration(seconds: 1), (timer) async {
    if (!(await service.isRunning())) timer.cancel();
    // service.setNotificationInfo(
    //   title: "",//My App Service
    //   content: "",//Updated at ${DateTime.now()}
    // );

    // test using external plugin
    final deviceInfo = DeviceInfoPlugin();
    String? device;
    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      device = androidInfo.model;
    }
    if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      device = iosInfo.model;
    }

    service.sendData(
      {
        "current_date": DateTime.now().toIso8601String(),
        "device": device,
      },
    );
  });
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: GeoLocScreen());
  }
}

class GeoLocScreen extends StatefulWidget {
  const GeoLocScreen({Key? key}) : super(key: key);

  @override
  _GeoLocScreenState createState() => _GeoLocScreenState();
}

class _GeoLocScreenState extends State<GeoLocScreen> {
  Location location = Location();
  late bool serviceEnabled;
  late PermissionStatus permissionGranted;
  late LocationData locationData;
  bool isListenLocation = false, isGetLocation = false;
  String text = "Stop Service";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder(
          stream: FlutterBackgroundService().onDataReceived,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  child: const Text("Foreground Mode"),
                  onPressed: () {
                    FlutterBackgroundService()
                        .sendData({"action": "setAsForeground"});
                  },
                ),
                ElevatedButton(
                  child: const Text("Background Mode"),
                  onPressed: () {
                    FlutterBackgroundService()
                        .sendData({"action": "setAsBackground"});
                  },
                ),
                ElevatedButton(
                  child: Text(text),
                  onPressed: () async {
                    final service = FlutterBackgroundService();
                    var isRunning = await service.isRunning();
                    if (isRunning) {
                      service.sendData(
                        {"action": "stopService"},
                      );
                    } else {
                      service.startService();
                    }

                    if (!isRunning) {
                      text = 'Stop Service';
                    } else {
                      text = 'Start Service';
                    }
                    setState(() {});
                  },
                ),
                ElevatedButton(
                    onPressed: () async {
                      serviceEnabled = await location.serviceEnabled();
                      if (!serviceEnabled) {
                        serviceEnabled = await location.requestService();
                        if (serviceEnabled) return;
                      }
                      permissionGranted = await location.hasPermission();
                      if (permissionGranted == PermissionStatus.denied) {
                        permissionGranted = await location.requestPermission();
                        if (permissionGranted != PermissionStatus.granted) {
                          return;
                        }
                      }
                      locationData = await location.getLocation();
                      setState(() {
                        isGetLocation = true;
                      });
                    },
                    child: const Text('Get Location')),
                isGetLocation
                    ? Text(
                        'Location: ${locationData.latitude}/${locationData.longitude}')
                    : Container(),
                ElevatedButton(
                    onPressed: () async {
                      serviceEnabled = await location.serviceEnabled();
                      if (!serviceEnabled) {
                        serviceEnabled = await location.requestService();
                        if (serviceEnabled) return;
                      }
                      permissionGranted = await location.hasPermission();
                      if (permissionGranted == PermissionStatus.denied) {
                        permissionGranted = await location.requestPermission();
                        if (permissionGranted != PermissionStatus.granted)
                          return;
                      }
                      setState(() {
                        isListenLocation = true;
                      });
                    },
                    child: const Text('Listen Location')),
                StreamBuilder(
                    stream: location.onLocationChanged,
                    builder: (BuildContext context, AsyncSnapshot snapshot) {
                      if (snapshot.connectionState != ConnectionState.waiting) {
                        var data = snapshot.data as LocationData;
                        return Text(
                            'Location always change: \n ${data.latitude}/${data.longitude}');
                      } else if (snapshot.hasError) {
                        return const Icon(Icons.error_outline);
                      } else {
                        return const CircularProgressIndicator();
                      }
                    })
              ],
            );
          }),
    );
  }
}
