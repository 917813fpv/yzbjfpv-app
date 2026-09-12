# YZBJFPV Android Demo —— 真实Android模拟器(虚拟机)运行APK
$ErrorActionPreference = 'Continue'
$emu = "C:\dev-tools\android-sdk\emulator\emulator.exe"
$adb = "C:\dev-tools\android-sdk\platform-tools\adb.exe"
$apk = "d:\yzbjfpv-app\build\app\outputs\flutter-apk\app-release.apk"
$pkg = "top.yzbjfpv.yzbjfpv"
$avd = "yzbjfpv_demo"

if (-not (Test-Path $apk)) {
  Write-Host "APK不存在: $apk ，请先编译: flutter build apk --release"
  Read-Host "按回车退出"
  exit 1
}

# 服务器指向本机(模拟器内10.0.2.2=宿主机localhost)
& $adb start-server 2>$null | Out-Null

# 模拟器未运行则启动虚拟机
$running = (& $adb devices) | Select-String "emulator-\d+\s+device"
if (-not $running) {
  Write-Host "启动Android模拟器(虚拟机)..."
  Start-Process -FilePath $emu -ArgumentList "-avd", $avd, "-no-snapshot-load", "-no-boot-anim", "-gpu", "auto" -WindowStyle Hidden
}

Write-Host "等待模拟器开机..." -NoNewline
& $adb wait-for-device 2>$null
$booted = $false
for ($i = 0; $i -lt 150; $i++) {
  $b = (& $adb shell getprop sys.boot_completed 2>$null) -join ''
  if ($b.Trim() -eq "1") { $booted = $true; break }
  Write-Host "." -NoNewline
  Start-Sleep -Seconds 2
}
Write-Host ""
if (-not $booted) { Write-Host "模拟器开机超时"; Read-Host "按回车退出"; exit 1 }

Write-Host "安装最新APK..."
& $adb install -r $apk
Write-Host "启动YZBJFPV APP..."
& $adb shell monkey -p $pkg -c android.intent.category.LAUNCHER 1
Write-Host "完成 —— 模拟器窗口中即为真实APP(非网页)"
