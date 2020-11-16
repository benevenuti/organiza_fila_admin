import 'dart:async';
import 'dart:developer';

import 'package:animations/animations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:organiza_fila_admin/estabelecimento.dart';
import 'package:organiza_fila_admin/estabelecimento_crud.dart';
import 'package:transparent_image/transparent_image.dart';

class EstabelecimentoList extends StatefulWidget {
  final FirebaseApp firebase;

  EstabelecimentoList(this.firebase) : super();

  final String title = "Meus Estabelecimentos";

  @override
  _EstabelecimentoListState createState() => _EstabelecimentoListState();
}

class _EstabelecimentoListState extends State<EstabelecimentoList> {
  ContainerTransitionType _transitionType = ContainerTransitionType.fade;

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
      log('ouvido => ${event.snapshot.value}');
      var it = event.snapshot.value as List;
      var il = it.map((e) => Estabelecimento.fromJson(e)).toList();

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

  OpenContainer<Object> _buildFabOpenContainer() {
    return OpenContainer(
      transitionType: _transitionType,
      transitionDuration: Duration(milliseconds: 600),
      openBuilder:
          (BuildContext context, void Function({Object returnValue}) action) {
        return EstabelecimentoCrud(new Estabelecimento());
      },
      closedBuilder: (BuildContext context, void Function() action) {
        return
            // Icon(Icons.add, size: 90,);
            FloatingActionButton(
                //backgroundColor: Colors.grey[850],
                onPressed: null,
                child: Icon(Icons.add));
      },
      closedElevation: 50,
      closedShape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(
          Radius.circular(50),
        ),
      ),
    );
  }

  Widget _buildActionProximo(BuildContext context, Estabelecimento item) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: IconSlideAction(
        caption: 'Próximo da Fila',
        color: Colors.deepOrange[900],
        icon: Icons.emoji_people,
        onTap: () async {
          // se estiver fechado
          if (!item.aberto &&
              (item.pessoasNaFila == null || item.pessoasNaFila < 1)) {
            _showSnackBar(context, 'O estabelecimento está fechado.');
          } else if (item.aberto && item.pessoasNaFila == null ||
              item.pessoasNaFila < 1) {
            _showSnackBar(
                context, 'O estabelecimento não tem clientes na fila.');
          } else if (item.pessoasNaFila != null || item.pessoasNaFila > 0) {
            String proximoId = await _buscaProximoCliente(context, item);
            var confirmacao = await showDialog<bool>(
              context: context,
              builder: (context) {
                return AlertDialog(
                  title: Text('Próximooo!'),
                  content:
                      Text('Vou chamar o próximo e ocupar uma mesa. Confirma?'),
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
              var msg = 'chamou o cliente $proximoId';
              log(msg);
              _showSnackBar(context, msg);
            }
          }
        },
      ),
    );
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
          int mesasOcupadas = item.mesas - item.mesasDisponiveis;

          // se estiver fechado
          if (!item.aberto && mesasOcupadas == 0) {
            _showSnackBar(context,
                'O estabelecimento está fechado não há mesas ocupadas.');
          } else if (mesasOcupadas == 0) {
            _showSnackBar(context, 'Não há mesas ocupadas.');
          } else if (mesasOcupadas > 0) {
            String proximoId = await _buscaProximoCliente(context, item);
            String text = '';
            if (proximoId != null) {
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
                    proximoId != null
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
            } else if (confirmacao == 2) {
              var msg = 'liberou e chamou o cliente $proximoId';
              log(msg);
              _showSnackBar(context, msg);
            }
          }
        },
      ),
    );
  }

  Widget _buildActionEditar_old(BuildContext context, Estabelecimento item) {
    return OpenContainer(
      transitionType: _transitionType,
      transitionDuration: Duration(milliseconds: 600),
      openBuilder:
          (BuildContext context, void Function({Object returnValue}) action) {
        return EstabelecimentoCrud(item);
      },
      closedBuilder: (BuildContext context, void Function() action) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: IconSlideAction(
            caption: 'Editar',
            //color: Colors.indigo[700],
            icon: Icons.edit,
            closeOnTap: false,
            //foregroundColor: Colors.grey[850],
          ),
        );
      },
      closedElevation: 50,
      closedColor: Colors.grey[850],
      closedShape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(
          Radius.circular(0),
        ),
      ),
    );
  }

  Widget _buildActionEditar(BuildContext context, Estabelecimento item) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: IconSlideAction(
        caption: 'Editar',
        //color: Colors.indigo[700],
        icon: Icons.edit,
        closeOnTap: false,
        onTap: () {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => EstabelecimentoCrud(item),
          ));
        },
        //foregroundColor: Colors.grey[850],
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
            var msg = 'deletou ${item.nome}, haha SQN';
            log(msg);
            _showSnackBar(context, msg);
          }
        },
      ),
    );
  }

  void _showSnackBar(BuildContext context, String text) {
    Scaffold.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<String> _buscaProximoCliente(BuildContext context,
      Estabelecimento item) async {
    return Future.value('Sagüi dourado');
  }
}

class ContentListItem extends StatelessWidget {
  ContentListItem(this.item);

  final Estabelecimento item;

  Widget _buildDefault(Widget image) {
    //log('_buildDefault');
    return image == null
        ? SizedBox(
      width: 120,
      height: 90,
    )
        : image;
  }

  Future<Widget> _buildImagePr(Estabelecimento item) async {
    if (item.imagempr != null) {
      if (item.imagemprUrl == null) {
        var dUrl =
        await FirebaseStorage.instance.ref(item.imagempr).getDownloadURL();
        //log('consegui a url $dUrl');
        item.imagemprUrl = dUrl;
        if (item.imagemprWidget == null) {
          item.imagemprWidget = FadeInImage.memoryNetwork(
            placeholder: kTransparentImage,
            image: item.imagemprUrl,
            width: 120,
            height: 90,
            fit: BoxFit.cover,
          );
        }
      }
      return item.imagemprWidget;
    } else {
      return _buildDefault(item.imagemprWidget);
    }
  }

  Widget _buildImageFromStorage() {
    return FutureBuilder(
      future: _buildImagePr(item),
      initialData: _buildDefault(item.imagemprWidget),
      builder: (BuildContext context, AsyncSnapshot<Widget> snapshot) {
        return snapshot.data;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () =>
      Slidable
          .of(context)
          ?.renderingMode == SlidableRenderingMode.none
          ? Slidable.of(context)?.open()
          : Slidable.of(context)?.close(),
      child: Container(
        // height: 50,
        color: Colors.grey[700],
        child: ListTile(
          leading: ClipRRect(
              clipBehavior: Clip.antiAliasWithSaveLayer,
              borderRadius: BorderRadius.circular(6),
              child: _buildImageFromStorage()),
          title: Text(item.nome),
          subtitle: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  item.aberto
                      ? Icon(
                    Icons.timer,
                    //color: Colors.grey,
                        )
                      : Icon(
                          Icons.timer_off,
                          //color: Colors.grey,
                        ),
                  SizedBox(
                    width: 4,
                  ),
                  item.aberto
                      ? Text(
                          'Aberto',
                          style: TextStyle(
                              color: Colors.green[200],
                              fontWeight: FontWeight.bold),
                        )
                      : Text('Fechado',
                          style: TextStyle(
                              color: Colors.red[200],
                              fontWeight: FontWeight.bold)),
                ],
              ),
              item.pessoasNaFila != null && item.pessoasNaFila > 0
                  ? Text('${item.pessoasNaFila} pessoas na fila')
                  : Text('')
            ],
          ),
          // trailing: Text('T'),
        ),
      ),
    );
  }
}
