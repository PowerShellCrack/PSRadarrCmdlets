


Function Update-RadarrMoviePath {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact='Medium')]
    param (
        [Parameter(Mandatory=$false, ValueFromPipelineByPropertyName=$true)]
        [string]$URL = 'http://localhost',
        
        [Parameter(Mandatory=$false, ValueFromPipelineByPropertyName=$true)]
        [string]$Port = '7878',

        [Parameter(Mandatory=$false, ValueFromPipelineByPropertyName=$true)]
        [string]$Api,

        [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [int32]$Id,
        
        [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [string]$Title,

        [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [string]$FolderName,
     
        [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [Alias('Path')]
        [string]$RadarrPath,
        
        [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [string]$TitleSlug,
        
        [Parameter(Mandatory=$true)]
        [string]$ActualPath,

        [Parameter(Mandatory=$false)]
        [switch]$Report
    )
    Begin{
        #if global setting found use those instead fo defualt
        If($Global:RadarrURL -and $Global:RadarrPort){
            [string]$URI = Test-RadarrURI "${Global:RadarrURL}:${Global:RadarrPort}/api/movie"
        }
        Else{
            [string]$URI = Test-RadarrURI "${URL}:${Port}/api/movie"
        }

        #use global API or check if specified APi is not null
        If($Global:RadarrAPIkey){
            $Api = $Global:RadarrAPIkey
        }
        Elseif($Api -eq $null){
            Throw "-Api parameter is mandatory"
        }

        if (-not $PSBoundParameters.ContainsKey('Verbose')) {
            $VerbosePreference = $PSCmdlet.SessionState.PSVariable.GetValue('VerbosePreference')
        }
        if (-not $PSBoundParameters.ContainsKey('Confirm')) {
            $ConfirmPreference = $PSCmdlet.SessionState.PSVariable.GetValue('ConfirmPreference')
        }
        if (-not $PSBoundParameters.ContainsKey('WhatIf')) {
            $WhatIfPreference = $PSCmdlet.SessionState.PSVariable.GetValue('WhatIfPreference')
        }
        #Write-Verbose ('[{0}] Confirm={1} ConfirmPreference={2} WhatIf={3} WhatIfPreference={4}' -f $MyInvocation.MyCommand, $Confirm, $ConfirmPreference, $WhatIf, $WhatIfPreference)
    }
    Process {
        #Write-Host ("Adding movie [{0}] to Radarr database..." -f $actualName) -ForegroundColor Gray
        If($VerbosePreference -eq "Continue"){
            Write-Host ("Movie [{0}] path is incorrect; updating Radarr's path..." -f $Title) -ForegroundColor Yellow
            Write-Host ("   Actual Path:") -ForegroundColor Gray -NoNewline
                 Write-Host (" {0}" -f $ActualPath)
            Write-Host ("   Radarr Path:") -ForegroundColor Gray -NoNewline
                 Write-Host (" {0}" -f $RadarrPath) -ForegroundColor Gray
        }

        #Grab current movie in Radarr
        $ExistingMovie = Get-RadarrMovie -Id $Id -Api $Api
            
        #update PSObject values
        $ExistingMovie.folderName = $ActualPath
        $ExistingMovie.path = $ActualPath
        $ExistingMovie.PSObject.Properties.Remove('movieFile')  
        
        #convert PSObject back into JSON format
        $BodyObj = $ExistingMovie | ConvertTo-Json #| % { [System.Text.RegularExpressions.Regex]::Unescape($_) }

        $RadarrPutMovieID = @{Headers = @{"X-Api-Key" = $Api}
                    URI = $URI + "/" + $Id
                    Method = "Put"
                }  
        try
        {
            If($VerbosePreference -eq "Continue"){write-host ("Invoking [{0}] using JSON: {1}" -f ($URI + "/" + $Id),$BodyObj)}
            If(!$WhatIfPreference){Invoke-WebRequest @RadarrPutMovieID -Body $BodyObj | Out-Null}
            $UpdateStatus = $true
            
        }
        catch {
            If($VerbosePreference -eq "Continue"){Write-Error -ErrorRecord $_}
            $UpdateStatus = $false
            #Break
        }
    }
    End {
        If(!$Report){
            Return $UpdateStatus
        }
        Else{
            $MovieReport = @()
            $Movie = New-Object System.Object
            $Movie | Add-Member -Type NoteProperty -Name ID -Value $Id
            $Movie | Add-Member -Type NoteProperty -Name Title -Value $Title
            $Movie | Add-Member -Type NoteProperty -Name RadarrPath -Value $RadarrPath
            $Movie | Add-Member -Type NoteProperty -Name ActualPath -Value $ActualPath
            $Movie | Add-Member -Type NoteProperty -Name Updated -Value $UpdateStatus 
            $MovieReport += $Movie

            Return $MovieReport

        }
    }
}

