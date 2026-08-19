Add-Type -AssemblyName System.Drawing

function Remove-Checkerboard($bmp) {
    for ($y = 0; $y -lt $bmp.Height; $y++) {
        for ($x = 0; $x -lt $bmp.Width; $x++) {
            $p = $bmp.GetPixel($x, $y)
            if ($p.A -lt 30) { continue }
            $brightness = ($p.R + $p.G + $p.B) / 3
            $rgDiff = [Math]::Abs($p.R - $p.G)
            $rbDiff = [Math]::Abs($p.R - $p.B)
            $gbDiff = [Math]::Abs($p.G - $p.B)
            if ($rgDiff -lt 20 -and $rbDiff -lt 20 -and $gbDiff -lt 20 -and $brightness -gt 170 -and $brightness -lt 250) {
                $bmp.SetPixel($x, $y, [System.Drawing.Color]::Transparent)
            }
        }
    }
}

function Crop-Content($bmp) {
    $minX = $bmp.Width; $minY = $bmp.Height; $maxX = 0; $maxY = 0
    $found = $false
    for ($y = 0; $y -lt $bmp.Height; $y++) {
        for ($x = 0; $x -lt $bmp.Width; $x++) {
            if ($bmp.GetPixel($x, $y).A -gt 20) {
                $found = $true
                if ($x -lt $minX) { $minX = $x }
                if ($y -lt $minY) { $minY = $y }
                if ($x -gt $maxX) { $maxX = $x }
                if ($y -gt $maxY) { $maxY = $y }
            }
        }
    }
    if (-not $found) { return $bmp }
    $w = $maxX - $minX + 1
    $h = $maxY - $minY + 1
    $cropped = $bmp.Clone([System.Drawing.Rectangle]::FromLTRB($minX, $minY, $maxX+1, $maxY+1), $bmp.PixelFormat)
    $bmp.Dispose()
    return $cropped
}

function Resize-Center($img, $size) {
    $result = New-Object System.Drawing.Bitmap($size, $size)
    $g = [System.Drawing.Graphics]::FromImage($result)
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
    $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::Half
    $g.Clear([System.Drawing.Color]::Transparent)
    $scale = [Math]::Min($size / $img.Width, $size / $img.Height)
    $newW = [int]($img.Width * $scale)
    $newH = [int]($img.Height * $scale)
    $offX = [int](($size - $newW) / 2)
    $offY = [int](($size - $newH) / 2)
    $g.DrawImage($img, $offX, $offY, $newW, $newH)
    $g.Dispose()
    $img.Dispose()
    return $result
}

function Process-Static($input, $output, $size) {
    $img = [System.Drawing.Image]::FromFile($input)
    $bmp = New-Object System.Drawing.Bitmap($img)
    $img.Dispose()
    Remove-Checkerboard $bmp
    $cropped = Crop-Content $bmp
    $result = Resize-Center $cropped $size
    $result.Save($output, [System.Drawing.Imaging.ImageFormat]::Png)
    $result.Dispose()
    Write-Host "Processed: $output"
}

function Process-SpriteSheet($input, $output, $frames, $size) {
    $img = [System.Drawing.Image]::FromFile($input)
    $bmp = New-Object System.Drawing.Bitmap($img)
    $img.Dispose()
    $frameW = [int]($bmp.Width / $frames)
    $frameH = $bmp.Height
    $sheet = New-Object System.Drawing.Bitmap($size * $frames, $size)
    $sg = [System.Drawing.Graphics]::FromImage($sheet)
    $sg.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
    $sg.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::Half
    $sg.Clear([System.Drawing.Color]::Transparent)
    for ($i = 0; $i -lt $frames; $i++) {
        $frame = $bmp.Clone([System.Drawing.Rectangle]::FromLTRB($i*$frameW, 0, ($i+1)*$frameW, $frameH), $bmp.PixelFormat)
        Remove-Checkerboard $frame
        $cropped = Crop-Content $frame
        $scale = [Math]::Min($size / $cropped.Width, $size / $cropped.Height)
        $newW = [int]($cropped.Width * $scale)
        $newH = [int]($cropped.Height * $scale)
        $offX = [int](($size - $newW) / 2)
        $offY = [int](($size - $newH) / 2)
        $sg.DrawImage($cropped, $i*$size + $offX, $offY, $newW, $newH)
        $cropped.Dispose()
    }
    $sg.Dispose()
    $bmp.Dispose()
    $sheet.Save($output, [System.Drawing.Imaging.ImageFormat]::Png)
    $sheet.Dispose()
    Write-Host "Processed sheet: $output"
}

function Process-Tile($input, $output, $size) {
    $img = [System.Drawing.Image]::FromFile($input)
    $result = New-Object System.Drawing.Bitmap($size, $size)
    $g = [System.Drawing.Graphics]::FromImage($result)
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
    $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::Half
    $g.DrawImage($img, 0, 0, $size, $size)
    $g.Dispose()
    $img.Dispose()
    $result.Save($output, [System.Drawing.Imaging.ImageFormat]::Png)
    $result.Dispose()
    Write-Host "Processed tile: $output"
}

$dir = "E:\GodotProjects\newgame"
$out = "$dir\processed"
if (-not (Test-Path $out)) { New-Item -ItemType Directory -Path $out | Out-Null }

# 精灵表
Process-SpriteSheet "$dir\raw_enemy_normal_walk.png" "$out\enemy_normal_walk.png" 4 32
Process-SpriteSheet "$dir\raw_enemy_fast_walk.png" "$out\enemy_fast_walk.png" 4 32
Process-SpriteSheet "$dir\raw_enemy_ranged_walk.png" "$out\enemy_ranged_walk.png" 4 32

# 塔防
Process-Static "$dir\raw_tower_machinegun.png" "$out\tower_machinegun.png" 32
Process-Static "$dir\raw_tower_cannon.png" "$out\tower_cannon.png" 32
Process-Static "$dir\raw_tower_laser.png" "$out\tower_laser.png" 32
Process-Static "$dir\raw_tower_mortar.png" "$out\tower_mortar.png" 32

# 子弹
Process-Static "$dir\raw_bullet_player.png" "$out\bullet_player.png" 16
Process-Static "$dir\raw_bullet_enemy.png" "$out\bullet_enemy.png" 16

# 爆炸/建造点
Process-Static "$dir\raw_explosion.png" "$out\explosion.png" 32
Process-Static "$dir\raw_build_spot.png" "$out\build_spot.png" 32

# 设施
Process-Static "$dir\raw_facility_medical.png" "$out\facility_medical.png" 32
Process-Static "$dir\raw_facility_workshop.png" "$out\facility_workshop.png" 32
Process-Static "$dir\raw_facility_power.png" "$out\facility_power.png" 32

# 障碍物
Process-Static "$dir\raw_obstacle_rubble.png" "$out\obstacle_rubble.png" 32
Process-Static "$dir\raw_obstacle_car.png" "$out\obstacle_car.png" 32
Process-Static "$dir\raw_obstacle_sandbag.png" "$out\obstacle_sandbag.png" 32

# 瓦片
Process-Tile "$dir\raw_tile_concrete.png" "$out\tile_concrete.png" 32
Process-Tile "$dir\raw_tile_dirt.png" "$out\tile_dirt.png" 32
Process-Tile "$dir\raw_tile_metal.png" "$out\tile_metal.png" 32

Write-Host "ALL DONE"
