#################################################################################################################################################################
# Script name : SQL_Month_DB_Reportv1.1
# Version : v1.1
# https://github.com/michaeldallariva
# Language : Powershell
# Release date : Feb 1st 2025
# Author : Michael DALLA RIVA, with the help of some AI
#
# Purpose :
# - Creates a HTML report to display all the databases names and their size at a point of time.
# - Allows for an easy and automated follow up of databases sizes evolution and storage capacity monitoring and/or for billing to business units/customers
#
# License : None. Feel free to use for any purpose. Personal or Commercial.
# 
#  Additional informations :
# - Run this script once a month
# - The HTML table format has been optimised for general email clients/Microsoft Outlook display
# - It scans all the files called "databasename_size.log" locally and reads the last line each month to generate the HTML report.
# - From a scheduled Windows task point of view, there is no need to use a service account that as SQL permissions of any kind. "System" is fine.
# - Run this script 5mn after running the SQL_Database_Info script, so you have all the latest "databasename_size.log" files present and up to date.
#################################################################################################################################################################


$logFolder = "C:\Scripts\databasesreport"

$year = (Get-Date).Year

$months = @('Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec')

$currentMonth = $months[(Get-Date).Month - 1]

$reportFont = "Verdana, Helvetica, sans-serif"


$reportTitle = "SQL DATABASES REPORT : YOURSQLSERVER01"
$reportSubtitle = "Monthly/Annual sizes overview for ${currentMonth} $year"

$databaseSizes = @{}

Get-ChildItem -Path $logFolder -Filter "*_size.log" | ForEach-Object {
    $dbName = $_.BaseName.Replace("_size", "")
    $content = Get-Content $_.FullName

    $content | ForEach-Object {
        $parts = $_ -split ','
        if ($parts.Count -eq 3) {
            $date = [DateTime]::ParseExact($parts[1], "dd-MM-yyyy HH:mm:ss", $null)
            if ($date.Year -eq $year) {
                $size = [double]$parts[2]
                if (-not $databaseSizes.ContainsKey($dbName)) {
                    $databaseSizes[$dbName] = @{}
                }
                $databaseSizes[$dbName][$date.Month] = $size
            }
        }
    }
}

$latestSizes = @{}
foreach ($dbName in $databaseSizes.Keys) {
    $latestMonth = ($databaseSizes[$dbName].Keys | Sort-Object -Descending)[0]
    $latestSizes[$dbName] = $databaseSizes[$dbName][$latestMonth]
}

# Get top 5 databases by size
# You can change to 10 if you wish. Just edit the number at the end.
$topDatabases = $latestSizes.GetEnumerator() | Sort-Object Value -Descending | Select-Object -First 5

$html = @"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>$reportTitle</title>
</head>
<body style="font-family: Arial, sans-serif; font-size: 14px; color: #333; background-color: #f0f0f0; margin: 0; padding: 20px;">
    <table cellpadding="0" cellspacing="0" border="0" width="100%" style="max-width: 800px; margin: 0 auto; background-color: #ffffff;">
        <tr>
            <td style="padding: 30px;">
                <h1 style="color: #2c3e50; margin: 0 0 10px 0;">$reportTitle</h1>
                <h2 style="color: #34495e; margin: 0 0 30px 0;">$reportSubtitle</h2>
                
                <h3 style="color: #3498db; margin: 30px 0 15px 0;">Top 5 databases by size today</h3>
                <table cellpadding="12" cellspacing="0" border="1" style="width: 100%; border-collapse: collapse; border: 1px solid #e0e0e0;">
                    <tr>
                        <th style="background-color: #3498db; color: white; font-weight: bold; text-align: left;">Database</th>
                        <th style="background-color: #3498db; color: white; font-weight: bold; text-align: left;">Size (GB)</th>
                    </tr>
"@

foreach ($db in $topDatabases) {
    $html += @"
                    <tr>
                        <td style="border: 1px solid #e0e0e0;">$($db.Key)</td>
                        <td style="border: 1px solid #e0e0e0;">$("{0:N2}" -f $db.Value)</td>
                    </tr>
"@
}

$html += @"
                </table>
                
                <h3 style="color: #3498db; margin: 30px 0 15px 0;">Monthly Database Size Report (In GB)</h3>
                <table cellpadding="12" cellspacing="0" border="1" style="width: 100%; border-collapse: collapse; border: 1px solid #e0e0e0;">
                    <tr>
                        <th style="background-color: #3498db; color: white; font-weight: bold; text-align: left;">Database</th>
