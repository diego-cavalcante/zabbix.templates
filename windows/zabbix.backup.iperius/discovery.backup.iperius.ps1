# Desenvolvido por Diego Cavalcante - 22/12/2017
# Monitora atividade de Jobs do Iperius Backup

Param(
  [string]$select,
  [string]$2
)

# Variáveis

$dirjobs = "C:\ProgramData\IperiusBackup\Jobs"
$dirlogs = "C:\ProgramData\IperiusBackup\Logs"

if ( $select -eq 'JSONJOBS' )
{
$comando = Get-ChildItem "$dirjobs" | Select Basename

$comparador = 1
write-host "{"
write-host " `"data`":[`n"
foreach ($objeto in $comando)
{
  $Name = [string]$objeto.BaseName
    if ($comparador -lt $comando.Count)
    {
    $line= "{ `"{#JOBCONF}`" : `"" + $Name + "`" },"
    write-host $line
    }
    elseif ($comparador -ge $comando.Count)
    {
    $line= "{ `"{#JOBCONF}`" : `"" + $Name + "`" }"
    write-host $line
    }
    $comparador++;
}
write-host
write-host " ]"
write-host "}"
}

# Coleta o nome do Job
if ( $select -eq 'JOBNOME' )
{
type $dirjobs\$2.ibj | FindStr "NAME=" | ForEach-Object {$_ -Replace "NAME=", ""}
}

# Coleta o ultimo status do Job
if ( $select -eq 'JOBSTATUS' )
{
type $dirjobs\$2.ibj | FindStr "LastResult=" | ForEach-Object {$_ -Replace "LastResult=", ""}
}

# Coleta a data e hora de inicio do ultimo Job
if ( $select -eq 'JOBINICIO' )
{
type $dirlogs\$2\LogFile.txt | FindStr "Iniciar backup:" | select -First 1 | ForEach-Object {$_ -Replace "Iniciar backup: ", ""}
}

# Coleta a data e hora do fim do ultimo Job
if ( $select -eq 'JOBFIM' ) 
{
type $dirlogs\$2\LogFile.txt | FindStr "Iniciar backup:" | select -Last 1 | ForEach-Object {$_ -Replace "Fim do backup: ", ""}
}

# Coleta o tempo que o ultimo Job levou para finalizar
if ( $select -eq 'JOBTEMPO' ) 
{
type $dirlogs\$2\LogFile.txt | FindStr "Tempo decorrido:" | select -First 1 | ForEach-Object {$_ -Replace "Tempo decorrido: ", ""} | ForEach-Object {$_ -Replace "[a-zA-Z :]", ""} | ForEach-Object {$_ -Replace ",", ":"}
}
