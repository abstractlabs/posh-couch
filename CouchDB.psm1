$ErrorActionPreference = "SilentlyContinue"

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
    
    # Echo the request to screen for informational purposes.
    Write-Host $method $url
    
    if (($method -eq "POST") -and ($data -ne $null)) {
        $requestStream = $request.GetRequestStream()
        $writeStream = New-Object System.IO.StreamWriter $requestStream
        $writeStream.WriteLine($data)
        $writeStream.Close()
        
        # Echo the $data to screen for informational purposes.
        Write-Host $data
    }
    
    # Set up error handling for the CouchDB requests
    trap [System.Net.WebException] {
        Handle-CouchDBError "$method $url" $_
        return
    }
    
    $response = $request.GetResponse()
    $responseStream = $response.GetResponseStream()
    $readStream = New-Object System.IO.StreamReader $responseStream
    $responseData = $readStream.ReadToEnd()
    
    $readStream.Close()
    $response.Close()
    
    return $responseData
}

function Handle-CouchDBError {
    param(
        [String] $request,
        [System.Management.Automation.ErrorRecord] $error)
    
    # Write a blank line for whitespacing purposes
    Write-Host
    
    if ($error.Exception.Status -eq [System.Net.WebExceptionStatus]::ConnectFailure) {
        Write-Host -ForegroundColor Red "CouchDB is not listening on port $port on the server $server."
        return
    } 
    
    if ($error.Exception.Status -eq [System.Net.WebExceptionStatus]::ProtocolError) {
        $description = $error.Exception.Message        
        Write-Host -ForegroundColor Red "CouchDB didn't like the request `"$request`".  Here's what it took issue with:`n`t${description}`n"
        Write-Host -ForegroundColor Red "Note that CouchDB parameters (database names, attachment names, etc.) must be lower case.`n"
        return
    }
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
  
 .Parameter Name
  The name of the database that you wish to created.  This is a required 
  parameter.  CouchDB requires that the database name be entered entirely in 
  lowercase.
  
 .Parameter Server
  The host name on which CouchDB is running.  Defaults to 127.0.0.1
  
 .Parameter Port
  The port number on which CouchDB is listening.  Defaults to CouchDB's native 
  port, 5984.  
  
 .Example
  # Create a database called "test"
  Create-Database -Name "test"
  
 .Example
  # Create a database called "test" running on server foo and port 1234
  Create-Database -Name "test" -Server "foo" -Port 1234
#>
function New-Database {
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
  
 .Parameter Database
  The name of the database in which the document should be created.  
 
 .Parameter Document
  The document to be saved to CouchDB.  This must be a valid JSON document.
  
 .Parameter Server
  The host name on which CouchDB is running.  Defaults to 127.0.0.1
  
 .Parameter Port
  The port number on which CouchDB is listening.  Defaults to CouchDB's native 
  port, 5984.  
#>
function New-Document {
    param(
        [string]$database = $(throw "Database name is required."),
        [string]$server = "127.0.0.1",
        [int]$port = 5984,
        [string]$document = $(throw "Document is required.")
    )
    
    Send-CouchDbRequest -method "POST" -dbHost $server -port $port -database $database -data $document
}

Export-ModuleMember -Function New-Database
Export-ModuleMember -Function New-Document