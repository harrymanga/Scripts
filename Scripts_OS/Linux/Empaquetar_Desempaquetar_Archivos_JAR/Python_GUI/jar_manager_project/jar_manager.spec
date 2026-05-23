# -*- mode: python ; coding: utf-8 -*-
import os
import sys
from PyInstaller.utils.hooks import collect_all, collect_submodules

block_cipher = None

# Recopilar todos los módulos, binarios y datos de PySide6
pyside6_datas, pyside6_binaries, pyside6_hiddenimports = collect_all('PySide6')

a = Analysis(
    ['src/jar_manager/main.py'],
    pathex=[],
    binaries=pyside6_binaries,
    datas=[
        ('src', 'src'),
    ] + pyside6_datas,
    hiddenimports=[
        'jar_manager.cli',
        'jar_manager.ui.main_window',
        'jar_manager.controllers.main_controller',
        'jar_manager.core.jar_service',
        'jar_manager.core.worker',
        'jar_manager.utils.logger',
    ] + pyside6_hiddenimports,
    hookspath=[],
    hooksconfig={},
    runtime_hooks=[],
    excludes=['matplotlib', 'numpy', 'pandas', 'scipy', 'sklearn'],
    win_no_prefer_redirects=False,
    win_private_assemblies=False,
    cipher=block_cipher,
    noarchive=False,
)

pyz = PYZ(a.pure, a.zipped_data, cipher=block_cipher)

exe = EXE(
    pyz,
    a.scripts,
    a.binaries,
    a.zipfiles,
    a.datas,
    [],
    name='JarManager',
    debug=False,
    bootloader_ignore_signals=False,
    strip=False,
    upx=True,
    upx_exclude=[],
    runtime_tmpdir=None,
    console=False,
    disable_windowed_traceback=False,
    argv_emulation=False,
    target_arch=None,
    codesign_identity=None,
    entitlements_file=None,
    icon=None,
)

# For macOS, create an app bundle instead of a single executable
if sys.platform == 'darwin':
    app = BUNDLE(
        exe,
        name='JarManager.app',
        icon=None,
        bundle_identifier='com.jarmanager.app',
        info_plist={
            'NSHighResolutionCapable': 'True',
        }
    )
