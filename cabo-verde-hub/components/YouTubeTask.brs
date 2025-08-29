function init()
    ' Initialize task node for background YouTube API calls
    m.top.functionName = "fetchYouTubeContent"
    m.top.observeField("result", "onResultReady")
    m.top.observeField("error", "onErrorReceived")
end function

function fetchYouTubeContent()
    ' Main task function - runs in background thread
    try
        searchQuery = m.top.searchQuery
        categoryIndex = m.top.categoryIndex
        pageToken = m.top.pageToken
        config = m.top.config
        cacheKey = m.top.cacheKey
        
        ' Validate inputs
        if searchQuery = invalid or config = invalid then
            m.top.error = "Invalid input parameters"
            return
        end if
        
        ' Check cache first (only for first page)
        if pageToken = "" and cacheKey <> "" then
            cachedData = getCachedResponse(cacheKey)
            if cachedData <> invalid then
                m.top.result = {
                    success: true
                    data: cachedData
                    fromCache: true
                    categoryIndex: categoryIndex
                    isLoadMore: false
                }
                return
            end if
        end if
        
        ' Build YouTube API URL
        url = buildYouTubeUrlWithPagination(searchQuery, config, pageToken)
        
        ' Make HTTP request
        result = makeHttpRequest(url, config)
        
        if result.success then
            ' Parse and validate response
            validation = validateYouTubeResponse(result.data)
            
            if validation.valid then
                ' Cache if first page
                if pageToken = "" and cacheKey <> "" then
                    setCachedResponse(cacheKey, validation.data)
                end if
                
                m.top.result = {
                    success: true
                    data: validation.data
                    fromCache: false
                    categoryIndex: categoryIndex
                    isLoadMore: pageToken <> ""
                }
            else
                m.top.error = validation.error
            end if
        else
            m.top.error = result.error
        end if
        
    catch error
        m.top.error = "Task execution error: " + error.message
    end try
end function

function makeHttpRequest(url as String, config as Object) as Object
    ' Make synchronous HTTP request (runs in task thread)
    request = CreateObject("roUrlTransfer")
    request.SetUrl(url)
    request.SetRequest("GET")
    
    ' Use secure certificate handling
    request.SetCertificatesFile("common:/certs/ca-bundle.crt")
    request.EnablePeerVerification(true)
    request.EnableHostVerification(true)
    
    ' Set headers
    request.AddHeader("User-Agent", "CaboVerdeHub/1.0.2")
    request.AddHeader("Accept", "application/json")
    
    ' Make request with timeout
    response = request.GetToString()
    responseCode = request.GetResponseCode()
    
    if responseCode = 200 then
        return {
            success: true
            data: response
            responseCode: responseCode
        }
    else
        return {
            success: false
            error: "HTTP Error: " + responseCode.ToStr()
            responseCode: responseCode
        }
    end if
end function

function onResultReady()
    ' Called when result is available - runs in render thread
    print "YouTube task completed successfully"
end function

function onErrorReceived()
    ' Called when error occurs - runs in render thread
    print "YouTube task error: " + m.top.error
end function

' Task-specific utility functions
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
                    error: "YouTube API Error: " + jsonResponse.error.message
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
            error: "JSON parse error"
        }
    end try
end function