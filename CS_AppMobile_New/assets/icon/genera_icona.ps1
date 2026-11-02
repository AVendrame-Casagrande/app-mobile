param([string]$OutDir)
# Icona "Stokky": una scatola da magazzino simpatica (mascotte), su sfondo petrolio.
Add-Type -AssemblyName System.Drawing

function C([int]$r, [int]$g, [int]$b, [int]$a = 255) { [System.Drawing.Color]::FromArgb($a, $r, $g, $b) }
function P([float]$x, [float]$y) { New-Object System.Drawing.PointF($x, $y) }

function RoundRect([float]$x, [float]$y, [float]$w, [float]$h, [float]$r) {
    $p = New-Object System.Drawing.Drawing2D.GraphicsPath
    $d = 2 * $r
    $p.AddArc($x, $y, $d, $d, 180, 90)
    $p.AddArc($x + $w - $d, $y, $d, $d, 270, 90)
    $p.AddArc($x + $w - $d, $y + $h - $d, $d, $d, 0, 90)
    $p.AddArc($x, $y + $h - $d, $d, $d, 90, 90)
    $p.CloseFigure()
    return $p
}

# Disegna la mascotte nel quadrato [0,size]. $mono = sola sagoma di un colore (icona notifiche).
function Disegna-Stokky([System.Drawing.Graphics]$g, [float]$s, [bool]$mono, [System.Drawing.Color]$coloreMono) {
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias

    $cartone = C 247 178 74      # fronte
    $cartoneChiaro = C 255 205 120  # coperchio
    $cartoneScuro = C 214 139 47   # fianco / ombre
    $nastro = C 255 236 200
    $inchiostro = C 38 50 56

    if ($mono) { $cartone = $coloreMono; $cartoneChiaro = $coloreMono; $cartoneScuro = $coloreMono }

    # Geometria: fronte quadrato + coperchio in prospettiva + fianco destro
    $fx = $s * 0.17; $fy = $s * 0.36; $fw = $s * 0.50; $fh = $s * 0.46
    $dx = $s * 0.13; $dy = $s * 0.11   # profondità

    # Ombra a terra
    if (-not $mono) {
        $ombra = New-Object System.Drawing.SolidBrush((C 0 0 0 55))
        $g.FillEllipse($ombra, $fx - $s * 0.02, $fy + $fh - $s * 0.035, $fw + $dx + $s * 0.04, $s * 0.08)
    }

    # Fianco destro
    $fianco = @((P ($fx + $fw) $fy), (P ($fx + $fw + $dx) ($fy - $dy)), (P ($fx + $fw + $dx) ($fy + $fh - $dy)), (P ($fx + $fw) ($fy + $fh)))
    $g.FillPolygon((New-Object System.Drawing.SolidBrush($cartoneScuro)), $fianco)

    # Coperchio
    $coperchio = @((P $fx $fy), (P ($fx + $dx) ($fy - $dy)), (P ($fx + $fw + $dx) ($fy - $dy)), (P ($fx + $fw) $fy))
    $g.FillPolygon((New-Object System.Drawing.SolidBrush($cartoneChiaro)), $coperchio)

    # Fronte con angoli leggermente arrotondati
    # Lato destro squadrato: deve combaciare col fianco senza fessure
    $g.FillRectangle((New-Object System.Drawing.SolidBrush($cartone)), $fx + $fw / 2, $fy, $fw / 2, $fh)
    $fronte = RoundRect $fx $fy $fw $fh ($s * 0.025)
    $g.FillPath((New-Object System.Drawing.SolidBrush($cartone)), $fronte)

    if ($mono) {
        # Nella sagoma il viso è "bucato" (trasparente)
        $g.CompositingMode = [System.Drawing.Drawing2D.CompositingMode]::SourceCopy
        $buco = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::Transparent)
        $occhio = $s * 0.075
        $g.FillEllipse($buco, $fx + $fw * 0.24, $fy + $fh * 0.36, $occhio, $occhio * 1.15)
        $g.FillEllipse($buco, $fx + $fw * 0.62, $fy + $fh * 0.36, $occhio, $occhio * 1.15)
        $penBuco = New-Object System.Drawing.Pen([System.Drawing.Color]::Transparent, ($s * 0.04))
        $penBuco.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
        $penBuco.EndCap = [System.Drawing.Drawing2D.LineCap]::Round
        $g.DrawArc($penBuco, $fx + $fw * 0.33, $fy + $fh * 0.50, $fw * 0.34, $fh * 0.26, 20, 140)
        $g.CompositingMode = [System.Drawing.Drawing2D.CompositingMode]::SourceOver
        return
    }

    # Nastro adesivo sul coperchio e giù sul fronte
    $nx = $fx + $fw * 0.40; $nw = $fw * 0.20
    $nastroCop = @((P $nx $fy), (P ($nx + $dx) ($fy - $dy)), (P ($nx + $nw + $dx) ($fy - $dy)), (P ($nx + $nw) $fy))
    $g.FillPolygon((New-Object System.Drawing.SolidBrush($nastro)), $nastroCop)
    $g.FillRectangle((New-Object System.Drawing.SolidBrush($nastro)), $nx, $fy, $nw, $fh * 0.22)

    # Occhi con riflesso
    $occhio = $s * 0.072
    $ink = New-Object System.Drawing.SolidBrush($inchiostro)
    $bianco = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)
    foreach ($ox in @(($fx + $fw * 0.25), ($fx + $fw * 0.61))) {
        $oy = $fy + $fh * 0.37
        $g.FillEllipse($ink, $ox, $oy, $occhio, $occhio * 1.15)
        $g.FillEllipse($bianco, $ox + $occhio * 0.52, $oy + $occhio * 0.18, $occhio * 0.30, $occhio * 0.30)
    }

    # Guance
    $guancia = New-Object System.Drawing.SolidBrush((C 240 110 80 150))
    $g.FillEllipse($guancia, $fx + $fw * 0.12, $fy + $fh * 0.58, $s * 0.07, $s * 0.04)
    $g.FillEllipse($guancia, $fx + $fw * 0.74, $fy + $fh * 0.58, $s * 0.07, $s * 0.04)

    # Sorriso
    $pen = New-Object System.Drawing.Pen($inchiostro, ($s * 0.024))
    $pen.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
    $pen.EndCap = [System.Drawing.Drawing2D.LineCap]::Round
    $g.DrawArc($pen, $fx + $fw * 0.36, $fy + $fh * 0.50, $fw * 0.28, $fh * 0.24, 20, 140)
}

