class ClienteFila {
  dynamic index;
  dynamic idpessoa;

  ClienteFila();

  ClienteFila.builder(this.index, this.idpessoa);

  factory ClienteFila.fromJson(dynamic json) {
    return ClienteFila.builder(json['index'] ?? 1, json['idpessoa']);
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
