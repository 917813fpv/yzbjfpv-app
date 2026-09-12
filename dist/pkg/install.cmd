@echo off
title YZBJFPV 客户端安装
echo.
echo  ============================================
echo    YZBJFPV Windows 客户端 V0.0.1.1Beta 安装
echo  ============================================
echo.
set "DEST=%LocalAppData%\Programs\YZBJFPV"
set "SMENU=%AppData%\Microsoft\Windows\Start Menu\Programs\YZBJFPV"

echo [1/3] 正在解压程序文件...
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "Expand-Archive -Path 'payload.zip' -DestinationPath $env:DEST -Force" >nul 2>&1
if not exist "%DEST%\yzbjfpv.exe" (
  echo 安装失败：解压出错，请以管理员身份重试或检查杀毒软件拦截。
  pause
  exit /b 1
)

echo [2/3] 正在创建快捷方式...
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$ws = New-Object -ComObject WScript.Shell; $exe = Join-Path $env:DEST 'yzbjfpv.exe'; $lnk = $ws.CreateShortcut([Environment]::GetFolderPath('Desktop') + '\YZBJFPV.lnk'); $lnk.TargetPath = $exe; $lnk.Description = 'YZBJFPV 航模穿越机平台客户端'; $lnk.Save(); New-Item -ItemType Directory -Force -Path ([Environment]::GetFolderPath('Programs') + '\YZBJFPV') | Out-Null; $lnk2 = $ws.CreateShortcut([Environment]::GetFolderPath('Programs') + '\YZBJFPV\YZBJFPV.lnk'); $lnk2.TargetPath = $exe; $lnk2.Save()" >nul 2>&1

echo [3/3] 安装完成，正在启动 YZBJFPV...
timeout /t 2 /nobreak >nul
start "" "%DEST%\yzbjfpv.exe"
exit /b 0
