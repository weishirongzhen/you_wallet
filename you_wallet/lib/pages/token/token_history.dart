import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart';
import 'package:web3dart/json_rpc.dart';
import 'package:youwallet/widgets/menu.dart';
import 'package:youwallet/db/sql_util.dart';
import 'package:common_utils/common_utils.dart';
import 'package:youwallet/bus.dart';
import 'package:youwallet/service/trade.dart';

class TokenHistory extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return new Page();
  }
}

class Page extends State<TokenHistory> {
  List list = [];
  int today = 0;
  int threeDay = 0;
  int weekday = 0;
  int month = 0;

  @override
  Widget build(BuildContext context) {
    return layout(context);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    this.initFilter();
    this._getHistory();
    print(DateTime.now().day);
  }

  void initFilter() {
    int now = DateTime.now().millisecondsSinceEpoch;
    int hour = DateTime.now().hour;
    int minute = DateTime.now().minute;
    int second = DateTime.now().second;
    int today = now - (hour * 60 * 60 + minute * 60 + second) * 1000;
    int threeDay = today - 3 * 24 * 60 * 60 * 1000;
    int weekday = today - (DateTime.now().weekday - 1) * 24 * 60 * 60 * 1000;
    int month = today - (DateTime.now().day - 1) * 24 * 60 * 60 * 1000;
    print(today);
    print(threeDay);
    print(weekday);
    this.setState(() {
      today = today;
      threeDay = threeDay;
      weekday = weekday;
      month = month;
    });
  }

  Widget layout(BuildContext context) {
    return DefaultTabController(
        length: 5,
        child: new Scaffold(
          appBar: buildAppBar(context),
          body: new TabBarView(
            children: [
              _getHistoryToken('all'),
              _getHistoryToken('today'),
              _getHistoryToken('three'),
              _getHistoryToken('week'),
              _getHistoryToken('month')
            ],
          ),
          bottomNavigationBar: new BottomAppBar(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Expanded(
                  child: new SizedBox(
                    height: 50.0,
                    child: RaisedButton.icon(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(0))),
                      elevation: 0,
                      icon: Icon(IconData(0xe6eb, fontFamily: 'iconfont')),
                      label: Text(
                        "??????",
                      ),
                      onPressed: () {
                        eventBus.fire(TabChangeEvent(1));
                        Navigator.of(context).pop();
                      },
                    ),
                  ),
                  flex: 1,
                ),
                Expanded(
                  child: new SizedBox(
                    height: 50.0,
                    child: RaisedButton.icon(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(0))),
                      elevation: 0.0,
                      icon: Icon(IconData(0xe624, fontFamily: 'iconfont'),
                          color: Colors.white),
                      color: Colors.blue,
                      highlightColor: Colors.blue,
                      splashColor: Colors.blue,
                      label:
                          Text("??????", style: new TextStyle(color: Colors.white)),
                      onPressed: () {
                        eventBus.fire(TabChangeEvent(2));
                        Navigator.of(context).pop();
                      },
                    ),
                  ),
                  flex: 1,
                ),
                Expanded(
                  child: new SizedBox(
                    height: 50.0,
                    child: RaisedButton.icon(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(0))),
                      elevation: 0,
                      icon: Icon(IconData(0xe616, fontFamily: 'iconfont'),
                          color: Colors.white),
                      label:
                          Text("??????", style: new TextStyle(color: Colors.white)),
                      color: Colors.green,
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                  ),
                  flex: 1,
                ),
              ],
            ),
          ),
        ));
  }

  // ??????app bar
  Widget buildAppBar(BuildContext context) {
    return new AppBar(
        backgroundColor: Colors.white,
        title: new Text('????????????'),
        bottom: new TabBar(
          tabs: [
            new Tab(text: '??????'),
            new Tab(text: '??????'),
            new Tab(text: '??????'),
            new Tab(text: '??????'),
            new Tab(text: '??????')
          ],
        )
        //leading: new Icon(Icons.account_balance_wallet),
        );
  }

  // ??????????????????
  // timestamp ???????????????????????????
  // ????????????
  _getHistoryToken(String para) {
    int timestamp = 0;
    int now = DateTime.now().millisecondsSinceEpoch;
    int hour = DateTime.now().hour;
    int minute = DateTime.now().minute;
    int second = DateTime.now().second;
    int today = now - (hour * 60 * 60 + minute * 60 + second) * 1000;
    if (para == 'three') {
      timestamp = today - 3 * 24 * 60 * 60 * 1000;
    } else if (para == 'week') {
      timestamp = today - (DateTime.now().weekday - 1) * 24 * 60 * 60 * 1000;
    } else if (para == 'month') {
      timestamp = today - (DateTime.now().day - 1) * 24 * 60 * 60 * 1000;
    } else if (para == 'today') {
      timestamp = now - (hour * 60 * 60 + minute * 60 + second) * 1000;
    } else {
      timestamp = 0;
    }
    List arr = List.from(this.list);
    arr.retainWhere((e) => (int.parse(e['createTime']) > timestamp));

    return new Container(
      padding: new EdgeInsets.all(16.0),
      child: new ListView(
          children: arr.reversed.map((item) => _buildToken(item)).toList()),
    );
  }

  Widget _buildToken(item) {
    String date = DateUtil.formatDateMs(int.parse(item['createTime']),
        format: "yyyy-MM-dd HH:mm:ss");
    return new Container(
        padding: const EdgeInsets.only(top: 12.0, bottom: 12.0), // ??????????????????32??????
        decoration: new BoxDecoration(
            border:
                Border(bottom: BorderSide(color: Colors.black12, width: 1.0))),
        child: GestureDetector(
          child: new Column(
            children: <Widget>[
              new Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  new Text('??????-${item['tokenName']}'),
                  new Text('-${item['num']} token',
                      style: new TextStyle(color: Colors.lightBlue))
                ],
              ),
              new Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  new Text('${date}',
                      style: new TextStyle(color: Colors.black38)),
                  new Text('${item['status'] ?? '?????????'}',
                      style: new TextStyle(color: Colors.deepOrange))
                ],
              ),
            ],
          ),
          onTap: () {
            print(item);
            Navigator.pushNamed(context, "order_detail", arguments: item);
          },
        ));
  }

  void _getHistory() async {
    var sql = SqlUtil.setTable("transfer");
    List arr = await sql.get();
    setState(() {
      this.list = arr;
    });
    print(arr);
//    this.list.forEach((item) async {
//      print('????????????${item}');
//      if(item['status'] == null && item['txnHash'].length == 66) {
//
//        Map blockHash = await Trade.getTransactionByHash(item['txnHash']);
//        print('????????????, ?????????blockHash=>${blockHash}');
//        if(blockHash['blockHash'] != null) {
//          await this.updateTransferStatus(item['txnHash']);
//        } else {
//          print('blockHash???null');
//        }
//      } else {
//        print('????????????????????????????????????null??????hash?????????????????????');
//      }
//    });
  }

  Future<void> updateTransferStatus(String txnHash) async {
    print('????????????????????? =??? ${txnHash}');
    var sql = SqlUtil.setTable("transfer");
    int i = await sql.update({'status': '??????'}, 'txnHash', txnHash);
    print('????????????=???${i}');
  }
}
