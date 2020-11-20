import 'dart:async';
import 'dart:developer';
import 'dart:ui';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:organiza_fila_admin/estabelecimento.dart';
import 'package:organiza_fila_admin/estabelecimento_crud.dart';

import 'cliente_fila.dart';
import 'content_list_item.dart';
import 'mesa.dart';

class EstabelecimentoList extends StatefulWidget {
  final FirebaseApp firebase;

  EstabelecimentoList(this.firebase) : super();

  final String title = "Meus Estabelecimentos";

  @override
  _EstabelecimentoListState createState() => _EstabelecimentoListState();
}

class _EstabelecimentoListState extends State<EstabelecimentoList> {
  List<Estabelecimento> items = List.empty();
  Map<String, dynamic> usuarios = Map();

  DatabaseError _error;
  DatabaseError _errorU;
  String s = "Aguarde...";

  DatabaseReference _empresasRef;
  StreamSubscription<Event> _empresasSubscription;

  DatabaseReference _usuariosRef;
  StreamSubscription<Event> _usuariosSubscription;

  @override
  void initState() {
    super.initState();

    _initDatabase();
  }

  void _initDatabase() {
    final FirebaseDatabase database = FirebaseDatabase(app: widget.firebase);

    database.setPersistenceEnabled(true);
    database.setPersistenceCacheSizeBytes(10000000);

    _empresasRef = database.reference().child('empresas');
    _empresasRef.keepSynced(true);

    _usuariosRef = database.reference().child('usuarios');
    _usuariosRef.keepSynced(true);

    _empresasSubscription = _empresasRef.onValue.listen((Event event) {
      log('sinto uma perturbação na Força<empresas>...');
      var it = event.snapshot.value as Map<dynamic, dynamic>;
      var il = List<Estabelecimento>();
      it.forEach((k, v) {
        il.add(Estabelecimento.fromJson(k, v));
      });

      setState(() {
        _error = null;
        items = il;
      });

      log('que a Força esteja com você <empresas>');
    }, onError: (Object o) {
      final DatabaseError error = o;
      log('lado escuro da Força<empresas>... => $error');

      setState(() {
        _error = error;
      });
    });

    _usuariosSubscription = _usuariosRef.onValue.listen((Event event) {
      log('sinto uma perturbação na Força<usuarios>');
      var it = event.snapshot.value as Map<dynamic, dynamic>;
      var il = it != null ? it.cast<String, dynamic>() : null;

      log('usuarios: $il');

      setState(() {
        _error = null;
        usuarios = il;
      });

      log('que a Força esteja com você<usuarios>');
    }, onError: (Object o) {
      final DatabaseError error = o;
      log('lado escuro da Força<usuarios>... => $error');

      setState(() {
        _errorU = error;
      });
    });
  }

  @override
  void dispose() {
    super.dispose();
    _empresasSubscription.cancel();
    _usuariosSubscription.cancel();
  }

