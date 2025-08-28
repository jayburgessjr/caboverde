function init()
    m.top.setFocus(true)
    
    ' Initialize configuration
    m.config = initializeConfig()
    
    ' Initialize UI components
    m.categoryList = m.top.findNode("categoryList")
    m.videoGrid = m.top.findNode("videoGrid")
    m.sectionTitle = m.top.findNode("sectionTitle")
    m.loadingOverlay = m.top.findNode("loadingOverlay")
    m.errorOverlay = m.top.findNode("errorOverlay")
    
    ' Current state
    m.currentCategory = 0
    m.focusState = "category"  ' "category" or "video"
    
    ' Pagination state
    m.currentPage = {}
    m.hasMoreContent = {}
    m.loadingMore = false
    
    ' Request handling
    m.activeRequests = {}
    m.nextRequestId = 0
    
    ' Create response timer for async requests
    m.responseTimer = CreateObject("roSGNode", "Timer")
    m.responseTimer.duration = 0.1  ' Check every 100ms
    m.responseTimer.repeat = true
    m.responseTimer.observeField("fire", "onResponseTimer")
    
    ' Cape Verdean search configurations
    setupCategories()
    
    ' Event observers
    m.categoryList.observeField("itemSelected", "onCategorySelected")
    m.videoGrid.observeField("itemSelected", "onVideoSelected")
    
    ' Initialize with first category
    loadCategoryContent(0)
end function

function setupCategories()
    m.categories = [
        {
            title: "🎵 Muzika",
            description: "Morna, Coladeira, Funana",
            searchTerms: "cesaria evora,morna,coladeira,tito paris,mayra andrade,funana,batuque,cabo verde music",
            sectionTitle: "Muzika Cabo Verdiana"
        },
        {
            title: "📰 Notisia",
            description: "Noticias di Cabo Verde",
            searchTerms: "noticias cabo verde,rtp africa,cabo verde hoje,politica cabo verde,cabo verde atualidades",
            sectionTitle: "Notisias di Nos Terra"
        },
        {
            title: "😂 Komedia",
            description: "Humor Cabo Verdiano",
            searchTerms: "humor cabo verdiano,comedia cabo verde,tony hopffer,piada cabo verde,teatro cabo verde",
            sectionTitle: "Humor di nos Ilha"
        },
        {
            title: "🎬 Filme",
            description: "Documentários, Curtas",
            searchTerms: "documentario cabo verde,filme cabo verde,cinema cabo verdiano,historia cabo verde",
            sectionTitle: "Cinema Cabo Verdiano"
        },
        {
            title: "🏖️ Viagem",
            description: "Turismo, Kultura",
            searchTerms: "cabo verde travel,turismo cabo verde,santa maria sal,mindelo,pico fogo,culture cabo verde",
            sectionTitle: "Descubra Cabo Verde"
        }
    ]
    
    ' Create category content
    categoryContent = CreateObject("roSGNode", "ContentNode")
    for each category in m.categories
        item = CreateObject("roSGNode", "ContentNode")
        item.title = category.title
        item.description = category.description
        categoryContent.appendChild(item)
    end for
    
    m.categoryList.content = categoryContent
    m.categoryList.setFocus(true)
end function

function onCategorySelected()
    selectedIndex = m.categoryList.itemSelected
    if selectedIndex >= 0 and selectedIndex < m.categories.count() then
        m.currentCategory = selectedIndex
        loadCategoryContent(selectedIndex)
    end if
end function

function loadCategoryContent(categoryIndex as Integer)
    if categoryIndex < 0 or categoryIndex >= m.categories.count() then return
    
    category = m.categories[categoryIndex]
    m.sectionTitle.text = category.sectionTitle
    
    ' Show loading state
    m.loadingOverlay.visible = true
    m.errorOverlay.visible = false
    
    ' Fetch YouTube videos
    fetchYouTubeVideos(category.searchTerms, categoryIndex)
end function

