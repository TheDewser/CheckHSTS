# Script to check websites for proper HSTS configuration
# goal is to check for proper configuration of HSTS


[CmdletBinding()]
param (
    [Parameter(Mandatory=$true)]
    [string]$listfile,
    [Parameter(Mandatory=$true)]
    [string]$outfilepath
)

$urllist = Get-Content $listfile

# Create a CSV file to store the results
$Date = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$outfile = $outfilepath+"HSTS-Results_$Date.csv"
#populate the CSV with the column headers
{} | Select-Object Site, StatusCode, HSTS, MaxAge, Preload, IncludeSubDomains, Status | Export-Csv $outfile -NoTypeInformation


# Loop through the $urlist and perform a check on each site.
# Write results to csv file.
# you need to initiate the the CSV before you can write data to it.
$hstsresults = Import-Csv $outfile
foreach ($url in $urllist) {
    $siteResponse2 = Invoke-WebRequest -Uri $url -Method Head -ErrorAction SilentlyContinue
    # If url response is 200, check for HSTS header, else skip to next url
    # there is probably a more efficient way of doing this.  Maybe checking for !eq first.
    if ($siteResponse2.StatusCode -eq 200) {
        if ($siteResponse2.Headers["Strict-Transport-Security"]) {
            $hstsHeader = $siteResponse2.Headers["Strict-Transport-Security"]
            $hstsMaxAge = $hstsHeader.Split("=")[1]
            if ($hstsMaxAge -ge 31536000) {
                $hstsresults.Site = $url
                $hstsresults.StatusCode = $siteResponse2.StatusCode
                $hstsresults.HSTS = "Yes"
                $hstsresults.MaxAge = $hstsMaxAge
                $hstsresults.Preload = $hstsHeader.Contains("preload")
                $hstsresults.IncludeSubDomains = $hstsHeader.Contains("includeSubDomains")
                $hstsresults.Status = "Pass"
                $hstsresults | Export-Csv $outfile -NoTypeInformation -Append
            }
            else {
                $hstsresults.Site = $url
                $hstsresults.StatusCode = $siteResponse2.StatusCode
                $hstsresults.HSTS = "Yes"
                $hstsresults.MaxAge = $hstsMaxAge
                $hstsresults.Preload = $hstsHeader.Contains("preload")
                $hstsresults.IncludeSubDomains = $hstsHeader.Contains("includeSubDomains")
                $hstsresults.Status = "Fail"
                $hstsresults | Export-Csv $outfile -NoTypeInformation -Append
            }
        }
        else {
            $hstsresults.Site = $url
            $hstsresults.StatusCode = $siteResponse2.StatusCode
            $hstsresults.HSTS = "No"
            $hstsresults.MaxAge = "N/A"
            $hstsresults.Preload = "N/A"
            $hstsresults.IncludeSubDomains = "N/A"
            $hstsresults.Status = "Fail"
            $hstsresults | Export-Csv $outfile -NoTypeInformation -Append
        }
    
    }
    # This does not seem to trigger.  Could be the Method Not Allowed error.
    else {
        $hstsresults.Site = $url
        $hstsresults.StatusCode = $siteResponse2.StatusCode
        $hstsresults.Status = "Fail"
        $hstsresults | Export-Csv $outfile -NoTypeInformation -Append
        continue
    }
    #Some error control or timeouts might be neeeded.  The check on the 100 hung up around 700.
}


#Concept test Block
#Check for the HSTS header in the response and if it is present, check the max-age value, used for testing.
<# if ($siteResponse.Headers["Strict-Transport-Security"]) {
    $hstsHeader = $siteResponse.Headers["Strict-Transport-Security"]
    $hstsMaxAge = $hstsHeader.Split("=")[1]
    if ($hstsMaxAge -ge 31536000) {
        Write-Host "HSTS is properly configured with a max-age of $hstsMaxAge seconds"
    }
    else {
        Write-Host "HSTS is not properly configured.  Max-age is $hstsMaxAge seconds"
    }
}
else {
    Write-Host "HSTS is not properly configured.  No HSTS header present"
} #>