import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tencentplayer_example/widget/tencent_player_bottom_widget.dart';
import 'package:flutter_tencentplayer_example/widget/tencent_player_gesture_cover.dart';
import 'package:flutter_tencentplayer_example/widget/tencent_player_loading.dart';
import 'package:screen/screen.dart';
import 'package:flutter_tencentplayer/flutter_tencentplayer.dart';
import 'package:flutter_tencentplayer_example/main.dart';
import 'package:flutter_tencentplayer_example/util/forbidshot_util.dart';


class FullVideoPage extends StatefulWidget {
  PlayType playType;
  String dataSource;

  //UI
  bool showBottomWidget;
  bool showClearBtn;


  FullVideoPage({this.showBottomWidget = true, this.showClearBtn = true, this.dataSource, this.playType = PlayType.network});

  @override
  _FullVideoPageState createState() => _FullVideoPageState();
}

class _FullVideoPageState extends State<FullVideoPage> {
  TencentPlayerController controller;
  VoidCallback listener;


  bool isLock = false;
  bool showCover = false;
  Timer timer;
  bool leftRotate = true;


  _FullVideoPageState() {
    listener = () {
      if (!mounted) {
        return;
      }
      setState(() {});
    };

  }

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIOverlays([]);
    _initController();
    controller.initialize();
    controller.addListener(listener);
    hideCover();
    ForbidShotUtil.initForbid(context);
    Screen.keepOn(true);
  }

  @override
  Future dispose() {
    super.dispose();
    SystemChrome.setEnabledSystemUIOverlays([SystemUiOverlay.top, SystemUiOverlay.bottom]);
    controller.removeListener(listener);
    controller.dispose();
    ForbidShotUtil.disposeForbid();
    Screen.keepOn(false);
  }

  _initController() {
    switch (widget.playType) {
      case PlayType.network:
        controller = TencentPlayerController.network(widget.dataSource);
        break;
      case PlayType.asset:
        controller = TencentPlayerController.asset(widget.dataSource);
        break;
      case PlayType.file:
        controller = TencentPlayerController.file(widget.dataSource);
        break;
      case PlayType.fileId:
        controller = TencentPlayerController.network(null, playerConfig: PlayerConfig(auth: {"appId": 1252463788, "fileId": widget.dataSource}));
        break;
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          hideCover();
        },
        onDoubleTap: () {
          if (!widget.showBottomWidget) return;
          if (controller.value.isPlaying) {
            controller.pause();
          } else {
            controller.play();
          }
        },
        child: RotatedBox(
          quarterTurns: leftRotate ? 1 : 3,
          child: Container(
            color: Colors.black,
            child: Stack(
              overflow: Overflow.visible,
              alignment: Alignment.center,
              children: <Widget>[
                /// 视频
                controller.value.initialized
                    ? AspectRatio(
                  aspectRatio: controller.value.aspectRatio,
                  child: TencentPlayer(controller),
                ) : Image.asset('static/place_nodata.png'),
                /// 半透明浮层
                showCover ?Container(color: Color(0x7f000000)) : SizedBox(),
                /// 处理滑动手势
                Offstage(
                  offstage: isLock,
                  child: TencentPlayerGestureCover(
                    controller: controller,
                    showBottomWidget: widget.showBottomWidget,
                    behavingCallBack: delayHideCover,
                  ),
                ),
                /// 加载loading
                TencentPlayerLoading(controller: controller, iconW: 53,),
                /// 头部浮层
                !isLock && showCover ? Positioned(
                  top: 0,
                  left: MediaQuery.of(context).padding.top,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: Container(
                      padding: EdgeInsets.only(top: 34, left: 10),
                      child: Image.asset('static/icon_back.png', width: 20, height: 20, fit: BoxFit.contain, color: Colors.white,
                      ),
                    ),
                  ),
                ) : SizedBox(),
                /// 锁
                showCover ? Align(
                  alignment: Alignment.centerLeft,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      setState(() {
                        isLock = !isLock;
                      });
                      delayHideCover();
                    },
                    child: Container(
                      color: Colors.transparent,
                      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top, right: 20, bottom: 20, left: MediaQuery.of(context).padding.top,),
                      child: Image.asset(isLock ? 'static/player_lock.png' : 'static/player_unlock.png', width: 38, height: 38,),
                    ),
                  ),
                ): SizedBox(),
                ///旋转按钮
                !isLock && showCover ? Align(
                  alignment: Alignment.topRight,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      setState(() {
                        leftRotate = !leftRotate;
                      });
                      delayHideCover();
                    },
                    child: Container(
                      color: Colors.transparent,
                      padding: EdgeInsets.only(top: 34, right: MediaQuery.of(context).padding.top, bottom: 20, left: 20,),
                      child: Image.asset('static/player_rotate.png', width: 25, height: 25,),
                    ),
                  ),
                ): SizedBox(),
                /// 进度、清晰度、速度
                Offstage(
                  offstage: !widget.showBottomWidget,
                  child: Padding(
                    padding: EdgeInsets.only(left: MediaQuery.of(context).padding.top, right: MediaQuery.of(context).padding.bottom),
                    child: TencentPlayerBottomWidget(
                      isShow: !isLock && showCover,
                      controller: controller,
                      showClearBtn: widget.showClearBtn,
                      behavingCallBack: () {
                        delayHideCover();
                      },
                      changeClear: (int index) {
                        changeClear(index);
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),

        ),
      ),
    );
  }

  List<String> clearUrlList = [
    'http://1252463788.vod2.myqcloud.com/95576ef5vodtransgzp1252463788/e1ab85305285890781763144364/v.f10.mp4',
    'http://1252463788.vod2.myqcloud.com/95576ef5vodtransgzp1252463788/e1ab85305285890781763144364/v.f20.mp4',
    'http://1252463788.vod2.myqcloud.com/95576ef5vodtransgzp1252463788/e1ab85305285890781763144364/v.f30.mp4',
  ];

  changeClear(int urlIndex, {int startTime}) {
    controller?.removeListener(listener);
    controller?.pause();
    controller = TencentPlayerController.network(clearUrlList[urlIndex], playerConfig: PlayerConfig(startTime: startTime ?? controller.value.position.inSeconds));
    controller?.initialize().then((_) {
      if (mounted) setState(() {});
    });
    controller?.addListener(listener);
  }


  hideCover() {
    if (!mounted) return;
    setState(() {
      showCover = !showCover;
    });
    delayHideCover();
  }

  delayHideCover() {
    if (timer != null) {
      timer.cancel();
      timer = null;
    }
    if (showCover) {
      timer = new Timer(Duration(seconds: 6), () {
        if (!mounted) return;
        setState(() {
          showCover = false;
        });
      });
    }
  }
}
