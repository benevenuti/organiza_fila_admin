import 'dart:async';
import 'dart:developer';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:organiza_fila_admin/estabelecimento.dart';
import 'package:organiza_fila_admin/estabelecimento_crud.dart';

import 'cliente_fila.dart';
import 'content_list_item.dart';

class EstabelecimentoList extends StatefulWidget {
  final FirebaseApp firebase;

  EstabelecimentoList(this.firebase) : super();

  final String title = "Meus Estabelecimentos";

  @override
  _EstabelecimentoListState createState() => _EstabelecimentoListState();
}

class _EstabelecimentoListState extends State<EstabelecimentoList> {
  List<Estabelecimento> items = List.empty();
  DatabaseError _error;
  String s = "Aguarde...";

  DatabaseReference _empresasRef;
  StreamSubscription<Event> _empresasSubscription;

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

    _empresasSubscription = _empresasRef.onValue.listen((Event event) {
      log('uma perturbação na força indicou mudança nos dados...');
      var it = event.snapshot.value as Map<dynamic, dynamic>;
      var il = List<Estabelecimento>();
      it.forEach((k, v) {
        il.add(Estabelecimento.fromJson(k, v));
      });

      setState(() {
        _error = null;
        items = il;
      });
    }, onError: (Object o) {
      final DatabaseError error = o;
      log('erro ao ouvir => $error');

      setState(() {
        _error = error;
      });
    });
  }

  @override
  void dispose() {
    super.dispose();
    _empresasSubscription.cancel();
  }

  @override
  Widget build(BuildContext context) {
    log('list build');
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
              : Text(_error != null ? _error : 'Que pena, nada por aqui :,(')),
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
      ClienteFila cliente = item.fila[0];
      log('o próximo da fila é o cliente ${cliente.idpessoa}');

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
        log(msg);
        _showSnackBar(context, msg);
        Future.value('${cliente.idpessoa}');
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
            ClienteFila cliente = item.fila[0];
            log('o próximo da fila é o cliente ${cliente.idpessoa}');

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
              _liberarMesa(context, item).then((value) {
                log('aqui chama o proximo cliente');
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

  void _deleteEstabelecimento(Estabelecimento item) {
    _empresasRef.orderByChild('id').equalTo(item.id).once().then((value) {
      (value.value as Map<dynamic, dynamic>).forEach((key, value) {
        _empresasRef
            .child('$key')
            .remove()
            .then((value) => log('remove retornou ok'))
            .catchError((error) => log('remove retornou $error'));
      });
    });
  }

  void _showSnackBar(BuildContext context, String text) {
    Scaffold.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<bool> _liberarMesa(BuildContext context, Estabelecimento item) async {
    // remove a primeira mesa
    item.mesa.removeAt(0);

    // monta a lista de mesas em json
    var mesa = List<dynamic>();
    item.mesa.forEach((element) {
      mesa.add(element.toJson());
    });

    // larga um set na mesa
    _empresasRef.child(item.key).child('mesa').set(mesa).then((_) =>
        log('set em mesa: ok')).catchError((error) =>
        log('set em mesa: $error'));
  }

}
