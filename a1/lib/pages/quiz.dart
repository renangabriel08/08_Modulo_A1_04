import 'dart:convert';
import 'package:a1/controllers/app.dart';
import 'package:a1/styles/cores.dart';
import 'package:a1/widgets/toast.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_headset_detector/flutter_headset_detector.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:volume_controller/volume_controller.dart';

class Quiz extends StatefulWidget {
  const Quiz({super.key});

  @override
  State<Quiz> createState() => _QuizState();
}

class _QuizState extends State<Quiz> with SingleTickerProviderStateMixin {
  final headsetDetector = HeadsetDetector();
  AnimationController? controller;
  Animation? angle;

  int score = 0;

  int index = 0;
  List qustoes = [];

  List resRel = [[], [], []];
  String selecionada = '';

  bool click = false;
  bool animando = false;

  encerrar() {
    MyToast.get('Fim de jogo! Score: $score');
    Navigator.pop(context);
  }

  proximo() async {
    angle = null;

    if (qustoes[index]['tipo'] == 'ME') {
      if (!click) {
        if (qustoes[index]['alternativas'][qustoes[index]['resposta']] ==
            selecionada) {
          score += int.parse(qustoes[index]['peso'].toString());
        }

        click = true;
        setState(() {});
      } else {
        click = false;
        selecionada = '';
        index++;
        setState(() {});
      }
    } else if (qustoes[index]['tipo'] == 'VF') {
      if (qustoes[index]['alternativas'][qustoes[index]['resposta']] ==
          selecionada) {
        score += int.parse(qustoes[index]['peso'].toString());
      }

      selecionada = '';
      index++;
      setState(() {});
    } else {
      if (resRel.toString() == qustoes[index]['resposta'].toString()) {
        score += int.parse(qustoes[index]['peso'].toString());
      }

      if (qustoes[index]['id'] == 502) {
        encerrar();
      } else {
        resRel = [[], [], []];
        index++;
        setState(() {});
      }
    }

    if (qustoes[index]['tipo'] == 'VF') {
      animando = true;
      setState(() {});

      angle = Tween<double>(
        begin: 0,
        end: 1.5,
      ).animate(CurvedAnimation(parent: controller!, curve: Curves.linear));

      controller!.addListener(() => setState(() {}));
      await controller!.forward();

      Future.delayed(
        const Duration(seconds: 1),
        () => setState(() {
          animando = false;
        }),
      );
    }

    setState(() {});
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

    accelerometerEvents.listen(
      (AccelerometerEvent event) {
        if (qustoes.isNotEmpty && qustoes[index]['tipo'] == 'VF') {
          if (event.x < -3) {
            selecionada = 'Verdadeiro';
          } else if (event.x > 3) {
            selecionada = 'Falso';
          }

          setState(() {});
        }
      },
      onError: (error) {},
      cancelOnError: true,
    );

    controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );

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

    String json = await rootBundle.loadString('assets/bancoQuestoes.json');
    Map dados = jsonDecode(json);

    qustoes = dados['perguntas'];
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
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;

    if (qustoes.isNotEmpty) {
      if (qustoes[index]['tipo'] == 'REL') {
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
      } else {
        SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Quiz My Brain'),
        automaticallyImplyLeading: true,
        actions: [Text('Score $score'), Container(width: 16)],
      ),
      body: qustoes.isEmpty
          ? Center(child: CircularProgressIndicator())
          : SizedBox(
              width: width,
              height: height,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text(
                      qustoes[index]['enunciado'],
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Cores.azulClaro,
                      ),
                    ),
                    Container(height: 16),
                    if (qustoes[index]['tipo'] == 'ME')
                      Column(
                        children: [
                          for (var alternativa
                              in qustoes[index]['alternativas'])
                            GestureDetector(
                              onTap: () {
                                selecionada = alternativa;
                                setState(() {});
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Container(
                                  width: width,
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      width: 2,
                                      color:
                                          click &&
                                              alternativa ==
                                                  qustoes[index]['alternativas'][qustoes[index]['resposta']]
                                          ? Colors.red
                                          : alternativa == selecionada
                                          ? Cores.azulClaro
                                          : Cores.preto,
                                    ),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(
                                      alternativa,
                                      style: TextStyle(
                                        color:
                                            click &&
                                                alternativa ==
                                                    qustoes[index]['alternativas'][qustoes[index]['resposta']]
                                            ? Colors.red
                                            : alternativa == selecionada
                                            ? Cores.azulClaro
                                            : Cores.preto,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),

                    if (qustoes[index]['tipo'] == 'VF')
                      Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              for (var alternativa
                                  in qustoes[index]['alternativas'])
                                GestureDetector(
                                  onTap: () {
                                    selecionada = alternativa;
                                    setState(() {});
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Container(
                                      width: width * .4,
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          width: 2,
                                          color:
                                              click &&
                                                  alternativa ==
                                                      qustoes[index]['alternativas'][qustoes[index]['resposta']]
                                              ? Colors.red
                                              : alternativa == selecionada
                                              ? Cores.azulClaro
                                              : Cores.preto,
                                        ),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Text(
                                          alternativa,
                                          style: TextStyle(
                                            color:
                                                click &&
                                                    alternativa ==
                                                        qustoes[index]['alternativas'][qustoes[index]['resposta']]
                                                ? Colors.red
                                                : alternativa == selecionada
                                                ? Cores.azulClaro
                                                : Cores.preto,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          Container(height: 16),
                          if (animando)
                            Transform.rotate(
                              angle: angle?.value ?? 0,
                              child: Icon(
                                Icons.screen_rotation_outlined,
                                size: 50,
                              ),
                            ),
                        ],
                      ),

                    if (qustoes[index]['tipo'] == 'REL')
                      Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              for (
                                int i = 0;
                                i < qustoes[index]['alternativas'][0].length;
                                i++
                              )
                                Draggable(
                                  data: {
                                    'index': i,
                                    'value':
                                        qustoes[index]['alternativas'][0][i],
                                  },
                                  feedback: Container(
                                    width: width * .3,
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        width: 2,
                                        color: Cores.preto,
                                      ),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text(
                                        qustoes[index]['alternativas'][0][i],
                                      ),
                                    ),
                                  ),
                                  child: Container(
                                    width: width * .3,
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        width: 2,
                                        color: Cores.preto,
                                      ),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text(
                                        qustoes[index]['alternativas'][0][i],
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          Container(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              for (
                                int i = 0;
                                i < qustoes[index]['alternativas'][1].length;
                                i++
                              )
                                DragTarget(
                                  builder:
                                      (
                                        context,
                                        candidateData,
                                        rejectedData,
                                      ) => Container(
                                        width: width * .3,
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            width: 2,
                                            color: Cores.preto,
                                          ),
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Text(
                                            qustoes[index]['alternativas'][1][i],
                                          ),
                                        ),
                                      ),
                                  onAccept: (Map data) {
                                    if (!qustoes[index]['alternativas'][1][i]
                                        .contains(':')) {
                                      resRel[data['index']].add(data['index']);
                                      resRel[data['index']].add(i);

                                      qustoes[index]['alternativas'][1][i] +=
                                          ': ${data['value']}';
                                    }

                                    setState(() {});
                                  },
                                ),
                            ],
                          ),
                        ],
                      ),

                    Container(height: 16),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ElevatedButton(
                          onPressed: () => encerrar(),
                          child: Text('Encerrar'),
                        ),

                        ElevatedButton(
                          onPressed: () => proximo(),
                          child: Text('Próximo'),
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
