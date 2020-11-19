class ClienteFila {
  dynamic idpessoa;
  dynamic index;

  ClienteFila();

  ClienteFila.builder(this.idpessoa, this.index);

  factory ClienteFila.fromJson(dynamic json) {
    return ClienteFila.builder(json['idpessoa'], json['index']);
  }

  Map<String, dynamic> toJson() => {
        'index': index,
        'idpessoa': idpessoa,
      };

  @override
  String toString() {
    return toJson().toString();
  }
}
