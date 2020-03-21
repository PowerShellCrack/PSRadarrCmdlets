

Function New-RadarrMovie {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact='Medium')]
    param (
        [Parameter(Mandatory=$false, ValueFromPipelineByPropertyName=$true)]
        [string]$URL = 'http://localhost',
        
        [Parameter(Mandatory=$false, ValueFromPipelineByPropertyName=$true)]
        [string]$Port = '7878',

        [Parameter(Mandatory=$false, ValueFromPipelineByPropertyName=$true)]
        [string]$Api,

        [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [string]$Title,

        [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [string]$Year,

        [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [string]$imdbID,
        
        [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [int32]$tmdbID,
        
        [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [Alias('Poster')]
        [string]$PosterImage,
        
        [Parameter(Mandatory=$true)]
        [string]$Path,
        
        [Parameter(Mandatory=$false)]
        [switch]$SearchAfterImport,

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
        If($VerbosePreference -eq "Continue"){Write-Host ("Processing details for movie title [{0}]..." -f $Title)}
        [string]$actualName = $Title
        [string]$sortName = ($Title).ToLower()
        $Regex = "[^{\p{L}\p{Nd}\'}]+"
        [string]$cleanName = (($Title) -replace $Regex,"").Trim().ToLower()
        [string]$ActualYear = $Year
        [string]$imdbID = $imdbID
        #[string]$imdbID = ($imdbID).substring(2,($imdbID).length-2)
        [int32]$tmdbID = $tmdbID
        [string]$Image = $PosterImage
        [string]$simpleTitle = (($Title).replace("'","") -replace $Regex,"-").Trim().ToLower()
        [string]$titleSlug = $simpleTitle + "-" + $tmdbID
    
        Write-Host ("Adding movie [{0}] to Radarr database..." -f $actualName) -ForegroundColor Yellow
        If($VerbosePreference -eq "Continue"){
            Write-Host ("   Title:") -ForegroundColor Gray -NoNewline
                Write-Host (" {0}" -f $actualName)
            Write-Host ("   Path:") -ForegroundColor Gray -NoNewline
                Write-Host (" {0}" -f $Path)
            Write-Host ("   Imdb:") -ForegroundColor Gray -NoNewline
                Write-Host (" {0}" -f $imdbID)
            Write-Host ("   Tmdb:") -ForegroundColor Gray -NoNewline
                Write-Host (" {0}" -f $tmdbID)
            Write-Host ("   Slug:") -ForegroundColor Gray -NoNewline
                Write-Host (" {0}" -f $titleSlug)
            Write-Host ("   Year:") -ForegroundColor Gray -NoNewline
                Write-Host (" {0}" -f $ActualYear)
            Write-Host ("   Poster:") -ForegroundColor Gray -NoNewline
                Write-Host (" {0}" -f $Image)
        }

        $Body = @{ title=$actualName;
            sortTitle=$sortName;
            cleanTitle=$cleanName;
            qualityProfileId="1";
            year=$ActualYear;
            tmdbid=$tmdbID;
            imdbid=$imdbID;
            titleslug=$titleSlug;
            monitored="true";
            path=$Path;
            addOptions=@{
                searchForMovie=[boolean]$SearchAfterImport
            };
            images=@( @{
                covertype="poster";
                url=$Image
            } );
        }

        $BodyObj = ConvertTo-Json -InputObject $Body #| % { [System.Text.RegularExpressions.Regex]::Unescape($_) }
        #$BodyArray = ConvertFrom-Json -InputObject $BodyObj

        $RadarrPostArgs = @{Headers = @{"X-Api-Key" = $Api}
                        URI = $URI
                        Method = "Post"
                }
        

        If($PSBoundParameters.ContainsKey('WhatIf')){
            Write-Host ('What if: Performing the operation "New Movie" on target "{0}"' -f $actualName)
        }
        Else{
            try
            {
                $Request = Invoke-WebRequest @RadarrPostArgs -Body $BodyObj -Verbose:$VerbosePreference
                Write-Verbose "Invoke API using JSON: $BodyObj"
                $ImportStatus = $true
            
            }
            catch {
                Write-Host ("Unable to add movie {0}, error {1}" -f $actualName,$_.Exception.Message)
                $ImportStatus = $false
                #Break
            }
        }
    }
    End {
        If(!$Report){
            Return $ImportStatus
        }
        Else{
            $MovieReport = @()
            $Movie = New-Object System.Object
            $Movie | Add-Member -Type NoteProperty -Name Title -Value $actualName
            $Movie | Add-Member -Type NoteProperty -Name Year -Value $ActualYear
            $Movie | Add-Member -Type NoteProperty -Name IMDB -Value $imdbID
            $Movie | Add-Member -Type NoteProperty -Name TMDB -Value $tmdbID
            $Movie | Add-Member -Type NoteProperty -Name TitleSlug -Value $titleslug
            $Movie | Add-Member -Type NoteProperty -Name FolderPath -Value $Path
            $Movie | Add-Member -Type NoteProperty -Name RadarrUrl -Value ('http://' + $URL + ':' + $Port + '/movie/' + $titleSlug)
            $Movie | Add-Member -Type NoteProperty -Name Imported -Value $ImportStatus
            $MovieReport += $Movie

            Return $MovieReport

        }

    }
}
