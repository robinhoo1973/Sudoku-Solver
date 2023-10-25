

Class Cell{
    [uint16]                            $x
    [uint16]                            $y
    [uint16]                            $value
    [array]                             $valid=@()
    [array]                             $iterated=@()
    Cell([uint16]$x,[uint16]$y,[int[,]]$matrix){
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

    [array] GetValid([int[,]]$matrix){
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

    [bool] GetNextValue([int[,]]$matrix){
        $private:valid = $this.GetValid($matrix)
        $private:available = [array] ($this.seeds |Where-Object{$_ -in $private:valid}|Sort-Object)
        $this.Value=0
        if($private:available.count -ne 0){
            $this.Value     =  $private:available[0] - 48
            $this.iterated  += $private:available[0]
        }
        return $this.Value -ne 0
    }
}

Class Sudoku{
    [int[,]]    $matrix
    [Cell[]]    $cells
    [array]     $preset=@()
    Sudoku(){
        $this.matrix = [int[,]]::new(10,10)
    }


    [void] Initialize(){
        for($private:x=1;$private:x -le 9;$private:x++){
            for($private:y=1;$private:y -le 9;$private:y++){
                if($this.matrix[$private:x,$private:y] -eq 0){
                    $this.cells += [Cell]::new($private:x,$private:y,$this.matrix)
                }
                else{
                    $this.preset+="{0},{1}" -f $private:x,$private:y
                }
            }
        }
        $this.cells = [array] ($this.cells|Sort-Object -Property counts)
        $this.DisplaySudoku()

    }
    [void] DisplaySudoku(){

        Write-Host "+---+---+---+---+---+---+---+---+---+"
        for($private:j=1;$private:j -le 9;$private:j++){
            $private:line="|"
            for($private:i=1;$private:i -le 9;$private:i++){
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
$Sudoku = [Sudoku]::new()
$Sudoku.matrix[1,6]=2
$Sudoku.matrix[2,3]=2
$Sudoku.matrix[2,7]=7
$Sudoku.matrix[3,2]=5
$Sudoku.matrix[3,4]=4
$Sudoku.matrix[3,6]=6
$Sudoku.matrix[3,8]=3
$Sudoku.matrix[4,1]=6
$Sudoku.matrix[4,3]=8
$Sudoku.matrix[4,5]=9
$Sudoku.matrix[4,7]=4
$Sudoku.matrix[5,4]=2
$Sudoku.matrix[5,6]=7
$Sudoku.matrix[6,3]=4
$Sudoku.matrix[6,5]=6
$Sudoku.matrix[6,7]=3
$Sudoku.matrix[6,9]=1
$Sudoku.matrix[7,2]=3
$Sudoku.matrix[7,4]=5
$Sudoku.matrix[7,6]=8
$Sudoku.matrix[7,8]=7
$Sudoku.matrix[8,3]=7
$Sudoku.matrix[8,7]=9
$Sudoku.matrix[9,4]=3

$Sudoku.Initialize()
$Sudoku.Seeking()
