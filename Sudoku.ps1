
Class Cell {
    [uint16]    $x
    [uint16]    $y
    [uint16]    $available  = 0
    [char]      $seed       = "0"
    [string]    $iterated   = ""
    Cell([uint16]$x, [uint16]$y) {
        $this.x = $x
        $this.y = $y
        $this.Seeding()
    }

    [void] Seeding() {
        $private:seeds = "123456789"
        $g = [math]::floor($this.x / 3) + [math]::floor($this.y / 3) * 3
        $private:mask = "{0}{1}{2}{3}" -f [Sudoku]::x_grp[$this.x], [Sudoku]::y_grp[$this.y], [Sudoku]::b_grp[$g], $this.iterated
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

# Class CellComparer: System.Collections.Generic.IComparer[Cell]
# {
#     [int] Compare([Cell] $x, [Cell] $y)
#     {
#         return $x.available -lt $y.available;
#     }
# }
Class Sudoku {
            [char[, ]]  $matrix
            [Cell[]]    $queue  = @()
            [array]     $preset     = @()
            [datetime]  $starttime
    static  [array]     $x_grp      = @()
    static  [array]     $y_grp      = @()
    static  [array]     $b_grp      = @()

    Sudoku([string]$matrix) {
        $private:lines = ($matrix -replace "[ |\.]", "0") -split "\n"
        $private:size = $private:lines.length
        $this.matrix = [char[,]]::new($private:size, $private:size)
        [Sudoku]::x_grp = [string[]]::new($private:size)
        [Sudoku]::y_grp = [string[]]::new($private:size)
        [Sudoku]::b_grp = [string[]]::new($private:size)
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
            [Sudoku]::x_grp[$x] += $v
            [Sudoku]::y_grp[$y] += $v
            [Sudoku]::b_grp[$g] += $v
        }
    }

    [void]DelCellValue([int]$x, [int]$y) {
        $v = $this.matrix[$x, $y]
        $this.matrix[$x, $y] = "0"
        $g = [math]::floor($x / 3) + [math]::floor($y / 3) * 3
        [Sudoku]::x_grp[$x]=[Sudoku]::x_grp[$x] -replace $v
        [Sudoku]::y_grp[$y]=[Sudoku]::y_grp[$y] -replace $v
        [Sudoku]::b_grp[$g]=[Sudoku]::b_grp[$g] -replace $v
    }

    [void] Initialize() {
        $private:size = [math]::sqrt($this.matrix.length)
        for ($private:x = 0; $private:x -lt $private:size; $private:x++) {
            for ($private:y = 0; $private:y -lt $private:size; $private:y++) {
                if ($this.matrix[$private:x, $private:y] -eq "0") {
                    $this.queue += [Cell]::new($private:x, $private:y)
                }
                else {
                    $this.preset += "{0},{1}" -f $private:x, $private:y
                }
            }
        }
        Write-Host ("{0:yyyy}-{0:MM}-{0:dd} {0:HH}:{0:mm}:{0:ss}.{0:fff}" -f (Get-Date))
        $this.DisplaySudoku()
        # [array]::sort($this.queue,[CellComparer]::new())
        # $this.queue   = [System.Linq.Enumerable]::OrderBy([Cell[]]$this.queue,[Func[Cell,uint16]] {($args[0]).available})
        $this.queue   = [Cell[]] ($this.queue | Sort-Object -Property available)
        $this.starttime = Get-Date
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
        while ($private:index -lt $this.queue.count -and $private:index -ge 0){
            $this.queue[$private:index].Seeding()
            $this.SetCellValue($this.queue[$private:index].x,$this.queue[$private:index].y,$this.queue[$private:index].seed)
            if($this.queue[$private:index].seed -ne "0"){
                $this.queue[$private:index].iterated += $this.queue[$private:index].seed
                if ($private:index -eq $this.queue.count-1) {
                    Write-Host ("{0:yyyy}-{0:MM}-{0:dd} {0:HH}:{0:mm}:{0:ss}.{0:fff}" -f (Get-Date))
                    Write-Host ("{0:HH}:{0:mm}:{0:ss}.{0:fff} -- {1:HH}:{1:mm}:{1:ss}.{1:fff}" -f $this.starttime, (Get-Date))
                    $this.DisplaySudoku()
                }
                else{
                    $private:index++
                }
            }
            else{
                $this.queue[$private:index].iterated = ""
                $private:index--
                $this.DelCellValue($this.queue[$private:index].x,$this.queue[$private:index].y)
            }

            for($i=$private:index;$i -lt $this.queue.count;$i++){
                $this.queue[$i].Seeding()   
            }
            if($private:index -lt $this.queue.count -and $private:index -ge 0){
                $private:queue = [Cell[]]$this.queue[$private:index..($this.queue.count-1)]
                # [array]::sort($private:queue,[CellComparer]::new())
                # $private:queue   = [Cell[]] [System.Linq.Enumerable]::OrderBy([Cell[]]$private:queue,[Func[Cell,uint16]] {($args[0]).available})
                $private:queue = [Cell[]] ($this.queue[$private:index..($this.queue.count-1)]| Sort-Object -Property available)
                [array]::copy($private:queue,0,$this.queue,$private:index,$private:queue.count)
            }
        }
    }
}
$PSDefaultParameterValues['*:Encoding'] = 'utf8'
$starttime=(get-date)
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

Write-Host
Write-Host ("{0:yyyy}-{0:MM}-{0:dd} {0:HH}:{0:mm}:{0:ss}.{0:fff} -- {1:yyyy}-{1:MM}-{1:dd} {1:HH}:{1:mm}:{1:ss}.{1:fff}" -f $starttime, (Get-Date))
