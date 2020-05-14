import 'dart:async';
import 'dart:convert';
import 'package:flushbar/flushbar.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:fidortry/Screens/Homepage/Home_page_Remodel.dart';

Future navigateToSubPage(context)async {
  Navigator.push(context, MaterialPageRoute(builder: (context)=> HomePageScreen()));
}

showSubmitRequestSnackBar(BuildContext context) async {

  Flushbar(
    flushbarPosition: FlushbarPosition.BOTTOM,
    message: "Transaction Completed. Redirecting to HomePage...",
    flushbarStyle: FlushbarStyle.FLOATING,
    margin: EdgeInsets.all(8),
    borderRadius: 8,
    icon: Icon(
    Icons.check_circle_outline,
    size: 28.0,
    color: Colors.blue[300],
    ),
    duration: Duration(seconds: 3),
    leftBarIndicatorColor: Colors.blue[300],
  )
    ..show(context).then((r)=> Navigator.push(
        context, MaterialPageRoute(builder: (context) => new HomePageScreen())));
}

Future<String> getCode() async{
  String clientID='01fa0f91453a0cc6';
  final response = await http.post('https://apm.fdp.fidorfzco.com/oauth/authorize?client_id='+clientID+'&redirect_uri=http://localhost:3000/&response_type=code&state=approved');
  print (response.statusCode);
  Map<String, dynamic> jsonn= json.decode(response.body);

  SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.setString('access', jsonn['access_token']);
  return jsonn['access_token'];
}

Future<String> getToken() async{
  String code="b337e121b296b1b7408c50a4a04c58f3";
  String clientID='01fa0f91453a0cc6';
  String clientSecret='4ac9580268a7f96c0ee01f7dc97c4a8d';
  final response = await http.post('https://apm.fdp.fidorfzco.com/oauth/token?grant_type=authorization_code&client_id='+clientID+'&client_secret='+clientSecret+'&code='+code+'&redirect_uri=http://localhost:3000');
  print (response.statusCode);
  Map<String, dynamic> jsonn= json.decode(response.body);

  SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.setString('access', jsonn['access_token']);
  return jsonn['access_token'];
}

Future<Customer> getCustomers() async{
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String token=(prefs.getString('access'));
  final response =await http.get('https://gateway.fdp.fidorfzco.com/fidor_banking/accounts',
  headers: {
    'Content-Type':"application/json",
    'Accept':"application/vnd.fidor.de; version=1,text/json",
    'Authorization':"Bearer "+token
  });
  Map<String, dynamic> decoded = json.decode(response.body);
  print(decoded['data'][0]['id']);
  Customer cust= Customer(decoded['data'][0]['id'], decoded['data'][0]['customers'][0]['first_name'], decoded['data'][0]['customers'][0]['last_name'], decoded['data'][0]['balance'],response.statusCode);
  int amount=decoded['data'][0]['balance'];
  return cust;
}

Future<void> postTransfer(int amountTrans,BuildContext context) async{
  var uuid = Uuid();
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String token=(prefs.getString('access'));
  final response =await http.post('https://gateway.fdp.fidorfzco.com/fidor_banking/internal_transfers',
  body: json.encode(
  {
  "account_id": "79054921",
  "receiver": "26857779",
  "external_uid": uuid.v4() ,
  "amount": amountTrans,
  "subject": "my share of yesterday evening"
  }),
  headers: {
    'Content-Type':"application/json",
    'Accept':"application/vnd.fidor.de; version=1,text/json",
    'Authorization':"Bearer "+ token
  });
  print(response.statusCode.toString());

  // return (response.statusCode.toString());
  //navigateToSubPage(context);
  showSubmitRequestSnackBar(context);
}

class Customer{
  String accountid;
  String firstName;
  String lastName;
  int balance;
  int reponse;

  Customer(String id, String fName, String lName, int bal, int respo){
    this.accountid=id;
    this.firstName=fName;
    this.lastName=lName;
    this.balance=bal;
    this.reponse=respo;
  }

  int get resp{
    return reponse;
  }

  String get custId{
    return accountid;
  }

  String get firName{
    return firstName;
  }

  String get lasName{
    return lastName;
  }

  int get bal{
    return balance;
  }
}

