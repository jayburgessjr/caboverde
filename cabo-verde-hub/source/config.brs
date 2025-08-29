function initializeConfig() as Object
    ' Secure configuration for Cabo Verde Hub
    config = {
        youtube: {
            baseUrl: "https://www.googleapis.com/youtube/v3/search"
            apiKey: "AIzaSyDVKM9I7EAwJUO15eOrq_8a9sZ-94EG5aU"  ' TODO: Move to server proxy
        }
        app: {
            name: "Cabo Verde Hub"
            version: "1.0.3"
            timeout: 10000  ' 10 seconds
            maxResults: 12
            cacheTimeout: 300000  ' 5 minutes
        }
        ui: {
            gridColumns: 4
            gridRows: 3
            itemSpacing: [25, 25]
            itemSize: [320, 240]
        }
    }
    
    ' Try to get API key from secure registry
    sec = CreateObject("roRegistrySection", "CaboVerdeHubSecure")
    secureApiKey = sec.Read("youtube_api_key")
    
    if secureApiKey <> "" and secureApiKey <> invalid then
        config.youtube.apiKey = secureApiKey
        print "[Config] Using secure API key from registry"
    else
        print "[Config] WARNING: Using development API key - move to production proxy!"
    end if
    
    return config
end function

function setSecureApiKey(apiKey as String) as Boolean
    ' Store API key securely in registry
    sec = CreateObject("roRegistrySection", "CaboVerdeHubSecure")
    success = sec.Write("youtube_api_key", apiKey)
    sec.Flush()
    return success
end function

function clearSecureData()
    ' Clear all secure configuration data
    sec = CreateObject("roRegistrySection", "CaboVerdeHubSecure")
    sec.Delete()
    sec.Flush()
    print "[Config] Secure data cleared"
end function