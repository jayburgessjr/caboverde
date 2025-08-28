function createHttpRequest(url as String, config as Object) as Object
    ' Create secure HTTP request with proper certificate handling
    request = CreateObject("roUrlTransfer")
    request.SetUrl(url)
    request.SetRequest("GET")
    
    ' Use secure certificate handling
    request.SetCertificatesFile("common:/certs/ca-bundle.crt")
    request.EnablePeerVerification(true)   ' Enable for security
    request.EnableHostVerification(true)   ' Enable for security
    
    ' Set timeout from config
    if config <> invalid and config.app <> invalid and config.app.timeout <> invalid then
        request.SetMessagePort(CreateObject("roMessagePort"))
        ' Note: Roku doesn't have direct timeout setting, handle via timer
    end if
    
    return request
end function

function makeAsyncRequest(url as String, config as Object, callback as String, context as Object) as Object
    ' Make asynchronous HTTP request with proper error handling
    request = createHttpRequest(url, config)
    port = CreateObject("roMessagePort")
    request.SetPort(port)
    
    if request.AsyncGetToString() then
        ' Create request context
        requestContext = {
            request: request
            port: port
            callback: callback
            context: context
            startTime: CreateObject("roTimespan")
            timeout: config.app.timeout
            url: url
        }
        requestContext.startTime.Mark()
        
        return requestContext
    else
        return invalid
    end if
end function

function handleHttpResponse(requestContext as Object) as Object
    ' Handle HTTP response with timeout and error checking
    if requestContext = invalid then return invalid
    
    msg = requestContext.port.GetMessage()
    
    if msg <> invalid then
        if type(msg) = "roUrlEvent" then
            responseCode = msg.GetResponseCode()
            
            if responseCode = 200 then
                ' Success
                response = msg.GetString()
                return {
                    success: true
                    data: response
                    responseCode: responseCode
                }
            else
                ' HTTP error
                return {
                    success: false
                    error: "HTTP Error: " + responseCode.ToStr()
                    responseCode: responseCode
                }
            end if
        end if
    else
        ' Check for timeout
        if requestContext.startTime.TotalMilliseconds() > requestContext.timeout then
            return {
                success: false
                error: "Request timeout"
                responseCode: -1
            }
        end if
    end if
    
    ' Still waiting
    return invalid
end function

function createCacheKey(searchTerms as String, categoryIndex as Integer) as String
    ' Create cache key for API responses
    return "category_" + categoryIndex.ToStr() + "_" + encodeUriComponent(searchTerms)
end function

function buildYouTubeUrl(searchQuery as String, config as Object) as String
    ' Build YouTube API URL with proper parameters
    return buildYouTubeUrlWithPagination(searchQuery, config, "")
end function

function buildYouTubeUrlWithPagination(searchQuery as String, config as Object, pageToken as String) as String
    ' Build YouTube API URL with pagination support
    url = config.youtube.baseUrl + "?"
    url = url + "part=snippet"
    url = url + "&type=video"
    url = url + "&maxResults=" + config.app.maxResults.ToStr()
    url = url + "&order=relevance"
    url = url + "&regionCode=PT"
    url = url + "&relevanceLanguage=pt"
    url = url + "&key=" + config.youtube.apiKey
    url = url + "&q=" + encodeUriComponent(searchQuery)
    
    ' Add page token for pagination
    if pageToken <> "" then
        url = url + "&pageToken=" + pageToken
    end if
    
    return url
end function

function validateYouTubeResponse(responseText as String) as Object
    ' Validate and parse YouTube API response
    try
        jsonResponse = ParseJSON(responseText)
        
        if jsonResponse <> invalid then
            ' Check for API errors
            if jsonResponse.error <> invalid then
                return {
                    valid: false
                    error: "API Error: " + jsonResponse.error.message
                }
            end if
            
            ' Check for valid items
            if jsonResponse.items <> invalid then
                return {
                    valid: true
                    data: jsonResponse
                }
            else
                return {
                    valid: false
                    error: "No video items in response"
                }
            end if
        else
            return {
                valid: false
                error: "Invalid JSON response"
            }
        end if
        
    catch error
        return {
            valid: false
            error: "JSON parse error: " + error.message
        }
    end try
end function