$size = 1024
$petrolio = C 0 122 135
$petrolioScuro = C 0 84 96

# 1) Icona completa
$bmp = New-Object System.Drawing.Bitmap($size, $size)
$g = [System.Drawing.Graphics]::FromImage($bmp)
$grad = New-Object System.Drawing.Drawing2D.LinearGradientBrush((New-Object System.Drawing.Point(0, 0)), (New-Object System.Drawing.Point($size, $size)), $petrolio, $petrolioScuro)
$g.FillRectangle($grad, 0, 0, $size, $size)
Disegna-Stokky $g $size $false ([System.Drawing.Color]::White)
$bmp.Save((Join-Path $OutDir 'icona.png'), [System.Drawing.Imaging.ImageFormat]::Png)
$g.Dispose(); $bmp.Dispose()

# 2) Primo piano dell'icona adattiva (zona sicura: 66% centrale)
$bmp = New-Object System.Drawing.Bitmap($size, $size)
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.Clear([System.Drawing.Color]::Transparent)
$g.TranslateTransform($size * 0.17, $size * 0.17)
Disegna-Stokky $g ($size * 0.66) $false ([System.Drawing.Color]::White)
$bmp.Save((Join-Path $OutDir 'icona_primo_piano.png'), [System.Drawing.Imaging.ImageFormat]::Png)
$g.Dispose(); $bmp.Dispose()

# 3) Icona notifiche: sagoma bianca su trasparente
$s = 96
$bmp = New-Object System.Drawing.Bitmap($s, $s)
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.Clear([System.Drawing.Color]::Transparent)
$g.TranslateTransform(-$s * 0.08, -$s * 0.12)
Disegna-Stokky $g ($s * 1.25) $true ([System.Drawing.Color]::White)
$bmp.Save((Join-Path $OutDir 'ic_notifica.png'), [System.Drawing.Imaging.ImageFormat]::Png)
$g.Dispose(); $bmp.Dispose()
