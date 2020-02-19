
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:youwallet/service/token_service.dart';
import 'package:provider/provider.dart';
import 'package:youwallet/model/wallet.dart' as myWallet;
import 'package:youwallet/widgets/loadingDialog.dart';
import 'package:youwallet/widgets/customButton.dart';

class WalletCheck extends StatefulWidget {
  TokenService _tokenService;
  @override
  Page createState()  => Page(this._tokenService);
}

class Page extends State<WalletCheck> {

  Page(this._tokenService);

  List randomMnemonic = [];
  List randomMnemonicAgain = [];
  TextEditingController _name = TextEditingController();
  TokenService _tokenService;

  final globalKey = GlobalKey<ScaffoldState>();

  void showSnackbar(String text) {
    final snackBar = SnackBar(content: Text(text));
    globalKey.currentState.showSnackBar(snackBar);
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    setRandomMnemonic();
  }

  /// 从本地缓存中拿出上一步的助记词，准备初始化
  void setRandomMnemonic() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String randomMnemonic = prefs.getString("randomMnemonic");
    this.randomMnemonic = [];
    print("助记词=》${randomMnemonic}");

//    String privateKey = TokenService.getPrivateKey(randomMnemonic);
//    String passwordMd5 = Md5Encrypt('123456').init();
//    print("password md5 =》${passwordMd5}");
//    String encryptPrivateKey = await FlutterAesEcbPkcs5.encryptString(privateKey, passwordMd5);
//    String encryptMnemonic = await FlutterAesEcbPkcs5.encryptString(randomMnemonic.toString(), passwordMd5);
//    print('this is encryptPrivateKey => ${encryptPrivateKey}');
//    print('this is encryptMnemonic => ${encryptMnemonic}');

    setState(() {
      List temp = randomMnemonic.split(' ');
      temp.forEach((element){
        this.randomMnemonic.add({
          'val': element,
          'active': false
        });
      });
      this.randomMnemonic.shuffle();
      print(this.randomMnemonic);
//      this._name.text = randomMnemonic;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        key: globalKey,
        appBar: AppBar(
          title: Text("确认助记词"),
        ),
        body: new Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.all(16.0), // 四周填充边距32像素
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              new Container(
                margin: const EdgeInsets.only(bottom: 30.0),
                child: new Image.asset(
                    'images/new_wallet.png'
                ),
              ),
              Text('请按照顺序依次点击助记词'),
//              new TextField(
//                controller: this._name,
//                maxLines: 3,
//                decoration: InputDecoration(
//                    filled: true,
//                    hintText: "请依次点击助记词",
//                    enabled: false,
//                    fillColor: Colors.black12,
//                    contentPadding: new EdgeInsets.all(6.0), // 内部边距，默认不是0
//                    border:InputBorder.none, // 没有任何边线
//                    enabledBorder: OutlineInputBorder(
//                      borderRadius: BorderRadius.circular(6.0),
//                      borderSide: BorderSide(
//                        width: 0, //边线宽度为2
//                      ),
//                    )
//                ),
//
//                onSubmitted: (text) {
//                  print('change $text');
//                },
//              ),
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                spacing: 8.0, // gap between adjacent chips
                runSpacing: 4.0, // gap between lines
                children: this.randomMnemonic.map((item) => buildItem(item)).toList()
              ),
              SizedBox(
                height: 10.0
              ),
              new CustomButton(
                  content: '清空重试',
                  onSuccessChooseEvent:(res){
                    this._name.text = ""; // 设置初始值
//                    this.randomMnemonicAgain = [];
                    this.setRandomMnemonic();
                  }
              )
            ],
          ),
        )
    );
  }

  //构建每一个助记词
  Widget buildItem(item){
    MediaQueryData mediaQuery = MediaQuery.of(context);
    var _screenWidth = mediaQuery.size.width;
    return Container(
      alignment:  Alignment.center,
      padding: const EdgeInsets.all(8.0), // 四周填充边距32像素
      decoration: new BoxDecoration(
        borderRadius: new BorderRadius.all(new Radius.circular(8.0)),
        color: item['active']? Colors.lightBlue:Colors.grey,
      ),

      width: _screenWidth/4,
      child: GestureDetector(
        onTap: () => this.clickItem(item), //写入方法名称就可以了，但是是无参的
        child: Text(
            item['val'],
            style: new TextStyle(
                fontSize: 18.0,
                color:Colors.white
            )),
      ),

    );
//    return Chip(
//      label: InkWell(
//        onTap: () {
//          this.clickItem(item);
//        },
//        child: Text(item,style: new TextStyle(fontSize: 18.0))
//      )
//    );
  }

  // 点击助记词
  void clickItem(item) async {
    print(item);
//    SharedPreferences prefs = await SharedPreferences.getInstance();
//    String randomMnemonic = prefs.getString("randomMnemonic");
    int index = this.randomMnemonic.indexWhere((element) => element==item);
    setState((){
      //this.randomMnemonicAgain.add(item['val']);
      this.randomMnemonic[index]['active'] = !item['active'];
      //this._name.text = this.randomMnemonicAgain.reduce((a,b)=>(a + " " +b));
      // this.randomMnemonic.remove(item);

    });

    print(this.randomMnemonic.length);
    if (this.randomMnemonic.length > 0) {
      return ;
    }

    if (this._name.text == randomMnemonic) {
      print("助记词备份输入一致");
      // 助记词和私钥在这里加密
      Navigator.of(context).pushNamed('password').then((data){
        this.saveWallet(data);
      });

    } else {
      Navigator.pop(context);
      if (this.randomMnemonic.length == 0) {
        print("助记词点击完毕，但是不一致");
        print(this._name.text);
        print(randomMnemonic);
      }
    }
  }

  void saveWallet(String passWord) async {
    showDialog<Null>(
        context: context, //BuildContext对象
        barrierDismissible: false,
        builder: (BuildContext context) {
          return new LoadingDialog( //调用对话框
            text: '保存钱包...',
          );
        });

    Map obj = {
      'privateKey':  TokenService.getPrivateKey(this._name.text),
      'mnemonic': this._name.text
    };

    int id = await Provider.of<myWallet.Wallet>(context).add(obj,passWord);
    if(id>0) {
      Navigator.of(context).pushReplacementNamed("wallet_success");
    } else {
      this.showSnackbar('钱包保存失败，请反馈给社区');
    }
  }


}
