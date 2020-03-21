Function Get-RadarrAllMovies{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$false, ValueFromPipelineByPropertyName=$true)]
        [string]$URL = 'http://localhost',
        
        [Parameter(Mandatory=$false, ValueFromPipelineByPropertyName=$true)]
        [string]$Port = '7878',

        [Parameter(Mandatory=$false, ValueFromPipelineByPropertyName=$true)]
        [string]$Api,

        [Parameter(Mandatory=$false)]
        [switch]$Count
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
    }
    Process {
        $RadarrGetArgs = @{Headers = @{"X-Api-Key" = $Api}
                    URI = $URI
                    Method = "Get"
                }

        If($PSBoundParameters.ContainsKey('Verbose')){Write-Verbose $RadarrGetArgs.URI}

        Try{
            $Request = Invoke-WebRequest @RadarrGetArgs -UseBasicParsing -Verbose:$VerbosePreference
            $MovieObj = $Request.Content | ConvertFrom-Json -Verbose:$VerbosePreference
            Write-Verbose ("Found {0} Movies" -f $MovieObj.Count)
        }
        Catch{
            Write-Host ("Unable to connect to Radarr, error {0}" -f $_.Exception.Message)
        }
    }
    End {
        If([boolean]$Count){
            return $MovieObj.Count
        }
        Else{
            return $MovieObj
        }
    }
}