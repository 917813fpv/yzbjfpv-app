@echo off
chcp 65001 >nul
title YZBJFPV 安装程序
echo.
echo  ╔══════════════════════════════════════╗
echo  ║   YZBJFPV Windows 客户端 安装程序    ║
echo  ║   网页壳架构 · 支持服务器热更新      ║
echo  ╚══════════════════════════════════════╝
echo.

:: 检查管理员权限
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [!] 需要管理员权限，正在请求...
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

set "DEST=%ProgramFiles%\YZBJFPV"
echo [1/4] 安装到 %DEST% ...
if not exist "%DEST%" mkdir "%DEST%"
xcopy "%~dp0app\*" "%DEST%\" /E /Y /I /Q >nul
if %errorlevel% neq 0 (
    echo [X] 文件复制失败！
    pause
    exit /b 1
)
echo      完成

echo [2/4] 创建桌面快捷方式 ...
powershell -NoProfile -Command ^
  "$ws = New-Object -ComObject WScript.Shell; $s = $ws.CreateShortcut([Environment]::GetFolderPath('Desktop')+'\YZBJFPV.lnk'); $s.TargetPath='%DEST%\yzbjfpv.exe'; $s.WorkingDirectory='%DEST%'; $s.Description='YZBJFPV 网页壳客户端'; $s.Save()"
echo      完成

echo [3/4] 创建开始菜单快捷方式 ...
powershell -NoProfile -Command ^
  "$ws = New-Object -ComObject WScript.Shell; $sm=[Environment]::GetFolderPath('Programs'); $s = $ws.CreateShortcut($sm+'\YZBJFPV.lnk'); $s.TargetPath='%DEST%\yzbjfpv.exe'; $s.WorkingDirectory='%DEST%'; $s.Save()"
echo      完成

echo [4/4] 配置开机自启（可选）...
set /p AUTOSTART=是否设置开机自动启动？(Y/N，默认N): 
if /i "%AUTOSTART%"=="Y" (
    reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Run" /v YZBJFPV /t REG_SZ /d "\"%DEST%\yzbjfpv\"" /f >nul
    echo      已设置开机自启
) else (
    echo      跳过
)

echo.
echo  ╔══════════════════════════════════════╗
echo  ║   安装完成！桌面已创建快捷方式       ║
echo  ║   日常功能更新由服务器自动下发       ║
echo  ║   无需重新下载安装包                 ║
echo  ╚══════════════════════════════════════╝
echo.
set /p LAUNCH=立即启动 YZBJFPV？(Y/N): 
if /i "%LAUNCH%"=="Y" start "" "%DEST%\yzbjfpv.exe"
exit /b 0