"@

foreach ($month in $months) {
    $html += @"
                        <th style="background-color: #3498db; color: white; font-weight: bold; text-align: left;">$month</th>
"@
}

$html += @"
                        <th style="background-color: #3498db; color: white; font-weight: bold; text-align: left;">Growth %</th>
                    </tr>
"@

$totalSizes = @{}
$totalJanuarySize = 0
$totalDecemberSize = 0

foreach ($dbName in $databaseSizes.Keys | Sort-Object) {
    $html += @"
                    <tr>
                        <td style="border: 1px solid #e0e0e0;">$dbName</td>
"@
    $januarySize = $databaseSizes[$dbName][1]
    $decemberSize = $databaseSizes[$dbName][12]

    $totalJanuarySize += $januarySize
    $totalDecemberSize += $decemberSize

    foreach ($month in 1..12) {
        $size = if ($databaseSizes[$dbName].ContainsKey($month)) { 
            $sizeValue = $databaseSizes[$dbName][$month]
            $totalSizes[$month] += $sizeValue
            "{0:N2}" -f $sizeValue
        } else { 
            "N/A" 
        }
        $html += @"
                        <td style="border: 1px solid #e0e0e0;">$size</td>
"@
    }

    $growthPercentage = if ($januarySize -and $decemberSize) {
        $growth = (($decemberSize - $januarySize) / $januarySize) * 100
        "{0:N2}%" -f $growth
    } else {
        "N/A"
    }

    $html += @"
                        <td style="border: 1px solid #e0e0e0;">$growthPercentage</td>
                    </tr>
"@
}

$totalGrowthPercentage = if ($totalJanuarySize -and $totalDecemberSize) {
    $growth = (($totalDecemberSize - $totalJanuarySize) / $totalJanuarySize) * 100
    "{0:N2}%" -f $growth
} else {
    "N/A"
}

$html += @"
                    <tr style="font-weight: bold;">
                        <td style="border: 1px solid #e0e0e0;">Total</td>
"@
foreach ($month in 1..12) {
    $totalSize = if ($totalSizes.ContainsKey($month)) {
        "{0:N2}" -f $totalSizes[$month]
    } else {
        "N/A"
    }
    $html += @"
                        <td style="border: 1px solid #e0e0e0;">$totalSize</td>
"@
}
$html += @"
                        <td style="border: 1px solid #e0e0e0;">$totalGrowthPercentage</td>
                    </tr>
"@

$html += @"
                </table>
                <div style="font-size: 12px; color: #7f8c8d; text-align: center; margin-top: 20px;">
                    This report provides an overview of databases sizes for the specified month/year
                </div>
            </td>
        </tr>
    </table>
</body>
</html>
"@

$reportPath = "C:\Scripts\databasesreport\DatabaseGrowthReport_${currentMonth}_$year.html"
$html | Out-File $reportPath
Write-Host "HTML report saved to: $reportPath"

# Function to send email
# Change the name of the SMTP Server to your own
# Add the $Port function in the Send-EmailReport statement below if your server is not using a standard port
# The Send-EmailReport function assumes your local SMTP server does not use authentication, but uses IP whitelist. This can be changed to your own needs
function Send-EmailReport {
    param (
        [string]$SmtpServer = "yoursmtpserver1", 
        [int]$Port = 25,
        [string]$From,
        [string]$To,
        [string]$Subject,
        [string]$HtmlBody
    )

    $message = New-Object System.Net.Mail.MailMessage
    $message.From = $From
    $message.To.Add($To)
    $message.Subject = $Subject
    $message.Body = $HtmlBody
    $message.IsBodyHtml = $true

    $smtpClient = New-Object System.Net.Mail.SmtpClient($SmtpServer, $Port)
    $smtpClient.EnableSsl = $false
    $smtpClient.UseDefaultCredentials = $true

    try {
        $smtpClient.Send($message)
        Write-Host "Email sent successfully."
    }
    catch {
        Write-Host "Failed to send email: $_"
    }
    finally {
        $message.Dispose()
        $smtpClient.Dispose()
    }
}

# Send email with the HTML report
# Uncomment the function below and add your own email addresses, if you want to send the report by email automatically, which you should to automate the process.
# Send-EmailReport -From "sql_report@yourcompany.com" -To "your_team_dl@yourcompany.com" -Subject "Database Growth Report $year" -HtmlBody $html
