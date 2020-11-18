import 'dart:developer';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:transparent_image/transparent_image.dart';

import 'estabelecimento.dart';

class ContentListItem extends StatelessWidget {
  ContentListItem(this.item);

  final Estabelecimento item;

  Widget _buildDefault(Widget image, double width, double height) {
    //log('_buildDefault');
    return image == null
        ? SizedBox(
            width: width,
            height: height,
          )
        : image;
  }

  Future<Widget> _buildImagePr(
      Estabelecimento item, double width, double height) async {
    if (item.imagempr != null) {
      if (item.imagemprUrl == null) {
        try {
          var dUrl = await FirebaseStorage.instance
              .ref(item.imagempr)
              .getDownloadURL();
          //log('consegui a url $dUrl');
          item.imagemprUrl = dUrl;
          if (item.imagemprWidget == null) {
            item.imagemprWidget = FadeInImage.memoryNetwork(
              placeholder: kTransparentImage,
              image: item.imagemprUrl,
              width: width,
              height: height,
              fit: BoxFit.cover,
            );
          }
        } on Exception catch (e) {
          log('erro ao buscar ${item.imagempr}: $e');
          return Container(
            width: width,
            height: height,
            child: Icon(Icons.not_interested),
          );
        }
      }
      return item.imagemprWidget;
    } else {
      return _buildDefault(item.imagemprWidget, width, height);
    }
  }

  Widget _buildImageFromStorage(double width, double height) {
    return FutureBuilder(
      future: _buildImagePr(item, width, height),
      initialData: _buildDefault(item.imagemprWidget, width, height),
      builder: (BuildContext context, AsyncSnapshot<Widget> snapshot) {
        return snapshot.data;
      },
    );
  }

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
          leading: ClipRRect(
              clipBehavior: Clip.antiAliasWithSaveLayer,
              borderRadius: BorderRadius.circular(6),
              child: _buildImageFromStorage(120, 90)),
          title: Text(item.nome ?? '<${item.id}>'),
          subtitle: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  item.aberto ?? false
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
                  item.aberto ?? false
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