  @override
  Widget build(BuildContext context) {
    log('build EstabelecimentoList');
    return Scaffold(
      appBar: AppBar(
        //backgroundColor: Colors.grey[850],
        centerTitle: false,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Hero(
              tag: 'splashscreenImage',
              child: Image.asset(
                'logo.png',
                width: 64,
                fit: BoxFit.fitWidth,
              ),
            ),
            SizedBox(
              width: 10,
            ),
            Text(widget.title),
          ],
        ),
      ),
      body: Center(
          child: items != null && items.length > 0
              ? ListView.builder(
                  itemBuilder: (context, index) {
                    return _buildSlidable(context, index);
                  },
                  itemCount: items.length,
                )
              : Column(
                  children: [
                    Text(_error != null ? _error : ''),
                    Text(_errorU != null ? _errorU : ''),
                    Text('Nada por aqui.'),
                  ],
                )),
      //backgroundColor: Colors.grey[600],
      floatingActionButton: _buildFabOpenContainer(),
    );
  }

  Widget _buildFabOpenContainer() {
    return FloatingActionButton(
        heroTag: 'tag_new_estab',
        onPressed: () {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (context) {
              return EstabelecimentoCrud(Estabelecimento(), _empresasRef);
            },
          ));
        },
        child: Icon(Icons.add));
  }

  Widget _buildActionProximo(BuildContext context, Estabelecimento item) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: IconSlideAction(
          caption: 'Próximo da Fila',
          color: Colors.deepOrange[900],
          icon: Icons.emoji_people,
          onTap: () => _onTapProximoAction(context, item)),
    );
  }

  void _onTapProximoAction(BuildContext context, Estabelecimento item) async {
    // se estiver fechado
    if (!item.aberto &&
        (item.pessoasNaFila == null || item.pessoasNaFila < 1)) {
      _showSnackBar(context, 'O estabelecimento está fechado.');
    } else if (item.aberto && item.pessoasNaFila == null ||
        item.pessoasNaFila < 1) {
      _showSnackBar(context, 'O estabelecimento não tem clientes na fila.');
    } else if (item.pessoasNaFila != null || item.pessoasNaFila > 0) {
      ClienteFila cliente =
          item.fila != null && item.fila.length > 0 ? item.fila[0] : null;
      log('o próximo da fila é o cliente ${cliente != null ? cliente.idpessoa : null}');

      var confirmacao = await showDialog<bool>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Próximooo!'),
            content: Text('Vou chamar o próximo e ocupar uma mesa. Confirma?'),
            actions: <Widget>[
              FlatButton(
                child: Text('Cancelar'),
                onPressed: () => Navigator.of(context).pop(false),
              ),
              FlatButton(
                child: Text(
                  'PRÓXIMO',
                  style: TextStyle(
                    //color: Colors.deepOrange,
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.bold),
                ),
                onPressed: () => Navigator.of(context).pop(true),
              ),
            ],
          );
        },
      );

      if (confirmacao) {
        var msg = 'vou chamar o cliente ${cliente.idpessoa}';
        _chamarProximo(item).then((value) {
          _ocupaMesa(item, value);
        });
      }
    }
  }

  Widget _buildActionLiberar(BuildContext context, Estabelecimento item) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: IconSlideAction(
        caption: 'Liberar Mesa',
        color: Colors.amber[900],
        icon: Icons.event_seat,
        onTap: () async {
          // calcula o delta
          int mesasOcupadas = (item.mesas ?? 0) - (item.mesasDisponiveis ?? 0);

          // se estiver fechado
          if (!item.aberto && mesasOcupadas == 0) {
            _showSnackBar(context,
                'O estabelecimento está fechado não há mesas ocupadas.');
          } else if (mesasOcupadas == 0) {
            _showSnackBar(context, 'Não há mesas ocupadas.');
          } else if (mesasOcupadas > 0) {
            ClienteFila cliente = item.fila != null && item.fila.length > 0
                ? item.fila[0]
                : null;
            log('o próximo da fila é o cliente ${cliente != null ? cliente
                .idpessoa : null}');

            String text = '';
            if (cliente != null) {
              text +=
              'É possível liberar uma mesa e, também, chamar o próximo cliente.';
            }

            var confirmacao = await showDialog<int>(
              context: context,
              builder: (context) {
                return AlertDialog(
                  title: Text('Liberar mesa?'),
                  content: Text(text),
                  actions: <Widget>[
                    FlatButton(
                      child: Text('Não'),
                      onPressed: () => Navigator.of(context).pop(0),
                    ),
                    FlatButton(
                      child: Text(
                        'SIM',
                        style: TextStyle(
                          //color: Colors.deepOrange,
                          //letterSpacing: 1.5,
                            fontWeight: FontWeight.bold),
                      ),
                      onPressed: () => Navigator.of(context).pop(1),
                    ),
                    cliente != null
                        ? FlatButton(
                      child: Text(
                        'SIM/CHAMAR',
                        style: TextStyle(
                          //color: Colors.deepOrange,
                          //letterSpacing: 1.5,
                            fontWeight: FontWeight.bold),
                      ),
                      onPressed: () => Navigator.of(context).pop(2),
                    )
                        : SizedBox(),
                  ],
                );
              },
            );

            if (confirmacao == 1) {
              var msg = 'liberou uma mesa';
              log(msg);
              _showSnackBar(context, msg);

              // dispara acao no firebase
              await _liberarMesa(context, item);
            } else if (confirmacao == 2) {
              var msg = 'liberou e chamou o cliente ${cliente.idpessoa}';
              log(msg);
              _showSnackBar(context, msg);

              // dispara acao no firebase e no then dispara outra
              log('aqui libera a mesa');
              _liberarMesa(context, item).then((value) {
                log('aqui chama o proximo cliente');
                _chamarProximo(item).then((value) {
                  log('aqui o proximo cliente ocupa a mesa');
                  _ocupaMesa(item, value);
                });
              });
            }
          }
        },
      ),
    );
  }

  Widget _buildActionEditar(BuildContext context, Estabelecimento item) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: Hero(
        tag: 'tag_${item.id}',
        child: IconSlideAction(
          caption: 'Editar',
          //color: Colors.indigo[700],
          icon: Icons.edit,
          closeOnTap: false,
          onTap: () {
            Navigator.of(context).push(MaterialPageRoute(
              builder: (context) {
                return EstabelecimentoCrud(item, _empresasRef);
              },
            ));
          },
          //foregroundColor: Colors.grey[850],
        ),
      ),
    );
  }

  Widget _buildSlidable(BuildContext context, int index) {
    final Estabelecimento item = items[index];
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: Slidable(
        child: ContentListItem(item),
        actionPane: SlidableDrawerActionPane(),
        actions: [
          _buildActionProximo(context, item),
          _buildActionLiberar(context, item),
        ],
        secondaryActions: [
          _buildActionEditar(context, item),
          _buildActionDeletar(context, item),
        ],
      ),
    );
  }

  Widget _buildActionDeletar(BuildContext context, Estabelecimento item) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: IconSlideAction(
        caption: 'Deletar',
        color: Colors.red[900],
        icon: Icons.delete,
        onTap: () async {
          var confirmacao = await showDialog<bool>(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: Text('Deletar?'),
                content: Text('Estabelecimento será deletado. Confirma?'),
                actions: <Widget>[
                  FlatButton(
                    child: Text('Cancelar'),
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                  FlatButton(
                    child: Text(
                      'DELETAR',
                      style: TextStyle(
                        //color: Colors.red[300],
                          letterSpacing: 1.5),
                    ),
                    onPressed: () => Navigator.of(context).pop(true),
                  ),
                ],
              );
            },
          );

          if (confirmacao) {
            _deleteEstabelecimento(item);
          }
        },
      ),
    );
  }

  void _deleteEstabelecimento(Estabelecimento item) async {
    await _empresasRef
        .child(item.key)
        .remove()
        .then((value) => log('remove estab retornou ok'))
        .catchError((error) => log('remove estab retornou $error'));
  }

  void _showSnackBar(BuildContext context, String text) {
    Scaffold.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<bool> _liberarMesa(BuildContext context, Estabelecimento item) async {
    log('lista mesa ${item.mesa}');

    // remove a primeira mesa
    Mesa mesaLiberada = item.mesa.removeAt(0);

    await _desvinculaUser(mesaLiberada);
    return await _atualizaMesa(item);
  }

  Future<bool> _desvinculaUser(Mesa mesaLiberada) async {
    log('desvinculado cliente ${mesaLiberada.idpessoa}');
    _usuariosRef.child(mesaLiberada.idpessoa).remove()
        .then((value) =>
        log('removeu o vinculo do cliente ${mesaLiberada.idpessoa}'))
        .catchError((error) {
      log('erro ao desvincular usuario ${mesaLiberada.idpessoa}: $error');
    });
  }

  Future<ClienteFila> _chamarProximo(Estabelecimento item) async {
    log('lista fila ${item.fila}');

    // remove o primeiro cliente
    var cliente = item.fila.removeAt(0);

    // monta a lista da fila em json
    var fila = List<dynamic>();
    item.fila.forEach((element) {
      fila.add(element.toJson());
    });

    // larga um set na fila
    try {
      await _empresasRef.child(item.key).child('fila').set(fila);
      // retorna o cliente que saiu
      return Future.value(cliente);
    } on Exception catch (e) {
      log('erro ao chamar set em fila: $e');
      return Future.value(null);
    }
  }

  Future<bool> _ocupaMesa(Estabelecimento item, ClienteFila cliente) async {
    log('lista mesa ${item.mesa}');

    Mesa mesaOcupada = Mesa.builder(cliente.index, cliente.idpessoa);

    // poe o cliente no fim
    item.mesa.add(mesaOcupada);

    // monta a lista de mesas em json
    return await _atualizaMesa(item);
  }

  _atualizaMesa(Estabelecimento item) async {
    var mesa = List<dynamic>();
    item.mesa.forEach((element) {
      mesa.add(element.toJson());
    });

    // larga um set na mesa
    try {
      await _empresasRef.child(item.key).child('mesa').set(mesa);
      return Future.value(true);
    } on Exception catch (e) {
      log('erro ao chamar set em mesa: $e');
      return Future.value(false);
    }
  }
}
