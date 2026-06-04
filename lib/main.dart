import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:tray_manager/tray_manager.dart';

import 'presentation/provider/clipboard_provider.dart';
import 'presentation/ui/app.dart';

const _windowChannel = MethodChannel('lipo/window');

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final clipboardProvider = ClipboardProvider();
  await clipboardProvider.initialize();

  final trayController = _TrayController(clipboardProvider);
  await trayController.initialize();

  runApp(
    ChangeNotifierProvider.value(
      value: clipboardProvider,
      child: const LipoApp(),
    ),
  );

  WidgetsBinding.instance.addPostFrameCallback((_) {
    trayController.postRunAppInit();
  });
}

class _TrayController with TrayListener {
  _TrayController(this._clipboardProvider);

  final ClipboardProvider _clipboardProvider;

  Future<void> initialize() async {
    trayManager.addListener(this);
    await _setTrayIcon();
    await trayManager.setToolTip('Lipo');
    await _setMenu(isWindowVisible: false);
  }

  void postRunAppInit() {
    _refreshMenuSafe();
  }

  @override
  void onTrayIconMouseDown() {
    _toggleWindowSafe();
  }

  @override
  void onTrayIconRightMouseDown() {
    trayManager.popUpContextMenu();
  }

  Future<void> _setMenu({required bool isWindowVisible}) async {
    final menu = Menu(
      items: [
        MenuItem(
          label: isWindowVisible ? 'Hide' : 'Open',
          onClick: (_) => _toggleWindowSafe(),
        ),
        MenuItem(
          label: 'Set Shortcut…',
          onClick: (_) {
            _clipboardProvider.requestHotKeySetup();
            _showWindowSafe();
          },
        ),
        MenuItem.separator(),
        MenuItem(
          label: 'Clear History',
          onClick: (_) => _clipboardProvider.clearAll(),
        ),
        MenuItem.separator(),
        MenuItem(
          label: 'Quit',
          onClick: (_) async {
            await trayManager.destroy();
            exit(0);
          },
        ),
      ],
    );
    await trayManager.setContextMenu(menu);
  }

  void _toggleWindowSafe() {
    unawaited(_toggleWindow());
  }

  void _showWindowSafe() {
    unawaited(_showWindow());
  }

  Future<void> _toggleWindow() async {
    try {
      await _windowChannel.invokeMethod<void>('toggle');
    } catch (_) {}
    await _refreshMenuSafe();
  }

  Future<void> _showWindow() async {
    try {
      await _windowChannel.invokeMethod<void>('show');
    } catch (_) {}
    await _refreshMenuSafe();
  }

  Future<void> _refreshMenuSafe() async {
    bool isVisible = false;
    try {
      final value = await _windowChannel.invokeMethod<bool>('isVisible');
      isVisible = value ?? false;
    } catch (_) {}
    await _setMenu(isWindowVisible: isVisible);
  }

  Future<void> _setTrayIcon() async {
    const base64Png =
        'iVBORw0KGgoAAAANSUhEUgAAABIAAAASCAYAAABWzo5XAAAAKklEQVR42mNgGCrgPwFMP4P+k4jxGkSKq+ln0BYCmGHUa6Neo0cWGXgAANxRTKVoolOCAAAAAElFTkSuQmCC';

    await const MethodChannel(
      'tray_manager',
    ).invokeMethod<void>('setIcon', <String, dynamic>{
      'id': DateTime.now().microsecondsSinceEpoch.toString(),
      'iconPath': 'lipo_tray_icon',
      'base64Icon': base64Png,
      'isTemplate': true,
      'iconPosition': 'left',
      'iconSize': 18,
    });
  }
}
