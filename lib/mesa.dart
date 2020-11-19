class Mesa {
  dynamic id;
  dynamic idpessoa;

  Mesa();

  Mesa.builder(this.id, this.idpessoa);

  factory Mesa.fromJson(dynamic json) {
    return Mesa.builder(json['id'], json['idpessoa']);
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'idpessoa': idpessoa,
      };

  @override
  String toString() {
    return toJson().toString();
  }
}
