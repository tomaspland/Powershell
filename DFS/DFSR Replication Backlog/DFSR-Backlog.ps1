# Get Start Time
# For testing - commented out for Prod
# $startDTM = (Get-Date)

#SMTP Settings
$smtp = "mail.company.local"
$to = "IT Helpdesk <helpdesk@company.com>"
$from = "DFS Monitoring Script<donotreply@company.com>"

# Get all replication groups
$replicationgroups = dfsradmin rg list;
 
# Reduce loop by 3 lines to filter out junk from dfsradmin
$i = 0;
$imax = ($replicationgroups.count -3);
 
# Loop through each replication group
foreach ($replicationgroup in $replicationgroups) {
 
    # Exclude first and last two lines as junk, and exclude the domain system volume
    if (($i -ge 1) -and ($i -le $imax) -and ($replicationgroup -notlike "*domain system volume*")) {
 
        # Format replication group name
        $replicationgroup = $replicationgroup.split(" ");
        $replicationgroup[-1] = "";
        $replicationgroup = ($replicationgroup.trim() -join " ").trim();
 
        # Get and format replication folder name
        $replicationfolder = & cmd /c ("dfsradmin rf list /rgname:`"{0}`"" -f $replicationgroup);
        $replicationfolder = (($replicationfolder[1].split("\"))[0]).trim();
 
        # Get servers for the current replication group
        $replicationservers = & cmd /c ("dfsradmin conn list /rgname:`"{0}`"" -f $replicationgroup);
 
        # Reduce loop by 3 lines to filter out junk from dfsradmin 
        $j = 0;
        $jmax = ($replicationservers.count -3);
 
        # Loop through each replication member server
        foreach ($replicationserver in $replicationservers) {
 
            # Exclude first and last two lines as junk
            if (($j -ge 1) -and ($j -le $jmax)) {
 
                # Format server names
				$sendingserver = ($replicationserver.split()| where {$_})[0].trim();
				$receivingserver = ($replicationserver.split()| where {$_})[1].trim();
                # Get backlog count with dfsrdiag
				$backlog = & cmd /c ("dfsrdiag backlog /rgname:`"{0}`" /rfname:`"{1}`" /smem:{2} /rmem:{3}" -f $replicationgroup, $replicationfolder, $sendingserver,  $receivingserver);
                $backlogcount = ($backlog[1]).split(":")[1];
 
                # Format backlog count
				if ($backlogcount -ne $null) {
    	                $backlogcount = $backlogcount.trim();
       	        }
           	    else {
                    	$backlogcount = 0;
               	}	
   	            # Create output string to <replication group> <sending server> <receiving server> <backlog count>;
       	        $outline = $replicationgroup + " From: " + $sendingserver + " To: " + $receivingserver + " Backlog: " + $backlogcount;

				# This is for testing - commented out for Prod
                $outline;
 					
                if ([int]$backlogcount -gt 1000) {
					$subject = "High DFS Backlog Alert for $replicationgroup"
                    $datetime = Get-Date
					$body = "There is a high back log count detected for $outline . This was detected at $datetime CST"
					send-MailMessage -SmtpServer $smtp -To $to -From $from -Subject $subject -Body $body -BodyAsHtml -Priority high
				}
			}
            	
 			#}
            $j = $j + 1;
        }
 
    }
 
    $i = $i + 1;
}

# Get End Time
# For testing - commented out for Prod
# $endDTM = (Get-Date)

# Echo Time elapsed
# For testing - commented out for Prod
# "Elapsed Time: $(($endDTM-$startDTM).totalseconds) seconds"