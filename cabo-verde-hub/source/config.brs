function getConfig() as Object
    ' Configuration for Cabo Verde Hub
    ' IMPORTANT: In production, move API key to server-side proxy or encrypted registry
    config = {
        youtube: {
            baseUrl: "https://www.googleapis.com/youtube/v3/search"
            ' TODO: Replace with server-side proxy endpoint or encrypted storage
            ' For now, set via registry in main.brs for security
            apiKey: ""  ' Set at runtime
        }
        app: {
            name: "Cabo Verde Hub"
            version: "1.0.1"
            timeout: 10000  ' 10 seconds
            maxResults: 12
            cacheTimeout: 300000  ' 5 minutes in milliseconds
        }
        ui: {
            gridColumns: 4
            gridRows: 3
            itemSpacing: [25, 25]
            itemSize: [320, 240]
        }
    }
    
    return config
end function

function initializeConfig() as Object
    ' Initialize configuration with secure API key handling
    config = getConfig()
    
    ' Try to get API key from registry (more secure than hardcoding)
    sec = CreateObject("roRegistrySection", "CaboVerdeHub")
    apiKey = sec.Read("youtube_api_key")
    
    if apiKey = "" or apiKey = invalid then
        ' Fallback to environment or prompt user to set it
        ' For development only - remove in production
        apiKey = "AIzaSyDVKM9I7EAwJUO15eOrq_8a9sZ-94EG5aU"
        print "WARNING: Using development API key. Set production key in registry!"
    end if
    
    config.youtube.apiKey = apiKey
    return config
end function

function setApiKey(apiKey as String) as Boolean
    ' Securely store API key in registry
    sec = CreateObject("roRegistrySection", "CaboVerdeHub")
    return sec.Write("youtube_api_key", apiKey)
end function

function clearCache() as Void
    ' Clear cached API responses
    sec = CreateObject("roRegistrySection", "CaboVerdeHubCache")
    sec.Delete()
end function

function getCachedResponse(cacheKey as String) as Object
    ' Get cached API response if still valid
    sec = CreateObject("roRegistrySection", "CaboVerdeHubCache")
    
    cachedData = sec.Read(cacheKey)
    if cachedData <> "" and cachedData <> invalid then
        try
            parsedCache = ParseJSON(cachedData)
            if parsedCache <> invalid and parsedCache.timestamp <> invalid then
                ' Check if cache is still valid (5 minutes)
                currentTime = CreateObject("roTimespan").TotalMilliseconds()
                if (currentTime - parsedCache.timestamp) < 300000 then  ' 5 minutes
                    return parsedCache.data
                end if
            end if
        catch error
            ' Invalid cache entry, ignore
        end try
    end if
    
    return invalid
end function

function setCachedResponse(cacheKey as String, data as Object) as Boolean
    ' Cache API response with timestamp
    sec = CreateObject("roRegistrySection", "CaboVerdeHubCache")
    
    cacheData = {
        timestamp: CreateObject("roTimespan").TotalMilliseconds()
        data: data
    }
    
    return sec.Write(cacheKey, FormatJSON(cacheData))
end function