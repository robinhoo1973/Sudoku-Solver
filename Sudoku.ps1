

Class Cell{
    [uint16]                            $x
    [uint16]                            $y
    [char]                              $value
    [array]                             $valid=@()
    [array]                             $iterated=@()
    Cell([uint16]$x,[uint16]$y,[char[,]]$matrix){
        $this.x         = $x
        $this.y         = $y
        $this.valid     = $this.GetValid($matrix)
        $this|Add-Member -Name 'seeds' -MemberType ScriptProperty  -Value {
            return [array] ($this.valid |Where-Object{$_ -notin $this.iterated})
        }
        $this|Add-Member -Name 'counts' -MemberType ScriptProperty  -Value {
            return ([array] ($this.valid |Where-Object{$_ -notin $this.iterated})).count
        }
    }

    [array] GetValid([char[,]]$matrix){
        $private:Valid="123456789"
        $private:x=$this.x - ($this.x -1) % 3 - 1
        $private:y=$this.y - ($this.y -1) % 3 - 1

        for($private:i=1;$private:i -le 9;$private:i++){
            if($matrix[$this.x,$private:i] -ne 0 -and $private:i -ne $this.y){
                $private:Valid = $private:Valid -replace $matrix[$this.x,$private:i],""
            }
            if($matrix[$private:i,$this.y] -ne 0 -and $private:i -ne $this.x){
                $private:Valid = $private:Valid -replace $matrix[$private:i,$this.y],""
            }
            $private:posx=($private:x+($private:i - 1) % 3 + 1)
            $private:posy=($private:y+[int](($private:i+0.6)/3))
            if($matrix[$private:posx , $private:posy] -ne 0 -and $private:posx -ne $this.x -and $private:posy -ne $this.y){
                $private:Valid = $private:Valid -replace $matrix[$private:posx , $private:posy],""
            }
        }
        return [array]($private:Valid.ToCharArray()|Sort-Object)
    }

    [bool] GetNextValue([char[,]]$matrix){
        $private:valid = $this.GetValid($matrix)
        $private:available = [array] ($this.seeds |Where-Object{$_ -in $private:valid}|Sort-Object)
        $this.Value=0
        if($private:available.count -ne 0){
            $this.Value     =  $private:available[0]
            $this.iterated  += $private:available[0]
        }
        return $this.Value -ne 0
    }
}

Class Sudoku{
    [char[,]]    $matrix
    [Cell[]]    $cells
    [array]     $preset=@()
    [datetime]  $starttick
    Sudoku(){
        $this.ReadMatrix()
    }

    Sudoku([string]$matrix){
        $private:lines = ($matrix -replace "[ |\.]","0") -split "\n"
        $private:size = $private:lines.length
        $this.matrix = [char[,]]::new($private:size+1,$private:size+1)
        for($private:x=1;$private:x -le $private:size;$private:x++){
            $private:line=($private:lines[$private:x-1]).ToCharArray()
            for($private:y=1;$private:y -le $private:size;$private:y++){
                $this.matrix[$private:x,$private:y]=$private:line[$private:y-1]
            }
        }
        $this.Initialize()
    }

    [void]ReadMatrix(){
        $private:size = 0
        while($private:size -lt 2 -or $private:size -gt 5){
            Clear-Host
            Write-Host "The sudoku matrix is formed by N x N of 3x3 blocks."
            $private:size=[uint16](Read-Host -Prompt "Please input the N(N>1 and N<5)")
            if($private:size -lt 2 -or $private:size -gt 5){
                Read-Host -Prompt "N is too small or too big! Try agian!"
            }
        }
        $this.matrix = [char[,]]::new($private:size*3+1,$private:size*3+1)
        Write-Host "Please input the preset numbers in the Sudoku matrix line by line."
        Write-Host "Space, dot(.), or number 0 indicate the cell is empty."
        for($private:i=1;$private:i -le $private:size*3;$private:i++){
            $private:line = Read-Host -Prompt ("Please input line {0}" -f $private:i)
            $private:line=($private:line -replace "[ |\.]","0") -replace "[^0-9]"
            if($private:line.length -gt $private:size*3){
                $private:line = $private:line.Substring(0,$private:size*3)
            }
            elseif($private:line.length -lt $private:size*3){
                $private:line="{0}{1}" -f $private:line,("0"*($private:size*3 - $private:line.length))
            }
            Write-Host ("Normalized Line {0}" -f $private:line)
            $private:line=$private:line.ToCharArray()
            for($private:j=1;$private:j -le $private:size*3;$private:j++){
                $this.matrix[$private:i,$private:j]=$private:line[$private:j-1]
            }
        }
        $this.Initialize()
    }

    [void] Initialize(){
        for($private:x=1;$private:x -le 9;$private:x++){
            for($private:y=1;$private:y -le 9;$private:y++){
                if($this.matrix[$private:x,$private:y] -eq "0"){
                    $this.cells += [Cell]::new($private:x,$private:y,$this.matrix)
                }
                else{
                    $this.preset+="{0},{1}" -f $private:x,$private:y
                }
            }
        }
        $this.cells = [array] ($this.cells|Sort-Object -Property counts)
        $this.DisplaySudoku()
        $this.starttick = Get-Date
    }

    [void] DisplaySudoku(){
        Write-Host "+---+---+---+---+---+---+---+---+---+"
        for($private:i=1;$private:i -le 9;$private:i++){
            $private:line="|"
            for($private:j=1;$private:j -le 9;$private:j++){
                if($this.matrix[$private:i,$private:j] -ne 0){
                    if(("{0},{1}" -f $private:i,$private:j) -in $this.preset){
                        $private:line="{0}[{1}]|" -f $private:line,$this.matrix[$private:i,$private:j]
                    }
                    else{
                        $private:line="{0} {1} |" -f $private:line,$this.matrix[$private:i,$private:j]
                    }
                }
                else{
                    $private:line="{0}   |" -f $private:line
                }
            }
            Write-Host $private:line
            Write-Host "+---+---+---+---+---+---+---+---+---+"
        }
        Write-Host ""
    }

    [void] Seeking(){
        $private:index = 0
        while ($private:index -lt $this.cells.count -and $private:index -ge 0){
            $private:seek = $this.cells[$private:index].GetNextValue($this.matrix)
            $this.matrix[$this.cells[$private:index].x,$this.cells[$private:index].y]=$this.cells[$private:index].value
            if($private:seek){
                if($private:index -eq $this.cells.count-1){
                    $this.DisplaySudoku()
                    Write-Host ("Solution Found in {0:hh}:{0:mm}:{0:ss}" -f (New-TimeSpan -Start $this.starttick -End (Get-Date)) )
                }
                else{
                    $private:index++
                }
            }
            else{
                $this.cells[$private:index].iterated = @()
                $private:index--
            }
        }
    }
}
$PSDefaultParameterValues['*:Encoding'] = 'utf8'
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
