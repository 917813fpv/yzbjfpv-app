Add-Type -AssemblyName System.Drawing

# YZBJFPV APP图标生成器：科技渐变底 + FPV护目镜图形
# 输出: icon.png (1024) / icon-512.png / icon-192.png / icon-144.png / icon-96.png / icon-72.png / icon-48.png

$outDir = "d:\yzbjfpv-app\assets\icon"
New-Item -ItemType Directory -Force -Path $outDir | Out-Null

function New-Icon([int]$size) {
    $bmp = New-Object System.Drawing.Bitmap($size, $size)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality

    $s = $size / 1024.0

    # 背景: 青→蓝→紫 对角渐变
    $rect = New-Object System.Drawing.Rectangle(0, 0, $size, $size)
    $bgBrush = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
        $rect,
        [System.Drawing.Color]::FromArgb(0, 240, 255),
        [System.Drawing.Color]::FromArgb(139, 92, 246), 35.0)
    $blend = New-Object System.Drawing.Drawing2D.Blend(3)
    $blend.Factors = [float[]](0.0, 0.5, 1.0)
    $blend.Positions = [float[]](0.0, 0.45, 1.0)
    $bgBrush.Blend = $blend
    $g.FillRectangle($bgBrush, $rect)

    # 左上/右下 暗色斜切装饰(科技感)
    $darkPath = New-Object System.Drawing.Drawing2D.GraphicsPath
    $darkPath.AddPolygon([System.Drawing.Point[]]@(
        [System.Drawing.Point]::new(0, [int](760 * $s)), [System.Drawing.Point]::new(0, [int](1024 * $s)),
        [System.Drawing.Point]::new([int](420 * $s), [int](1024 * $s)), [System.Drawing.Point]::new([int](640 * $s), [int](760 * $s))))
    $darkBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(40, 10, 26, 58))
    $g.FillPath($darkBrush, $darkPath)

    $white = [System.Drawing.Brushes]::White
    $navy = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(10, 14, 26))

    # 护目镜主体: 两个镜筒 + 鼻梁
    $g.FillEllipse($white, [int](212 * $s), [int](352 * $s), [int](272 * $s), [int](232 * $s))
    $g.FillEllipse($white, [int](540 * $s), [int](352 * $s), [int](272 * $s), [int](232 * $s))
    $g.FillRectangle($white, [int](470 * $s), [int](430 * $s), [int](84 * $s), [int](80 * $s))

    # 镜片: 深色内芯
    $g.FillEllipse($navy, [int](262 * $s), [int](390 * $s), [int](172 * $s), [int](156 * $s))
    $g.FillEllipse($navy, [int](590 * $s), [int](390 * $s), [int](172 * $s), [int](156 * $s))

    # 镜片高光: 青色圆点(左) + 紫色圆点(右) —— 呼应平台双主色
    $cyanBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(0, 240, 255))
    $purpleBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(139, 92, 246))
    $g.FillEllipse($cyanBrush, [int](300 * $s), [int](432 * $s), [int](48 * $s), [int](48 * $s))
    $g.FillEllipse($purpleBrush, [int](676 * $s), [int](432 * $s), [int](48 * $s), [int](48 * $s))

    # 顶部天线
    $pen = New-Object System.Drawing.Pen([System.Drawing.Color]::White, [float](26 * $s))
    $pen.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
    $pen.EndCap = [System.Drawing.Drawing2D.LineCap]::Round
    $g.DrawLine($pen, [float](512 * $s), [float](352 * $s), [float](512 * $s), [float](268 * $s))
    $g.FillEllipse($white, [int](486 * $s), [int](212 * $s), [int](52 * $s), [int](52 * $s))

    # 底部速度线(竞速感)
    $speedPen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(200, 255, 255, 255), [float](22 * $s))
    $speedPen.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
    $speedPen.EndCap = [System.Drawing.Drawing2D.LineCap]::Round
    $g.DrawLine($speedPen, [float](300 * $s), [float](700 * $s), [float](470 * $s), [float](700 * $s))
    $g.DrawLine($speedPen, [float](560 * $s), [float](700 * $s), [float](724 * $s), [float](700 * $s))
    $g.DrawLine($speedPen, [float](380 * $s), [float](762 * $s), [float](644 * $s), [float](762 * $s))

    $g.Dispose()
    return $bmp
}

foreach ($sz in @(1024, 512, 192, 144, 96, 72, 48)) {
    $bmp = New-Icon $sz
    $name = if ($sz -eq 1024) { "icon.png" } else { "icon-$sz.png" }
    $bmp.Save("$outDir\$name", [System.Drawing.Imaging.ImageFormat]::Png)
    $bmp.Dispose()
    Write-Host "OK $name"
}
Write-Host "ICON_DONE"

