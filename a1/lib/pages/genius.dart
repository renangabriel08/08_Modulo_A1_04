import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:a1/controllers/app.dart';
import 'package:a1/styles/cores.dart';
import 'package:a1/widgets/toast.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_headset_detector/flutter_headset_detector.dart';
import 'package:volume_controller/volume_controller.dart';

class Genius extends StatefulWidget {
  const Genius({super.key});

  @override
  State<Genius> createState() => _GeniusState();
}

class _GeniusState extends State<Genius> {
  final headsetDetector = HeadsetDetector();

  bool habilitado = true;
  bool jogoIniciado = false;

  int segundos = 0;
  int nivel = 1;
  int score = 0;

  Timer? timer;
  String idioma = 'pt';

  List cores = [];

  List coresClicadas = [];
  List coresFaladas = [];

  fimDejogo() {
    MyToast.get(
      'Fim de jogo! Score: $score | Tempo: ${(segundos ~/ 60).toString().padLeft(2, '0')}:${(segundos % 60).toString().padLeft(2, '0')}',
    );

    coresClicadas = [];
    coresFaladas = [];

    timer?.cancel();
    segundos = 0;
    nivel = 1;
    score = 0;

    habilitado = true;
    jogoIniciado = false;

    setState(() {});
  }

  click(cor) async {
    cor['click'] = true;
    setState(() {});

    coresClicadas.add(cor['path']);
    final player = AudioPlayer();
    await player.play(AssetSource('genius/click.mp3'));
    await Future.delayed(const Duration(milliseconds: 200));

    cor['click'] = false;
    setState(() {});

    if (coresClicadas.length == coresFaladas.length) {
      if (coresClicadas.toString() == coresFaladas.toString()) {
        score++;

        coresClicadas.clear();
        coresFaladas.clear();

        if (score % 2 == 0) {
          nivel++;
        }

        await falar();
      } else {
        fimDejogo();
      }
    }
  }

  falar() async {
    habilitado = false;
    setState(() {});

    for (int i = 0; i < nivel; i++) {
      int i = Random().nextInt(5);
      final player = AudioPlayer();
      await player.play(AssetSource('genius/$idioma/$i.mp3'));
      coresFaladas.add('assets/genius/$idioma/$i.mp3');
      await Future.delayed(const Duration(milliseconds: 1000));
    }

    await Future.delayed(const Duration(seconds: 1));

    habilitado = true;
    setState(() {});
  }

  start() async {
    jogoIniciado = !jogoIniciado;
    setState(() {});

    if (jogoIniciado) {
      timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        segundos++;
        setState(() {});
      });

      await falar();
    } else {
      fimDejogo();
    }
  }

  startApp() async {
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

    var battery = Battery();
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

    if (window.locale.languageCode == 'es') {
      idioma = 'es';
    } else if (window.locale.languageCode == 'en') {
      idioma = 'en';
    }

    cores = [
      {
        'path': 'assets/genius/$idioma/0.mp3',
        'color': Colors.blue,
        'click': false,
      },
      {
        'path': 'assets/genius/$idioma/1.mp3',
        'color': Colors.yellow,
        'click': false,
      },
      {
        'path': 'assets/genius/$idioma/2.mp3',
        'color': Colors.green,
        'click': false,
      },
      {
        'path': 'assets/genius/$idioma/3.mp3',
        'color': Colors.orange,
        'click': false,
      },
      {
        'path': 'assets/genius/$idioma/4.mp3',
        'color': Colors.red,
        'click': false,
      },
    ];

    setState(() {});
  }

  @override
  void initState() {
    startApp();
    super.initState();
  }

  @override
  void dispose() {
    headsetDetector.removeListener();
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

    return Scaffold(
      appBar: AppBar(
        title: Text('Genius Play'),
        automaticallyImplyLeading: false,
        leading: IconButton(
          onPressed: () {
            fimDejogo();
            Navigator.pop(context);
          },
          icon: Icon(Icons.arrow_back),
        ),
      ),
      body: SizedBox(
        width: width,
        height: height,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              DropdownButtonFormField(
                value: idioma,
                items: [
                  DropdownMenuItem(value: 'pt', child: Text('Português')),
                  DropdownMenuItem(value: 'en', child: Text('Inglês')),
                  DropdownMenuItem(value: 'es', child: Text('Espanhol')),
                ],
                onChanged: (value) {
                  idioma = value.toString();
                  cores = [
                    {
                      'path': 'assets/genius/$idioma/0.mp3',
                      'color': Colors.blue,
                      'click': false,
                    },
                    {
                      'path': 'assets/genius/$idioma/1.mp3',
                      'color': Colors.yellow,
                      'click': false,
                    },
                    {
                      'path': 'assets/genius/$idioma/2.mp3',
                      'color': Colors.green,
                      'click': false,
                    },
                    {
                      'path': 'assets/genius/$idioma/3.mp3',
                      'color': Colors.orange,
                      'click': false,
                    },
                    {
                      'path': 'assets/genius/$idioma/4.mp3',
                      'color': Colors.red,
                      'click': false,
                    },
                  ];

                  setState(() {});
                },
              ),
              Container(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Nível: $nivel'),
                  Text('Score: $score'),
                  Text(
                    'Cronometro: ${(segundos ~/ 60).toString().padLeft(2, '0')}:${(segundos % 60).toString().padLeft(2, '0')}',
                  ),
                ],
              ),
              Container(height: 16),
              Wrap(
                children: [
                  for (var cor in cores)
                    Padding(
                      padding: EdgeInsetsGeometry.all(10),
                      child: GestureDetector(
                        onTap: () => click(cor),
                        child: Container(
                          width: 100,
                          height: 100,
                          color: !habilitado ? Colors.grey : cor['color'],
                          child: cor['click']
                              ? Center(
                                  child: Container(
                                    width: 20,
                                    height: 20,
                                    decoration: BoxDecoration(
                                      color: Cores.branco,
                                      borderRadius: BorderRadius.circular(999),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Cores.branco,
                                          blurRadius: 20,
                                          spreadRadius: 20,
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              : Container(),
                        ),
                      ),
                    ),
                ],
              ),

              Container(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton(
                    onPressed: () => start(),
                    child: Text(jogoIniciado ? 'STOP' : 'START'),
                  ),

                  ElevatedButton(onPressed: () => (), child: Text('Restart')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
