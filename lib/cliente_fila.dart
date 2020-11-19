class ClienteFila {
  dynamic idpessoa;
  dynamic index;

  ClienteFila();

  ClienteFila.builder(this.idpessoa, this.index);

  factory ClienteFila.fromJson(dynamic json) {
    return ClienteFila.builder(json['idpessoa'], json['index']);
  }
}
