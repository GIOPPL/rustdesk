import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' hide Key;
import 'package:flutter_hbb/mobile/pages/home_page.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:http/http.dart' as http;

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

var _inputAccount = '';
var _inputPwd = '';

class _LoginPageState extends State<LoginPage> {
  final _accountController = TextEditingController.fromValue(TextEditingValue(
      text: _inputAccount,
      selection: TextSelection.fromPosition(TextPosition(
          affinity: TextAffinity.downstream, offset: _inputAccount.length))));
  final _pwdController = TextEditingController.fromValue(TextEditingValue(
      text: _inputPwd,
      selection: TextSelection.fromPosition(TextPosition(
          affinity: TextAffinity.downstream, offset: _inputPwd.length))));


  late PackageInfo _packageInfo ;




  @override
  void dispose() {
    super.dispose();
    _accountController.dispose();
    _pwdController.dispose();
  }

  @override
  void initState() {
    super.initState();

  }

  Future<void> login(context) async {

    final snackBar = SnackBar(content: Text('登录成功'));
    final snackBar2 = SnackBar(content: Text('登录失败'));
    ///点击登录
    Map<String, dynamic> map = {};
    map['username'] = _accountController.value.text;
    map['password'] = _pwdController.value.text;
    final response = await http.post(
      Uri.parse('http://118.178.186.181:8080/jwt/token'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(map), // 将Map转换为JSON字符串
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(snackBar);

      Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => HomePage())
      );
      return json.decode(response.body);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to send data: ${response.statusCode}')));

      Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => HomePage())
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
        // resizeToAvoidBottomInset: false,
        body: Stack(
          children: [
            Column(
              children: [
                const SizedBox(
                  height: 20,
                ),
                const Text('登录',
                  style: TextStyle(
                    color: Color(0xff4481ff),
                    fontSize: 20,
                  ),
                ),

                ///账户
                Container(
                  margin: const EdgeInsets.only(
                      left: 40, right: 40, top: 14, bottom: 14),
                  child: TextField(
                    controller: _accountController,
                    decoration: const InputDecoration(
                        counterText: '',
                        hintText: '请输入账户',
                        hintStyle: TextStyle(
                            color: Color(0xff8c8c8c), fontSize: 14),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.orange),
                        ),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Color(0xffdadada)),
                        ),
                        fillColor: Colors.transparent,
                        filled: true,
                        prefixIcon: Icon(
                          Icons.person,
                          color: Color(0xffb3d0fe),
                        )),
                  ),
                ),

                ///密码
                Container(
                  margin: const EdgeInsets.only(
                      left: 40, right: 40, top: 14, bottom: 14),
                  child: TextField(
                    obscureText: true,
                    controller: _pwdController,
                    keyboardType: TextInputType.text,
                    decoration: const InputDecoration(
                        counterText: '',
                        hintText: '请输入密码',
                        hintStyle: TextStyle(
                            color: Color(0xff8c8c8c), fontSize: 14),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.orange),
                        ),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Color(0xffdadada)),
                        ),
                        fillColor: Colors.transparent,
                        filled: true,
                        prefixIcon: Icon(
                          Icons.lock,
                          color: Color(0xffb3d0fe),
                        )),
                  ),
                ),
                const SizedBox(height: 30,),

                ///登录按钮
                Container(
                  margin: const EdgeInsets.only(left: 30, right: 30),
                  width: double.infinity,
                  child: MaterialButton(
                    color: const Color(0xff3381ff),
                    shape: const RoundedRectangleBorder(
                        side: BorderSide.none,
                        borderRadius: BorderRadius.all(Radius.circular(50)
                        )
                    ),
                    onPressed: () {
                      login(context);
                    },
                    child: const Text('登录', style: TextStyle(color: Colors.white,),),
                  ),
                ),
                const SizedBox(height: 10,),
              ],
            ),
            if(Platform.isAndroid)
              Positioned(
                left: 0.0,
                right: 0.0,
                bottom:20.0,
                child: Container(
                  alignment: Alignment.center,
                  child: const Text('-中移铁通安徽分公司-',style: TextStyle(color:Color(0xff999999)),),
                ),
              )
          ],
        ),
    );
  }

}

