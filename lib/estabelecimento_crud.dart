import 'dart:developer';
import 'dart:io';

import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_switch/flutter_switch.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:organiza_fila_admin/estabelecimento.dart';
import 'package:path/path.dart' as path;
import 'package:transparent_image/transparent_image.dart';
import 'package:uuid/uuid.dart';

class EstabelecimentoCrud extends StatefulWidget {
  final Estabelecimento estabelecimento;
  final DatabaseReference empresasRef;

  EstabelecimentoCrud(this.estabelecimento, this.empresasRef);

  @override
  _EstabelecimentoCrudState createState() => _EstabelecimentoCrudState();
}

class _EstabelecimentoCrudState extends State<EstabelecimentoCrud> {
  String _title;

  // campos do estabelecimento
  dynamic _id;
  String _nome;
  String _imagembg;
  String _imagempr;
  String _imagembgUrl;
  String _imagemprUrl;
  bool _aberto = true;
  int _mesas = 0;
  String _sobre;

  // aux
  Widget _imgBg;
  Widget _imgPr;
  String _imgBgLocal;
  String _imgPrLocal;

  bool _saving = false;

  // controles
  final _formKey = GlobalKey<FormState>();
  final picker = ImagePicker();

  DatabaseReference _empresasRef;

  @override
  void initState() {
    log('crud init ini');
    super.initState();
    _id = widget.estabelecimento.id;
    _nome = widget.estabelecimento.nome;
    _sobre = widget.estabelecimento.sobre;
    _mesas = widget.estabelecimento.mesas ?? 0;
    _aberto = widget.estabelecimento.aberto == true;

    _imagembg = widget.estabelecimento.imagembg;
    _imagembgUrl = widget.estabelecimento.imagembgUrl;

    _imagempr = widget.estabelecimento.imagempr;
    _imagemprUrl = widget.estabelecimento.imagemprUrl;

    imagensInit();

    _title = _id == null ? 'Novo estabelecimento' : 'Editar estbelecimento';

    _empresasRef = widget.empresasRef;

    log('crud init end');
  }

  @override
  bool get mounted {
    var m = super.mounted;
    log('get mounted = $m');
    return m;
  }

  void imagensInit() async {
    _imgBgInit();
    _imgPrInit();
  }

  void _imgPrInit() async {
    if (_imagempr != null) {
      if (_imagemprUrl == null) {
        _imagemprUrl =
            await FirebaseStorage.instance.ref(_imagempr).getDownloadURL();
      }
      var img = FadeInImage.memoryNetwork(
        placeholder: kTransparentImage,
        image: _imagemprUrl,
        fit: BoxFit.cover,
        width: 100,
        height: 100,
      );

      setState(() {
        _imgPr = img;
      });
    }
  }

