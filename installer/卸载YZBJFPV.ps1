# 卸载 YZBJFPV
# 右键"以 PowerShell 运行"或管理员运行本脚本

$dest = "$env:ProgramFiles\YZBJFPV"
if (Test-Path $dest) {
    Get-Process yzbjfpv -ErrorAction SilentlyContinue | Stop-Process -Force
    Remove-Item $dest -Recurse -Force
    Write-Host "[1/3] 程序目录已删除"
} else {
    Write-Host "[1/3] 程序目录不存在，跳过"
}

$desktop = [Environment]::GetFolderPath('Desktop')
$sm = [Environment]::GetFolderPath('Programs')
Remove-Item "$desktop\YZBJFPV.lnk", "$sm\YZBJFPV.lnk" -Force -ErrorAction SilentlyContinue
Write-Host "[2/3] 快捷方式已删除"

Remove-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run" -Name YZBJFPV -ErrorAction SilentlyContinue
Write-Host "[3/3] 开机自启已清理"
Write-Host "`n卸载完成" -ForegroundColor Green
Pause
