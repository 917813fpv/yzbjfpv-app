# YZBJFPV iOS Demo —— 同一套Flutter代码原生渲染iOS液态玻璃界面
# 说明: iOS官方模拟器必须macOS+Xcode才能运行(Apple许可限制)，Windows无法运行。
# 此demo为真实原生APP窗口(Flutter引擎原生渲染，非浏览器网页)，通过
# YZBJFPV_IOS_PREVIEW=1 强制启用iOS液态玻璃(BackdropFilter)渲染分支，
# 展示的界面代码与iOS端完全一致。
$env:YZBJFPV_IOS_PREVIEW = "1"
$exe = "d:\yzbjfpv-app\build\windows\x64\runner\Release\yzbjfpv.exe"
if (-not (Test-Path $exe)) {
  Write-Host "程序不存在: $exe ，请先编译: flutter build windows --release"
  Read-Host "按回车退出"
  exit 1
}
Start-Process -FilePath $exe -WorkingDirectory (Split-Path $exe)
Write-Host "已启动 —— iOS液态玻璃预览(原生Flutter窗口，非网页)"
