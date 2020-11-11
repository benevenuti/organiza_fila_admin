import 'package:flutter/material.dart';
import 'package:organiza_fila_admin/estabelecimento_list.dart';
import 'package:splashscreen/splashscreen.dart';

class MySplash extends StatefulWidget {
  @override
  _MySplashState createState() => new _MySplashState();
}

class _MySplashState extends State<MySplash> {
  @override
  Widget build(BuildContext context) {
    return new SplashScreen(
      seconds: 2,
      navigateAfterSeconds: new EstabelecimentoList(),
      //backgroundColor: Colors.black,
      imageBackground: AssetImage('splash.png'),
      loaderColor: Colors.white,
    );
  }
}
