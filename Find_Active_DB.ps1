$chosenMachine  = $OctopusParameters["Octopus.Action[Choose Cluster For Deployment].Output.ChosenMachine"]
$currentMachine = $OctopusParameters['Octopus.Machine.Id']
$currentMachineName = $OctopusParameters['Octopus.Machine.Name']
$alwaysOn = $OctopusParameters['Server_AlwaysOn_Enabled']
$alwaysOnClusterInstance = $OctopusParameters['Server_DB_Instance_Name']

if ($chosenMachine -eq $null -or $chosenMachine.length -eq 0)
{
    if ($alwaysOn -eq "false")
    {
        Set-OctopusVariable -name "ChosenMachine" -value "$currentMachine"
        write-host "Choosing machine: $currentMachine"
    }
    else
    {
        #we need to connect to the always on cluster and determine the primary server
        ######################################
        $serverName = $OctopusParameters['Server_DB_Local_Instance']
        $sqlLogin = $OctopusParameters['Server_DB_Admin_User']
        $sqlPassword = $OctopusParameters['Server_DB_Admin_Password']
        $ISdbName = $OctopusParameters['Database_InitialStaging_DBName']
        $MDdbName = $OctopusParameters['Database_MasterData_DBName']
        $dbInstanceName = $OctopusParameters['Server_DB_Instance_Name']
        
        [System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.SMO") | Out-Null
        [System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.SmoExtended") | Out-Null
        [System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.ConnectionInfo") | Out-Null
        [System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.SmoEnum") | Out-Null
        
        $server = new-object Microsoft.SqlServer.Management.Smo.Server $serverName
        
        
        if ($sqlLogin -ne $null -and $sqlLogin -ne "") {
            if ($sqlPassword -eq $null -or $sqlPassword -eq "") {
                throw "SQL Password must be specified when using SQL authentication."
            }
            Write-Host "Connecting to server using SQL authentication as $SqlLogin."
            $server.ConnectionContext.LoginSecure = $false
            $server.ConnectionContext.Login = $SqlLogin
            $server.ConnectionContext.Password = $sqlPassword
            $server = New-Object Microsoft.SqlServer.Management.Smo.Server $server.ConnectionContext
        }
        else {
            Write-Host "Connecting to server using Windows authentication."
        }
        
        try {
            $server.ConnectionContext.Connect()
        } catch {
            Write-Error "An error occurred connecting to the database server!`r`n$($_.Exception.ToString())"
            return -1
        }
        Write-Host "Connected to server."

        ######################################
        $masterDB = $server.Databases["master"]
        
        #Before the database can be restored, it needs to be removed from always on availability!
        try
        {
            Write-Host "Attempting to discover primary node from AlwaysOn cluster"
            $alwaysOnQuery = "SELECT TOP 1 hags.primary_replica FROM  sys.dm_hadr_availability_group_states hags INNER JOIN sys.availability_groups ag ON ag.group_id = hags.group_id WHERE ag.name = '$alwaysOnClusterInstance';"
            $ds = $masterDB.ExecuteWithResults($alwaysOnQuery)
            $primaryNode = ""
            Foreach ($t in $ds.Tables)
            {
               Foreach ($r in $t.Rows)
               {
                  Foreach ($c in $t.Columns)
                  {
                      $primaryNode = $r.Item($c)
                  }
               }
            }
            Write-Host "Primary host is: $primaryNode"
            Write-Host "Current Machine is: $currentMachineName"
            
            if ($currentMachineName -like "*$primaryNode*")
            {
                Set-OctopusVariable -name "ChosenMachine" -value "$currentMachine"
                write-host "Choosing machine: $currentMachine"
            }
            else
            {
                Write-Host "Not choosing current machine."
            }
        }
        catch
        {
            # Handle the error
            #write-host "error:"
            echo $_.Exception|format-list -force
            #write-error "failed to remove always on availability."
            #return 1
        }
    }
}
else {
    write-host "Machine already chosen - skipping"
}