function fetchYouTubeVideos(searchQuery as String, categoryIndex as Integer, pageToken = "" as String)
    ' Initialize pagination for category if needed
    categoryKey = categoryIndex.ToStr()
    if m.currentPage[categoryKey] = invalid then
        m.currentPage[categoryKey] = ""
        m.hasMoreContent[categoryKey] = true
    end if
    
    ' Don't fetch if loading more content
    if m.loadingMore and pageToken <> "" then return
    
    ' Check cache first (only for first page)
    if pageToken = "" then
        cacheKey = createCacheKey(searchQuery, categoryIndex)
        cachedData = getCachedResponse(cacheKey)
        
        if cachedData <> invalid then
            ' Use cached data
            processYouTubeResponse(FormatJSON(cachedData), categoryIndex, true, "", false)
            return
        end if
    end if
    
    ' Build YouTube API URL using new service
    url = buildYouTubeUrlWithPagination(searchQuery, m.config, pageToken)
    
    ' Set loading state
    if pageToken = "" then
        m.loadingOverlay.visible = true
    else
        m.loadingMore = true
    end if
    
    ' Make secure async request
    requestContext = makeAsyncRequest(url, m.config, "onYouTubeResponse", {
        categoryIndex: categoryIndex,
        cacheKey: cacheKey,
        pageToken: pageToken,
        isLoadMore: pageToken <> ""
    })
    
    if requestContext <> invalid then
        ' Store request with unique ID
        requestId = m.nextRequestId
        m.nextRequestId = m.nextRequestId + 1
        m.activeRequests[requestId.ToStr()] = requestContext
        
        ' Start response timer if not already running
        if m.responseTimer.control <> "start" then
            m.responseTimer.control = "start"
        end if
    else
        showError("Falha na conexão com YouTube")
        m.loadingMore = false
    end if
end function

function onResponseTimer()
    ' Handle all active requests
    requestsToRemove = []
    
    for each requestId in m.activeRequests
        requestContext = m.activeRequests[requestId]
        
        if requestContext <> invalid then
            result = handleHttpResponse(requestContext)
            
            if result <> invalid then
                ' Request completed
                if result.success then
                    processYouTubeResponse(
                        result.data,
                        requestContext.context.categoryIndex,
                        false,
                        requestContext.context.cacheKey,
                        requestContext.context.isLoadMore
                    )
                else
                    showError(result.error)
                    m.loadingMore = false
                end if
                
                requestsToRemove.Push(requestId)
            end if
        end if
    end for
    
    ' Remove completed requests
    for each requestId in requestsToRemove
        m.activeRequests.Delete(requestId)
    end for
    
    ' Stop timer if no active requests
    if m.activeRequests.Count() = 0 then
        m.responseTimer.control = "stop"
    end if
end function

function processYouTubeResponse(response as String, categoryIndex as Integer, fromCache = false as Boolean, cacheKey = "" as String, isLoadMore = false as Boolean)
    ' Validate response using new service
    validation = validateYouTubeResponse(response)
    
    if not validation.valid then
        showError(validation.error)
        m.loadingMore = false
        return
    end if
    
    jsonResponse = validation.data
    categoryKey = categoryIndex.ToStr()
    
    ' Update pagination info
    if jsonResponse.nextPageToken <> invalid then
        m.currentPage[categoryKey] = jsonResponse.nextPageToken
        m.hasMoreContent[categoryKey] = true
    else
        m.hasMoreContent[categoryKey] = false
    end if
    
    ' Cache response if not from cache and first page
    if not fromCache and cacheKey <> "" and not isLoadMore then
        setCachedResponse(cacheKey, jsonResponse)
    end if
    
    ' Create or append to video content
    videoContent = invalid
    if isLoadMore and m.videoGrid.content <> invalid then
        ' Append to existing content
        videoContent = m.videoGrid.content
    else
        ' Create new content
        videoContent = CreateObject("roSGNode", "ContentNode")
    end if
    
    itemCount = 0
    for each item in jsonResponse.items
        if item.snippet <> invalid then
            videoItem = CreateObject("roSGNode", "ContentNode")
            
            ' Basic info
            videoItem.title = item.snippet.title
            videoItem.description = item.snippet.description
            
            ' Thumbnail with fallback
            if item.snippet.thumbnails <> invalid then
                if item.snippet.thumbnails.high <> invalid then
                    videoItem.hdPosterUrl = item.snippet.thumbnails.high.url
                else if item.snippet.thumbnails.medium <> invalid then
                    videoItem.hdPosterUrl = item.snippet.thumbnails.medium.url
                else if item.snippet.thumbnails.default <> invalid then
                    videoItem.hdPosterUrl = item.snippet.thumbnails.default.url
                end if
            end if
            
            ' Video URL and metadata
            if item.id <> invalid and item.id.videoId <> invalid then
                videoItem.videoId = item.id.videoId
                videoItem.url = "https://www.youtube.com/watch?v=" + item.id.videoId
            end if
            
            ' Additional metadata
            videoItem.channelTitle = item.snippet.channelTitle
            videoItem.publishedAt = item.snippet.publishedAt
            
            videoContent.appendChild(videoItem)
            itemCount = itemCount + 1
        end if
    end for
    
    ' Update UI
    m.videoGrid.content = videoContent
    m.loadingOverlay.visible = false
    m.loadingMore = false
    
    ' Set focus to video grid if we have content
    if videoContent.getChildCount() > 0 then
        if not isLoadMore then
            m.focusState = "video"
            m.videoGrid.setFocus(true)
        end if
    else if not isLoadMore then
        showError("Nenhum vídeo encontrado")
    end if
    
    ' Show load more indicator if more content available
    updateLoadMoreIndicator(categoryIndex)
