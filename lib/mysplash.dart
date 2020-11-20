import 'dart:developer';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:organiza_fila_admin/estabelecimento_list.dart';
import 'package:splashscreen/splashscreen.dart';

class MySplash extends StatefulWidget {
  @override
  _MySplashState createState() => new _MySplashState();
}

class _MySplashState extends State<MySplash> {
  String _msg = '';
  FirebaseApp _firebase;

  // receitinha de bolo do flutterfire
  Future<FirebaseApp> initializeFlutterFire() async {
    var msg = 'inicializando';
    log(msg);

    try {
      // sem parametros busca do google-services.json no andoird
      var firebase = await Firebase.initializeApp();

      msg = 'inicializado';
      log(msg);

      return Future.value(firebase);
    } catch (e) {
      //se deu erro
      msg = 'erro ao inicializar: $e';
      log(msg);

      return Future.error(e);
    }
  }

  FirebaseOptions optFromJson(optDec) {
    FirebaseOptions optObj = FirebaseOptions(
        appId: optDec['appId'] as String,
        apiKey: optDec['apiKey'] as String,
        messagingSenderId: optDec['messagingSenderId'] as String,
        projectId: optDec['projectId'] as String,
        databaseURL: optDec['databseURL'] as String);
    return optObj;
  }

  @override
  void initState() {
    super.initState();
  }

  Future<Widget> loadFromFuture() async {
    var fb = _firebase;
    if (_firebase == null) {
      fb = await initializeFlutterFire();
    }

    return Future.delayed(
        Duration(seconds: 2), () => Future.value(EstabelecimentoList(fb)));
    //return Future.value(EstabelecimentoList(fb));
  }

  @override
  Widget build(BuildContext context) {
    return SplashScreen(
      //seconds: 3,
      navigateAfterFuture: loadFromFuture(),
      // title: new Text(
      //   'Aplicativo Administrativo',
      //   style: new TextStyle(fontWeight: FontWeight.bold, fontSize: 20.0),
      // ),
      image: Image.asset(
        'logo.png',
      ),
      backgroundColor: Colors.black,
      imageBackground: AssetImage('splash_sem_logo.png'),
      // styleTextUnderTheLoader: new TextStyle(),
      photoSize: 100.0,
      onClick: () => log('clica clica clica no loading que vai mais rapido'),
      loaderColor: Colors.white,
      loadingText: Text(_msg),
    );
  }
}
