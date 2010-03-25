function Send-CouchDbRequest {
param(
    [string] $method = "GET",
    [string] $dbHost = "127.0.0.1",
    [int] $port = 5984,
    [string] $database = $(throw "Please specify the database name."),
    [string] $data
    )
    
    $request = [System.Net.WebRequest]::Create("http://${dbHost}:$port/$database")
    $request.Method = $method
    $request.UserAgent = "Posh-Couch"
    
    if ($data -ne $null) {
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