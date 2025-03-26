[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$Path = [System.IO.Path]::Combine($PSScriptRoot, 'source')
(Get-ChildItem $Path -Filter *.ps1 -Recurse -File).FullName | ForEach-Object {
    . $_
}

$Script:GraphApiToken = $null
$Script:GraphStartDate = '1970-01-01'
$Script:GraphEndDate = '1970-01-01'

$script:initialCloudDomain = $null

#Enable TLS 1.2
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12