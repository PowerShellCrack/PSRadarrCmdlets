Function Test-RadarrURI{
    [cmdletbinding()] 
    param(
        [Parameter(Mandatory=$true)] 
        [System.Uri]$URI,
        [System.Uri]$defaultURI = "http://localhost:7878"
    )

    Begin{
        $OriginalURI = $URI
        $validAddress = $null
    }
    Process{
        Try{
            If([system.uri]::IsWellFormedUriString($URI,[System.UriKind]::Absolute))
            {
                If($URI.Port -eq -1 -and $URI.LocalPath -match "(\d)"){
                    [System.Uri]$newURI = 'http://' + $URI.Scheme + ':' + $URI.LocalPath
                }
                Else{
                    [System.Uri]$newURI = $URI
                }
                
            }
            Else{
                [System.Uri]$newURI = 'http://' + $URI.OriginalString
            }
        }
        Catch{
            
        }

        
    }
    End{
        return $newURI.OriginalString
    }
}