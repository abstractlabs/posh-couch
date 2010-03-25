function CouchDbRequest {
param(
    [string] $method = "GET",
    [string] $dbHost = "127.0.0.1",
    [int] $port = 5984    
    )
    
    $request = [System.Net.WebRequest]::Create("http://$host:$port")
    $request.Method = $method
    
    $response = $request.GetResponse()
    #$responseStream = $response.GetResponseStream()
}