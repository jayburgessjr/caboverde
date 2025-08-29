function handleDeepLink(args as Object) as Object
    ' 2024 Roku Deep Linking Handler
    ' Handles input launch parameters for direct content access
    
    if args = invalid then return {}
    
    deepLinkData = {
        handled: false
        category: invalid
        videoId: invalid
        searchQuery: invalid
    }
    
    ' Check for category deep link
    if args.category <> invalid then
        categoryName = args.category
        categoryIndex = getCategoryIndexByName(categoryName)
        if categoryIndex >= 0 then
            deepLinkData.category = categoryIndex
            deepLinkData.handled = true
        end if
    end if
    
    ' Check for direct video ID
    if args.videoId <> invalid then
        deepLinkData.videoId = args.videoId
        deepLinkData.handled = true
    end if
    
    ' Check for search query
    if args.search <> invalid then
        deepLinkData.searchQuery = args.search
        deepLinkData.handled = true
    end if
    
    ' Universal deep link support
    if args.contentId <> invalid then
        ' Parse universal content ID
        deepLinkData = parseUniversalContentId(args.contentId)
    end if
    
    return deepLinkData
end function

function getCategoryIndexByName(categoryName as String) as Integer
    ' Map category names to indices for deep linking
    categoryMap = {
        "music": 0
        "muzika": 0
        "news": 1
        "notisia": 1
        "comedy": 2
        "komedia": 2
        "film": 3
        "filme": 3
        "travel": 4
        "viagem": 4
    }
    
    if categoryMap[categoryName.ToLower()] <> invalid then
        return categoryMap[categoryName.ToLower()]
    end if
    
    return -1
end function

function parseUniversalContentId(contentId as String) as Object
    ' Parse universal deep link format: caboverde://category/music or caboverde://video/abc123
    result = {
        handled: false
        category: invalid
        videoId: invalid
    }
    
    if contentId.StartsWith("caboverde://") then
        parts = contentId.Replace("caboverde://", "").Split("/")
        
        if parts.Count() >= 2 then
            linkType = parts[0]
            linkValue = parts[1]
            
            if linkType = "category" then
                categoryIndex = getCategoryIndexByName(linkValue)
                if categoryIndex >= 0 then
                    result.category = categoryIndex
                    result.handled = true
                end if
            else if linkType = "video" then
                result.videoId = linkValue
                result.handled = true
            end if
        end if
    end if
    
    return result
end function

function executeDeepLink(deepLinkData as Object, mainScene as Object)
    ' Execute the deep link action on the main scene
    if not deepLinkData.handled then return
    
    if deepLinkData.category <> invalid then
        ' Navigate to specific category
        mainScene.callFunc("navigateToCategory", deepLinkData.category)
    else if deepLinkData.videoId <> invalid then
        ' Play specific video
        mainScene.callFunc("playVideoById", deepLinkData.videoId)
    else if deepLinkData.searchQuery <> invalid then
        ' Perform search
        mainScene.callFunc("performSearch", deepLinkData.searchQuery)
    end if
end function

function createDeepLinkUrl(category as Integer, videoId = "" as String) as String
    ' Create shareable deep link URLs
    if videoId <> "" then
        return "caboverde://video/" + videoId
    else if category >= 0 then
        categoryNames = ["music", "news", "comedy", "film", "travel"]
        if category < categoryNames.Count() then
            return "caboverde://category/" + categoryNames[category]
        end if
    end if
    
    return "caboverde://home"
end function