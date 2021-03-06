import 'package:http/http.dart' as http;

class Api {
  static Future<int> createAlbum(String albumName, String photoprismUrl) async {
    String body = '{"AlbumName":"' + albumName + '"}';

    try {
      http.Response response =
          await http.post(photoprismUrl + '/api/v1/albums', body: body);

      if (response.statusCode == 200) {
        return 0;
      } else {
        return 2;
      }
    } catch (_) {
      return 1;
    }
  }

  static Future<int> renameAlbum(
      String albumId, String newAlbumName, String photoprismUrl) async {
    String body = '{"AlbumName":"' + newAlbumName + '"}';

    try {
      http.Response response = await http
          .put(photoprismUrl + '/api/v1/albums/' + albumId, body: body);

      if (response.statusCode == 200) {
        return 0;
      } else {
        return 2;
      }
    } catch (_) {
      return 1;
    }
  }

  static Future<int> deleteAlbum(String albumId, String photoprismUrl) async {
    String body = '{"albums":["' + albumId + '"]}';

    try {
      http.Response response = await http
          .post(photoprismUrl + '/api/v1/batch/albums/delete', body: body);

      if (response.statusCode == 200) {
        return 0;
      } else {
        return 2;
      }
    } catch (_) {
      return 1;
    }
  }

  static Future<int> addPhotosToAlbum(
      String albumId, List<String> photoUUIDs, String photoprismUrl) async {
    // wrap uuids in double quotes
    List<String> photoUUIDsWrapped = [];

    photoUUIDs.forEach((photoUUID) {
      photoUUIDsWrapped.add('"' + photoUUID + '"');
    });

    String body = '{"photos":' + photoUUIDsWrapped.toString() + '}';

    try {
      http.Response response = await http.post(
          photoprismUrl + '/api/v1/albums/' + albumId + '/photos',
          body: body);
      if (response.statusCode == 200) {
        return 0;
      } else {
        return 2;
      }
    } catch (_) {
      return 1;
    }
  }

  static Future<int> importPhotos(String photoprismUrl) async {
    try {
      http.Response response = await http.post(photoprismUrl + "/api/v1/import/", body: "{}");
      if (response.statusCode == 200) {
        return 0;
      } else {
        return 2;
      }
    } catch (_) {
      return 1;
    }
  }
}
