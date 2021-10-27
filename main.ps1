$ResourceGroupName = "rg-wvd-eas-prd-com-01"
$HostPoolName = "hp-wvd-eas-prd-com-07"

$WvdSessionHost = Get-AzWvdSessionHost -ResourceGroupName $ResourceGroupName -HostPoolName $HostPoolName

foreach($SessionHostName in $WvdSessionHost.name){
    $SessionHostName = $SessionHostName.split("/")
    $VmName = $SessionHostName[1].split(".")
    $Status = Get-AzWvdUserSession -ResourceGroupName $ResourceGroupName -HostPoolName $HostPoolName -SessionHostName $SessionHostName[1]
    if ($Null -eq $Status) {
        Stop-AzVM -ResourceGroupName $ResourceGroupName -Name $VmName[0]
    }
}
