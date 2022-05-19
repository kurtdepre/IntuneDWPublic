function Get-AccessToken {
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true, ParameterSetName = 'Resource')]
        [Parameter(Mandatory = $true, ParameterSetName = 'Scope')]
        [string]$ClientId,
        
        [Parameter(Mandatory = $true, ParameterSetName = 'Resource')]
        [Parameter(Mandatory = $true, ParameterSetName = 'Scope')]
        [string]$ClientSecret,
        
        [Parameter(Mandatory = $true, ParameterSetName = 'Resource')]
        [Parameter(Mandatory = $true, ParameterSetName = 'Scope')]
        [string]$TenantId,
        
        [Parameter(Mandatory = $true, ParameterSetName = 'Resource')]
        [string]$Resource,
        
        [Parameter(Mandatory = $true, ParameterSetName = 'Scope')]
        [string]$Scope
    )

    begin {
        $body = @{ 
            "grant_type"    = "client_credentials" 
            "client_id"     = $ClientId
            "client_secret" = $ClientSecret
        }

        switch ( $PSCmdlet.ParameterSetName ) {
            "Resource" {
                $body["resource"] = $Resource
            }
            "Scope" {
                $body["scope"] = $Scope
            }
        }
    }
    process {
        if ($Resource -eq $Authscopes.Graph) {
            Invoke-RestMethod -Uri https://login.microsoftonline.com/$TenantId/oauth2/token -Method Post -Body $body | SELECT -ExpandProperty access_token
        }
        elseif ($Scope -eq $Authscopes.Vault) {
            Invoke-RestMethod -Uri https://login.microsoftonline.com/$TenantId/oauth2/v2.0/token -Method Post -Body $body | SELECT -ExpandProperty access_token
            
        }
            
    }
    end {
    }
}

function Get-VaultSecret {
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = $true)][string]$AccessToken,
        [parameter(Mandatory = $true)][string]$SecretName,
        [parameter(Mandatory = $true)][string]$VaultBaseUrl
       
    )
    
    begin {
        $headers = @{ "Authorization" = "Bearer $AccessToken" }

        $url = "$($VaultBaseUrl)/secrets/$($SecretName)?api-version=2016-10-01"
    }
    process {
        Invoke-RestMethod -Method Get -Uri $url -Headers $headers | SELECT -ExpandProperty value
    }
    end {
    }    
}

function Invoke-GraphReport {
    param($resourcename, $token)

    $headers = @{
        "Authorization" = "Bearer $($token)"
        "Content-type"  = "application/json"
    }


    $Uri = "https://graph.microsoft.com/beta/$($resourcename)"
   # Invoke-RestMethod -Uri $uri -Headers $headers -Method Get -Verbose -ErrorAction Stop

    $UserResponse = Invoke-RestMethod -Uri $uri -Headers $headers -Method Get -ErrorAction Stop
    if ($UserResponse.value) {
        $CloudUser = $UserResponse.value 
    }
    else {
        return $UserResponse
    }
    $UserNextLink = $UserResponse."@odata.nextLink"


    while ($UserNextLink -ne $null) {

        $UserResponse = (Invoke-RestMethod -Uri $UserNextLink -Headers $headers -Method Get -Verbose)
        $UserNextLink = $UserResponse."@odata.nextLink"
        $CloudUser += $UserResponse.value

    }
    return $CloudUser
}
