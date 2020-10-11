import 'package:flutter/material.dart';
import 'package:splashscreen/splashscreen.dart';

import 'estabelecimento_list.dart';

class MySplash extends StatefulWidget {
  @override
  _MySplashState createState() => new _MySplashState();
}

class _MySplashState extends State<MySplash> {
  @override
  Widget build(BuildContext context) {
    return new SplashScreen(
      seconds: 5,
      navigateAfterSeconds: new EstabelecimentoListing(),
      title: new Text(
        'Organiza Fila!',
        style: new TextStyle(fontWeight: FontWeight.bold, fontSize: 20.0),
      ),
      image: new Image.network(
          'https://miro.medium.com/max/100/1*fTVH1wCAgB457DtD4IbSAw.png'),
      gradientBackground: LinearGradient(
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
        colors: [Color(0xffED213A), Color(0xff93291E)],
      ),
      styleTextUnderTheLoader: new TextStyle(),
      photoSize: 100.0,
      onClick: () => print("Clicou no splash!"),
      loaderColor: Colors.deepOrange,
      loadingText: new Text("SOLETRE em voz alta: Arnold Schwarzenegger"),
    );
  }
}
