import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_mdns_plugin/flutter_mdns_plugin.dart';
import 'package:http/http.dart' as http;
import 'dart:convert' as convert;

void main() => runApp(new MyApp());

const String discovery_service = "_co2ampel._tcp";

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => new _MyAppState();
}

class _MyAppState extends State<MyApp> {
  FlutterMdnsPlugin _mdnsPlugin;
  List<String> messageLog = <String>[];
  DiscoveryCallbacks discoveryCallbacks;
  List<ServiceInfo> _discoveredServices = <ServiceInfo>[];

  @override
  initState() {
    super.initState();

    discoveryCallbacks = new DiscoveryCallbacks(
      onDiscovered: (ServiceInfo info) {
        print("Discovered ${info.toString()}");
        setState(() {
          messageLog.insert(0, "DISCOVERY: Discovered ${info.toString()}");
        });
      },
      onDiscoveryStarted: () {
        print("Discovery started");
        setState(() {
          messageLog.insert(0, "DISCOVERY: Discovery Running");
        });
      },
      onDiscoveryStopped: () {
        print("Discovery stopped");
        setState(() {
          messageLog.insert(0, "DISCOVERY: Discovery Not Running");
        });
      },
      onResolved: (ServiceInfo info) async {
        var response = await http
            .get('http://' + info.address + ':' + info.port.toString());
        if (response.statusCode == 200) {
          var jsonResponse = convert.jsonDecode(response.body);
          print(
              "Resolved Service ${info.address}:${info.port}: ${jsonResponse['co2']} ppm");
          setState(() {
            messageLog.insert(
                0, "${info.name}: ${jsonResponse['co2']}ppm CO2");
          });
        }
      },
    );

    messageLog.add("Starting mDNS for service [$discovery_service]");
    startMdnsDiscovery(discovery_service);
  }

  startMdnsDiscovery(String serviceType) {
    _mdnsPlugin = new FlutterMdnsPlugin(discoveryCallbacks: discoveryCallbacks);
    // cannot directly start discovery, have to wait for ios to be ready first...
    Timer(Duration(seconds: 3), () => _mdnsPlugin.startDiscovery(serviceType));
//    mdns.startDiscovery(serviceType);
  }

  // this gets called on hot-reload - useful while debgging
  void reassemble() {
    super.reassemble();

    if (null != _mdnsPlugin) {
      _discoveredServices = <ServiceInfo>[];
      _mdnsPlugin.restartDiscovery();
    }
  }

  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      home: new Scaffold(
          body: new ListView.builder(
        reverse: true,
        itemCount: messageLog.length,
        itemBuilder: (BuildContext context, int index) {
          return new Text(messageLog[index]);
        },
      )),
    );
  }
}
