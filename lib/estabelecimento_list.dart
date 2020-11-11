import 'dart:convert';
import 'dart:developer';

import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:organiza_fila_admin/estabelecimento.dart';
import 'package:organiza_fila_admin/estabelecimento_crud.dart';
import 'package:transparent_image/transparent_image.dart';

class EstabelecimentoList extends StatefulWidget {
  EstabelecimentoList() : super();

  final String title = "Meus Estabelecimentos";

  @override
  _EstabelecimentoListState createState() => _EstabelecimentoListState();
}

class _EstabelecimentoListState extends State<EstabelecimentoList> {
  ContainerTransitionType _transitionType = ContainerTransitionType.fade;

  List<Estabelecimento> items = List.empty();
  String s = "Aguarde...";

  Future<String> _loadFromAsset() async {
    String s = await rootBundle.loadString("lib/assets/estabelecimentos.json");
    return s;
  }

  void _loadEstabelecimentos(String json) {
    var jsonAsList = jsonDecode(json) as List;

    setState(() {
      items = jsonAsList.map((e) => Estabelecimento.fromJson(e)).toList();
      s = json;
    });
  }

  @override
  void initState() {
    // carrega os dados do json
    _loadFromAsset()
        .then((json) => _loadEstabelecimentos(json))
        .catchError((error) => print(error));

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    log('list build');
    return Scaffold(
      appBar: AppBar(
        //backgroundColor: Colors.grey[850],
        centerTitle: true,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Image.asset(
              'logo.png',
              width: 64,
              fit: BoxFit.fitWidth,
            ),
            SizedBox(
              width: 10,
            ),
            Text(widget.title),
          ],
        ),
      ),
      body: Center(
          child: ListView.builder(
        itemBuilder: (context, index) {
          return _buildSlidable(context, index);
        },
        itemCount: items.length,
      )),
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

  Widget _buildSlidable(BuildContext context, int index) {
    final Estabelecimento item = items[index];

    // ################################################################################################################################################
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: Slidable(
        child: ContentListItem(items[index]),
        actionPane: SlidableDrawerActionPane(),
        actions: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: IconSlideAction(
              caption: 'Próximo da Fila',
              color: Colors.deepOrange[900],
              icon: Icons.person_outline_rounded,
              onTap: () async {
                // se estiver fechado
                if (!item.aberto &&
                    (item.pessoasNaFila == null || item.pessoasNaFila < 1)) {
                  _showSnackBar(context, 'O estabelecimento está fechado.');
                } else if (item.aberto && item.pessoasNaFila == null ||
                    item.pessoasNaFila < 1) {
                  _showSnackBar(
                      context, 'O estabelecimento não tem clientes na fila.');
                } else if (item.pessoasNaFila != null ||
                    item.pessoasNaFila > 0) {
                  String proximoId = await _buscaProximoCliente();
                  var confirmacao = await showDialog<bool>(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: Text('Próximooo!'),
                        content: Text(
                            'Vou chamar o próximo e ocupar uma mesa. Confirma?'),
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
                    var msg = 'chamou o cliente $proximoId, tá com fome/sede';
                    log(msg);
                    _showSnackBar(context, msg);
                  }
                }
              },
            ),
          ),
        ],
        secondaryActions: [
          OpenContainer(
            transitionType: _transitionType,
            transitionDuration: Duration(milliseconds: 600),
            openBuilder: (BuildContext context,
                void Function({Object returnValue}) action) {
              return EstabelecimentoCrud(items[index]);
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
          ),
          ClipRRect(
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
          ),
        ],
      ),
    );
  }

  void _showSnackBar(BuildContext context, String text) {
    Scaffold.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<String> _buscaProximoCliente() async {
    return Future.value('Sagüi dourado');
  }
}

class ContentListItem extends StatelessWidget {
  ContentListItem(this.item);

  final Estabelecimento item;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () =>
          Slidable.of(context)?.renderingMode == SlidableRenderingMode.none
              ? Slidable.of(context)?.open()
              : Slidable.of(context)?.close(),
      child: Container(
        // height: 50,
        color: Colors.grey[700],
        child: ListTile(
          leading: item.imagempr != null
              ? ClipRRect(
            clipBehavior: Clip.antiAliasWithSaveLayer,
            borderRadius: BorderRadius.circular(6),
            child: FadeInImage.memoryNetwork(
              placeholder: kTransparentImage,
              image: item.imagempr,
              width: 120,
              height: 90,
              fit: BoxFit.fitWidth,
            ),
          )
              : Image.asset(
            'splash.png',
            width: 120,
            height: 90,
            fit: BoxFit.fitHeight,
          ),
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
