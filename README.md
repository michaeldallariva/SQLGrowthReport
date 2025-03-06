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
