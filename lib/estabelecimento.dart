import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class Estabelecimento {
  dynamic id;
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
  List<dynamic> mesa;
  List<dynamic> fila;

  bool isNew = false;

  Estabelecimento();

  Estabelecimento.builder(
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

  factory Estabelecimento.fromJson(dynamic json) {
    return Estabelecimento.builder(
      json['id'],
      json['nome'] as String,
      json['imagembg'] as String,
      json['imagempr'] as String,
      json['aberto'] as bool,
      json['mesas'] as int,
      json['mesasDisponiveis'] as int,
      json['sobre'] as String,
      json['pessoasNaFila'] as int,
      json['mesa'] as List<dynamic>,
      json['fila'] as List<dynamic>,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': this.id,
      'nome': this.nome,
      'imagembg': this.imagembg,
      'imagempr': this.imagempr,
      'aberto': this.aberto,
      'mesas': this.mesas,
      'mesasDisponiveis': this.mesasDisponiveis,
      'sobre': this.sobre,
      'pessoasNaFila': this.pessoasNaFila,
      'mesa': this.mesa,
      'fila': this.fila
    };
  }
}
