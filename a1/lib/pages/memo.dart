import 'dart:async';

import 'package:a1/controllers/app.dart';
import 'package:a1/styles/cores.dart';
import 'package:a1/widgets/toast.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_headset_detector/flutter_headset_detector.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:vibration/vibration.dart';
import 'package:volume_controller/volume_controller.dart';

class Memo extends StatefulWidget {
  const Memo({super.key});

  @override
  State<Memo> createState() => _MemoState();
}

enum Estado { iniciado, timer, parado }

class _MemoState extends State<Memo> {
  final headsetDetector = HeadsetDetector();
  Estado estado = Estado.parado;

  int segundos = 0;
  int acertos = 0;
  int erros = 0;

  bool iniciado = false;

  Timer? timer;
  List imagens = [];
  List imagensSelecionadas = [];

  String tema = 'Animais da Amazonia';

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

    selecionarImagens();
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

    gyroscopeEvents.listen(
      (GyroscopeEvent event) {
        if (event.z > 5 || event.z < -5) {
          imagens.shuffle();
          setState(() {});
        }
      },
      onError: (error) {},
      cancelOnError: true,
    );

    setState(() {});
  }

  selecionarImagens() {
    imagens.clear();

    for (int i = 0; i < 4; i++) {
      imagens.add({
        'tipo': 'assets',
        'path': 'assets/memocheck/$tema/$i.jpg',
        'virada': true,
      });
    }

    for (int i = 0; i < 4; i++) {
      imagens.add({
        'tipo': 'assets',
        'path': 'assets/memocheck/$tema/$i.jpg',
        'virada': true,
      });
    }

    imagens.shuffle();
    setState(() {});
  }

  click(img) async {
    if (!img['virada']) {
      imagensSelecionadas.add(img['path']);
      img['virada'] = true;
      setState(() {});

      if (imagensSelecionadas.length == 2) {
        if (imagensSelecionadas[0] == imagensSelecionadas[1]) {
          acertos++;
          if (acertos == 4) {
            stop();
          }
        } else {
          erros++;
          Vibration.vibrate();
          await Future.delayed(const Duration(milliseconds: 500));
          for (var img in imagens) {
            if (img['path'] == imagensSelecionadas[0] ||
                img['path'] == imagensSelecionadas[1]) {
              img['virada'] = false;
            }
          }
        }

        imagensSelecionadas.clear();
      }
    }
  }

  start() {
    estado = Estado.timer;
    segundos = 3;
    setState(() {});

    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      segundos--;
      setState(() {});

      if (segundos == 0) {
        timer?.cancel();
        estado = Estado.iniciado;
        iniciado = true;

        for (var img in imagens) {
          img['virada'] = false;
        }

        setState(() {});

        timer = Timer.periodic(const Duration(seconds: 1), (_) {
          segundos++;
          setState(() {});
        });
      }
    });
  }

  stop() {
    MyToast.get(
      'Fim de jogo! Acertos: $acertos | Erros: $erros | Tempo: ${(segundos ~/ 60).toString().padLeft(2, '0')}:${(segundos % 60).toString().padLeft(2, '0')}',
    );

    estado = Estado.parado;
    iniciado = false;

    segundos = 0;
    acertos = 0;
    erros = 0;

    timer?.cancel();

    setState(() {});
  }

  @override
  void initState() {
    startApp();
    super.initState();
  }

  @override
  void dispose() {
    timer?.cancel();
    headsetDetector.removeListener();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(title: Text('MemoCheck'), automaticallyImplyLeading: true),
      body: SizedBox(
        width: width,
        height: height,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: imagens.isEmpty
              ? Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Tema:'),
                        SizedBox(
                          width: width * .8,
                          child: DropdownButtonFormField(
                            value: tema,
                            items: iniciado
                                ? []
                                : [
                                    DropdownMenuItem(
                                      value: 'Animais da Amazonia',
                                      child: Text('Animais da Amazonia'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'Carros',
                                      child: Text('Carros'),
                                    ),
                                  ],
                            onChanged: (value) {
                              tema = value.toString();
                              selecionarImagens();

                              setState(() {});
                            },
                          ),
                        ),
                      ],
                    ),
                    Container(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Tempo: ${(segundos ~/ 60).toString().padLeft(2, '0')}:${(segundos % 60).toString().padLeft(2, '0')}',
                        ),
                        Text('Acertos: ${acertos.toString().padLeft(2, '0')}'),
                        Text('Erros: ${erros.toString().padLeft(2, '0')}'),
                      ],
                    ),
                    Container(height: 16),
                    Wrap(
                      children: [
                        for (var img in imagens)
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: GestureDetector(
                              onTap: () {
                                if (iniciado) {
                                  click(img);
                                }
                              },
                              child: Container(
                                color: Cores.azulClaro,
                                width: 100,
                                height: 100,
                                child: img['virada']
                                    ? Image.asset(
                                        img['path'],
                                        fit: BoxFit.cover,
                                      )
                                    : null,
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
                          onPressed: () => estado == Estado.parado
                              ? start()
                              : estado == Estado.iniciado
                              ? stop()
                              : null,
                          child: Text(
                            estado == Estado.parado
                                ? 'START'
                                : estado == Estado.iniciado
                                ? 'STOP'
                                : '${(segundos ~/ 60).toString().padLeft(2, '0')}:${(segundos % 60).toString().padLeft(2, '0')}',
                          ),
                        ),
                        IconButton(
                          onPressed: () async {
                            final ImagePicker picker = ImagePicker();
                            await picker.pickImage(source: ImageSource.gallery);
                          },
                          icon: Icon(Icons.settings),
                        ),
                      ],
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
