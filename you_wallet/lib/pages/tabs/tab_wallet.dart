import 'package:flutter/material.dart';
import 'package:youwallet/service/app_server.dart';
import 'package:youwallet/widgets/addressFormat.dart';
import 'package:youwallet/widgets/tokenList.dart';
import 'package:youwallet/bus.dart';

import 'package:provider/provider.dart';
import 'package:youwallet/model/token.dart';
import 'package:youwallet/model/network.dart';
import 'package:youwallet/model/wallet.dart' as walletModel;
import 'package:youwallet/global.dart';
import 'package:youwallet/widgets/loadingDialog.dart';
import 'package:youwallet/widgets/userMenu.dart';
import 'package:url_launcher/url_launcher.dart';

class TabWallet extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => new Page();
}

class Page extends State<TabWallet> {
  List<Map> tokenArr = [];
  List<Map> wallets = []; // 用户添加的钱包数组
  int current_wallet = 0;
  String current_wallet_address = "";
  String _balance = '0Eth';
  var showNotice = false;
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

//  @override
//  void didUpdateWidget(ContainerPage oldWidget) {
//    super.didUpdateWidget(oldWidget);
//  }

  @override // override是重写父类中的函数
  void initState() {
    super.initState();

    // 监听页面切换，
    eventBus.on<TabChangeEvent>().listen((event) {
      if (event.index == 0) {
        print('tab切换到首页');
        this.checkVersion();
      }
    });

    //监听token列表刷新事件
    eventBus.on<TokenListUpdateEvent>().listen((event) async {
      String address = Provider.of<walletModel.Wallet>(context, listen: false)
          .currentWalletObject['address'];
      // 更新钱包的ETH余额
      Provider.of<walletModel.Wallet>(context, listen: false).updateWallet(address);
      // 更新钱包里面多个token的余额
      Provider.of<Token>(context, listen: false).updateBalance(address);
    });

    //监听版本检查
    eventBus.on<CheckVersion>().listen((event) async {
      showDialog<Null>(
          context: context, //BuildContext对象
          barrierDismissible: false,
          builder: (BuildContext context) {
            return new LoadingDialog(
              text: '版本检查中...',
            );
          });
      String version = await APPService.getVersion();
      Navigator.pop(context);
      Global.showSnackBar(context, '当前最新版：' + version);
    });
  }

  // 页面回退时候触发
  // 切换网络后，当前钱包应该还是存在的，但是钱包的余额需要刷新
  // 钱包是否存在跟网络没有关系，任何一个钱包，可以在任意网络上使用
  @override
  void deactivate() async {
    print('start deactivate');
    var bool = ModalRoute.of(context).isCurrent;
    if (bool) {
      String address = Provider.of<walletModel.Wallet>(context, listen: false)
          .currentWalletObject['address'];
      await Provider.of<walletModel.Wallet>(context, listen: false).updateWallet(address);
    }
  }

  @override
  Widget build(BuildContext context) {
    return layout(context);
  }

  /// 通过Consumer的方式引用共享的token列表
  /// 当token列表中有余额变动后，首页自动更新
  Widget layout(BuildContext context) {
    return new Scaffold(
        appBar: buildAppBar(context),
        body: RefreshIndicator(
          onRefresh: _refresh,
          child: new ListView(
            children: <Widget>[
              buildNotice(context),
              topCard(context),
              listTopBar(context),
              new Container(
                padding: const EdgeInsets.only(
                    left: 16.0, right: 16.0), // 四周填充边距32像素
                child: Consumer<Token>(
                  builder: (context, Token, child) {
                    return tokenList(
                        arr: Token.items,
                        network: Provider.of<Network>(context, listen: false).network,
                        currentWalletObject:
                            Provider.of<walletModel.Wallet>(context, listen: false)
                                .currentWalletObject);
                  },
                ),
              )
            ],
          ),
        ),
        drawer: new UserMenu());
  }

  // 构建AppBar
  // 如何自定义icon来打开draw
  Widget buildAppBar(BuildContext context) {
    return new AppBar(
//          leading: Builder(builder: (content) {
//            return new IconButton(
//                icon: new Icon(Icons.menu, color: Colors.white),
//                onPressed: () {
//                  // Scaffold.of(context).openDrawer();
//                  _scaffoldKey.currentState.openDrawer();
//                }
//            );
//          }) ,
      title: Text(
        'youWallet',
        style: new TextStyle(color: Colors.white),
      ),
      actions: this.appBarActions(),
      backgroundColor: Colors.lightBlue,
      elevation: 0.0,
    );
  }

