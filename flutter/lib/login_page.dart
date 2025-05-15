import 'dart:io';
import 'package:encrypt/encrypt.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/cupertino.dart';
import 'package:encrypt/encrypt.dart' as Encrypt;
import 'package:flutter/material.dart' hide Key;
import 'package:go_router/go_router.dart';
import 'package:zy_app/bean/app_version_bean.dart';
import 'package:zy_app/bean/login_bean.dart';
import 'package:zy_app/bean/title_bean.dart';
import 'package:zy_app/bean/user_info_bean.dart';
import 'package:zy_app/const/conf_encode.dart';
import 'package:zy_app/const/const_file.dart';
import 'package:zy_app/const/const_net.dart';
import 'package:zy_app/const/const_sp.dart';
import 'package:zy_app/main.dart';
import '../bean/const_file_bean.dart';
import '../const/const_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter_app_update/flutter_app_update.dart';
import 'dart:convert';
import 'package:package_info_plus/package_info_plus.dart';
import '../utils/sp_util.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

final dio = Dio();
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


  /// 背景
  final Widget _topBg = Container(
    height: 270,
    width: double.infinity,
    decoration: BoxDecoration(
        image: DecorationImage(
            image: AssetImage(ImageConstant.loginBg), fit: BoxFit.cover)),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: const Color(0xfff6f3f3),
          ),
          alignment: Alignment.center,
          height: 60,
          width: 60,
          child: Image.asset(
            ImageConstant.logo,
            height: 50,
            width: 50,
          ),
        ),
        const SizedBox(
          height: 20,
        ),
        const Text(
          '准研上岸！',
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16),
        )
      ],
    ),
  );


  @override
  void dispose() {
    super.dispose();
    _accountController.dispose();
    _pwdController.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadShare();
    _initPackageInfo();

  }

  //初始化包信息
  Future<void> _initPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      _packageInfo = info;
      _showUpdateDialog(true);
    });
  }

  //显示更新弹窗
  _showUpdateDialog(bool forcedUpgrade) async {
    await dio.post('${NetConst.getNewApk}/${_packageInfo.buildNumber}').then((response){
      Map<String, dynamic> map = jsonDecode(response.toString());
      var versionBean = AppVersionBean.fromJson(map);
      if(versionBean.data==null||versionBean.data!.url==null||versionBean.data!.content==null){
        return;
      }
      showDialog(
        context: context,
        barrierDismissible: !forcedUpgrade,
        builder: (BuildContext context) {
          return WillPopScope(
            onWillPop: () => Future.value(!forcedUpgrade),
            child: AlertDialog(
              title: const Text('发现新版本'),
              content: Text(versionBean.data!.content!.replaceAll("\\n", "\n")),
              actions: <Widget>[
                TextButton(
                  child: const Text('升级'),
                  onPressed: () {
                    _appUpdate(versionBean);
                    if (!forcedUpgrade) {
                      Navigator.of(context).pop();
                    }
                  },
                ),
              ],
            ),
          );
        },
      );
    });
  }

  _appUpdate(AppVersionBean bean) {
    UpdateModel model = UpdateModel(
      NetConst.base_url+bean.data!.url!,
      "准妍计算机复试V${bean.data!.versionId!}.apk",
      "ic_launcher",
      'iosurl',
    );
    AzhonAppUpdate.update(model).then((value) => debugPrint('$value'));
  }

  //解析专题
  void _analysisSubject(){
    var subjectBeanListLength = SpUtils.getIntByBase64("subjectBeanListLength");
    if(subjectBeanListLength!=0){
      return;
    }
    //解密
    final key = Encrypt.Key.fromUtf8(EncodeConf.fileKey);
    final iv = IV.fromLength(16);
    final encrypter = Encrypter(AES(key));
    var codeStr = rootBundle.loadString(FileConstant.titleJson);
    codeStr.then((code) {
      String jsonStr = encrypter.decrypt64(code,iv: iv);
      TitleBean titleBean = TitleBean.fromJson(jsonDecode(jsonStr));
      for(int i=0;i<titleBean.subjectBeanList!.length;i++){
        var subjectBeanList = titleBean.subjectBeanList![i];
        var sid=subjectBeanList.sid;
        for(int j=0;j<subjectBeanList.topicBeanList!.length;j++){
          var topicBean = subjectBeanList.topicBeanList![j];
          var tid=topicBean.tid!;

          SpUtils.setBase64ByString('${tid}_title', topicBean.title!);
          SpUtils.setBase64ByString('${tid}_answer', topicBean.answer!);
          SpUtils.setBase64ByString('${tid}_explain', topicBean.explain!);
        }

        SpUtils.setBase64ByInt('${sid}_topicBeanListLength', subjectBeanList.topicBeanList!.length);
      }
      SpUtils.setBase64ByInt('subjectBeanListLength' ,titleBean.subjectBeanList!.length);


    });
  }

  Future<void> login() async {
    ///点击登录
    Map<String, dynamic> map = {};
    map['username'] = _accountController.value.text;
    map['password'] = _pwdController.value.text;
    final response = await dio.post(NetConst.login, data: map);
    Map<String, dynamic> userMap = jsonDecode(response.toString());
    var loginBean = LoginBean.fromJson(userMap);
    if(loginBean.status!=null && loginBean.status==200){
      _analysisSubject();
      sp.setString(SpConst.username, _accountController.value.text);
      sp.setString(SpConst.password, _pwdController.value.text);
      context.go("/indexPage");
      _getUserInfo();
    }
    // _writeWinFile();
  }

  // 获取用户信息
  Future<void> _getUserInfo() async {
    FormData formData = FormData.fromMap({"username": _accountController.value.text});
    final response = await dio.post(NetConst.getUserInfo,data: formData);
    var userInfoBean = UserInfoBean.fromJson(jsonDecode(response.toString()));
    sp.setString(SpConst.userId, userInfoBean.data!.id!);
  }

  // 初始化对象存储
  Future<void> _loadShare() async {
    sp = await SharedPreferences.getInstance();
    _inputAccount=sp.getString(SpConst.username) ?? "";
    _inputPwd=sp.getString(SpConst.password) ?? "";
    _accountController.text=_inputAccount;
    _pwdController.text=_inputPwd;
    setState(() {
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        resizeToAvoidBottomInset: false,
        body: Stack(
          children: [
            Column(
              children: [
                _topBg,
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
                      login();
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
                  child: const Text('-皖ICP备2024037336号-',style: TextStyle(color:Color(0xff999999)),),
                ),
              )
          ],
        ),
    );
  }

}

