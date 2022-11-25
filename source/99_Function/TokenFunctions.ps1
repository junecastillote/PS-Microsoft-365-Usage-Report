Function Get-TokenByCertificate {
    [cmdletbinding()]
    Param(
        [Parameter(Mandatory)]
        [string]
        $ClientID,

        [Parameter(Mandatory)]
        [string]
        $TenantID,

        [Parameter(Mandatory)]
        [System.Security.Cryptography.X509Certificates.X509Certificate2]
        $ClientCertificate
    )

    # Create base64 hash of certificate
    $certificateBase64Hash = [System.Convert]::ToBase64String($ClientCertificate.GetCertHash())

    # Create JWT timestamp for expiration
    $jwtStartDate = (Get-Date "1970-01-01T00:00:00Z" ).ToUniversalTime()
    $jwtExpirationTimeSpan = (New-TimeSpan -Start $jwtStartDate -End (Get-Date).ToUniversalTime().AddMinutes(2)).TotalSeconds
    $jwtExpiration = [math]::Round($jwtExpirationTimeSpan, 0)

    # Create JWT validity start timestamp
    $NotBeforeExpirationTimeSpan = (New-TimeSpan -Start $jwtStartDate -End ((Get-Date).ToUniversalTime())).TotalSeconds
    $NotBefore = [math]::Round($NotBeforeExpirationTimeSpan, 0)

    # Create JWT header
    $jwtHeader = @{
        alg = "RS256"
        typ = "JWT"
        # Use the CertificateBase64Hash and replace/strip to match web encoding of base64
        x5t = $certificateBase64Hash -replace '\+', '-' -replace '/', '_' -replace '='
    }

    # Create JWT payload
    $jwtPayLoad = @{
        # What endpoint is allowed to use this JWT
        aud = "https://login.microsoftonline.com/$TenantID/oauth2/token"

        # Expiration timestamp
        exp = $jwtExpiration

        # Issuer = your application
        iss = $ClientID

        # JWT ID: random guid
        jti = [guid]::NewGuid()

        # Not to be used before
        nbf = $NotBefore

        # JWT Subject
        sub = $ClientID
    }

    # Convert header and payload to base64
    $jwtHeaderToByte = [System.Text.Encoding]::UTF8.GetBytes(($jwtHeader | ConvertTo-Json))
    $encodedHeader = [System.Convert]::ToBase64String($jwtHeaderToByte)

    $jwtPayLoadToByte = [System.Text.Encoding]::UTF8.GetBytes(($jwtPayLoad | ConvertTo-Json))
    $encodedPayload = [System.Convert]::ToBase64String($jwtPayLoadToByte)

    # Join header and Payload with "." to create a valid (unsigned) JWT
    $jwt = $encodedHeader + "." + $encodedPayload

    # Get the private key object of your certificate
    $privateKey = [System.Security.Cryptography.X509Certificates.RSACertificateExtensions]::GetRSAPrivateKey($ClientCertificate)

    # Define RSA signature and hashing algorithm

    # Create a signature of the JWT
    $signature = [Convert]::ToBase64String(
        $privateKey.SignData([System.Text.Encoding]::UTF8.GetBytes($jwt), [Security.Cryptography.HashAlgorithmName]::SHA256, [Security.Cryptography.RSASignaturePadding]::Pkcs1)
    ) -replace '\+', '-' -replace '/', '_' -replace '='

    # Join the signature to the JWT with "."
    $jwt = $jwt + "." + $signature

    # Create the request splat
    $request = @{
        body        = @{
            client_id             = $ClientID
            client_assertion      = $jwt
            client_assertion_type = "urn:ietf:params:oauth:client-assertion-type:jwt-bearer"
            scope                 = "https://graph.microsoft.com/.default"
            grant_type            = "client_credentials"
        }
        ContentType = 'application/x-www-form-urlencoded'
        Method      = 'POST'
        Uri         = "https://login.microsoftonline.com/$TenantID/oauth2/v2.0/token"
        Headers     = @{
            Authorization = "Bearer $jwt"
        }
    }

    $oauth = Invoke-RestMethod @request
    $oauth | Add-Member -MemberType NoteProperty -Name TenantID -Value $TenantID
    $oauth | Add-Member -MemberType NoteProperty -Name ClientId -Value $ClientID
    $oauth | Add-Member -MemberType NoteProperty -Name ClientCertificate $ClientCertificate
    $oauth | Add-Member -MemberType NoteProperty -Name ClientSecret -Value $null
    $oauth | Add-Member -MemberType NoteProperty -Name ExpiresOn -Value $((Get-Date).AddSeconds($oauth.expires_in))

    return $oauth
}

