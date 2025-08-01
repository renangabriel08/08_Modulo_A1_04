import 'package:a1/controllers/app.dart';
import 'package:a1/widgets/toast.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_headset_detector/flutter_headset_detector.dart';
import 'package:volume_controller/volume_controller.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final headsetDetector = HeadsetDetector();

  startApp() async {
    final List<ConnectivityResult> connectivityResult = await (Connectivity()
        .checkConnectivity());

    if (connectivityResult.contains(ConnectivityResult.none)) {
      MyToast.modal(
        context,
        'Sem conexão com internet, seus dados podem não estar completamente salvos.',
      );
    }

    var battery = Battery();

    if (await battery.isInBatterySaveMode) {
      MyToast.modal(
        context,
        'Seu dispositivo está no modo economia de energia, alguns recursos podem ser limitados.',
      );
    }

    battery.onBatteryStateChanged.listen((BatteryState state) async {
      if (await battery.batteryLevel <= 20 && !App.bateria) {
        App.bateria = true;
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Atenção. Bateria Baixa.'),
            content: Image.asset('assets/bateria.png'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Fechar'),
              ),
            ],
          ),
        );
      }
    });

    Map<HeadsetType, HeadsetState> headsetState = {
      HeadsetType.WIRED: HeadsetState.DISCONNECTED,
      HeadsetType.WIRELESS: HeadsetState.DISCONNECTED,
    };

    headsetDetector.getCurrentState.then((_val) {
      headsetState = _val;
      setState(() {});
    });

    headsetDetector.setListener((_val) async {
      switch (_val) {
        case HeadsetChangedEvent.WIRED_CONNECTED:
          headsetState[HeadsetType.WIRED] = HeadsetState.CONNECTED;

          MyToast.snack(
            context,
            'Fone de ouvido conectado, o volume do dispositivo foi diminuido em 70%',
          );
          double volume = await VolumeController.instance.getVolume();
          await VolumeController.instance.setVolume(volume * .3);
          break;
        case HeadsetChangedEvent.WIRED_DISCONNECTED:
          headsetState[HeadsetType.WIRED] = HeadsetState.DISCONNECTED;
          break;
        case HeadsetChangedEvent.WIRELESS_CONNECTED:
          headsetState[HeadsetType.WIRELESS] = HeadsetState.CONNECTED;

          MyToast.snack(
            context,
            'Fone de ouvido conectado, o volume do dispositivo foi diminuido em 70%',
          );
          double volume = await VolumeController.instance.getVolume();
          await VolumeController.instance.setVolume(volume * .3);
          break;
        case HeadsetChangedEvent.WIRELESS_DISCONNECTED:
          headsetState[HeadsetType.WIRELESS] = HeadsetState.DISCONNECTED;
          break;
      }
      setState(() {});
    });
  }

  @override
  void initState() {
    startApp();
    super.initState();
  }

  @override
  void dispose() {
    headsetDetector.removeListener();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;
    return Scaffold(
      appBar: AppBar(title: Text('Aprender+')),
      drawer: Drawer(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Container(height: 60),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.arrow_back),
                  ),
                  Image.asset('assets/rostos/pessoa1.jpg', height: 100),
                ],
              ),
              ListTile(
                title: Text('Home'),
                onTap: () {
                  Navigator.pop(context);
                },
              ),

              ListTile(
                title: Text('QuizMyBrain'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/quiz');
                },
              ),

              ListTile(
                title: Text('GeniusPLay'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/genius');
                },
              ),

              ListTile(
                title: Text('MemoCheck'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/memo');
                },
              ),

              ListTile(
                title: Text('Sair'),
                onTap: () {
                  SystemNavigator.pop();
                },
              ),
            ],
          ),
        ),
      ),
      body: SizedBox(
        width: width,
        height: height,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/logo.png', height: 150),
            Container(height: 16),
            Text('Bem-vindo ao Aprender+'),
          ],
        ),
      ),
    );
  }
}
