#################################################################################################################################################################
# Script name : SQL_Database_Info
# Version : v1.2
# https://github.com/michaeldallariva
# Language : Powershell
# Release date : Feb 1st 2025
# Author : Michael DALLA RIVA, with the help of some AI
# Purpose : Gather Microsoft SQL databases names and sizes in a log file to monitor the evolution of the size they occupy on disk(s) over a period of 12 months.
# License : None. Feel free to use for any purpose. Personal or Commercial.
# 
#  Additional informations :
# - Run this script once a month
# - This script will always create a debug file to make it easier to troubleshoot if you are having errors (sql_inventory_debug.log)
# - Run this script from your SQL server directly.
# - From a scheduled Windows task, use a service account that has read only access to your databases.
#################################################################################################################################################################

[System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.SMO') | Out-Null

# SQL Server instance names
# Edit the SQL instance(s) names here
$instanceNames = @("SQLSERVER1", "SQLSERVER1\Instance2")


$outputFolder = "C:\scripts\databasesreport"
$debugLogFile = "C:\scripts\databasesreport\sql_inventory_debug.log"

$currentDate = Get-Date -Format "dd-MM-yyyy HH:mm:ss"
Write-DebugLog "Current date: $currentDate"

function Write-DebugLog {
    param([string]$message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp - $message" | Out-File -FilePath $debugLogFile -Append
}

if (Test-Path $debugLogFile) {
    Clear-Content $debugLogFile
}

Write-DebugLog "Script started"

# Creates the output folder if it does not exist
if (!(Test-Path -Path $outputFolder)) {
    New-Item -ItemType Directory -Force -Path $outputFolder
    Write-DebugLog "Created output folder: $outputFolder"
} else {
    Write-DebugLog "Output folder already exists: $outputFolder"
}

foreach ($instanceName in $instanceNames) {
    Write-DebugLog "Processing instance: $instanceName"
    
    try {
        $server = New-Object ('Microsoft.SqlServer.Management.Smo.Server') $instanceName
        Write-DebugLog "Connected to instance: $instanceName"
    } catch {
        Write-DebugLog "Failed to connect to instance: $instanceName. Error: $_"
        continue
    }

    foreach ($database in $server.Databases) {
        $dbName = $database.Name
        $dbSize = [Math]::Round(($database.Size / 1024), 2)
        
        Write-DebugLog "Processing database: $dbName (Size: $dbSize GB)"
        
        # Determine output file name based on instance
		# The function below : $outputFile = Join-Path $outputFolder "instance2_${dbName}_size.log", will generate *_size.log files for the databases stored on your second instance of SQL server.
		# Edit only the variable "instanceNames" at the beginning of the script.
        if ($instanceName -eq "SQLSERVER1") {
            $outputFile = Join-Path $outputFolder "${dbName}_size.log"
        } else {
            $outputFile = Join-Path $outputFolder "instance2_${dbName}_size.log"
        }
        
        $outputLine = "$dbName,$currentDate,$dbSize"
        
        try {
            Add-Content -Path $outputFile -Value $outputLine
            Write-DebugLog "Added content to file: $outputFile"
        } catch {
            Write-DebugLog "Failed to write to file: $outputFile. Error: $_"
        }
    }
}

Write-DebugLog "Script completed"
