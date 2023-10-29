
Class Cell {
    [uint16]    $x
    [uint16]    $y
    [uint16]    $available  = 0
    [char]      $seed       = "0"
    [char[]]    $iterated   = @()
    Cell([uint16]$x, [uint16]$y) {
        $this.x = $x
        $this.y = $y
        $this.Seeding()
    }

    [void] Seeding() {
        $private:seeds = "123456789"
        $g = [math]::floor($this.x / 3) + [math]::floor($this.y / 3) * 3
        $private:mask = "{0}{1}{2}{3}" -f ([Sudoku]::xrows[$this.x] -join ''), ([Sudoku]::yrows[$this.y] -join ''), ([Sudoku]::group[$g] -join ''), ($this.iterated -join '')
        if ($private:mask.length -ne 0) {
            $private:seeds = $private:seeds -replace "[$private:mask]"
        }
        if ($private:seeds.length -ne 0) {
            $private:seeds = [char[]] $private:seeds.ToCharArray()
            [array]::sort($private:seeds)
        }
        else {
            $private:seeds = [char[]] @()
        }
        $this.available = $private:seeds.count
        $this.seed = "0"
        if($this.available -ne 0){
            $this.seed  = $private:seeds[0]
        }
    }
}

Class Sudoku {
            [char[, ]]  $matrix
            [Cell[]]    $available  = @()
            [array]     $preset     = @()
            [datetime]  $starttick
    static  [array]     $xrows      = @()
    static  [array]     $yrows      = @()
    static  [array]     $group      = @()

    Sudoku([string]$matrix) {
        $private:lines = ($matrix -replace "[ |\.]", "0") -split "\n"
        $private:size = $private:lines.length
        $this.matrix = [char[,]]::new($private:size, $private:size)
        [Sudoku]::xrows = [array[]]::new($private:size)
        [Sudoku]::yrows = [array[]]::new($private:size)
        [Sudoku]::group = [array[]]::new($private:size)
        for ($private:y = 0; $private:y -lt $private:size; $private:y++) {
            $private:line = ($private:lines[$private:y]).ToCharArray()
            for ($private:x = 0; $private:x -lt $private:size; $private:x++) {
                $this.SetCellValue($private:x, $private:y, $private:line[$private:x])
            }
        }
        $this.Initialize()
    }

    [void]SetCellValue([int]$x, [int]$y, [char]$v) {
        $g = [math]::floor($x / 3) + [math]::floor($y / 3) * 3
        $this.DelCellValue($x, $y)
        if ($v -ne "0") {
            $this.matrix[$x, $y] = $v
            [Sudoku]::xrows[$x] += $v
            [Sudoku]::yrows[$y] += $v
            [Sudoku]::group[$g] += $v
            [array]::sort([Sudoku]::xrows[$x])
            [array]::sort([Sudoku]::yrows[$y])
            [array]::sort([Sudoku]::group[$g])
        }
    }

    [void]DelCellValue([int]$x, [int]$y) {
        $v = $this.matrix[$x, $y]
        $this.matrix[$x, $y] = "0"
        $g = [math]::floor($x / 3) + [math]::floor($y / 3) * 3
        $private:mask = ([Sudoku]::xrows[$x] -join '') -replace $v
        if ($private:mask.length -ne 0) {
            [Sudoku]::xrows[$x] = $private:mask.ToCharArray()
        }
        else {
            [Sudoku]::xrows[$x] = @()
        }
        $private:mask = ([Sudoku]::yrows[$y] -join '') -replace $v
        if ($private:mask.length -ne 0) {
            [Sudoku]::yrows[$y] = $private:mask.ToCharArray()
        }
        else {
            [Sudoku]::yrows[$y] = @()
        }
        $private:mask = ([Sudoku]::group[$g] -join '') -replace $v
        if ($private:mask.length -ne 0) {
            [Sudoku]::group[$g] = $private:mask.ToCharArray()
        }
        else {
            [Sudoku]::group[$g] = @()
        }
    }

    [void] Initialize() {
        $private:size = [math]::sqrt($this.matrix.length)
        for ($private:x = 0; $private:x -lt $private:size; $private:x++) {
            for ($private:y = 0; $private:y -lt $private:size; $private:y++) {
                if ($this.matrix[$private:x, $private:y] -eq "0") {
                    $this.available += [Cell]::new($private:x, $private:y)
                }
                else {
                    $this.preset += "{0},{1}" -f $private:x, $private:y
                }
            }
        }
        Write-Host ("{0:yyyy}-{0:MM}-{0:dd} {0:HH}:{0:mm}:{0:ss}" -f (Get-Date))
        $this.DisplaySudoku()
        $this.available   = [Cell[]] ($this.available | Sort-Object -Property available)
        $this.starttick = Get-Date
    }

    [void] DisplaySudoku() {
        $private:size = [math]::sqrt($this.matrix.length)
        Write-Host "+---+---+---+---+---+---+---+---+---+"
        for ($private:y = 0; $private:y -lt $private:size; $private:y++) {
            $private:line = "|"
            for ($private:x = 0; $private:x -lt $private:size; $private:x++) {
                if ($this.matrix[$private:x, $private:y] -ne "0") {
                    if (("{0},{1}" -f $private:x, $private:y) -in $this.preset) {
                        $private:line = "{0}[{1}]|" -f $private:line, $this.matrix[$private:x, $private:y]
                    }
                    else {
                        $private:line = "{0} {1} |" -f $private:line, $this.matrix[$private:x, $private:y]
                    }
                }
                else {
                    $private:line = "{0}   |" -f $private:line
                }
            }
            Write-Host $private:line
            Write-Host "+---+---+---+---+---+---+---+---+---+"
        }
        Write-Host ""
    }

    [void] Seeking() {
        $private:index = 0
        while ($private:index -lt $this.available.count -and $private:index -ge 0){
            $this.available[$private:index].Seeding()
            $this.SetCellValue($this.available[$private:index].x,$this.available[$private:index].y,$this.available[$private:index].seed)
            if($this.available[$private:index].seed -ne "0"){
                $this.available[$private:index].iterated += $this.available[$private:index].seed
                if ($private:index -eq $this.available.count-1) {
                    Write-Host ("{0:yyyy}-{0:MM}-{0:dd} {0:HH}:{0:mm}:{0:ss}" -f (Get-Date))
                    Write-Host ("{0:hh}:{0:mm}:{0:ss} -- {1:hh}:{1:mm}:{1:ss}" -f $this.starttick, (Get-Date))
                    $this.DisplaySudoku()
                }
                else{
                    $private:index++
                }
            }
            else{
                $this.available[$private:index].iterated = @()
                $private:index--
                $this.DelCellValue($this.available[$private:index].x,$this.available[$private:index].y)
            }

            for($i=$private:index;$i -lt $this.available.count;$i++){
                $this.available[$i].Seeding()   
            }
            if($private:index -lt $this.available.count -and $private:index -ge 0){
                $private:available = [Cell[]] ($this.available[$private:index..($this.available.count-1)]| Sort-Object -Property available)
                [array]::copy($private:available,0,$this.available,$private:index,$private:available.count)
            }

        }
    }
}
$PSDefaultParameterValues['*:Encoding'] = 'utf8'

$Sudoku = [Sudoku]::new(@"
1.4.67...
5.983..4.
.7..9.3..
8..5.....
..51.67..
.....9..5
..1.7..3.
.9..541.2
...91.6.4
"@)

$Sudoku.Seeking()


$Sudoku = [Sudoku]::new(@"
...6.....
..5...3..
.2.8.4.7.
..4.2.5.3
...9.6...
2.6.7.8..
.7.4.3.9.
..3...7..
.....1...
"@)

$Sudoku.Seeking()

$Sudoku = [Sudoku]::new(@"
8........
..36.....
.7..9.2..
.5...7...
....457..
...1...3.
..1....68
..85...1.
.9....4..
"@)

$Sudoku.Seeking()
