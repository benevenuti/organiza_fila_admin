import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_switch/flutter_switch.dart';
import 'package:image_picker/image_picker.dart';
import 'package:organiza_fila_admin/estabelecimento.dart';

class EstabelecimentoCrud extends StatefulWidget {
  final Estabelecimento estabelecimento;

  EstabelecimentoCrud(this.estabelecimento);

  @override
  _EstabelecimentoCrudState createState() => _EstabelecimentoCrudState();
}

class _EstabelecimentoCrudState extends State<EstabelecimentoCrud> {
  // campos do estabelecimento
  String _nome;
  String _imagembg;
  String _imagempr;
  bool _aberto = true;
  int _mesas = 0;
  String _sobre;

  // aux
  Image _imgBg;
  Image _imgPr;

  // controles
  final _formKey = GlobalKey<FormState>();
  final picker = ImagePicker();

  @override
  void initState() {
    log('crud init ini');
    super.initState();

    _nome = widget.estabelecimento.nome;
    _sobre = widget.estabelecimento.sobre;
    _mesas =
        widget.estabelecimento.mesas != null ? widget.estabelecimento.mesas : 0;
    _aberto = widget.estabelecimento.aberto == true;

    if (widget.estabelecimento.imagembg != null) {
      _imgBg = Image.network(
        widget.estabelecimento.imagembg,
        fit: BoxFit.cover,
        width: 400,
        height: 180,
      );
    }

    if (widget.estabelecimento.imagempr != null) {
      _imgPr = Image.network(
        widget.estabelecimento.imagempr,
        fit: BoxFit.cover,
        width: 100,
        height: 100,
      );
    }

    log('crud init end');
  }

  @override
  bool get mounted {
    var m = super.mounted;
    log('get mounted = $m');
    return m;
  }