  void _imgBgInit() async {
    if (_imagembg != null) {
      if (_imagembgUrl == null) {
        _imagembgUrl =
            await FirebaseStorage.instance.ref(_imagembg).getDownloadURL();
      }
      var img = FadeInImage.memoryNetwork(
        placeholder: kTransparentImage,
        image: _imagembgUrl,
        fit: BoxFit.cover,
        width: 400,
        height: 180,
      );

      setState(() {
        _imgBg = img;
      });
    }
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
              Text(_title),
            ],
          ),
        ),
        body: SingleChildScrollView(
          child: Container(
            margin: EdgeInsets.all(30),
            child: Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: _buildForm(context),
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

  Widget _buildForm(BuildContext context) {
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
        _buildFooterButtons(context),
      ],
    );
  }

  Widget _buildFooterButtons(BuildContext context) {
    return Column(
      //mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Container(
          padding: EdgeInsets.symmetric(vertical: 10.0),
          width: double.infinity,
          child: Hero(
            tag: 'tag_new_estab',
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
        ),
        Container(
          padding: EdgeInsets.symmetric(vertical: 10.0),
          width: double.infinity,
          child: Hero(
            tag: 'tag_${widget.estabelecimento.id}',
            child: RaisedButton(
              elevation: 5.0,
              onPressed: () {
                _saveForm(context);
              },
              padding: EdgeInsets.all(15.0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              color: Colors.white,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'SALVAR',
                    style: TextStyle(
                      color: Colors.cyan,
                      letterSpacing: 1.5,
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                      // fontFamily: 'OpenSans',
                    ),
                  ),
                  SizedBox(
                    width: 6,
                  ),
                  _saving
                      ? CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.cyan),
                        )
                      : Container()
                ],
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
      return _cropImage(f.path);
    } else {
      return Future.value(null);
    }
  }

  Future<File> _cropImage(String path) async {
    File croppedFile = await ImageCropper.cropImage(
        sourcePath: path,
        aspectRatioPresets: [
          CropAspectRatioPreset.square,
          CropAspectRatioPreset.ratio3x2,
          CropAspectRatioPreset.original,
          CropAspectRatioPreset.ratio4x3,
          CropAspectRatioPreset.ratio16x9,
        ],
        androidUiSettings: AndroidUiSettings(
            toolbarTitle: 'Recorte sua imagem',
            // toolbarColor: Colors.deepOrange,
            // toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: true),
        iosUiSettings: IOSUiSettings(
          title: 'Recorte sua imagem',
        ));
    return croppedFile;
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
                      var img;
                      if (value != null) {
                        img = Image.file(value,
                            width: 480, height: 180, fit: BoxFit.cover);
                      }
                      setState(() {
                        _imgBg = img;
                        _imgBgLocal = value.path;
                      });
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
                            _imgBgLocal = null;
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
                    var img;
                    if (value != null) {
                      img = Image.file(value,
                          width: 100, height: 100, fit: BoxFit.cover);
                    }
                    setState(() {
                      _imgPr = img;
                      _imgPrLocal = value.path;
                    });
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
                          _imgPrLocal = null;
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

  void _saveForm(BuildContext context) async {
    log('o vivente pregou o dedo no SALVAR');
    if (_saving) {
      return;
    }
    setState(() {
      _saving = true;
    });

    _fillEstabelecimento();

    await _update(context, widget.estabelecimento);

    setState(() {
      _saving = false;
    });

    Navigator.of(context).pop(true);
  }

  void _fillEstabelecimento() {
    if (_id == null) {
      log('gerando novo estabelecimento');
      _id = Uuid()
          .v5(Uuid.NAMESPACE_URL, 'br.com.organizafila.organiza_fila_admin');
      widget.estabelecimento.id = _id;
      widget.estabelecimento.fila = List(0);
      widget.estabelecimento.mesa = List(0);
      widget.estabelecimento.pessoasNaFila = 0;
      widget.estabelecimento.mesasDisponiveis = _mesas;
      widget.estabelecimento.isNew = true;
    }

    widget.estabelecimento.nome = _nome;
    widget.estabelecimento.sobre = _sobre;
    widget.estabelecimento.mesas = _mesas;
    widget.estabelecimento.aberto = _aberto;

    DateFormat dateFormat = DateFormat("yyyyMMdd_HHmmss");
    String _now = dateFormat.format(DateTime.now());

    if (_imgPrLocal != null) {
      var _ext = path.extension(_imgPrLocal).toLowerCase();
      widget.estabelecimento.imagempr = 'images/empresas/$_id/pr_$_now$_ext';
      widget.estabelecimento.imagemprLocal = _imgPrLocal;
    }

    if (_imgBgLocal != null) {
      var _ext = path.extension(_imgBgLocal).toLowerCase();
      widget.estabelecimento.imagembg = 'images/empresas/$_id/bg_$_now$_ext';
      widget.estabelecimento.imagembgLocal = _imgBgLocal;
    }
  }

  void _cancelForm() {
    log('o vivente pregou o dedo no CANCELAR');
    Navigator.of(context).pop();
  }

  bool _checkModified() {
    var o = widget.estabelecimento;
    return o.id != _id ||
        o.nome != _nome ||
        o.sobre != _sobre ||
        o.mesas != _mesas ||
        o.imagembg != _imagembg ||
        o.imagempr != _imagempr;
  }

  Future<void> _update(BuildContext context, Estabelecimento item) async {
    if (item == null) {
      log('o vivente não salvou');
    }
    try {
      var itemMap = item.toMap();
      if (item.isNew) {
        await _empresasRef.push().update(itemMap);
      } else {
        var f = _empresasRef
            .orderByChild('id')
            .equalTo(item.id)
            .once()
            .then((value) {
          //var m = value.value as Map<dynamic, dynamic>;
          log('chave ${value.key}');
          log('valor ${value.value}');

          (value.value as Map<dynamic, dynamic>).forEach((key, value) {
            var m = {
              '$key': itemMap
            };
            _empresasRef.update(m);
          });
        });
      }
      if (item.imagemprLocal != null) {
        await _uploadFile(item.imagemprLocal, item.imagempr);
      }
      if (item.imagembgLocal != null) {
        await _uploadFile(item.imagembgLocal, item.imagembg);
      }
      _showSnackBar(context, 'Estabelecimento salvo.');
    } on Exception catch (e) {
      var msg = 'Erro ao salvar o estabelcimento: $e';
      _showSnackBar(context, msg);
    }

    setState(() {
      _saving = false;
    });
  }

  Future<void> _uploadFile(String localFile, String remoteFile) async {
    File file = File(localFile);
    try {
      await FirebaseStorage.instance.ref(remoteFile).putFile(file);
    } on FirebaseException catch (e) {
      var msg = 'erro ao subir $localFile -> $remoteFile';
      log(msg);
      _showSnackBar(context, msg);
    }
  }

  Future<bool> _onBackPressed() {
    if (_checkModified()) {
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
    } else {
      return Future.value(true);
    }
  }

  void _showSnackBar(BuildContext context, String text) {
    //Scaffold.of(context).showSnackBar(SnackBar(content: Text(text)));
    log(text);
  }
}