Function Get-TokenBySecret {
    [cmdletbinding()]
    param (
        [parameter(Mandatory)]
        [string]
        $ClientID,

        [parameter(Mandatory)]
        [string]
        $ClientSecret,

        [parameter(Mandatory)]
        [string]
        $TenantID
    )

    # Create the request splat
    $request = @{
        Body        = @{
            grant_type    = 'client_credentials'
            scope         = 'https://graph.microsoft.com/.default'
            client_id     = $ClientID
            client_secret = $ClientSecret
        }
        ContentType = 'application/x-www-form-urlencoded'
        Method      = 'POST'
        Uri         = "https://login.microsoftonline.com/$($TenantID)/oauth2/v2.0/token"
    }

    $oauth = Invoke-RestMethod @request
    $oauth | Add-Member -MemberType NoteProperty -Name TenantID -Value $TenantID
    $oauth | Add-Member -MemberType NoteProperty -Name ClientId -Value $ClientID
    $oauth | Add-Member -MemberType NoteProperty -Name ClientCertificate -Value $null
    $oauth | Add-Member -MemberType NoteProperty -Name ClientSecret -Value ($ClientSecret | ConvertTo-SecureString -AsPlainText -Force)
    $oauth | Add-Member -MemberType NoteProperty -Name ExpiresOn -Value $((Get-Date).AddSeconds($oauth.expires_in))

    return $oauth
}

Function New-AccessToken {
    [CmdletBinding(DefaultParameterSetName = 'bySecret')]
    param (
        [Parameter(Mandatory, ParameterSetName = 'bySecret')]
        [Parameter(Mandatory, ParameterSetName = 'byCertificate')]
        [string]
        $ClientID,

        [Parameter(Mandatory, ParameterSetName = 'bySecret')]
        [Parameter(Mandatory, ParameterSetName = 'byCertificate')]
        [string]
        $TenantID,

        [Parameter(Mandatory, ParameterSetName = 'byCertificate')]
        [System.Security.Cryptography.X509Certificates.X509Certificate2]
        $ClientCertificate,

        [Parameter(Mandatory, ParameterSetName = 'bySecret')]
        [string]
        $ClientSecret,

        [Parameter()]
        [switch]
        $ReturnToken
    )


    if ($PSCmdlet.ParameterSetName -eq 'byCertificate') {
        try {
            $result = Get-TokenByCertificate -ClientID $ClientID -TenantID $TenantID -ClientCertificate $ClientCertificate -ErrorAction Stop
        }
        catch {
            SayError $_.Exception.Message
            return $null
        }
    }

    if ($PSCmdlet.ParameterSetName -eq 'bySecret') {
        try {
            $result = Get-TokenBySecret -ClientID $ClientID -TenantID $TenantID -ClientSecret $ClientSecret -ErrorAction Stop
        }
        catch {
            SayError $_.Exception.Message
            return $null
        }
    }

    $Script:GraphApiToken = $result
    if ($ReturnToken) { return $result }
}

Function Get-AccessToken {
    $Script:GraphApiToken
}

Function Update-AccessToken {
    [CmdletBinding()]
    param (
        [Parameter()]
        [Switch]
        $Force
    )

    $oldAccessToken = Get-AccessToken
    $isExpired = $((Get-Date) -gt $oldAccessToken.ExpiresOn)

    if (!$oldAccessToken) {
        Say 'No existing access token is found in the session. Run the New-AccessToken command instead to acquire an access token.'
        Return $null
    }

    if (!$isExpired -and !$Force) {
        # Say "The currect access token is not yet expired. To force the renewal, specify the -Force switch."
        return $null
    }

    $tokenRequest = @{
        ClientId = $oldAccessToken.ClientId
        TenantId = $oldAccessToken.TenantId
    }
    if ($oldAccessToken.ClientCertificate) {
        $tokenRequest = $tokenRequest + @{ClientCertificate = $oldAccessToken.ClientCertificate }
    }

    if ($oldAccessToken.ClientSecret) {
        $tokenRequest = $tokenRequest + @{ClientSecret = ([System.Net.NetworkCredential]::new("", $oldAccessToken.ClientSecret).Password) }
    }

    New-AccessToken @tokenRequest
}