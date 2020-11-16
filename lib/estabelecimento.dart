import 'package:flutter/material.dart';

class Estabelecimento {
  String id;
  String nome;
  String imagembg;
  String imagembrUrl;
  Widget imagembgWidget;

  String imagempr;
  String imagemprUrl;
  Widget imagemprWidget;

  bool aberto;
  int mesas;
  int mesasDisponiveis;
  String sobre;
  int pessoasNaFila;

  Estabelecimento();

  Estabelecimento.builder(this.id,
      this.nome,
      this.imagembg,
      this.imagempr,
      this.aberto,
      this.mesas,
      this.mesasDisponiveis,
      this.sobre,
      this.pessoasNaFila);

  factory Estabelecimento.fromJson(dynamic json) {
    return Estabelecimento.builder(
        json['id'] as String,
        json['nome'] as String,
        json['imagembg'] as String,
        json['imagempr'] as String,
        json['aberto'] as bool,
        json['mesas'] as int,
        json['mesasDisponiveis'] as int,
        json['sobre'] as String,
        json['pessoasNaFila'] as int);
  }
}
