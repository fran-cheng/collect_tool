import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Collect Tool',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: .fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: 'Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  //		1D3A2E29141080
  // 前缀
  String preStr = "1D";

  // 后缀
  String endStr = "29131080";

  //		1D46B129131080
  int nfc_number = 0x46B1;
  late String nfcStr = nfc_number.toRadixString(16);

  // 分割保存的间隔
  int splitNumber = 1000;

  // 3. 修改功能：弹出输入框修改appName
  void editDate(
    String tag,
    dynamic arg,
    Function(dynamic) onChanged,
    bool isHex,
  ) {
    // 定义输入控制器，默认填充当前appName
    String inputText = arg.toString();
    final TextEditingController controller = TextEditingController(
      text: inputText,
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("修改$tag"),
        content: TextField(
          controller: controller,
          autofocus: true,
          // 自动聚焦
          inputFormatters: arg is int
              ? [FilteringTextInputFormatter.digitsOnly] // 仅数字输入
              : null,
          decoration: InputDecoration(
            hintText: "请输入新的$tag",
            border: OutlineInputBorder(),
          ),
          // 可选：限制输入长度
          maxLength: 50,
        ),
        actions: [
          // 取消按钮
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("取消"),
          ),
          // 确认按钮
          TextButton(
            onPressed: () {
              final String newArg = controller.text.trim();
              if (newArg.isEmpty) {
                showSnackBar("$tag不能为空", isError: true);
                return;
              }
              if(newArg.length!=4){
                showSnackBar("$tag只能是4个", isError: true);
                return;
              }
              if (isHex) {
                if (!isHexString(newArg)) {
                  showSnackBar("$tag 得是16进制格式", isError: true);
                  return;
                }
              }
              // 更新状态变量（刷新UI）
              setState(() {
                if (arg is int) {
                  // 校验是否为合法数字
                  final int? numValue = int.tryParse(newArg);
                  arg = numValue;
                } else {
                  arg = newArg;
                }
                onChanged(arg);
              });
              Navigator.pop(context); // 关闭对话框
              showSnackBar("修改成功：$newArg");
            },
            child: const Text("确认"),
          ),
        ],
      ),
    );
  }

  void showSnackBar(String message, {bool isError = false}) {
    if (!context.mounted) return; // 避免上下文销毁报错
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.orange,
        duration: const Duration(seconds: 2),
        // 桌面端优化：悬浮显示，避免被遮挡
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Widget buildEditText(
    String tag,
    dynamic arg,
    Function(dynamic) onChanged, {
    bool canClick = true, bool isHex = false,
  }) {
    return InkWell(
      onTap: canClick ? () => editDate(tag, arg, onChanged, isHex) : null,
      // 点击修改
      onLongPress: () => copyDate(arg.toString()),
      // 长按复制
      // 点击波纹效果（提升体验）
      splashColor: Colors.blue.withOpacity(0.2),
      borderRadius: BorderRadius.circular(4),
      child: Text("$tag：$arg"),
    );
  }

  bool isHexString(String str) {
    // 正则匹配：仅包含 0-9、a-f、A-F，且非空
    final hexRegex = RegExp(r'^[0-9a-fA-F]+$');
    return hexRegex.hasMatch(str);
  }

  Future<void> copyDate(String arg) async {
    if (arg.isEmpty) {
      showSnackBar("参数为空，无法复制", isError: true);
      return;
    }
    // 写入剪贴板
    await Clipboard.setData(ClipboardData(text: arg));
    showSnackBar("已复制：$arg");
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Column(
        // alignment: Alignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              // 边框配置（颜色+宽度+样式）
              border: Border.all(
                color: Colors.blue, // 边框颜色（必填）
                width: 2, // 边框宽度（默认1.0，可选）
                style: BorderStyle
                    .solid, // 边框样式：solid(实线，默认)/dashed(虚线)/dotted(点线)
              ),
              // 可选：容器背景色（注意：不能同时用Container的color属性，否则冲突）
              // color: Colors.grey[100],
              borderRadius: BorderRadius.circular(16), // 圆角半径（单位dp，值越大越圆）
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 10,
                  children: [
                    buildEditText("前缀", preStr, (value) => preStr = value),
                    buildEditText(
                      "中间",
                      nfcStr,
                      (value) => {
                        nfcStr = value
                      },
                      isHex: true
                    ),
                    buildEditText("后缀", endStr, (value) => endStr = value),
                  ],
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  spacing: 10,
                  children: [Text("当前是: " + preStr + nfcStr + endStr)],
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              // 边框配置（颜色+宽度+样式）
              border: Border.all(
                color: Colors.blue, // 边框颜色（必填）
                width: 2, // 边框宽度（默认1.0，可选）
                style: BorderStyle
                    .solid, // 边框样式：solid(实线，默认)/dashed(虚线)/dotted(点线)
              ),
              // 可选：容器背景色（注意：不能同时用Container的color属性，否则冲突）
              // color: Colors.grey[100],
              borderRadius: BorderRadius.circular(16), // 圆角半径（单位dp，值越大越圆）
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Column(children: [


            ]),
          ),
        ],
      ),
    );
  }
}
