Add-Type -AssemblyName System.Drawing

$size = 256
$s = $size / 1024.0
$src = "d:\yzbjfpv-app\assets\icon\icon-256.png"
$dst = "d:\yzbjfpv-app\assets\icon\icon.ico"

$bmp = [System.Drawing.Bitmap]::new($size, $size)
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$rect = [System.Drawing.Rectangle]::new(0, 0, $size, $size)
$bgBrush = [System.Drawing.Drawing2D.LinearGradientBrush]::new(
    $rect, [System.Drawing.Color]::FromArgb(0,240,255), [System.Drawing.Color]::FromArgb(139,92,246), 35.0)
$g.FillRectangle($bgBrush, $rect)
$white = [System.Drawing.Brushes]::White
$navy = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(10,14,26))
$cyanBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(0,240,255))
$purpleBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(139,92,246))
$g.FillEllipse($white, [int](212*$s), [int](352*$s), [int](272*$s), [int](232*$s))
$g.FillEllipse($white, [int](540*$s), [int](352*$s), [int](272*$s), [int](232*$s))
$g.FillRectangle($white, [int](470*$s), [int](430*$s), [int](84*$s), [int](80*$s))
$g.FillEllipse($navy, [int](262*$s), [int](390*$s), [int](172*$s), [int](156*$s))
$g.FillEllipse($navy, [int](590*$s), [int](390*$s), [int](172*$s), [int](156*$s))
$g.FillEllipse($cyanBrush, [int](300*$s), [int](432*$s), [int](48*$s), [int](48*$s))
$g.FillEllipse($purpleBrush, [int](676*$s), [int](432*$s), [int](48*$s), [int](48*$s))
$pen = [System.Drawing.Pen]::new([System.Drawing.Color]::White, [float](26*$s))
$pen.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
$pen.EndCap = [System.Drawing.Drawing2D.LineCap]::Round
$g.DrawLine($pen, [float](512*$s), [float](352*$s), [float](512*$s), [float](268*$s))
$g.FillEllipse($white, [int](486*$s), [int](212*$s), [int](52*$s), [int](52*$s))
$speedPen = [System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(200,255,255,255), [float](22*$s))
$speedPen.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
$speedPen.EndCap = [System.Drawing.Drawing2D.LineCap]::Round
$g.DrawLine($speedPen, [float](300*$s), [float](700*$s), [float](470*$s), [float](700*$s))
$g.DrawLine($speedPen, [float](560*$s), [float](700*$s), [float](724*$s), [float](700*$s))
$g.DrawLine($speedPen, [float](380*$s), [float](762*$s), [float](644*$s), [float](762*$s))
$g.Dispose()
$bmp.Save($src, [System.Drawing.Imaging.ImageFormat]::Png)
$bmp.Dispose()

# 手工封装 ICO (PNG内嵌, Vista+ 支持)
$png = [System.IO.File]::ReadAllBytes($src)
$ms = [System.IO.MemoryStream]::new()
$bw = [System.IO.BinaryWriter]::new($ms)
$bw.Write([UInt16]0)
$bw.Write([UInt16]1)
$bw.Write([UInt16]1)
$bw.Write([byte]0)
$bw.Write([byte]0)
$bw.Write([byte]0)
$bw.Write([byte]0)
$bw.Write([UInt16]1)
$bw.Write([UInt16]32)
$bw.Write([UInt32]$png.Length)
$bw.Write([UInt32]22)
$bw.Write($png)
$bw.Flush()
[System.IO.File]::WriteAllBytes($dst, $ms.ToArray())
$bw.Close(); $ms.Close()
Write-Host "ICO_OK $((Get-Item $dst).Length) bytes"
