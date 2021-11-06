param (
    [Parameter(Mandatory=$false)] 
    [String]  $connectionName = 'AzureRunAsConnection',
        
    [Parameter(Mandatory=$false)] 
    [String] $ResourceGroupName = "rg-JackChan",
    [Parameter(Mandatory=$false)] 
    [String] $HostPoolName = "avd-host-pool-004"
)

try
{
    # Get the connection "AzureRunAsConnection "

    $servicePrincipalConnection = Get-AutomationConnection -Name $connectionName

    "Logging in to Azure..."
    $connectionResult =  Connect-AzAccount -Tenant $servicePrincipalConnection.TenantID `
    -ApplicationId $servicePrincipalConnection.ApplicationID   `
    -CertificateThumbprint $servicePrincipalConnection.CertificateThumbprint `
    -ServicePrincipal
    "Logged in."
}
catch {
    if (!$servicePrincipalConnection)
    {
        $ErrorMessage = "Connection $connectionName not found."
        throw $ErrorMessage
    } else{
        Write-Error -Message $_.Exception
        throw $_.Exception
    }
}

# Returns strings with status messages
[OutputType([String])]


$allAvailableSessionHosts = @()
try {
    $runningSessionHosts = (Get-AzWvdSessionHost -ErrorAction Stop -HostPoolName $HostPoolName -ResourceGroupName $ResourceGroupName | Where-Object { $_.AllowNewSession -eq $true } )
    $availableSessionHosts = ($runningSessionHosts | Where-Object { $_.Status -eq "Available" })
}
catch {
    $errMsg = $_.Exception.message
    Write-Error ("Error to get the available session hosts" + $errMsg)
    Break
}
foreach ($sessionHost in $availableSessionHosts){
    $sessionHostName = (($sessionHost).name -split '/')[1]
    $allAvailableSessionHosts += $sessionHostName
}
Write-Host $allAvailableSessionHosts 


foreach($sh in $allAvailableSessionHosts){

    try {
        $status = (Get-AzWvdUserSession -ResourceGroupName $ResourceGroupName -HostPoolName $HostPoolName -SessionHostName $sh).SessionState
        Write-Output $status
    }
    catch {
        $errMsg = $_.Exception.message
        Write-Error ("Error to get status from session host" + $errMsg)
        Break 
    }

    if($status -eq "Disconnected"){
        $VmName = ($sh.split("."))[0]
        Write-Output 'Shutdown a session host: '$VmName
        Stop-AzVM -ResourceGroupName $ResourceGroupName -Name $VmName -Force -NoWait
    }
    else {
        "Active User Still Logon the machine"
    }
}

# $WvdSessionHost = Get-AzWvdSessionHost -ResourceGroupName $ResourceGroupName -HostPoolName $HostPoolName


# foreach($SessionHostName in $WvdSessionHost.name){
#     $SessionHostName = $SessionHostName.split("/")
#     $VmName = $SessionHostName[1].split(".")
#     $Status = Get-AzWvdUserSession -ResourceGroupName $ResourceGroupName -HostPoolName $HostPoolName -SessionHostName $SessionHostName[1]
#     Write-Host $Null -eq $Status
#     if ($Null -eq $Status) {
#         Stop-AzVM -ResourceGroupName $ResourceGroupName -Name $VmName[0]
#     }
#     else{
#         "Active User Still Logon the machine"
#     }
# }