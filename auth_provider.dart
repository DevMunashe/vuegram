import 'dart:convert';
import 'dart:async';
import 'package:connectivity_wrapper/connectivity_wrapper.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/http_exception.dart';

class Auth with ChangeNotifier {
  
  String _token;
   String _rToken;
  DateTime _expiryDate;
  String _userId;
  String _email;
  Timer _authTimer;
  Timer timeout;
  bool isValid;

  bool get isAuth {
    return token != null;
  }

  String get token {
    if (_expiryDate != null &&
        _expiryDate.isAfter(DateTime.now()) &&
        _token != null 
      //  && _rToken != null
        ) {
          if( isValid  == false ){
            _refreshTokenID();
          } 
      return _token;
    }
    isValid= false;
    return null;
  }
 String get rToken {
    if (_expiryDate != null &&
        _expiryDate.isAfter(DateTime.now()) &&
        _token != null //&&
        // _rToken != null
        ){
          isValid= true;
      return _rToken;
    }
    return null;
  }
  String get email {
    return _email;
  } 
  
  String get userId {
    return _userId;
  }
  Future<void> changePassword(String password) async {
    String urlSegment = 'setAccountInfo';
    final url =
        'https://www.googleapis.com/identitytoolkit/v3/relyingparty/$urlSegment?key=AIzaSyCv-LK3PExh9UYxUm4SqIdAn15QB_HstWs';
     try {
      final response = await http.post(
        url,
        body: json.encode(
          {
           // 'email': _email,
            'idToken': _token,
            'password': password,
            'returnSecureToken': true,
          },
        ),
      );
      final responseData = json.decode(response.body);
      if (responseData['error'] != null) {
        print(responseData['error']['message']);
        throw HttpException(responseData['error']['message']);
      }
      _token = responseData['idToken'];
      _userId = responseData['localId'];
      _email = responseData['email'];
      _rToken = _rToken;
      _expiryDate = DateTime.now().add(
        Duration(
          seconds: 86400,
        ),
      );
      print(_expiryDate);
        isValid = true;
        _timerToken();
      _autoLogout();
      notifyListeners();
      final prefs = await SharedPreferences.getInstance();
      final userData = json.encode(
        {
          'token': _token,
          'rToken': _rToken,
          'userId': _userId,
          'email': _email,
          'expiryDate': _expiryDate.toIso8601String(),
        },
      );
      prefs.setString('userData', userData);
    } catch (error) {
      throw error;
    }
  }

  Future<void> resetPassword(String email) async {
     String urlSegment = 'getOobConfirmationCode';
    final url =
        'https://www.googleapis.com/identitytoolkit/v3/relyingparty/$urlSegment?key=AIzaSyCv-LK3PExh9UYxUm4SqIdAn15QB_HstWs';
   try{
     final response = await http.post(
        url,
        body: json.encode(
          {
            'email': email,
            'requestType': "PASSWORD_RESET",
          },
        ),
      );
      final responseData = json.decode(response.body);
      if (responseData['error'] != null) {
        throw HttpException(responseData['error']['message']);
      }
      if(responseData['email'] == email){
        print("reset code sent");
      }
    } catch (error) {
      throw error;
    }
}

  Future<void> confirmResetPassword(String code, String password) async {
     String urlSegment = 'resetPassword';
    final url =
        'https://www.googleapis.com/identitytoolkit/v3/relyingparty/$urlSegment?key=AIzaSyCv-LK3PExh9UYxUm4SqIdAn15QB_HstWs';
   try{
     final response = await http.post(
        url,
        body: json.encode(
          {
            'oobCode': code,
            'requestType': "PASSWORD_RESET",
          },
        ),
      );
      final responseData = json.decode(response.body);
      if (responseData['error'] != null) {
        throw HttpException(responseData['error']['message']);
      }
      if(responseData['email'] != null){
        print("change password");
        final response2 = await http.post(
        url,
        body: json.encode(
          {
            'oobCode': code,
            'newPassword': password,
          },
        ),
      );
      final responseData2 = json.decode(response2.body);
      if (responseData2['error'] != null) {
        throw HttpException(responseData2['error']['message']);
      }
      _rToken =  _rToken;
      _token = responseData2['refreshToken'];
       _expiryDate = DateTime.now().add(
        Duration(
          seconds: 86400,
        ),
      );
      _autoLogout();
      notifyListeners();
      final prefs = await SharedPreferences.getInstance();
      final userData = json.encode(
        {
          'token': _token,
          'rToken': _rToken,
          'userId': _userId,
          'email': _email,
          'expiryDate': _expiryDate.toIso8601String(),

        },
      );
      prefs.setString('userData', userData);
      }
    } catch (error) {
      throw error;
    }
}
  Future<void> signup(String email, String password, String name, String surname, String phone, String companyName, String country) async {
    String urlSegment = 'signupNewUser';
    final url =
        'https://www.googleapis.com/identitytoolkit/v3/relyingparty/$urlSegment?key=AIzaSyCv-LK3PExh9UYxUm4SqIdAn15QB_HstWs';
   try {
      final response = await http.post(
        url,
        body: json.encode(
          {
            'email': email,
            'password': password,
            'returnSecureToken': true,
          },
        ),
      );
      final responseData = json.decode(response.body);
      if (responseData['error'] != null) {
        throw HttpException(responseData['error']['message']);
      }
      _token = responseData['idToken'];
      _rToken = responseData['refreshToken'];
      _userId = responseData['localId'];
       _email = responseData['email'];
      _expiryDate = DateTime.now().add(
        Duration(
          seconds: 86400,
         /* seconds: int.parse(
            responseData['expiresIn'],
          ), */
        ),
      );
      isValid= true;

      final url2 = 'https://sengai.firebaseio.com/users/$_userId.json?auth=$_token';
      try {
       final responses = await http.patch(
        url2,
        body: json.encode(
          {
            'usersId': _userId,
            'email': email,
            'name': name,
            'surname': surname,
            'phone': phone,
            'companyName':companyName,
            'country': "country",
            'type':'user',
          },
        ),
      );
      final responsesData = json.decode(responses.body);
      if (responsesData['error'] != null) {
        throw HttpException(responsesData['error']['message']);
      }
    } catch (error) {
      throw error;
    }
      _autoLogout();
      
      notifyListeners();
      final prefs = await SharedPreferences.getInstance();
      final userData = json.encode(
        {
          'token': _token,
          'rToken': _rToken,
          'userId': _userId,
          'email': _email,
          'expiryDate': _expiryDate.toIso8601String(),

        },
      );
      prefs.setString('userData', userData);
      _timerToken();
    } catch (error) {
      throw error;
    }
  }

