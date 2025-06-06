using namespace System.Net

Function Invoke-ListGroupSenderAuthentication {
    [CmdletBinding()]
    param($Request, $TriggerMetadata)

    $APIName = $Request.Params.CIPPEndpoint
    $Headers = $Request.Headers
    Write-LogMessage -headers $Headers -API $APIName -message 'Accessed this API' -Sev 'Debug'

    # Interact with query parameters or the body of the request.
    $TenantFilter = $Request.Query.TenantFilter
    $groupid = $Request.query.groupid
    $GroupType = $Request.query.Type

    $params = @{
        Identity = $groupid
    }


    try {
        switch ($GroupType) {
            'Distribution List' {
                Write-Host 'Checking DL'
                $State = (New-ExoRequest -tenantid $TenantFilter -cmdlet 'Get-DistributionGroup' -cmdParams $params -UseSystemMailbox $true).RequireSenderAuthenticationEnabled
            }
            'Microsoft 365' {
                Write-Host 'Checking M365 Group'
                $State = (New-ExoRequest -tenantid $TenantFilter -cmdlet 'Get-UnifiedGroup' -cmdParams $params -UseSystemMailbox $true).RequireSenderAuthenticationEnabled

            }
            default { $state = $true }
        }

    } catch {
        $state = $true
    }

    # We flip the value because the API is asking if the group is allowed to receive external mail
    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
            StatusCode = [HttpStatusCode]::OK
            Body       = @{ allowedToReceiveExternal = !$state }
        })
}
