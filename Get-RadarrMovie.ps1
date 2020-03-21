
Function Get-RadarrMovie{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$false, ValueFromPipelineByPropertyName=$true)]
        [string]$URL = 'http://localhost',
        
        [Parameter(Mandatory=$false, ValueFromPipelineByPropertyName=$true)]
        [string]$Port = '7878',

        [Parameter(Mandatory=$false, ValueFromPipelineByPropertyName=$true)]
        [string]$Api,


        [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [int32]$Id,

        [Parameter(Mandatory=$false)]
        [switch]$AsObject
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
                    URI = "$URI/$Id"
                    Method = "Get"
        }
        If($PSBoundParameters.ContainsKey('Verbose')){Write-Verbose $RadarrGetArgs.URI}

        try {
            $request = Invoke-WebRequest @RadarrGetArgs -UseBasicParsing -Verbose:$VerbosePreference
            $MovieObj = $request.Content | ConvertFrom-Json -Verbose:$VerbosePreference
        }
        catch {
            Write-Error -ErrorRecord $_
        }
    }
    End{
        If([boolean]$AsObject){
            return $MovieObj
        }
        Else{
            return $request
        }
    }
}
