import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MQTTExample(),
    );
  }
}

class MQTTExample extends StatefulWidget {
  const MQTTExample({super.key});

  @override
  State<MQTTExample> createState() => _MQTTExampleState();
}

class _MQTTExampleState extends State<MQTTExample> {
  final client = MqttServerClient(
    'broker.hivemq.com',
    'your_unique_client_id3',
  );
  final String topic2 = 'flutter/dart';
  List<String> topic2Messages = [];
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    connectToMQTT();
  }

  Future<void> connectToMQTT() async {
    client.port = 1883;
    client.logging(on: false);
    client.keepAlivePeriod = 10;
    client.onDisconnected = () => print('Disconnected from MQTT');

    final connMessage =
        MqttConnectMessage()
            .withClientIdentifier('your_unique_client_id3')
            .startClean();
    client.connectionMessage = connMessage;

    try {
      await client.connect();
      print('Connected to MQTT Broker!');
      subscribeToTopic2();
    } catch (e) {
      print('Connection failed: $e');
    }
  }

  void subscribeToTopic2() {
    client.subscribe(topic2, MqttQos.atMostOnce);
    client.updates!.listen((List<MqttReceivedMessage<MqttMessage>> c) {
      final recMess = c[0].payload as MqttPublishMessage;
      final message = MqttPublishPayload.bytesToStringAsString(
        recMess.payload.message,
      );
      if (c[0].topic == topic2) {
        setState(() {
          topic2Messages.add(message);
        });
      }
    });
  }

  void publishMessage() {
    final message = _controller.text.trim();
    if (message.isNotEmpty) {
      final builder = MqttClientPayloadBuilder();
      builder.addString(message);
      client.publishMessage(topic2, MqttQos.atMostOnce, builder.payload!);
      _controller.clear();
    }
  }

  @override
  void dispose() {
    client.disconnect();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('MQTT Flutter Example')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: topic2Messages.length,
              itemBuilder: (context, index) {
                return ListTile(title: Text(topic2Messages[index]));
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Enter message...',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: publishMessage,
                  child: const Text('Publish'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
