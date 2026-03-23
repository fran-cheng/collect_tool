import 'dart:async';
import 'dart:io';
import 'dart:convert'; // 必须导入
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;

/// Windows 平台日志工具类：彻底解决中文乱码（字节流写入）
class WindowsLogUtil {
  static File? _logFile;
  static bool _isInitialized = false;

  /// 初始化日志文件（建议在 main 函数 runApp 前调用）
  /// [exeDir]：可执行文件所在目录（Windows 用 Platform.resolvedExecutable 获取）
  static Future<void> init({required String exeDir}) async {
    if (_isInitialized) return;

    try {
      // 1. 创建日志目录
      final logDir = Directory(path.join(exeDir, "log"));
      if (!logDir.existsSync()) {
        logDir.createSync(recursive: true);
        _printConsole("日志目录创建成功：${logDir.path}");
      }

      // 2. 创建按日期命名的日志文件（不写BOM，避免解析冲突）
      final dateStr = DateTime.now().toString().split(' ')[0].replaceAll('-', '_');
      final logFilePath = path.join(logDir.path, "log_$dateStr.txt");
      _logFile = File(logFilePath);
      if (!_logFile!.existsSync()) {
        _logFile!.createSync(); // 仅创建空文件，不写BOM
        _printConsole("日志文件创建成功：$logFilePath");
      }

      _isInitialized = true;
      _printConsole("日志工具初始化完成");
    } catch (e) {
      _printConsole("日志工具初始化失败：$e");
    }
  }

  /// 核心方法：写入日志到文件（字节流方式，彻底解决乱码）
  /// [content]：要写入的日志内容（支持任意中文）
  /// [printConsole]：是否同时打印到控制台（默认 true）
  static Future<void> log(String content, {bool printConsole = true}) async {
    // 未初始化则直接打印到控制台并返回
    if (!_isInitialized || _logFile == null) {
      _printConsole("日志工具未初始化，日志内容：$content");
      return;
    }

    try {
      // 1. 拼接带时间戳的日志内容
      final timeStamp = DateTime.now().toString().substring(0, 23);
      final logWithTime = "[$timeStamp] $content\n";

      // 2. 关键：直接转成 UTF-8 字节，避免字符串编码转换
      final utf8Bytes = utf8.encode(logWithTime);

      // 3. 字节流追加写入（无编码转换，最底层方式）
      await _logFile!.writeAsBytes(
        utf8Bytes,
        mode: FileMode.append,
        flush: true, // 立即刷盘，避免日志丢失
      );

      // 可选：同时打印到控制台
      if (printConsole) {
        _printConsole(logWithTime.trim());
      }
    } catch (e) {
      _printConsole("日志写入失败：$e，日志内容：$content");
    }
  }

  /// 快捷方法：替代 print - 既打印到控制台又写入日志
  static Future<void> printLog(String content) async {
    await log(content, printConsole: true);
  }

  /// 内部方法：打印到控制台（统一封装）
  static void _printConsole(String content) {
    if (kDebugMode) {
      print(content);
    }
  }

  /// 关闭日志工具
  static void dispose() {
    _isInitialized = false;
    _printConsole("日志工具已关闭");
  }
}