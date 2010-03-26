function Send-CouchDbRequest {
param(
    [string] $method = "GET",
    [string] $dbHost = "127.0.0.1",
    [int] $port = 5984,
    [string] $database = $(throw "Please specify the database name."),
    [string] $document,
    [string] $rev,
    [string] $attachment,
    [string] $data
    )
    
    if (($attachment -ne $null) -and ($document -eq $null)) {
        throw "Cannot accept an attachment name without a document id"
    }
    
    $url = "http://${dbHost}:$port/$database/$document"
    if ($attachment -ne $null) {
        $url += "/$attachment"
    }
    
    New-Variable queryString
    if ($rev -ne $null) {
        $queryString += "rev=$rev"
    }
    
    $request = [System.Net.WebRequest]::Create("${url}?$queryString")
    $request.Method = $method
    $request.UserAgent = "Posh-Couch"
    
    if (($method -eq "POST") -and ($data -ne $null)) {
        $requestStream = $request.GetRequestStream()
        $writeStream = New-Object System.IO.StreamWriter $requestStream
        $writeStream.WriteLine($data)
        $writeStream.Close()
    }
    
    $response = $request.GetResponse()
    $responseStream = $response.GetResponseStream()
    $readStream = New-Object System.IO.StreamReader $responseStream
    $responseData = $readStream.ReadToEnd()
    
    $readStream.Close()
    $response.Close()
    
    return $responseData
}