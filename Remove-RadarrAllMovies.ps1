
Function Remove-RadarrAllMovies{
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact='Medium')]
    param (
        [Parameter(Mandatory=$false, ValueFromPipelineByPropertyName=$true)]
        [string]$URL = 'http://localhost',
        
        [Parameter(Mandatory=$false, ValueFromPipelineByPropertyName=$true)]
        [string]$Port = '7878',

        [Parameter(Mandatory=$false, ValueFromPipelineByPropertyName=$true)]
        [string]$Api,

        [Parameter(Mandatory=$false)]
        [switch]$UnmonitoredOnly
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
        $removeMovies = @()
        If($UnmonitoredOnly){
            $i=1
            while ($i -le 500) {
                $iwrArgs = @{Headers = @{"X-Api-Key" = $radarrAPIkey}
                            URI = "$URI/.$i"
                    }

                try {
                    $movie = Invoke-WebRequest @iwrArgs | Select-Object -ExpandProperty Content | ConvertFrom-Json -Verbose:$VerbosePreference
                    if ($movie.downloaded -eq $true -or $movie.monitored -eq $false) {
                        Write-Host "Adding $($movie.title) to list of movies to be removed." -ForegroundColor Red
                        $removeMovies += $movie
                    }
                    else {
                        Write-Host "$($movie.title) is monitored. Skipping." -ForegroundColor Gray
                    }
                }
                catch {
                    Write-Host "Empty ID#$i or bad request"
                }
                $i++

            }
        }
        Else{
            $removeMovies = Get-RadarrAllMovies -Api $radarrAPIkey -Verbose:$VerbosePreference
        }

        Write-Host "Proceeding to remove $($removeMovies.count) movies!" -ForegroundColor Yellow
        If($PSBoundParameters.ContainsKey('Confirm')){
            $confirmation = Read-Host "Confirm`nAre you sure you want to perform this action`nPerforming the operation '"'Remove-RadarrAllMovies'"' on $($removeMovies.count) movies`n[Y] Yes to All"
            if ($confirmation -eq 'y') {
                Continue
            }
            Else{
                Return
            }
        }
        
        $deletecount = 0
        foreach ($downloadedMovie in $removeMovies){
            

            $iwrArgs = @{Headers = @{"X-Api-Key" = $radarrAPIkey}
                    URI = "$URI/.$($downloadedMovie.id)"
                    Method = "Delete"
            }

            If($PSBoundParameters.ContainsKey('WhatIf')){
                Write-Host ('What if: Performing the operation "Remove Movie" on target "{0}"' -f $downloadedMovie.title)
            }
            Else{
                Try{
                    $Request = Invoke-WebRequest @iwrArgs -Verbose:$VerbosePreference
                    Write-Host "Removed $($downloadedMovie.title)!" -ForegroundColor Green
                    $deletecount ++
                }
                Catch{
                    Write-Host ("Unable to delete movie {0}, error {1}" -f $downloadedMovie.title,$_.Exception.Message)
                }
            }
        }
    } 
    End{
        Write-Ver ("{0} movies were removed from Radarr" -f $deletecount)
    }           
}