  Future<void> login(String email, String password) async {


    final urlSegment = 'verifyPassword' ;
  final url =
        'https://www.googleapis.com/identitytoolkit/v3/relyingparty/$urlSegment?key=AIzaSyCv-LK3PExh9UYxUm4SqIdAn15QB_HstWs';
   try {
      final response = await http.post(
        url,
        body: json.encode(
          {
            'email': email,
            'password': password,
            'returnSecureToken': true,
          },
        ),
      );
      final responseData = json.decode(response.body);
      if (responseData['error'] != null) {
        throw HttpException(responseData['error']['message']);
      }
      _rToken = responseData['refreshToken'];
      _token = responseData['idToken'];
      _userId = responseData['localId'];
      _email = responseData['email'];
      _expiryDate = DateTime.now().add(
        Duration(
          seconds: 86400,
        ),
      );
      isValid= true;
     print("did i get refresh token:"); print(responseData['refreshToken']);
      print(_expiryDate);
      _autoLogout();
      _timerToken();
      notifyListeners();
      final prefs = await SharedPreferences.getInstance();
      final userData = json.encode(
        {
          'token': _token,
          'rToken': _rToken,
          'userId': _userId,
          'email': _email,
          'expiryDate': _expiryDate.toIso8601String(),
        },
      );
      prefs.setString('userData', userData);
    } catch (error) {
      throw error;
    }
  }

   Future<bool> tryAutoLogin() async {
     
    final prefs = await SharedPreferences.getInstance();

    if (!prefs.containsKey('userData')) {
      _token = null;
      _rToken = null;
      _userId = null;
      _email = null;
      _expiryDate = null;
      return false;
    }
    final extractedUserData = json.decode(prefs.getString('userData')) as Map<String, Object>;
    final expiryDate = DateTime.parse(extractedUserData['expiryDate']);

    if (expiryDate.isBefore(DateTime.now())) {
      return false;
    }
    _token = extractedUserData['token'];
    _rToken = extractedUserData['rToken'];
    _userId = extractedUserData['userId'];
    _email = extractedUserData['email'];
    _expiryDate = expiryDate;
    
      
    notifyListeners();
    _autoLogout();
    await _refreshTokenID();
    return true;
  }

  Future<void> logout() async {
    isValid = false;
    _token = null;
    _rToken = null;
    _userId = null;
    _email = null;
    _expiryDate = null;
    if (_authTimer != null) {
      _authTimer.cancel();
      _authTimer = null;
    }
    if (timeout != null) {
      timeout.cancel();
      timeout = null;
    }
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
     prefs.remove('userData');
    print("expired buda muApp");
  }

  void _autoLogout() {
    
    if (_authTimer != null) {
      _authTimer.cancel();
    }
    final timeToExpiry = _expiryDate.difference(DateTime.now()).inSeconds;
    _authTimer = Timer(Duration(seconds: timeToExpiry), logout);
  }

  void _timerToken() async {
    print("takunorefresher futi");
     timeout = Timer(Duration(seconds: 3500), _refreshTokenID);
  }

  Future<void> _refreshTokenID() async{
    isValid = false;
  final url =
        'https://securetoken.googleapis.com/v1/token?key=AIzaSyCv-LK3PExh9UYxUm4SqIdAn15QB_HstWs';
   try {
     if (await ConnectivityWrapper.instance.isConnected) {
      final response = await http.post(
        url,
        body: json.encode(
          {
            'grant_type': 'refresh_token',
            'refresh_token': _rToken,
          },
        ),
      );
      print(response.body);
      final responseData = json.decode(response.body);
      if (responseData['error'] != null) {
        print(responseData['error']['message']);
       // logout();
        //throw HttpException(responseData['error']['message']);
      }
      print("we have called and refreshed , granted the id again response was success");
     //_rToken =  _rToken;
      _token = responseData['access_token'];
     // _userId = responseData['localId'];
      //_email = responseData['email'];
      _expiryDate = DateTime.now().add(
        Duration(
          seconds: 86400,
        ),
      );
      print("printing the expriry time as updates new token"); print(_token);
     }
      _autoLogout();
      notifyListeners();
      final prefs = await SharedPreferences.getInstance();
      final userData = json.encode(
        {
          'token': _token,
          'rToken': _rToken,
          'userId': _userId,
          'email': _email,
          'expiryDate': _expiryDate.toIso8601String(),

        },
      );
      isValid = true;
      _timerToken();
      prefs.setString('userData', userData);
  } catch (error) {
      throw error;
    }
}
}
/*{
  "rules": {
    ".read": true,
    ".write": true,
  }
}
{
  "rules": {
   ".read": "auth != null",
   ".write":"auth != null",
    "jobs": {
      ".indexOn": ["userID"]
    },
    "users": {
      ".indexOn": ["usersId"]
    }
    
   }
}
*/