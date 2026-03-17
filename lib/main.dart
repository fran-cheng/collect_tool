import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

final List<JsonParseExcelDTO> dataList_R = []; // 右眼数据列表
final List<JsonParseExcelDTO> dataList_L = []; // 左眼数据列表

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
      home: const MyHomePage(title: 'YSL 数据查询'),
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
  static final Map<String, String> mXcxData = {};

  //		1D3A2E29141080
  // 前缀
  String preStr = "1D";
  bool _isLoading = false;

  // 后缀
  String endStr = "29131080";

  //		1D46B129131080
  int nfc_number = 0x46B1;
  late String nfcStr = nfc_number.toRadixString(16);

  // 分割保存的间隔
  int splitNumber = 1000;

  // 间隔请求时间
  int sleepTime = 1;

  // 请求数量
  int maxRequestNumber = 1000;

  // 保存文件目录
  String saveDirPath = "";

  bool isStart = false;

  // 小程序sessionId
  String sessionId = "486754BB63A64895BF8BB4338CC2D37A";

  //  已执行
  int currentNumber = 0;

  // 已执行信息
  Map<String, String> mProcessData = {};

  @override
  void initState() {
    super.initState();
    // 直接调用异步方法（无需 await，不阻塞 initState 执行）
    initPath();
  }

  Future<void> initPath() async {
    String exeDir = path.dirname(Platform.resolvedExecutable);

    // 3. 拼接应用目录下的temp子目录路径
    String appTempDirPath = path.join(exeDir, "temp");
    Directory appTempDir = Directory(appTempDirPath);

    // 4. 如果temp目录不存在，自动创建
    if (!await appTempDir.exists()) {
      await appTempDir.create(recursive: true);
      print("应用temp目录已创建：$appTempDirPath");
    }
    saveDirPath = appTempDirPath;
  }

  /// 修改后：返回解析后的JSON数据（成功返回Map，失败/异常返回null）
  Future<Map<String, dynamic>?> checkNfcNumber(String nfcNumber) async {
    // 1. 正在加载/运行中，返回null并提示
    if (_isLoading) {
      showSnackBar("正在检查请稍等");
      return null;
    }

    // 2. 参数不合法，返回null并提示
    if (nfcNumber.isEmpty) {
      showSnackBar("参数不合法", isError: true);
      return null;
    }

    _isLoading = true;
    Map<String, dynamic>? resultData; // 存储要返回的data
    String url =
        "https://gc-eoca.essilorchina.com/masterdata/orders?nfc_code=${nfcNumber}&application=nfc_code";

    try {
      // 发送 GET 请求
      http.Response getResponse = await http.get(
        Uri.parse(url),
        headers: {
          "user-agent":
              "Mozilla/5.0 (iPhone; CPU iPhone OS 6_0 like Mac OS X) AppleWebKit/536.26 (KHTML, like Gecko) Version/6.0 Mobile/10A5376e Safari/8536.25",
        },
      );

      // 处理响应
      if (getResponse.statusCode == 200) {
        // 解析 JSON 并赋值给返回变量
        resultData = json.decode(getResponse.body);
        print("GET 请求成功：$resultData");
        showSnackBar("请求成功，是有效的");
      } else {
        print("GET 请求失败，状态码：${getResponse.statusCode}");
        showSnackBar("失败了,无效的", isError: true);
        resultData = null; // 状态码非200返回null
      }
    } catch (e) {
      // 捕获网络异常，返回null
      print("网络请求异常：$e");
      showSnackBar("失败了", isError: true);
      resultData = null;
    } finally {
      // 无论成功/失败/异常，都重置加载状态（关键：避免_isLoading卡死）
      _isLoading = false;
    }

    // 返回解析后的data（成功为Map，失败/异常为null）
    return resultData;
  }

  Future<void> xcxProcess(String realNumber, JsonParseExcelDTO dto) async {
    // 1. 先从缓存读取响应内容
    String responseBody = mXcxData[realNumber] ?? "";

    if (responseBody.isEmpty) {
      // 2. 拼接目标 URL 并转换为 Uri（http 库要求 Uri 类型）
      final String targetUrlStr =
          "https://crmprod.essilorluxottica.com.cn/membercenter/lens/authcode?qrCode=$realNumber&type=null&authType=2&domain=null";
      final Uri targetUrl = Uri.parse(targetUrlStr);
      print("xcxProcess url : $targetUrlStr");

      try {
        // 3. 构建请求头（和原 Java/ Dio 版本完全一致）
        final Map<String, String> headers = {
          // 核心鉴权头
          "sessionId": "${sessionId}",
          // 模拟微信小程序环境的 User-Agent
          "User-Agent":
              "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/132.0.0.0 Safari/537.36 MicroMessenger/7.0.20.1781(0x6700143B) NetType/WIFI MiniProgramEnv/Windows WindowsWechat/WMPF WindowsWechat(0x63090a13) UnifiedPCWindowsWechat(0xf254162e) XWEB/18163",
          // 来源校验头
          "Referer":
              "https://servicewechat.com/wxa6cee9315b68fa9b/390/page-frame.html",
          // 其他必要请求头
          "Host": "crmprod.essilorluxottica.com.cn",
          "Connection": "keep-alive",
          "Content-Type": "application/json",
          "xweb_xhr": "1",
          "Accept": "*/*",
          "Sec-Fetch-Site": "cross-site",
          "Sec-Fetch-Mode": "cors",
          "Sec-Fetch-Dest": "empty",
          "Accept-Encoding": "gzip, deflate, br",
          "Accept-Language": "zh-CN,zh;q=0.9",
        };

        // 4. 发送 GET 请求（http 库核心 API）
        final http.Response response = await http.get(
          targetUrl,
          headers: headers,
        );

        // 5. 检查响应是否成功（状态码 200-299）
        if (response.statusCode >= 200 && response.statusCode < 300) {
          // 6. 读取响应内容（http 库通过 response.body 获取字符串）
          responseBody = response.body.isNotEmpty ? response.body : "无响应内容";
          print("响应内容：\n$responseBody");

          // 7. 存入缓存
          mXcxData[realNumber] = responseBody;

          // 8. 处理响应结果
          await xcxProcessResponseDto(realNumber, dto, responseBody);
        } else {
          // 非 2xx 状态码，打印错误
          print("请求失败，状态码：${response.statusCode}");
          final String errorBody = response.body.isNotEmpty
              ? response.body
              : "无错误内容";
          print("错误响应内容：$errorBody");
        }
      } on SocketException catch (e) {
        // 捕获网络连接异常（如无网络、连接超时）
        print("网络连接异常：${e.message}");
      } on HttpException catch (e) {
        // 捕获 HTTP 协议异常
        print("HTTP 协议异常：${e.message}");
      } on FormatException catch (e) {
        // 捕获响应格式异常（如 JSON 解析失败）
        print("响应格式异常：${e.message}");
      } catch (e) {
        // 捕获其他未知异常
        print("请求异常：$e");
      }
    } else {
      // 从缓存读取数据，处理响应
      print("读取缓存响应内容：\n$responseBody");
      await xcxProcessResponseDto(realNumber, dto, responseBody);
    }
  }

  xcxProcessResponseDto(
    String trackingNo,
    JsonParseExcelDTO dto,
    String responseStr,
  ) async {
    // 防御性判断：DTO 为空或响应字符串为空，直接返回
    if (responseStr.isEmpty) {
      print("xcxProcessResponseDto：DTO 为空或响应字符串为空");
      return;
    }

    try {
      // 1. 解析 JSON 字符串为 Dart 的 Map（对应 Java 的 JsonObject）
      final Map<String, dynamic> jsonObject = jsonDecode(responseStr);

      // 2. 获取 "data" 字段（对应 Java 的 dataElement）
      // 2. 获取 "data" 字段并判断是否为 Map 类型
      final dynamic dataElement = jsonObject['data'];
      if (dataElement is Map<String, dynamic>) {
        final Map<String, dynamic> data = dataElement;

        // 3. 处理日期格式化（核心：解析 invoiceDate 并重新格式化）
        final String? invoiceDateStr = data['invoiceDate']?.toString();
        String invoiceDate = "";
        if (invoiceDateStr != null && invoiceDateStr.isNotEmpty) {
          try {
            // 解析原始日期字符串
            // final DateTime dateTime = inputFormatter.parse(invoiceDateStr);
            // // 格式化为易读的日期字符串
            // invoiceDate = outputFormatter.format(dateTime);
            invoiceDate = invoiceDateStr;
          } on FormatException catch (e) {
            print("日期解析失败：$e，原始日期字符串：$invoiceDateStr");
            invoiceDate = invoiceDateStr; // 解析失败则保留原始值
          }
        }

        // 4. 提取产品名（处理空值）
        final String productNameLeft =
            data['productNameLeft']?.toString() ?? "";
        final String productNameRight =
            data['productNameRight']?.toString() ?? "";

        // 5. 提取验光数据（球镜/柱镜/轴位）
        final String sphLeft = data['sphLeft']?.toString() ?? "";
        final String sphRight = data['sphRight']?.toString() ?? "";
        final String cylLeft = data['cylLeft']?.toString() ?? "";
        final String cylRight = data['cylRight']?.toString() ?? "";
        final String axisLeft = data['axisLeft']?.toString() ?? "";
        final String axisRight = data['axisRight']?.toString() ?? "";

        // 6. 提取防伪码/物流码
        final String qrcodeRight = data['qrcodeRight']?.toString() ?? "";
        final String qrcodeLeft = data['qrcodeLeft']?.toString() ?? "";
        final String logisticCodeRight =
            data['logisticCodeRight']?.toString() ?? "";
        final String logisticCodeLeft =
            data['logisticCodeLeft']?.toString() ?? "";

        // 7. 判断右眼产品是否含“星趣控”，创建 DTO 并加入列表
        if (productNameRight.contains("星趣控")) {
          dto.trackingNo = trackingNo;
          dto.SPH = sphRight;
          dto.CYL = cylRight;
          dto.AXIS = axisRight;
          dto.qrCode = qrcodeRight;
          dto.invoiceDatetime = invoiceDate;
          dto.setUrlWithNfc(
            logisticCodeRight,
            false,
          ); // 对应 Java 的 setUrl(url, false)
          dataList_R.add(dto);
          print("右眼星趣控数据已添加：${dto.toString()}");
        }

        // 8. 判断左眼产品是否含“星趣控”，创建 DTO 并加入列表
        if (productNameLeft.contains("星趣控")) {
          dto.trackingNo = trackingNo;
          dto.SPH = sphLeft;
          dto.CYL = cylLeft;
          dto.AXIS = axisLeft;
          dto.qrCode = qrcodeLeft;
          dto.invoiceDatetime = invoiceDate;
          dto.setUrlWithNfc(
            logisticCodeLeft,
            false,
          ); // 对应 Java 的 setUrl(url, false)
          dataList_L.add(dto);
          print("左眼星趣控数据已添加：${dto.toString()}");
        }
      }
    } on FormatException catch (e) {
      // 捕获 JSON 格式错误
      print("xcxProcessResponse：JSON 解析失败 - ${e.message}");
    } catch (e) {
      // 捕获其他未知异常
      print("xcxProcessResponse：处理失败 - $e");
    }
  }

  Future<void> startRequest() async {
    if (isStart) {
      isStart = false;
      showSnackBar("正在停止");
    } else {
      showSnackBar("已开始");
      isStart = true;
      final mixSleepTime = sleepTime > 0 ? sleepTime : 1;
      for (; currentNumber < maxRequestNumber; currentNumber++) {
        nfcStr = nfc_number.toRadixString(16);
        String realNumber = preStr + nfcStr + endStr;
        print("fran: " + realNumber);

        Map<String, dynamic>? responseData = await checkNfcNumber(realNumber);
        if (responseData != null) {
          JsonParseExcelDTO dto = JsonParseExcelDTO();
          String trackingNo = responseData["results"][0]["TrackingNo"];
          dto.trackingNo = trackingNo;
          print("fran: trackingNo ${trackingNo}");
          // xcxProcess(trackingNo, dto);
        }
        await Future.delayed(Duration(seconds: mixSleepTime));
        nfc_number--;
        setState(() {});
        if (!isStart || true) {
          break;
        }
      }
      if (currentNumber == maxRequestNumber) {
        showSnackBar("已完成");
      }
    }

    setState(() {});
  }

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

              if (isHex) {
                if (newArg.length != 4) {
                  showSnackBar("$tag只能是4个", isError: true);
                  return;
                }
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
    bool canClick = true,
    bool isHex = false,
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
                      (value) => {nfcStr = value},
                      isHex: true,
                    ),
                    buildEditText("后缀", endStr, (value) => endStr = value),
                  ],
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  spacing: 10,
                  children: [
                    Text("当前是: " + preStr + nfcStr + endStr),
                    ElevatedButton(
                      onPressed: () => checkNfcNumber(preStr + nfcStr + endStr),
                      child: Text("检查当前是否有效"),
                    ),
                  ],
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
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 10,
                  children: [
                    buildEditText(
                      "sessionId",
                      sessionId,
                      (value) => sessionId = value,
                    ),
                    buildEditText(
                      "保存间隔(每满多少保存一次)",
                      splitNumber,
                      (value) => splitNumber = value,
                    ),
                    buildEditText(
                      "请求间隔(每次请求间隔，单位秒)",
                      sleepTime,
                      (value) => sleepTime = value,
                    ),
                    buildEditText(
                      "数量",
                      maxRequestNumber,
                      (value) => maxRequestNumber = value,
                    ),
                    buildEditText(
                      "导出文件路径",
                      saveDirPath,
                      (value) => saveDirPath = value,
                    ),
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
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 10,
                  children: [Text("请求日志：")],
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  spacing: 10,
                  children: [
                    Text("当前: $currentNumber"),
                    ElevatedButton(
                      onPressed: () => startRequest(),
                      child: Text(isStart ? "暂停" : "开始"),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class JsonParseExcelDTO {
  // ========== 字段定义（对应Java，标注Excel注解信息） ==========
  // 追踪码（index=0）
  // @ExcelProperty(value = "追踪码", index = 0)
  String? trackingNo;

  // 产品名（index=1）
  // @ExcelProperty(value = "产品名", index = 1)
  String? productName;

  // 球镜（index=2）
  // @ExcelProperty(value = "球镜", index = 2)
  String? SPH;

  // 柱镜（index=3）
  // @ExcelProperty(value = "柱镜", index = 3)
  String? CYL;

  // AXIS（index=4）
  // @ExcelProperty(value = "AXIS", index = 4)
  String? AXIS;

  // 生产时间（index=5）
  // @ExcelProperty(value = "生产时间", index = 5)
  String? invoiceDatetime; // Dart推荐小驼峰，对应Java的InvoiceDatetime

  // 防伪码（index=6）
  // @ExcelProperty(value = "防伪码", index = 6)
  String? qrCode; // Dart推荐小驼峰，对应Java的QrCode

  // 详情链接（index=7）
  // @ExcelProperty(value = "详情链接", index = 7)
  String? url;

  // 眼睛位置 R/L（index=8）
  // @ExcelProperty(value = "眼睛位置", index = 8)
  String? eye; // Dart推荐小驼峰，对应Java的Eye

  // 扫描次数（index=9）
  // @ExcelProperty(value = "扫描次数", index = 9)
  String? scanTimes;

  // 产品编码（index=10）
  // @ExcelProperty(value = "产品编码", index = 10)
  String? productCode;

  // ========== 构造函数 ==========
  // 空构造函数
  JsonParseExcelDTO();

  // 可选：带参数的构造函数（方便快速初始化）
  JsonParseExcelDTO.withParams({
    this.trackingNo,
    this.productName,
    this.SPH,
    this.CYL,
    this.AXIS,
    this.invoiceDatetime,
    this.qrCode,
    this.url,
    this.eye,
    this.scanTimes,
    this.productCode,
  });

  // ========== Getter/Setter（Dart特性：字段默认有get/set，特殊逻辑单独实现） ==========
  // 普通字段的get/set Dart自动生成，无需手动写（比如trackingNo的get/set）

  // 重载setUrl的替代方案（Dart不支持方法重载，用参数区分）
  /// 基础setUrl（对应Java的setUrl(String url)）
  set setUrl(String? newUrl) {
    url = newUrl;
  }

  /// 带NFC标识的setUrl（对应Java的setUrl(String url, boolean isNfc)）
  void setUrlWithNfc(String? newUrl, bool isNfc) {
    if (newUrl == null) return;
    if (isNfc) {
      url =
          "https://authcode.essilorchina.com/essilornfc/info?nfc_code=$newUrl";
    } else {
      url =
          "https://authcode.essilorchina.com/essilornfc/info?logistic_code=$newUrl";
    }
  }

  // ========== 重写toString方法 ==========
  @override
  String toString() {
    return 'JsonParseExcelDTO{'
        'trackingNo: $trackingNo, '
        'productName: $productName, '
        'SPH: $SPH, '
        'CYL: $CYL, '
        'AXIS: $AXIS, '
        'invoiceDatetime: $invoiceDatetime, '
        'qrCode: $qrCode, '
        'url: $url, '
        'eye: $eye, '
        'scanTimes: $scanTimes, '
        'productCode: $productCode'
        '}';
  }
}
