import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:drag_select_grid_view/drag_select_grid_view.dart';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photoprism/common/transparent_route.dart';
import 'package:photoprism/model/photo.dart';
import 'package:http/http.dart' as http;
import 'package:photoprism/model/photoprism_model.dart';
import 'package:photoprism/pages/photoview.dart';
import 'package:photoprism/widgets/selectable_tile.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Photos extends StatelessWidget {
  final ScrollController _scrollController;
  final BuildContext context;
  final String photoprismUrl;
  final String albumId;

  Photos({Key key, this.context, this.photoprismUrl, this.albumId})
      : _scrollController = ScrollController();

  static Future loadPhotosFromNetworkOrCache(
      PhotoprismModel model, String photoprismUrl, String albumId) async {
    print("loadPhotosFromNetworkOrCache: AlbumID:" + albumId);
    var key = 'photosList';
    key += albumId;
    SharedPreferences sp = await SharedPreferences.getInstance();
    if (sp.containsKey(key)) {
      final parsed =
          json.decode(sp.getString(key)).cast<Map<String, dynamic>>();
      List<Photo> photoList =
          parsed.map<Photo>((json) => Photo.fromJson(json)).toList();
      if (albumId == "") {
        model.setPhotoList(photoList);
      } else {
        model.setPhotoListOfAlbum(photoList, albumId);
      }
      return;
    }
    await loadPhotos(model, photoprismUrl, albumId);
  }

  static Future loadMorePhotos(
      PhotoprismModel model, String photoprismUrl, String albumId) async {
    if (model.isLoading) {
      return;
    }
    model.isLoading = true;
    print("loading more photos");
    List<Photo> photoList;
    if (albumId == "") {
      photoList = model.photoList;
    } else {
      photoList = model.albums[albumId].photoList;
    }

    var url = photoprismUrl +
        '/api/v1/photos?count=100&offset=' +
        photoList.length.toString();
    if (albumId != "") {
      url += "&album=" + albumId;
    }
    http.Response response = await http.get(url);
    final parsed = json.decode(response.body).cast<Map<String, dynamic>>();
    photoList
        .addAll(parsed.map<Photo>((json) => Photo.fromJson(json)).toList());

    if (albumId == "") {
      model.setPhotoList(photoList);
    } else {
      model.setPhotoListOfAlbum(photoList, albumId);
    }
    model.isLoading = false;
  }

  static Future loadPhotos(
      PhotoprismModel model, String photoprismUrl, String albumId) async {
    var url = photoprismUrl + '/api/v1/photos?count=100';
    if (albumId != "") {
      url += "&album=" + albumId;
    }
    http.Response response = await http.get(url);
    final parsed = json.decode(response.body).cast<Map<String, dynamic>>();
    List<Photo> photoList =
        parsed.map<Photo>((json) => Photo.fromJson(json)).toList();

    if (albumId == "") {
      model.setPhotoList(photoList);
    } else {
      model.setPhotoListOfAlbum(photoList, albumId);
    }
  }

  static List<Photo> getPhotoList(context, String albumId) {
    List<Photo> photoList;
    if (albumId == "") {
      photoList =
          Provider.of<PhotoprismModel>(context, listen: false).photoList;
    } else {
      photoList = Provider.of<PhotoprismModel>(context, listen: false)
          .albums[albumId]
          .photoList;
    }
    return photoList;
  }

  void _scrollListener() async {
    if (_scrollController.position.extentAfter < 500) {
      await Photos.loadMorePhotos(
          Provider.of<PhotoprismModel>(context), photoprismUrl, albumId);
    }
  }

  @override
  Widget build(BuildContext context) {
    DragSelectGridViewController gridController =
        Provider.of<PhotoprismModel>(context).getGridController();
    _scrollController.addListener(_scrollListener);
    if (Photos.getPhotoList(context, albumId) == null) {
      return Text("loading", key: ValueKey("photosGridView"));
    }
    return DragSelectGridView(
        key: ValueKey('photosGridView'),
        scrollController: _scrollController,
        gridController: gridController,
        gridDelegate: new SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 4,
          crossAxisSpacing: 4,
        ),
        itemCount: Photos.getPhotoList(context, albumId).length,
        itemBuilder: (context, index, selected) {
          return SelectableTile(
              key: ValueKey("PhotoTile"),
              index: index,
              context: context,
              gridController: gridController,
              selected: selected,
              onTap: () {
                Provider.of<PhotoprismModel>(context)
                    .setPhotoViewScaleState(PhotoViewScaleState.initial);
                Navigator.push(
                    context,
                    TransparentRoute(
                      builder: (context) =>
                          FullscreenPhotoGallery(index, albumId),
                    ));
              },
              child: Hero(
                tag: index.toString(),
                createRectTween: (begin, end) {
                  return RectTween(begin: begin, end: end);
                },
                child: CachedNetworkImage(
                  alignment: Alignment.center,
                  fit: BoxFit.contain,
                  imageUrl: photoprismUrl +
                      '/api/v1/thumbnails/' +
                      Photos.getPhotoList(context, albumId)[index].fileHash +
                      '/tile_224',
                  placeholder: (context, url) => Container(
                    color: Colors.grey,
                  ),
                  errorWidget: (context, url, error) => Icon(Icons.error),
                ),
              ));
        });
  }
}
