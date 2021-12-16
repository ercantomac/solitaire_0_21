// ignore_for_file: must_be_immutable
import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:solitaire_0_21/colors.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:audioplayers/audioplayers.dart';

void main() {
  //Paint.enableDithering = true;
  WidgetsFlutterBinding.ensureInitialized();
  MobileAds.instance.initialize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);
  static Color _mainColor = MyColors.dark, _mediumColor = MyColors.mediumDark, _complementColor = MyColors.light;
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Solitaire 0 - 21',
      color: _mainColor,
      darkTheme: ThemeData(
        primaryColor: _mainColor,
        primaryColorDark: _mainColor,
        primaryColorBrightness: Brightness.dark,
        brightness: Brightness.dark,
        fontFamily: 'Quicksand',
      ),
      themeMode: ThemeMode.dark,
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);
  static bool _locked = false;
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with TickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final AudioCache _player = AudioCache();
  late SharedPreferences _sp;
  @override
  void initState() {
    super.initState();
    _getLevel();
    for (int i = 0; i < 10; i++) {
      for (int j = 0; j < 8; j++) {
        _numbers[i].add(_rightNumbers[i][j]);
        _numbers[i].add(_leftNumbers[i][j]);
      }
    }
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 200), reverseDuration: const Duration(milliseconds: 300));
    _controller.addStatusListener((AnimationStatus status) {
      if (status == AnimationStatus.completed) {
        _controller.reverse();
      }
    });
    _startUpAnimation = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    for (int i = 0; i < 16; i++) {
      _animationControllers.add(AnimationController(vsync: this, duration: const Duration(milliseconds: 1600)));
    }
    WidgetsBinding.instance!.addPostFrameCallback((Duration timeStamp) {
      _player.play('starting.mp3');
      _startUpAnimation.forward();
      Timer(const Duration(milliseconds: 1400), () {
        if (_maxLevel == 0) {
          showGeneralDialog(
              context: context,
              barrierDismissible: false,
              barrierColor: Colors.transparent,
              transitionDuration: const Duration(milliseconds: 500),
              transitionBuilder: (BuildContext context, Animation<double> anim1, Animation<double> anim2, Widget child) {
                return BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: (16.8) * anim1.value, sigmaY: (16.8) * anim1.value),
                  child: FadeTransition(
                    opacity: Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: anim1, curve: Curves.easeInOutCubic)),
                    child: child,
                  ),
                );
              },
              pageBuilder: (BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) {
                return BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 16.8, sigmaY: 16.8),
                  child: AlertDialog(
                    elevation: 0.0,
                    backgroundColor: Colors.transparent,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
                    insetPadding: EdgeInsets.zero,
                    content: RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        text: 'Keep the sum between ',
                        style: TextStyle(
                          fontFamily: 'Quicksand',
                          fontSize: 40.0,
                          color: MyApp._complementColor,
                        ),
                        children: const <TextSpan>[
                          TextSpan(text: '0', style: TextStyle(fontFamily: 'Quicksand', color: MyColors.orangered)),
                          TextSpan(text: ' and '),
                          TextSpan(text: '21.', style: TextStyle(fontFamily: 'Quicksand', color: MyColors.orangered)),
                        ],
                      ),
                    ),
                  ),
                );
              });
          Timer(const Duration(milliseconds: 2800), () {
            Navigator.of(context).pop();
          });
        }
        setState(() {
          MyHomePage._locked = false;
        });
      });
    });
  }

  @override
  void dispose() {
    super.dispose();
    _total.dispose();
    _coins.dispose();
    _controller.dispose();
    _startUpAnimation.dispose();
    for (int i = 0; i < _animationControllers.length; i++) {
      _animationControllers[i].dispose();
    }
  }

  void _changeTheme() {
    setState(() {
      MyApp._mainColor = ((MyApp._mainColor == MyColors.dark) ? MyColors.light : MyColors.dark);
      MyApp._mediumColor = ((MyApp._mediumColor == MyColors.mediumDark) ? MyColors.mediumLight : MyColors.mediumDark);
      MyApp._complementColor = ((MyApp._complementColor == MyColors.light) ? MyColors.dark : MyColors.light);
    });
  }

  void _getLevel() async {
    _sp = await SharedPreferences.getInstance();
    if (_sp.getInt('level') != null) {
      _level = _sp.getInt('level')!;
    } else {
      _level = 0;
    }
    if (_sp.getInt('maxLevel') != null) {
      _maxLevel = _sp.getInt('maxLevel')!;
    } else {
      _maxLevel = 0;
    }
    if (_sp.getInt('coins') != null) {
      _coins.value = _sp.getInt('coins')!;
    }
    setState(() {});
  }

  void _loadAd(int type) {
    InterstitialAd.load(
        //adUnitId: 'ca-app-pub-7651255833293298/8486287733',
        adUnitId: 'ca-app-pub-3940256099942544/1033173712',
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (InterstitialAd ad) {
            ad.fullScreenContentCallback = FullScreenContentCallback<InterstitialAd>(
              onAdShowedFullScreenContent: (InterstitialAd ad) {},
              onAdDismissedFullScreenContent: (InterstitialAd ad) {
                ad.dispose();
                if (type == 0) {
                  Navigator.of(context).pushReplacement(MyRoute(builder: (BuildContext context) => const MyHomePage()));
                } else if (type == 1) {
                  _isFailed = true;
                  _coins.value -= 250;
                  _sp.setInt('coins', _coins.value);
                  _total.value = 10;
                  setState(() {
                    MyHomePage._locked = false;
                  });
                }
              },
              onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError error) {
                ad.dispose();
              },
              onAdImpression: (InterstitialAd ad) {},
            );
            ad.show();
          },
          onAdFailedToLoad: (LoadAdError error) {},
        ));
  }

  void _loadBonusAd(String type) {
    InterstitialAd.load(
        //adUnitId: 'ca-app-pub-7651255833293298/8486287733',
        adUnitId: 'ca-app-pub-3940256099942544/1033173712',
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (InterstitialAd ad) {
            ad.fullScreenContentCallback = FullScreenContentCallback<InterstitialAd>(
              onAdShowedFullScreenContent: (InterstitialAd ad) {},
              onAdDismissedFullScreenContent: (InterstitialAd ad) {
                ad.dispose();
                Timer(const Duration(milliseconds: 150), () {
                  if (type == 'MIN') {
                    _isMined = true;
                    _total.value = 1;
                  } else if (type == 'MAX') {
                    _isMaxed = true;
                    _total.value = 20;
                  } else if (type == 'RESET') {
                    _isReset = true;
                    _total.value = 10;
                  }
                  _coins.value -= ((type == 'RESET') ? 150 : 75);
                  _sp.setInt('coins', _coins.value);
                  setState(() {});
                  _controller.forward();
                });
              },
              onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError error) {
                ad.dispose();
              },
              onAdImpression: (InterstitialAd ad) {},
            );
            ad.show();
          },
          onAdFailedToLoad: (LoadAdError error) {},
        ));
  }

  void tapHandler(int _index, Alignment _state, double _padding, String _number, AnimationController _animation) {
    setState(() {
      MyHomePage._locked = true;
    });
    HapticFeedback.selectionClick();
    _player.play('card_pick.mp3');
    if (_index != _states.length - 1) {
      _states.removeAt(_index);
      _paddings.removeAt(_index);
      _numbers[_level].removeAt(_index);
      _animationControllers.removeAt(_index);
      _states.add(_state);
      _paddings.add(_padding);
      _numbers[_level].add(_number);
      _animationControllers.add(_animation);
      setState(() {});
    }
  }

  void tapHandler2() {
    Timer(const Duration(milliseconds: 1300), () {
      int _temp = int.parse((_numbers[_level][(_numbers[_level].length - 1)]));
      _states.removeLast();
      _paddings.removeLast();
      _animationControllers.removeLast();
      _numbers[_level].removeLast();
      _controller.forward();
      Timer(const Duration(milliseconds: 250), () {
        _sum(_temp);
      });
    });
  }

  void _sum(int _no) {
    if ((_total.value + _no) > 18 && (_total.value + _no) > _total.value && (_total.value + _no) < 21) {
      _player.play('warning.mp3');
      HapticFeedback.mediumImpact();
    } else if ((_total.value + _no) < 3 && (_total.value + _no) < _total.value && (_total.value + _no) > 0) {
      _player.play('warning.mp3');
      HapticFeedback.mediumImpact();
    }
    _total.value += _no;
    if (_total.value >= 21 || _total.value < 1 || _states.isEmpty == true) {
      setState(() {});
      if (_states.isEmpty == true) {
        _player.play('WIN3.mp3');
        if ((_level + 1) < 10) {
          _sp.setInt('level', (_level + 1));
          if (_maxLevel < (_level + 1)) {
            _sp.setInt('maxLevel', (_level + 1));
          }
          if (_level == _maxLevel) {
            _sp.setInt('coins', (_coins.value + 200));
          }
        } else {
          //FINISHED THE GAME
          _sp.remove('level');
        }
      } else {
        HapticFeedback.heavyImpact();
        _player.play('LOSE.wav');
        //LEVEL FAILED
      }
      Timer(const Duration(milliseconds: 800), () {
        if (_states.isNotEmpty == true) {
          if (_isFailed == false && _coins.value >= 250) {
            _continueFailed();
          } else {
            _startUpAnimation.reverse();
            Timer(const Duration(milliseconds: 1200), () {
              Navigator.of(context).pushReplacement(MyRoute(builder: (BuildContext context) => const MyHomePage()));
            });
          }
        } else {
          _startUpAnimation.reverse();
          Timer(const Duration(milliseconds: 1600), () {
            _loadAd(0);
          });
        }
      });
    } else {
      setState(() {
        MyHomePage._locked = false;
      });
    }
  }

  final List<AnimationController> _animationControllers = <AnimationController>[];
  final List<Alignment> _states = <Alignment>[
    Alignment.topRight,
    Alignment.topLeft,
    Alignment.topRight,
    Alignment.topLeft,
    Alignment.topRight,
    Alignment.topLeft,
    Alignment.topRight,
    Alignment.topLeft,
    Alignment.topRight,
    Alignment.topLeft,
    Alignment.topRight,
    Alignment.topLeft,
    Alignment.topRight,
    Alignment.topLeft,
    Alignment.topRight,
    Alignment.topLeft
  ];
  final List<double> _paddings = <double>[12.0, 12.0, 18.0, 18.0, 24.0, 24.0, 30.0, 30.0, 36.0, 36.0, 42.0, 42.0, 48.0, 48.0, 54.0, 54.0];
  final List<List<String>> _numbers = <List<String>>[
        <String>[],
        <String>[],
        <String>[],
        <String>[],
        <String>[],
        <String>[],
        <String>[],
        <String>[],
        <String>[],
        <String>[]
      ],
      _leftNumbers = <List<String>>[
        <String>['+2', '+1', '+4', '-3', '+5', '-2', '+7', '+2'],
        <String>['-3', '+5', '+4', '-2', '-4', '-6', '+7', '-5'],
        <String>['-1', '+3', '-6', '-2', '+2', '-4', '+1', '-5'],
        <String>['+5', '-3', '-1', '-2', '+3', '-6', '-7', '+5'],
        <String>['+4', '+3', '+2', '-5', '+3', '-4', '+2', '+6'],
        <String>['-7', '+1', '-2', '-6', '-3', '-3', '+2', '+5'],
        <String>['+5', '+1', '-2', '-1', '+3', '-4', '+2', '+7'],
        <String>['+3', '-7', '+1', '-6', '-2', '+4', '+5', '-6'],
        <String>['+2', '+6', '-1', '-7', '+3', '+7', '+5', '+1'],
        <String>['-7', '+2', '+3', '-6', '-5', '+1', '+4', '-3']
      ],
      _rightNumbers = <List<String>>[
        <String>['-5', '+2', '-7', '-2', '-2', '-1', '-4', '+3'],
        <String>['-1', '-3', '-7', '+5', '+7', '-5', '+6', '+2'],
        <String>['-2', '+4', '-1', '+5', '+1', '-3', '+6', '+2'],
        <String>['-4', '-7', '+7', '-5', '-5', '+3', '-1', '+2'],
        <String>['-6', '+4', '-2', '-6', '-4', '-3', '+2', '+5'],
        <String>['-3', '+1', '-2', '-5', '-6', '+3', '-5', '+6'],
        <String>['-3', '+4', '-2', '-7', '+5', '-1', '+2', '+7'],
        <String>['-2', '-4', '-5', '+6', '-3', '-7', '-1', '+6'],
        <String>['+3', '-7', '-5', '-1', '-2', '-6', '+1', '+7'],
        <String>['+5', '-1', '+5', '+3', '+7', '-7', '-3', '+6']
      ];
  final ValueNotifier<int> _total = ValueNotifier<int>(10), _coins = ValueNotifier<int>(500);
  late AnimationController _controller, _startUpAnimation;
  late int _level, _maxLevel;
  late bool _isFailed = false, _isMaxed = false, _isMined = false, _isReset = false;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: MyApp._mainColor,
      appBar: AppBar(
        titleSpacing: 0.0,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            IconButton(
              icon: Icon(
                (MyApp._mainColor == MyColors.dark) ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
                color: MyApp._complementColor,
              ),
              onPressed: () {
                HapticFeedback.selectionClick();
                _player.play('theme_switch.mp3');
                _changeTheme();
              },
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(
                  Icons.attach_money,
                  size: 18.0,
                  color: MyApp._complementColor,
                ),
                ValueListenableBuilder<int>(
                  valueListenable: _coins,
                  builder: (BuildContext context, int value, Widget? child) {
                    return Text(
                      value.toString(),
                      style: TextStyle(
                        fontSize: 16.0,
                        color: MyApp._complementColor,
                      ),
                    );
                  },
                ),
              ],
            ),
            ButtonTheme(
              alignedDropdown: true,
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: _level,
                  icon: Icon(
                    Icons.arrow_drop_down,
                    color: MyApp._complementColor,
                  ),
                  dropdownColor: MyApp._mediumColor,
                  borderRadius: const BorderRadius.all(Radius.circular(12.0)),
                  onChanged: (int? newValue) {
                    if (newValue! != _level) {
                      _sp.setInt('level', newValue);
                      Navigator.of(context).pushReplacement(MyRoute(builder: (BuildContext context) => const MyHomePage()));
                    }
                  },
                  items: <int>[0, 1, 2, 3, 4, 5, 6, 7, 8, 9].map<DropdownMenuItem<int>>((int value) {
                    return DropdownMenuItem<int>(
                      value: value,
                      enabled: (value <= _maxLevel),
                      alignment: AlignmentDirectional.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: <Widget>[
                          if (value > _maxLevel)
                            Icon(
                              Icons.lock_outline,
                              color: Colors.grey.shade600,
                            ),
                          Text(
                            'LEVEL ${value + 1}',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: (((value == _level)
                                  ? MyColors.blue
                                  : (value <= _maxLevel)
                                      ? MyApp._complementColor
                                      : Colors.grey.shade600)),
                              fontWeight: (value == _level) ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            IconButton(
              onPressed: () {
                showGeneralDialog(
                    context: _scaffoldKey.currentContext!,
                    barrierDismissible: false,
                    barrierColor: Colors.transparent,
                    transitionDuration: const Duration(milliseconds: 500),
                    transitionBuilder: (BuildContext context, Animation<double> anim1, Animation<double> anim2, Widget child) {
                      return BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: (16.8) * anim1.value, sigmaY: (16.8) * anim1.value),
                        child: FadeTransition(
                          opacity: Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: anim1, curve: Curves.easeInOutCubic)),
                          child: child,
                        ),
                      );
                    },
                    pageBuilder: (BuildContext context2, Animation<double> animation, Animation<double> secondaryAnimation) {
                      return BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 16.8, sigmaY: 16.8),
                        child: AlertDialog(
                          elevation: 0.0,
                          backgroundColor: Colors.transparent,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
                          insetPadding: EdgeInsets.zero,
                          content: Text(
                            'Restart level ${_level + 1}?\n\n',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Quicksand',
                              fontSize: 30.0,
                              color: MyApp._complementColor,
                            ),
                          ),
                          actionsPadding: EdgeInsets.zero,
                          actions: <Row>[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: <GestureDetector>[
                                GestureDetector(
                                  onTap: () {
                                    Navigator.of(context).pop();
                                  },
                                  child: Text(
                                    'CANCEL',
                                    style: TextStyle(
                                      fontSize: 20.0,
                                      color: MyApp._complementColor,
                                    ),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    Navigator.of(context).pop();
                                    Timer(const Duration(milliseconds: 500), () {
                                      Navigator.of(context).pushReplacement(MyRoute(builder: (BuildContext context) => const MyHomePage()));
                                    });
                                  },
                                  child: Text(
                                    'OK',
                                    style: TextStyle(
                                      fontSize: 20.0,
                                      color: MyApp._complementColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    });
              },
              icon: Icon(
                Icons.restart_alt,
                color: MyApp._complementColor,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0.0,
        systemOverlayStyle: (MyApp._mediumColor == MyColors.mediumDark)
            ? SystemUiOverlayStyle.light.copyWith(
                statusBarColor: Colors.transparent,
                systemNavigationBarColor: Colors.transparent,
              )
            : SystemUiOverlayStyle.dark.copyWith(
                statusBarColor: Colors.transparent,
                systemNavigationBarColor: Colors.transparent,
              ),
      ),
      body: Container(
        padding: const EdgeInsets.fromLTRB(24.0, 12.0, 24.0, 24.0),
        child: Stack(
          children: <Widget>[
            RepaintBoundary(
              key: const ValueKey<int>(63),
              child: Container(
                alignment: Alignment.topCenter,
                height: 180.0,
                child: Center(
                  child: AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 1600),
                    curve: Curves.fastOutSlowIn,
                    style: TextStyle(
                      fontFamily: 'Quicksand',
                      fontSize: 42.0,
                      color: (_states.isEmpty == true) ? MyColors.blue : Colors.transparent,
                    ),
                    child: Text(
                      'Good Job!\nLevel ${_level + 1} Completed.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ),
            RepaintBoundary(
              key: const ValueKey<int>(150),
              child: SizeTransition(
                axisAlignment: -1.0,
                sizeFactor: Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _startUpAnimation, curve: Curves.decelerate)),
                child: Align(
                  alignment: Alignment.bottomRight,
                  child: GestureDetector(
                    onTap: () {
                      if (MyHomePage._locked != true && _coins.value >= 150 && _isReset == false) {
                        if (_total.value == 10) {
                          _controller.forward();
                        } else {
                          _watchAdPrompt('RESET');
                        }
                      }
                    },
                    child: Container(
                      key: const ValueKey<String>('resetBonusCard'),
                      width: 42.85,
                      height: 75.0,
                      decoration: ShapeDecoration(
                        shape: RoundedRectangleBorder(
                          borderRadius: const BorderRadius.all(Radius.circular(8.0)),
                          side: BorderSide(color: (_isReset == false && _coins.value >= 150) ? MyColors.blue : Colors.grey.shade600),
                        ),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Icon(
                              Icons.arrow_downward,
                              color: (_isReset == false && _coins.value >= 150) ? MyColors.blue : Colors.grey.shade600,
                            ),
                            Icon(
                              Icons.arrow_upward,
                              color: (_isReset == false && _coins.value >= 150) ? MyColors.blue : Colors.grey.shade600,
                            ),
                            const SizedBox(height: 4.0),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                Icon(
                                  Icons.attach_money,
                                  size: 14.0,
                                  color: (_isReset == false && _coins.value >= 150) ? MyApp._complementColor : Colors.grey.shade600,
                                ),
                                Text(
                                  '150',
                                  style: TextStyle(
                                    fontSize: 12.0,
                                    color: (_isReset == false && _coins.value >= 150) ? MyApp._complementColor : Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            RepaintBoundary(
              key: const ValueKey<int>(151),
              child: SizeTransition(
                axisAlignment: -1.0,
                sizeFactor: Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _startUpAnimation, curve: Curves.decelerate)),
                child: Align(
                  alignment: Alignment.bottomLeft,
                  child: GestureDetector(
                    onTap: () {
                      if (MyHomePage._locked != true && _coins.value >= 75 && _isMined == false) {
                        if (_total.value == 1) {
                          _controller.forward();
                        } else {
                          _watchAdPrompt('MIN');
                        }
                      }
                    },
                    child: Container(
                      key: const ValueKey<String>('minBonusCard'),
                      width: 42.85,
                      height: 75.0,
                      decoration: ShapeDecoration(
                        shape: RoundedRectangleBorder(
                          borderRadius: const BorderRadius.all(Radius.circular(8.0)),
                          side: BorderSide(color: (_isMined == false && _coins.value >= 75) ? MyColors.blue : Colors.grey.shade600),
                        ),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Icon(
                              Icons.arrow_downward,
                              color: (_isMined == false && _coins.value >= 75) ? MyColors.blue : Colors.grey.shade600,
                            ),
                            Text(
                              'MIN',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16.0,
                                color: (_isMined == false && _coins.value >= 75) ? MyColors.blue : Colors.grey.shade600,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4.0),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                Icon(
                                  Icons.attach_money,
                                  size: 14.0,
                                  color: (_isMined == false && _coins.value >= 75) ? MyApp._complementColor : Colors.grey.shade600,
                                ),
                                Text(
                                  '75',
                                  style: TextStyle(
                                    fontSize: 12.0,
                                    color: (_isMined == false && _coins.value >= 75) ? MyApp._complementColor : Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            RepaintBoundary(
              key: const ValueKey<int>(152),
              child: SizeTransition(
                axisAlignment: -1.0,
                sizeFactor: Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _startUpAnimation, curve: Curves.decelerate)),
                child: Align(
                  alignment: Alignment.bottomLeft,
                  child: GestureDetector(
                    onTap: () {
                      if (MyHomePage._locked != true && _coins.value >= 75 && _isMaxed == false) {
                        if (_total.value == 20) {
                          _controller.forward();
                        } else {
                          _watchAdPrompt('MAX');
                        }
                      }
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 85.0),
                      key: const ValueKey<String>('maxBonusCard'),
                      width: 42.85,
                      height: 75.0,
                      decoration: ShapeDecoration(
                        shape: RoundedRectangleBorder(
                          borderRadius: const BorderRadius.all(Radius.circular(8.0)),
                          side: BorderSide(color: (_isMaxed == false && _coins.value >= 75) ? MyColors.blue : Colors.grey.shade600),
                        ),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Text(
                              'MAX',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16.0,
                                color: (_isMaxed == false && _coins.value >= 75) ? MyColors.blue : Colors.grey.shade600,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Icon(
                              Icons.arrow_upward,
                              color: (_isMaxed == false && _coins.value >= 75) ? MyColors.blue : Colors.grey.shade600,
                            ),
                            const SizedBox(height: 4.0),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                Icon(
                                  Icons.attach_money,
                                  size: 14.0,
                                  color: (_isMaxed == false && _coins.value >= 75) ? MyApp._complementColor : Colors.grey.shade600,
                                ),
                                Text(
                                  '75',
                                  style: TextStyle(
                                    fontSize: 12.0,
                                    color: (_isMaxed == false && _coins.value >= 75) ? MyApp._complementColor : Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            for (int i = 0; i < _states.length; i++)
              BuildCards(_states[i], _paddings[i], i, _numbers[_level][i], _animationControllers[i], _startUpAnimation, tapHandler, tapHandler2,
                  ((i != (_states.length - 1)) ? const Duration(milliseconds: 60) : Duration.zero), MyApp._mediumColor, (i == _states.lastIndexOf(_states[i]))),
            RepaintBoundary(
              key: const ValueKey<int>(42),
              child: SlideTransition(
                key: const ValueKey<String>('sumCardSlide'),
                position: Tween<Offset>(begin: const Offset(0.0, 0.55), end: Offset.zero)
                    .animate(CurvedAnimation(parent: _startUpAnimation, curve: Curves.easeInOutCubic)),
                child: ValueListenableBuilder<int>(
                  key: const ValueKey<String>('sumCardValue'),
                  valueListenable: _total,
                  builder: (BuildContext context, int value, Widget? child) {
                    return Align(
                      alignment: Alignment.bottomCenter,
                      child: AnimatedBuilder(
                        animation: _controller,
                        builder: (BuildContext context, Widget? child) {
                          return Transform.scale(
                            scale: Tween<double>(begin: 1.0, end: 0.97)
                                .animate(
                                    CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic, reverseCurve: /*Curves.easeInBack*/ Curves.decelerate))
                                .value,
                            child: AnimatedContainer(
                              key: const ValueKey<String>('sumCard3'),
                              duration: const Duration(milliseconds: 800),
                              curve: Curves.easeInOutCubic,
                              width: 102.8,
                              height: 180.0,
                              decoration: ShapeDecoration(
                                color: ((value > 15 && value <= 18) || (value >= 3 && value <= 5))
                                    ? MyApp._complementColor
                                    : ((value > 18 && value < 21) || (value < 3 && value >= 1))
                                        ? MyColors.gold
                                        : (value >= 21 || value < 1)
                                            ? MyColors.orangered
                                            : MyColors.blue,
                                /*gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: <Color>[
                                    //Colors.white10,
                                    Colors.transparent,
                                    Colors.black12
                                  ],
                                ),*/
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.all(Radius.circular(20.0)),
                                  /*side: ((value > 15 && value <= 18) || (value >= 3 && value <= 5))
                                      ? const BorderSide(color: MyColors.light)
                                      : ((value > 18 && value < 21) || (value < 3 && value >= 1))
                                          ? const BorderSide(color: MyColors.gold)
                                          : (value >= 21 || value < 1)
                                              ? const BorderSide(color: MyColors.orangered)
                                              : const BorderSide(color: MyColors.blue),*/
                                ),
                                shadows: <BoxShadow>[
                                  ((value > 15 && value <= 18) || (value >= 3 && value <= 5))
                                      ? BoxShadow(
                                          blurRadius: 36.0,
                                          spreadRadius: 18.0,
                                          color: MyApp._complementColor.withOpacity(0.27),
                                        )
                                      : ((value > 18 && value < 21) || (value < 3 && value >= 1))
                                          ? BoxShadow(
                                              blurRadius: 36.0,
                                              spreadRadius: 18.0,
                                              color: MyColors.gold.withOpacity(0.27),
                                            )
                                          : (value >= 21 || value < 1)
                                              ? BoxShadow(
                                                  blurRadius: 36.0,
                                                  spreadRadius: 18.0,
                                                  color: MyColors.orangered.withOpacity(0.27),
                                                )
                                              : BoxShadow(
                                                  blurRadius: 36.0,
                                                  spreadRadius: 18.0,
                                                  color: MyColors.blue.withOpacity(0.27),
                                                ),
                                ],
                              ),
                              child: Center(
                                child: AnimatedDefaultTextStyle(
                                  key: const ValueKey<String>('sumCard'),
                                  duration: const Duration(milliseconds: 800),
                                  curve: Curves.easeInOutCubic,
                                  style: TextStyle(
                                    fontFamily: 'Quicksand',
                                    fontSize: 72.0,
                                    color: MyApp._mainColor,
                                  ),
                                  /*((value > 15 && value <= 18) || (value >= 3 && value <= 5))
                                      ? TextStyle(
                                          fontFamily: 'Quicksand',
                                          fontSize: 72.0,
                                          color: MyColors.light,
                                          shadows: <Shadow>[
                                            Shadow(
                                              color: MyColors.light.withOpacity(0.56),
                                              blurRadius: 42.0,
                                            ),
                                          ],
                                        )
                                      : ((value > 18 && value < 21) || (value < 3 && value >= 1))
                                          ? TextStyle(
                                              fontFamily: 'Quicksand',
                                              fontSize: 72.0,
                                              color: MyColors.gold,
                                              shadows: <Shadow>[
                                                Shadow(
                                                  color: MyColors.gold.withOpacity(0.56),
                                                  blurRadius: 42.0,
                                                ),
                                              ],
                                            )
                                          : (value >= 21 || value < 1)
                                              ? TextStyle(
                                                  fontFamily: 'Quicksand',
                                                  fontSize: 72.0,
                                                  color: MyColors.orangered,
                                                  shadows: <Shadow>[
                                                    Shadow(
                                                      color: MyColors.orangered.withOpacity(0.56),
                                                      blurRadius: 42.0,
                                                    ),
                                                  ],
                                                )
                                              : TextStyle(
                                                  fontFamily: 'Quicksand',
                                                  fontSize: 72.0,
                                                  color: MyColors.blue,
                                                  shadows: <Shadow>[
                                                    Shadow(
                                                      color: MyColors.blue.withOpacity(0.56),
                                                      blurRadius: 42.0,
                                                    ),
                                                  ],
                                                ),*/
                                  child: Text('$value'),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _continueFailed() {
    showGeneralDialog(
        context: _scaffoldKey.currentContext!,
        barrierDismissible: false,
        barrierColor: Colors.transparent,
        transitionDuration: const Duration(milliseconds: 500),
        transitionBuilder: (BuildContext context, Animation<double> anim1, Animation<double> anim2, Widget child) {
          return BackdropFilter(
            filter: ImageFilter.blur(sigmaX: (16.8) * anim1.value, sigmaY: (16.8) * anim1.value),
            child: FadeTransition(
              opacity: Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: anim1, curve: Curves.easeInOutCubic)),
              child: child,
            ),
          );
        },
        pageBuilder: (BuildContext context2, Animation<double> animation, Animation<double> secondaryAnimation) {
          return BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16.8, sigmaY: 16.8),
            child: AlertDialog(
              elevation: 0.0,
              backgroundColor: Colors.transparent,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
              insetPadding: EdgeInsets.zero,
              content: Text(
                'Watch an ad to continue playing?\n\n',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Quicksand',
                  fontSize: 30.0,
                  color: MyApp._complementColor,
                ),
              ),
              actionsPadding: EdgeInsets.zero,
              actions: <Row>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <GestureDetector>[
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).pop();
                        Timer(const Duration(milliseconds: 500), () {
                          _startUpAnimation.reverse();
                          Timer(const Duration(milliseconds: 1200), () {
                            Navigator.of(context).pushReplacement(MyRoute(builder: (BuildContext context) => const MyHomePage()));
                          });
                        });
                      },
                      child: Text(
                        'CANCEL',
                        style: TextStyle(
                          fontSize: 20.0,
                          color: MyApp._complementColor,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        _player.play('coin_drop.mp3');
                        Navigator.of(context).pop();
                        _loadAd(1);
                      },
                      child: Column(
                        children: <Widget>[
                          Text(
                            'OK',
                            style: TextStyle(
                              fontSize: 20.0,
                              color: MyApp._complementColor,
                            ),
                          ),
                          const SizedBox(height: 8.0),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              Icon(
                                Icons.attach_money,
                                size: 18.0,
                                color: MyApp._complementColor,
                              ),
                              Text(
                                '250',
                                style: TextStyle(
                                  fontSize: 16.0,
                                  color: MyApp._complementColor,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        });
  }

  void _watchAdPrompt(String type) {
    showGeneralDialog(
        context: context,
        barrierDismissible: false,
        barrierColor: Colors.transparent,
        transitionDuration: const Duration(milliseconds: 500),
        transitionBuilder: (BuildContext context, Animation<double> anim1, Animation<double> anim2, Widget child) {
          return BackdropFilter(
            filter: ImageFilter.blur(sigmaX: (16.8) * anim1.value, sigmaY: (16.8) * anim1.value),
            child: FadeTransition(
              opacity: Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: anim1, curve: Curves.easeInOutCubic)),
              child: child,
            ),
          );
        },
        pageBuilder: (BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) {
          return BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16.8, sigmaY: 16.8),
            child: AlertDialog(
              elevation: 0.0,
              backgroundColor: Colors.transparent,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
              insetPadding: EdgeInsets.zero,
              content: RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  text: 'Watch an ad to earn a ',
                  style: TextStyle(
                    fontFamily: 'Quicksand',
                    fontSize: 30.0,
                    color: MyApp._complementColor,
                  ),
                  children: <TextSpan>[
                    TextSpan(text: type, style: const TextStyle(fontFamily: 'Quicksand', color: MyColors.orangered)),
                    const TextSpan(text: ' bonus?\n\n'),
                  ],
                ),
              ),
              actionsPadding: EdgeInsets.zero,
              actions: <Row>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <GestureDetector>[
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).pop();
                      },
                      child: Text(
                        'CANCEL',
                        style: TextStyle(
                          fontSize: 20.0,
                          color: MyApp._complementColor,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        _player.play('coin_drop.mp3');
                        Navigator.of(context).pop();
                        _loadBonusAd(type);
                      },
                      child: Text(
                        'OK',
                        style: TextStyle(
                          fontSize: 20.0,
                          color: MyApp._complementColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        });
  }
}

class BuildCards extends StatelessWidget {
  final Alignment _state;
  final double _padding;
  final int _index;
  final String _number;
  final AnimationController _animation, _startUpAnimation;
  final Function tapHandler, tapHandler2;
  final Duration _a;
  final Color _mediumColor;
  final bool _clickable;
  late Animation<AlignmentGeometry> _alignAnimation;
  late Animation<double> _scaleAnimation;

  BuildCards(this._state, this._padding, this._index, this._number, this._animation, this._startUpAnimation, this.tapHandler, this.tapHandler2, this._a,
      this._mediumColor, this._clickable,
      {Key? key})
      : super(key: key) {
    _alignAnimation = TweenSequence<Alignment>(
      <TweenSequenceItem<Alignment>>[
        TweenSequenceItem<Alignment>(
          tween: Tween<Alignment>(begin: _state, end: Alignment.topCenter).chain(CurveTween(curve: Curves.easeInOutCubicEmphasized)),
          weight: 37.5,
        ),
        TweenSequenceItem<Alignment>(
          tween: Tween<Alignment>(begin: Alignment.topCenter, end: Alignment.bottomCenter).chain(CurveTween(curve: Curves.easeInOutQuart)),
          weight: 62.5,
        ),
      ],
    ).animate(_animation);
    _scaleAnimation = TweenSequence<double>(
      <TweenSequenceItem<double>>[
        TweenSequenceItem<double>(
          tween: Tween<double>(begin: 1.0, end: 1.1).chain(CurveTween(curve: Curves.easeInOutQuart)),
          weight: 37.5,
        ),
        TweenSequenceItem<double>(
          tween: Tween<double>(begin: 1.1, end: 0.4).chain(CurveTween(curve: Curves.easeInOutCubicEmphasized)),
          weight: 62.5,
        ),
      ],
    ).animate(_animation);
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      key: ValueKey<int>(_index),
      child: SlideTransition(
        key: ValueKey<String>('cardSlide_$_index'),
        position: Tween<Offset>(
                begin: (_index % 2 == 0) ? Offset((0.5 + ((_index + 15 - (_index * 2)) / 50)), 0.0) : Offset((-0.5 - ((_index + 15 - (_index * 2)) / 50)), 0.0),
                end: Offset.zero)
            .animate(CurvedAnimation(parent: _startUpAnimation, curve: Curves.easeInOutCubic)),
        child: AlignTransition(
          alignment: _alignAnimation,
          key: ValueKey<String>('cardAlign_$_index'),
          child: ScaleTransition(
            scale: _scaleAnimation,
            key: ValueKey<String>('cardScale_$_index'),
            child: GestureDetector(
              key: ValueKey<String>('card2_$_index'),
              onTap: () {
                if (MyHomePage._locked != true && _clickable == true) {
                  tapHandler(_index, _state, _padding, _number, _animation);
                  Timer(_a, () {
                    _animation.forward();
                    tapHandler2();
                  });
                }
              },
              child: Container(
                key: ValueKey<String>('card1_$_index'),
                margin: EdgeInsets.only(top: _padding),
                width: 85.7,
                height: 150.0,
                decoration: ShapeDecoration(
                  color: _mediumColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: const BorderRadius.all(Radius.circular(16.0)),
                    side: BorderSide(color: (_mediumColor == MyColors.mediumDark) ? Colors.white30 : Colors.black38, width: 0.2),
                  ),
                  /*gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: <Color>[
                        Colors.white10,
                        Colors.transparent,
                      ],
                    ),*/
                ),
                child: Center(
                  child: Text(
                    _number,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 56.0,
                      color: (int.parse(_number)) > 0 ? MyColors.limegreen : MyColors.orangered,
                      /*shadows: <Shadow>[
                        Shadow(
                          color: (int.parse(_number)) > 0 ? MyColors.limegreen.withOpacity(0.56) : MyColors.orangered.withOpacity(0.56),
                          blurRadius: 42.0,
                        ),
                      ],*/
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class MyRoute extends MaterialPageRoute {
  MyRoute({required Widget Function(BuildContext context) builder}) : super(builder: builder);

  @override
  Duration get transitionDuration => const Duration(milliseconds: 600);
}
