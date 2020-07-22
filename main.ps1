$ErrorActionPreference = "SilentlyContinue"
$userEventIds = 4720,4723,4724,4767,4725,4726,4740,4722,4741,4742,4743
$groupEventIds = 4728,4729,4732,4733
$ids = $userEventIds + $groupEventIds
$eventSource = "MDN Pilot Collection"
$eventStartTimeFilter = (Get-Date).date.AddDays(-@daysBack@)
$eventEndTimeFilter = (Get-Date).date

$jobStartTime = (Get-date).ToString("yyyy-MM-dd HH:mm:ss")
	Write-EventLog -LogName "Application" -Source $eventSource -EntryType Information -EventID 10100 -Message "Beginning collection of raw event data for %computername%."
$testArray = Get-WinEvent -FilterHashTable @{LogName='Security'; ID=$ids;StartTime=$eventStartTimeFilter;EndTime=$eventEndTimeFilter}
	Write-EventLog -LogName "Application" -Source "$eventSource" -EntryType Information -EventID 10101 -Message "Collection of raw event data completed for %computername%."
$userCounter = 0
$groupCounter = 0
$computerid = %computerid%
$userTestArray = $testArray | Where-Object {$_.ID -in $userEventIds}
$groupTestArray = $testArray | Where-Object {$_.ID -in $groupEventIds}
$userCount = $userTestArray.Count
$groupCount = $groupTestArray.Count
$workingDir = "%ltsvcdir%\collection\ad_security_logs"
$workingFile = "$workingDir\evtworking"
$userOutFile = "$workingDir\user_1_day.txt"
$groupOutFile = "$workingDir\group_1_day.txt"
$userTargetArray = @()
$groupTargetArray = @()

Write-EventLog -LogName "Application" -Source "$eventSource" -EntryType Information -EventID 10102 -Message "Starting to parse user event data."
IF ($userTestArray.count -ne 0)
{
foreach ($item in $userTestArray) {
	$timeStr = $item.timeCreated.ToString("yyyy-MM-dd HH:mm:ss")

	$idStr = $item.Id
	$levelStr = $item.LevelDisplayName
	$messageStr = $item.Message
	$providerName = $item.providerName	
	#$groupName = " "
	New-Item $workingDir -ItemType Directory -ErrorAction SilentlyContinue | out-null
	New-Item $workingFile -ItemType File -ErrorAction SilentlyContinue | out-null
	$messageStr | Out-File $workingFile
	$messageTest = Get-Content $workingFile -raw | findstr /C:"Account Name:"
	$subjectAccount = $messageTest[0].split()[-1]
		
	$targetAccount = $messageTest[1].split()[-1]
	$userRecordToAdd = "(`"$computerID`",`"$timeStr`",`"$idStr`",`"$levelStr`",`"$providerName`",`"$subjectAccount`",`"$targetAccount`"`,`"$messageStr`")"
	$userCounter = $userCounter + 1
					
	$userStringToAdd = Out-String -InputObject $userRecordToAdd		
	
	$userTargetArray += $userStringToAdd
					
		IF ($userCounter -lt $userCount)
			{
				$userTargetArray += ","
			}
			
	}

$userTargetArray | Out-File $userOutFile

	Write-EventLog -LogName "Application" -Source "$eventSource" -EntryType Information -EventID 10110 -Message "Executed text file export command for user data."

	Write-EventLog -LogName "Application" -Source "$eventSource" -EntryType Information -EventID 10103 -Message "Completed parsing user event data."

	Write-EventLog -LogName "Application" -Source "$eventSource" -EntryType Information -EventID 10104 -Message "Starting to parse group event data."
}	ELSE{
			Write-EventLog -LogName "Application" -Source $eventSource -EntryType Information -EventID 10004 -Message "No events were found for %computername%."
		}
		
IF ($groupTestArray.count -ne 0){
foreach ($item in $groupTestArray){
	$timeStr = $item.timeCreated.ToString("yyyy-MM-dd HH:mm:ss")
	$idStr = $item.Id
	$levelStr = $item.LevelDisplayName
	$messageStr = $item.Message
	$providerName = $item.providerName
	
	New-Item $workingDir -ItemType Directory -ErrorAction SilentlyContinue | out-null
	New-Item $workingFile -ItemType File -ErrorAction SilentlyContinue | out-null
	$messageStr | Out-File $workingFile
							
	$messageAccountTest = Get-Content $workingFile -raw | findstr /C:"Account Name:"
						
	$subjectAccount = $messageAccountTest[0].split()[-1]
	$messageAccountTest[1] -match "cn=(.*)" | out-null
	$targetAccountTest = $matches[1]
	$targetAccountTest = $targetAccountTest.split(",")[0]
	$workingArray = $targetAccountTest.split()
	$targetAccount = $workingArray[-2].substring(0,1)+$workingArray[-1]
	$targetAccount = $targetAccount.ToLower()
	$messageGroupTest = Get-Content $workingFile -raw | findstr /C:"Group Name:"
	$groupName = $messageGroupTest.split("`t")[-1]
	$groupRecordToAdd ="(`"$computerID`",`"$timeStr`",`"$idStr`",`"$levelStr`"`,`"$providerName`"`,`"$subjectAccount`"`,`"$targetAccount`"`,`"$groupName`"`,`"$messageStr`")"
								
	$groupStringToAdd = Out-String -InputObject $groupRecordToAdd		
		
	$groupTargetArray += $groupStringToAdd
								
	$groupCounter = $groupCounter + 1
	IF ($groupCounter -lt $groupCount)
		{
			$groupTargetArray += ","
		}	
	}

	$groupTargetArray | Out-File $groupOutFile

	Write-EventLog -LogName "Application" -Source "$eventSource" -EntryType Information -EventID 10111 -Message "Executed text file export command for group data."

	Write-EventLog -LogName "Application" -Source "$eventSource" -EntryType Information -EventID 10105 -Message "Completed parsing group event data."




}ELSE 	{
			Write-EventLog -LogName "Application" -Source "$eventSource" -EntryType Information -EventID 10004 -Message "No events were found for %computername%."
		}
$jobEndTime = (Get-date).ToString("yyyy-MM-dd HH:mm:ss")
$scriptEvtCount = $groupTargetArray.count + $userTargetArray.count
$eventStartTimeFilter = $eventStartTimeFilter.ToString("yyyy-MM-dd HH:mm:ss")
$eventEndTimeFilter = $eventEndTimeFilter.ToString("yyyy-MM-dd HH:mm:ss")
$usrEvtCount = $userTargetArray.count
$groupEvtCount = $groupTargetArray.count

$finalString = "$usrEvtCount,$groupEvtCount,$scriptEvtCount,'$jobStartTime','$jobEndTime','$eventStartTimeFilter','$eventEndTimeFilter'"

$finalString