  // 定义bar右侧的icon按钮
  appBarActions() {
    return <Widget>[
      new Container(
        width: 50.0,
        child: new IconButton(
          icon: new Icon(IconData(0xe61d, fontFamily: 'iconfont'),
              color: Colors.white),
          onPressed: () async {
            String code = await Global.scan(context);
            if (code == null) {
              Global.showSnackBar(context, '扫码结果解析异常');
            }
            List arr = code.split(':');
            if (arr.length == 1) {
              Navigator.pushNamed(context, "scan",
                  arguments: {'res': code, 'allowCopy': true, 'title': '扫码提示'});
            } else {
              if (arr[1] == 'token') {
                Navigator.pushNamed(context, "add_token",
                    arguments: {'address': arr[0]});
              } else if (arr[1] == 'transfer') {
                Global.setToAddress(arr[0]);
                eventBus.fire(TabChangeEvent(3));
              } else {
                // print(code);
                // 如果模式无法匹配，就跳转扫码结果页面，显示扫码内容
                Navigator.pushNamed(context, "scan",
                    arguments: {'res': code, 'allowCopy': true});
              }
            }
          },
        ),
      )
    ];
  }

  // 构建通知卡片
  Widget buildNotice(BuildContext context) {
    if (this.showNotice) {
      return GestureDetector(
          onTap: () async {
            const url = 'https://github.com/youwallet/wallet/releases/';
            await launch(url);
          },
          child: new Container(
            padding: const EdgeInsets.all(16.0),
            color: Color(0xffA9DFED),
            child: new Text('新版本已发布，点击立即下载'),
          ));
    } else {
      return new Container();
    }
  }

  // 构建顶部卡片
  Widget topCard(BuildContext context) {
    return new Container(
      padding: const EdgeInsets.all(16.0), // 四周填充边距32像素
      //margin: const EdgeInsets.all(16.0),
      alignment: Alignment.center,
      decoration: new BoxDecoration(
        color: Colors.lightBlue,
//          image: DecorationImage(
//            image: AssetImage(
//                "images/homebk.png",
//            ),
//            fit: BoxFit.fill
//          ),
      ),
      child: Consumer<walletModel.Wallet>(
        builder: (context, Wallet, child) {
          return new Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                new Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        new Text(
                            Wallet.currentWalletObject['name'].length == 0
                                ? 'Account${Wallet.currentWalletObject['id']}'
                                : Wallet.currentWalletObject['name'],
                            // Wallet.currentWalletObject['name']??'--',
                            style: new TextStyle(
                                color: Colors.white, fontSize: 24.0)),
                        new IconButton(
                          icon: Icon(IconData(0xe600, fontFamily: 'iconfont'),
                              color: Colors.white),
                          onPressed: () {
                            eventBus.fire(TabChangeEvent(2));
                          },
                        ),
                      ],
                    ),
                    new IconButton(
                      icon: new Icon(Icons.settings, color: Colors.white),
                      onPressed: () {
                        Navigator.pushNamed(context, "manage_wallet");
                      },
                    ),
                  ],
                ),
                new AddressFormat(Wallet.currentWallet),
                new Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    new Text(''),
                    new Text(Wallet.currentWalletObject['balance'] + 'ETH',
                        style:
                            new TextStyle(fontSize: 32.0, color: Colors.white)),
                  ],
                ),
              ]);
        },
      ),
    );
  }

  // 构建列表的表头菜单
  Widget listTopBar(BuildContext context) {
    return new Container(
        color: Colors.lightBlue,
        child: Container(
          padding: const EdgeInsets.only(
              left: 16.0, right: 16.0, top: 16.0, bottom: 4.0),
          decoration: new BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
                topLeft: Radius.circular(30), topRight: Radius.circular(30)),
          ),
          child: new Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              new Text(
                'Token',
                style:
                    new TextStyle(fontWeight: FontWeight.w900, fontSize: 16.0),
              ),
              GestureDetector(
                child: new Icon(Icons.add_circle_outline),
                onTap: () {
                  Navigator.pushNamed(context, "add_token", arguments: {});
                },
              )
            ],
          ),
        ));
  }

  // 检查新版本
  Future<void> checkVersion() async {
    String version = await APPService.getVersion();
    if (version != Global.version) {
      this.setState(() {
        this.showNotice = true;
      });
    } else {
      this.setState(() {
        this.showNotice = false;
      });
    }
  }

  // 首页下拉刷新
  // 刷新钱包的ETH余额
  // 刷新每个token的余额
  Future<void> _refresh() async {
    showDialog<Null>(
        context: context, //BuildContext对象
        barrierDismissible: false,
        builder: (BuildContext context) {
          return new LoadingDialog(
            //调用对话框
            text: '刷新中...',
          );
        });
    String address =
        Provider.of<walletModel.Wallet>(context, listen: false).currentWalletObject['address'];
    // 更新钱包的ETH余额
    await Provider.of<walletModel.Wallet>(context, listen: false).updateWallet(address);
    // 更新钱包里面多个token的余额
    await Provider.of<Token>(context, listen: false).updateBalance(address);
    final snackBar = new SnackBar(content: new Text('刷新结束'));
    Scaffold.of(context).showSnackBar(snackBar);
    Navigator.pop(context);
  }
}
