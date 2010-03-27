<#
 .Synopsis
  Sends a request to a CouchDB database server.
  
 .Description
  Sends a request to a CouchDB database server.
#>

function Send-CouchDbRequest {
param(
    [string] $method = "GET",
    [string] $dbHost = "127.0.0.1",
    [int] $port = 5984,
    [string] $database = $(throw "Please specify the database name."),
    [string] $document,
    [string] $rev,
    [string] $attachment,
    [string] $data,
    [boolean] $includeDoc = $false
    )
    
    if (($attachment -ne $null) -and ($document -eq $null)) {
        throw "Cannot accept an attachment name without a document id"
    }
    
    # Build the URL
    
    $url = "http://${dbHost}:$port/$database"
    
    $document = $document.Trim()
    if (![String]::IsNullOrEmpty($document)) {
        $url += "/$document"
    }
    
    $attachment = $attachment.Trim()
    if (![String]::IsNullOrEmpty($attachment)) {
        $url += "/$attachment"
    }
    
    # Build the query string    
    $queryString = @{}
    
    $rev = $rev.Trim()
    if (![String]::IsNullOrEmpty($rev)) {
        $queryString["rev"] = $rev
    }
    
    if ($includeDoc -eq $true) {
        $queryString["include_doc"] = "true"
    }
    
    # Add the query string to the URL, if there is anything to add.
    if ($queryString.Count > 0) {
        $url += (Format-QueryString $queryString)
    }
    
    $request = [System.Net.WebRequest]::Create("$url")
    $request.Method = $method
    $request.UserAgent = "Posh-Couch"
    
    if (($method -eq "POST") -and ($data -ne $null)) {
        $requestStream = $request.GetRequestStream()
        $writeStream = New-Object System.IO.StreamWriter $requestStream
        $writeStream.WriteLine($data)
        $writeStream.Close()
    }
    
    Write-Host $method $url
    
    $response = $request.GetResponse()
    $responseStream = $response.GetResponseStream()
    $readStream = New-Object System.IO.StreamReader $responseStream
    $responseData = $readStream.ReadToEnd()
    
    $readStream.Close()
    $response.Close()
    
    return $responseData
}

<#
 .Synopsis
  Serialises an arbitrary hashtable into a query string.
  
 .Description
  Serialises an arbitrary hashtable into a query string.
#>
function Format-QueryString {
    param([hashtable] $hashtable)
    
    $queryString = "?"    
    foreach($key in $hashtable.Keys) {
        $queryString += [string]::Format("{0}={1}&", $key, $hashtable.$key)
    }
    
    return $queryString.TrimEnd("&")
}

<#
 .Synopsis
  Creates a new CouchDB database.
  
 .Description
  Creates a new CouchDB database.
#>
function Create-Database {
    param(
        [string]$name = $(throw "Database name is required."),
        [string]$server = "127.0.0.1",
        [int]$port = 5984
    )
    
    Send-CouchDbRequest -method "PUT" -dbHost $server -port $port -database $name
}

<#
 .Synopsis
  Creates a new document in the specified CouchDB database.
  
 .Description
  Creates a new document in the specified CouchDB database.
#>
function Create-Document {
    param(
        [string]$database = $(throw "Database name is required."),
        [string]$server = "127.0.0.1",
        [int]$port = 5984,
        [string]$document = $(throw "Document is required.")
    )
    
    Send-CouchDbRequest -method "POST" -dbHost $server -port $port -database $database -data $document
}

Export-ModuleMember -Function Create-Database
Export-ModuleMember -Function Create-Document