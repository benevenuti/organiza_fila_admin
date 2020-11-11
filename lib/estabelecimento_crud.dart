import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_switch/flutter_switch.dart';
import 'package:image_picker/image_picker.dart';
import 'package:network_to_file_image/network_to_file_image.dart';
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

  // controles
  final _formKey = GlobalKey<FormState>();
  final picker = ImagePicker();

  // aux
  File _imgPr;
  File _imgBg;

  @override
  void initState() {
    log('crud init');

    _nome = widget.estabelecimento.nome;
    _sobre = widget.estabelecimento.sobre;
    _mesas =
        widget.estabelecimento.mesas != null ? widget.estabelecimento.mesas : 0;

    _aberto = widget.estabelecimento.aberto == true;

    if (widget.estabelecimento != null) {
      if (widget.estabelecimento.imagempr != null) {
        _imgPr =
            NetworkToFileImage(file: null, url: widget.estabelecimento.imagempr)
                .file;
      }

      if (widget.estabelecimento.imagembg != null) {
        _imgBg =
            NetworkToFileImage(file: null, url: widget.estabelecimento.imagembg)
                .file;
      }
    }

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    log('crud build');
    return Scaffold(
      appBar: AppBar(
        //backgroundColor: Colors.grey[850],
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
              log('o vivente pregou o dedo no CANCELAR');
              Navigator.of(context).pop(false);
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
              log('o vivente pregou o dedo no SALVAR');
              Navigator.of(context).pop(true);
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
    File file;
    var f = await picker.getImage(
      source: src,
    );
    if (f != null) {
      file = File(f.path);
    }
    return Future.value(file);
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
                        Navigator.of(context).pop(f);
                      }),
                  new ListTile(
                    leading: new Icon(Icons.photo_camera),
                    title: new Text('Câmera'),
                    onTap: () async {
                      var f = await _getImg(context, ImageSource.camera);
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
    return Stack(
      children: [
        Center(
          child: GestureDetector(
            onTap: () {
              _showImgPickerDlg(context).then((value) {
                if (value != null) {
                  setState(() {
                    _imgBg = value;
                  });
                }
              });
            },
            onLongPress: () {
              if (_imgBg != null) {
                _confirmImageClear(context).then((value) {
                  if (value) {
                    setState(() {
                      _imgBg = null;
                    });
                  }
                });
              } else {
                log('sem imagem para limpar');
                SystemSound.play(SystemSoundType.click);
              }
            },
            child: _imgBg != null
                ? _renderImagemBg()
                : _renderImagemBgPlaceholder(),
          ),
        ),
        Column(
          children: [
            SizedBox(
              height: 46,
            ),
            Center(
              child: GestureDetector(
                onTap: () {
                  _showImgPickerDlg(context).then((value) {
                    if (value != null) {
                      setState(() {
                        _imgPr = value;
                      });
                    }
                  });
                },
                onLongPress: () {
                  if (_imgPr != null) {
                    _confirmImageClear(context).then((value) {
                      if (value) {
                        setState(() {
                          _imgPr = null;
                        });
                      }
                    });
                  } else {
                    log('sem imagem para limpar');
                    SystemSound.play(SystemSoundType.click);
                  }
                },
                child: CircleAvatar(
                  radius: 55,
                  backgroundColor: Colors.black38,
                  child: _imgPr != null
                      ? _renderImagemPr()
                      : _renderImagemPrPlaceholder(),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _renderImagemPrPlaceholder() {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
              //color: Colors.grey[200],
              borderRadius: BorderRadius.circular(52.5)),
          width: 105,
          height: 105,
        ),
        Center(
          child: Row(
            children: [
              Icon(
                Icons.edit,
                color: Colors.deepOrange,
              ),
              Icon(
                Icons.delete,
                color: Colors.deepOrange,
              ),
            ],
          ),
        )
      ],
    );
  }

  ClipRRect _renderImagemPr() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(52.5),
      child: Image.file(
        _imgPr,
        width: 105,
        height: 105,
        fit: BoxFit.fitWidth,
      ),
    );
  }

  Widget _renderImagemBgPlaceholder() {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            //color: Colors.grey[200],
          ),
          width: 400,
          height: 200,
        ),
      ],
    );
  }

  ClipRRect _renderImagemBg() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Image.file(
        _imgBg,
        width: 400,
        height: 200,
        fit: BoxFit.fitWidth,
      ),
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
    Navigator.of(context).pop(true);
  }

  void _cancelForm() {
    Navigator.of(context).pop(false);
  }
}
