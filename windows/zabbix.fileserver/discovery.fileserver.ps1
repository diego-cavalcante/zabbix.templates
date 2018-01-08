# Desenvolvido por Diego Cavalcante - 12/12/2017
# Monitoramento File Server, Tamanho de Diretórios e Contagem de Arquivos.

Param(
  [string]$select,
  [string]$dir
)
if ( $select -eq 'JSONDIR' ) 
{
$comando = ls $dir | select-object Name | select-object -ExpandProperty Name
$idx = 1
write-host "{"
write-host " `"data`":[`n"
foreach ($a in $comando)
{
    if ($idx -lt $comando.Count)
    {
        $line= "{ `"{#DIRETORIO}`" : `"" + $a + "`" },"
        write-host $line
    }
    elseif ($idx -ge $comando.Count)
    {
    $line= "{ `"{#DIRETORIO}`" : `"" + $a + "`" }"
    write-host $line
    }
    $idx++;
}
write-host
write-host " ]"
write-host "}"
}
