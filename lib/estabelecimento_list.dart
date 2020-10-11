import 'package:flutter/material.dart';

class EstabelecimentoListing extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
          title: new Text("Estabelecimentos - Admin"),
          automaticallyImplyLeading: false),
      body: new Center(
        child: new Text(
          "Feito!",
          style: new TextStyle(fontWeight: FontWeight.bold, fontSize: 30.0),
        ),
      ),
    );
  }
}
