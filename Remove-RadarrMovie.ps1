
Function Remove-RadarrMovie{
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact='Medium')]
    param (
        [Parameter(Mandatory=$false, ValueFromPipelineByPropertyName=$true)]
        [string]$URL = 'http://localhost',
        
        [Parameter(Mandatory=$false, ValueFromPipelineByPropertyName=$true)]
        [string]$Port = '7878',

        [Parameter(Mandatory=$false, ValueFromPipelineByPropertyName=$true)]
        [string]$Api,

        [Parameter(Mandatory=$false, ValueFromPipelineByPropertyName=$true)]
        [int32]$Id,

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
        $ExistingMovie = Get-RadarrMovie -Id $Id -Api $Api
        
        If($ExistingMovie){
            Write-Host ("Removing Movie [{0}] from Radarr..." -f $ExistingMovie.Title) -ForegroundColor Yellow
            If($PSBoundParameters.ContainsKey('Verbose')){ 
                Write-Host ("   Title:") -ForegroundColor Gray -NoNewline
                    Write-Host (" {0}" -f $ExistingMovie.Title)
                Write-Host ("   Radarr ID:") -ForegroundColor Gray -NoNewline
                    Write-Host (" {0}" -f $ExistingMovie.id)
                Write-Host ("   Imdb:") -ForegroundColor Gray -NoNewline
                    Write-Host (" {0}" -f $ExistingMovie.imdbId)
                Write-Host ("   Path:") -ForegroundColor Gray -NoNewline
                    Write-Host (" {0}" -f $ExistingMovie.path)
            }

            If($PSBoundParameters.ContainsKey('Confirm')){
                $confirmation = Read-Host "Confirm`nAre you sure you want to perform this action`nPerforming the operation '"'Remove-RadarrMovie'"' on $($ExistingMovie.Title)`n[Y] Yes"
                if ($confirmation -eq 'y') {
                    Continue
                }
                Else{
                    Return
                }
            }

            $deleteMovieArgs = @{Headers = @{"X-Api-Key" = $Api}
                                URI = "$URI/$Id"
                                Method = "Delete"
            }

            If($PSBoundParameters.ContainsKey('WhatIf')){
                Write-Host ('What if: Performing the operation "Remove Movie" on target "{0}"' -f $ExistingMovie.Title)
            }
            Else{
                try
                {
                    $Request = Invoke-WebRequest @deleteMovieArgs -Verbose:$VerbosePreference
                    $DeleteStatus = $true
                }
                catch {
                    Write-Host ("Unable to delete movie {0}, error {1}" -f $ExistingMovie.Title,$_.Exception.Message)
                    $DeleteStatus = $false
                    #Break
                }
            }
        
        }
        Else{
            Write-Host ("Movie with ID [{0}] does not exist in Radarr..." -f $Id) -ForegroundColor Yellow
            $DeleteStatus = $false
        }

    }
    End {
        If($Report -and $ExistingMovie){
            $MovieReport = @()
            $Movie = New-Object System.Object
            $Movie | Add-Member -Type NoteProperty -Name Id -Value $ExistingMovie.Id
            $Movie | Add-Member -Type NoteProperty -Name Title -Value $ExistingMovie.Title
            $Movie | Add-Member -Type NoteProperty -Name Year -Value $ExistingMovie.Year
            $Movie | Add-Member -Type NoteProperty -Name IMDB -Value $ExistingMovie.imdbID
            $Movie | Add-Member -Type NoteProperty -Name TMDB -Value $ExistingMovie.tmdbID
            $Movie | Add-Member -Type NoteProperty -Name TitleSlug -Value $ExistingMovie.titleslug
            $Movie | Add-Member -Type NoteProperty -Name FolderPath -Value $ExistingMovie.Path
            $Movie | Add-Member -Type NoteProperty -Name Deleted -Value $DeleteStatus
            $MovieReport += $Movie

            Return $MovieReport
        }
        ElseIf($Report -and !$ExistingMovie){
            $MovieReport = @()
            $Movie = New-Object System.Object
            $Movie | Add-Member -Type NoteProperty -Name Id -Value $ExistingMovie.Id
            $MovieReport += $Movie

            Return $MovieReport

        }
        Else{
            
            Return $DeleteStatus
        }

    }     
}