end function

function onVideoSelected()
    selectedIndex = m.videoGrid.itemSelected
    if selectedIndex >= 0 then
        playVideo(selectedIndex)
    end if
end function

function playVideo(videoIndex as Integer)
    videoContent = m.videoGrid.content.getChild(videoIndex)
    
    if videoContent <> invalid and videoContent.videoId <> invalid then
        ' Create video player
        videoPlayer = CreateObject("roSGNode", "Video")
        videoPlayer.content = videoContent
        videoPlayer.visible = true
        videoPlayer.control = "play"
        
        ' Add to scene
        m.top.appendChild(videoPlayer)
        videoPlayer.setFocus(true)
        
        ' Observe video events
        videoPlayer.observeField("state", "onVideoStateChange")
    else
        showError("Não é possível reproduzir este vídeo")
    end if
end function

function onVideoStateChange()
    ' Handle video state changes if needed
end function

function showError(message as String)
    m.loadingOverlay.visible = false
    m.errorOverlay.visible = true
    m.top.findNode("errorText").text = message
    
    ' Create non-blocking timer for auto-hide
    if m.errorTimer = invalid then
        m.errorTimer = CreateObject("roSGNode", "Timer")
        m.errorTimer.duration = 5
        m.errorTimer.repeat = false
        m.errorTimer.observeField("fire", "onErrorTimer")
    end if
    
    m.errorTimer.control = "start"
end function

function onErrorTimer()
    m.errorOverlay.visible = false
end function

function loadMoreContent(categoryIndex as Integer)
    if categoryIndex < 0 or categoryIndex >= m.categories.count() then return
    
    categoryKey = categoryIndex.ToStr()
    if m.hasMoreContent[categoryKey] = invalid or not m.hasMoreContent[categoryKey] then return
    
    category = m.categories[categoryIndex]
    pageToken = m.currentPage[categoryKey]
    
    if pageToken <> invalid and pageToken <> "" then
        fetchYouTubeVideos(category.searchTerms, categoryIndex, pageToken)
    end if
end function

function updateLoadMoreIndicator(categoryIndex as Integer)
    ' Add visual indicator if more content is available
    categoryKey = categoryIndex.ToStr()
    if m.hasMoreContent[categoryKey] = invalid then return
    
    ' Update section title to show loading state or more available
    sectionText = m.categories[categoryIndex].sectionTitle
    
    if m.hasMoreContent[categoryKey] then
        sectionText = sectionText + " (▼ Mais conteúdo disponível)"
    end if
    
    m.sectionTitle.text = sectionText
end function

function onKeyEvent(key as String, press as Boolean) as Boolean
    handled = false
    
    if press then
        if key = "back" then
            if m.errorOverlay.visible then
                m.errorOverlay.visible = false
                handled = true
            else if m.focusState = "video" then
                m.focusState = "category"
                m.categoryList.setFocus(true)
                handled = true
            end if
            
        else if key = "OK" then
            if m.errorOverlay.visible then
                m.errorOverlay.visible = false
                loadCategoryContent(m.currentCategory)  ' Retry
                handled = true
            end if
            
        else if key = "left" then
            if m.focusState = "video" then
                m.focusState = "category"
                m.categoryList.setFocus(true)
                handled = true
            end if
            
        else if key = "right" then
            if m.focusState = "category" and m.videoGrid.content <> invalid then
                if m.videoGrid.content.getChildCount() > 0 then
                    m.focusState = "video"
                    m.videoGrid.setFocus(true)
                    handled = true
                end if
            end if
            
        else if key = "down" then
            ' Load more content when reaching end of list
            if m.focusState = "video" and not m.loadingMore then
                selectedIndex = m.videoGrid.itemSelected
                totalItems = m.videoGrid.content.getChildCount()
                
                ' If near the end, load more content
                if selectedIndex >= totalItems - 4 then  ' Load when 4 items from end
                    loadMoreContent(m.currentCategory)
                end if
            end if
        end if
    end if
    
    return handled
end function