  @override
  Widget build(BuildContext context) {
    log('crud build');
    return WillPopScope(
      onWillPop: _onBackPressed,
      child: Scaffold(
        appBar: AppBar(
          //backgroundColor: Colors.grey[850],
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
              Text('Editar Estabelecimento'),
            ],
          ),
        ),
        body: SingleChildScrollView(
          child: Container(
            margin: EdgeInsets.all(30),
            child: Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: _buildForm(),
            ),
          ),
        ),
        //backgroundColor: Colors.grey[600],
      ),
    );
  }

  Future<bool> _confirmImageClear(BuildContext context) {
    var confirmation = AlertDialog(
      title: Text('Confirmação'),
      content: Text('Limpar imagem?'),
      actions: [
        FlatButton.icon(
            onPressed: () {
              Navigator.of(context).pop(true);
            },
            icon: Icon(Icons.image_not_supported),
            label: Text('Remover')),
        FlatButton.icon(
            onPressed: () {
              Navigator.of(context).pop(false);
            },
            icon: Icon(Icons.cancel),
            label: Text('Cancelar'))
      ],
    );

    return showDialog<bool>(
      context: context,
      builder: (context) {
        return confirmation;
      },
    );
  }

  Widget _buildForm() {
    return Column(
      children: [
        // icone
        _buildImagesStack(),
        // nome
        _buildFieldNome(),
        // sobre
        _buildFieldSobre(),
        // quantidad de mesas
        _buildFieldMesas(),
        // spacer
        SizedBox(
          height: 10,
        ),
        // aberto
        _buildFieldAberto(),
        // spacer
        SizedBox(
          height: 20,
        ),
        // footer / buttons
        _buildFooterButtons(),
      ],
    );
  }

  Widget _buildFooterButtons() {
    return Column(
      //mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Container(
          padding: EdgeInsets.symmetric(vertical: 10.0),
          width: double.infinity,
          child: RaisedButton(
            elevation: 5.0,
            onPressed: () {
              _cancelForm();
            },
            padding: EdgeInsets.all(15.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            color: Colors.grey,
            child: Text(
              'CANCELAR',
              style: TextStyle(
                //color: Colors.grey,
                letterSpacing: 1.5,
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
                // fontFamily: 'OpenSans',
              ),
            ),
          ),
        ),
        Container(
          padding: EdgeInsets.symmetric(vertical: 10.0),
          width: double.infinity,
          child: RaisedButton(
            elevation: 5.0,
            onPressed: () {
              _saveForm();
            },
            padding: EdgeInsets.all(15.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            color: Colors.white,
            child: Text(
              'SALVAR',
              style: TextStyle(
                color: Colors.cyan,
                letterSpacing: 1.5,
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
                // fontFamily: 'OpenSans',
              ),
            ),
          ),
        ),
      ],
    );
  }

  Row _buildFieldAberto() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Icon(
          _aberto ? Icons.timer : Icons.timer_off,
          //color: Colors.grey[800],
        ),
        Text('O estabelecimento está '),
        FlutterSwitch(
          activeColor: Colors.cyan,
          onToggle: (bool value) {
            setState(() {
              _aberto = value;
            });
          },
          value: _aberto,
          activeText: 'Aberto',
          inactiveText: 'Fechado',
          showOnOff: true,
          width: 110,
        ),
      ],
    );
  }

  Future<File> _getImg(context, src) async {
    var f = await picker.getImage(
      source: src,
    );
    if (f != null) {
      return Future.value(File(f.path));
    } else {
      return Future.value(null);
    }
  }

  Future<File> _showImgPickerDlg(context) async {
    var f = await showModalBottomSheet(
        context: context,
        builder: (BuildContext bc) {
          return SafeArea(
            child: Container(
              child: new Wrap(
                children: <Widget>[
                  new ListTile(
                      leading: new Icon(Icons.photo_library),
                      title: new Text('Galeria'),
                      onTap: () async {
                        var f = await _getImg(context, ImageSource.gallery);
                        log('retornando $f');
                        Navigator.of(context).pop(f);
                      }),
                  new ListTile(
                    leading: new Icon(Icons.photo_camera),
                    title: new Text('Câmera'),
                    onTap: () async {
                      var f = await _getImg(context, ImageSource.camera);
                      log('retornando $f');
                      Navigator.of(context).pop(f);
                    },
                  ),
                ],
              ),
            ),
          );
        });

    return Future.value(f);
  }

  Widget _buildImagesStack() {
    return Stack(children: [
      // imagem de fundo
      Center(
        child:
            _imgBg != null ? _renderImagemBg() : _renderImagemBgPlaceholder(),
      ),
      // ícones para a imagem de fundo
      Opacity(
        opacity: 0.5,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  tooltip: 'Alterar imagem de fundo',
                  icon: Icon(Icons.camera_alt),
                  iconSize: 20,
                  splashRadius: 20,
                  onPressed: () {
                    _showImgPickerDlg(context).then((value) {
                      log('recebi $value');
                      if (value != null) {
                        var img = Image.file(value,
                            width: 480, height: 180, fit: BoxFit.cover);
                        setState(() {
                          _imgBg = img;
                        });
                      }
                    });
                  },
                ),
              ],
            ),
            SizedBox(
              height: 82,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  tooltip: 'Remover imagem de fundo',
                  icon: Icon(Icons.image_not_supported),
                  iconSize: 20,
                  splashRadius: 20,
                  onPressed: () {
                    if (_imgBg != null) {
                      _confirmImageClear(context).then((value) {
                        if (value) {
                          setState(() {
                            _imgBg = null;
                          });
                        }
                      });
                    } else {
                      log('sem imagem de fundo para limpar');
                      SystemSound.play(SystemSoundType.click);
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
      // imagem do avatar
      Center(
        child: Column(
          children: [
            SizedBox(
              height: 32,
            ),
            CircleAvatar(
              radius: 55,
              backgroundColor: Colors.black38,
              child: _imgPr != null
                  ? _renderImagemPr()
                  : _renderImagemPrPlaceholder(),
            ),
          ],
        ),
      ),
      // ícones para a imagem do avatar
      Opacity(
        opacity: 0.5,
        child: Center(
            child: Column(children: [
          SizedBox(
            height: 22,
          ),
          IconButton(
            tooltip: 'Alterar imagem de avatar',
            icon: Icon(Icons.camera_alt),
            iconSize: 20,
            //splashRadius: 30,
            onPressed: () {
              _showImgPickerDlg(context).then((value) {
                log('recebi $value');
                if (value != null) {
                  var img = Image.file(value, width: 100,
                      height: 100,
                      fit: BoxFit.cover);
                  setState(() {
                    _imgPr = img;
                  });
                }
              });
            },
          ),
          SizedBox(
            height: 32,
          ),
          IconButton(
            tooltip: 'Remover imagem de avatar',
            icon: Icon(Icons.image_not_supported),
            iconSize: 20,
            //splashRadius: 30,
            onPressed: () {
              if (_imgPr != null) {
                _confirmImageClear(context).then((value) {
                  if (value) {
                    setState(() {
                      _imgPr = null;
                    });
                  }
                });
              } else {
                log('sem imagem de avatar para limpar');
                SystemSound.play(SystemSoundType.click);
              }
            },
          ),
        ])),
      ),
    ]);
  }

  Widget _renderImagemPrPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        //color: Colors.grey[200],
          borderRadius: BorderRadius.circular(52.5)),
      width: 100,
      height: 100,
    );
  }

  ClipRRect _renderImagemPr() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(52.5),
      child: _imgPr,
    );
  }

  Widget _renderImagemBgPlaceholder() {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: Colors.grey,
          ),
          width: 400,
          height: 180,
        ),
      ],
    );
  }

  ClipRRect _renderImagemBg() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: _imgBg,
    );
  }

  Widget _buildFieldMesas() {
    return TextFormField(
      keyboardType: TextInputType.number,
      maxLength: 3,
      decoration: InputDecoration(
          hintText: 'Mesas no estabelecimento', icon: Icon(Icons.event_seat)),
      initialValue: _mesas > 0 ? '$_mesas' : null,
      onChanged: (value) {
        setState(() {
          _mesas = value as int;
        });
      },
    );
  }

  Widget _buildFieldSobre() {
    return TextFormField(
      style: TextStyle(
          //backgroundColor: Colors.grey[850]
          ),
      keyboardType: TextInputType.multiline,
      maxLength: 300,
      minLines: 1,
      maxLines: 4,
      decoration: InputDecoration(hintText: 'Sobre', icon: Icon(Icons.message)),
      initialValue: _sobre,
      onChanged: (value) {
        setState(() {
          _sobre = value;
        });
      },
    );
  }

  Widget _buildFieldNome() {
    return TextFormField(
      maxLength: 50,
      decoration: InputDecoration(
          hintText: 'Nome do estabelecimento', icon: Icon(Icons.add_business)),
      validator: _validarNome,
      initialValue: _nome,
      onChanged: (value) {
        setState(() {
          _nome = value;
        });
      },
    );
  }

  String _validarNome(String value) {
    // String patttern = r'(^[a-zA-Z ]*$)';
    // RegExp regExp = new RegExp(patttern);
    if (value.length == 0) {
      return "Informe o nome";
    }
    // else if (!regExp.hasMatch(value)) {
    //   return "O nome deve conter caracteres de a-z ou A-Z";
    // }
    return null;
  }

  void _saveForm() {
    log('o vivente pregou o dedo no SALVAR');
    Navigator.of(context).pop(true);
  }

  void _cancelForm() {
    log('o vivente pregou o dedo no CANCELAR');
    Navigator.of(context).pop(false);
  }

  Future<bool> _onBackPressed() {
    return showDialog(
      context: context,
      builder: (context) =>
      new AlertDialog(
        title: new Text('Tem certeza?'),
        content: new Text('Alterações serão descartadas. Confirma?'),
        actions: [
          FlatButton.icon(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              icon: Icon(Icons.cancel_rounded),
              label: Text('Não')),
          FlatButton.icon(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              icon: Icon(Icons.check_circle),
              label: Text('Descartar'))
        ],
      ),
    ) ??
        false;
  }
}
