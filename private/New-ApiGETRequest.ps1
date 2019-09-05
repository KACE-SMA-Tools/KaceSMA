Function New-ApiGETRequest {
    <#
    .DESCRIPTION
        Performs an authentication request, then a GET request to the provided endpoint.
    #>
    [cmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [ValidateScript({
            If ($_ -notmatch "^(http|https)://") {
                Throw 'Must start with "http://" or "https://"'
        } Else{ $true }}
        )]
        [String]
        $Server,

        [String]
        $Org,

        [Parameter(Mandatory)]
        [String]
        $Endpoint,

        [Parameter(Mandatory)]
        [PSCredential]
        $Credential,

        [Parameter()]
        [String]
        $QueryParameters
    )

    $Auth = @{
        'password'         = ($Credential.GetNetworkCredential().password)
        'userName'         = ($Credential.username)
    }

    If ($Org) {
        $Auth['organizationName'] = $Org
    }

    $Auth = $Auth | ConvertTo-Json

    # Dynamically find and include all available protocols 'Tls12' or higher.
    # Module requires PS 5.1+ so no error checking should be required.

    $CurrentVersionTls = [Net.ServicePointManager]::SecurityProtocol
    Set-ClientTlsProtocols -ErrorAction Stop

    $Uri = "$Server/ams/shared/api/security/login"
    $Session = New-Object Microsoft.Powershell.Commands.Webrequestsession

    $Headers = @{}
    $headers.Add('Accept', 'application/json')
    $headers.Add('Content-Type', 'application/json')
    $headers.Add('x-dell-api-version', '8')

    $RequestSplat = @{
        Uri             = $Uri
        Headers         = $Headers
        Body            = $Auth
        Method          = 'POST'
        WebSession      = $Session
        UseBasicParsing = $True
    }
    $Request = Invoke-WebRequest @RequestSplat

    $CSRFToken = $Request.Headers.'x-dell-csrf-token'
    $headers.Add("x-dell-csrf-token", "$CSRFToken")

    If ($QueryParameters) {
        $APIUrl = "{0}{1}{2}" -f $Server,$Endpoint,$QueryParameters
    }
    Else { $APIUrl = "{0}{1}" -f $Server,$Endpoint }

    $IRMSplat = @{
        Uri             = $APIUrl
        Headers         = $Headers
        Method          = 'GET'
        WebSession      = $Session
        UseBasicParsing = $True
    }
    Invoke-RestMethod @IRMSplat

    # Be nice and set session security protocols back to how we found them.
    [Net.ServicePointManager]::SecurityProtocol = $currentVersionTls
}