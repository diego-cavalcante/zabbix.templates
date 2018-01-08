# Desenvolvido por Diego Cavalcante - 10/02/2017
# Monitoramento Windows RDP - Terminal Server

Param(
  [string]$select
)

# Nome dos Usuarios Ativos
if ( $select -eq 'ATIVO' )
{
Import-Module PSTerminalServices
Get-TSSession -State Active -ComputerName localhost | foreach {$_.UserName}
}

# Total de Usuarios Ativos
if ( $select -eq 'ATIVONUM' )
{
Import-Module PSTerminalServices
Get-TSSession -State Active -ComputerName localhost | foreach {$_.UserName} | Measure-Object -Line | select-object Lines | select-object -ExpandProperty Lines
}

# Nome dos Usuarios Inativos
if ( $select -eq 'INATIVO' )
{
Import-Module PSTerminalServices
Get-TSSession -State Disconnected -ComputerName localhost | where { $_.SessionID -ne 0 } | foreach {$_.UserName}
}

# Total de Usuarios Inativos
if ( $select -eq 'INATIVONUM' )
{
Import-Module PSTerminalServices
Get-TSSession -State Disconnected -ComputerName localhost | where { $_.SessionID -ne 0 } | foreach {$_.UserName} | Measure-Object -Line | select-object Lines | select-object -ExpandProperty Lines
}

# Nome do Dispositivo Remoto
if ( $select -eq 'DEVICE' )
{
Import-Module PSTerminalServices
Get-TSSession -State Active -ComputerName localhost | foreach {$_.ClientName}
}

# IP do Dispositivo Remoto
if ( $select -eq 'IP' )
{
Import-Module PSTerminalServices
Get-TSSession -State Active -ComputerName localhost | foreach {(($_.IPAddress).IPAddressToString)}
}
