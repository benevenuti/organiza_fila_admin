import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:organiza_fila_admin/cliente_fila.dart';

import 'mesa.dart';

class Estabelecimento {
  dynamic id;
  dynamic key;
  String nome;
  String imagembg;
  String imagembgUrl;
  Widget imagembgWidget;
  String imagembgLocal;

  String imagempr;
  String imagemprUrl;
  Widget imagemprWidget;
  String imagemprLocal;

  bool aberto;
  int mesas;
  int mesasDisponiveis;
  String sobre;
  int pessoasNaFila;
  List<Mesa> mesa;
  List<ClienteFila> fila;

  bool isNew = false;

  Estabelecimento();

  Estabelecimento.builder(
      this.key,
      this.id,
      this.nome,
      this.imagembg,
      this.imagempr,
      this.aberto,
      this.mesas,
      this.mesasDisponiveis,
      this.sobre,
      this.pessoasNaFila,
      this.mesa,
      this.fila);

  factory Estabelecimento.fromJson(dynamic key, dynamic json) {
    // log('converter k: $key');
    // log('converter v: $json');

    var mesa = List.from(json['mesa'] ?? [], growable: true);
    mesa.removeWhere((element) => element == null);
    mesa = mesa.map((e) => Mesa.fromJson(e)).toList();

    var fila = List.from(json['fila'] ?? [], growable: true);
    fila.removeWhere((element) => element == null);
    fila = fila.map((e) => ClienteFila.fromJson(e)).toList();

    var mesas = (json['mesas'] as int) ?? 0;
    var mesasDisponiveis = mesas - mesa.length;

    return Estabelecimento.builder(
      '$key',
      json['id'],
      json['nome'] as String,
      json['imagembg'] as String,
      json['imagempr'] as String,
      json['aberto'] as bool,
      mesas,
      mesasDisponiveis,
      json['sobre'] as String,
      fila.length,
      mesa,
      fila,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': this.id,
      'nome': this.nome,
      'imagembg': this.imagembg,
      'imagempr': this.imagempr,
      'aberto': this.aberto,
      'mesas': this.mesas,
      //'mesasDisponiveis': this.mesasDisponiveis,
      'sobre': this.sobre,
      //'pessoasNaFila': this.pessoasNaFila,
      //'mesa': this.mesa,
      //'fila': this.fila
    };
  }

  Map<String, dynamic> toMapUpdate() {
    return {'${this.key}': toJson()};
  }

  Map<String, dynamic> toMapPush() {
    return toJson();
  }

  @override
  String toString() {
    return toJson().toString();
  }
}
