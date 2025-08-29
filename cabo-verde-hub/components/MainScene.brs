function init()
    m.top.setFocus(true)
    
    ' Initialize configuration (2024 Security Best Practice)
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
    
    ' Pagination state (2024 Performance Best Practice)
    m.currentPage = {}
    m.hasMoreContent = {}
    m.loadingMore = false
    
    ' Task-based request handling (2024 SceneGraph Best Practice)
    m.youtubeTask = CreateObject("roSGNode", "YouTubeTask")
    m.youtubeTask.observeField("result", "onYouTubeTaskResult")
    m.youtubeTask.observeField("error", "onYouTubeTaskError")
    
    ' Thread management tracking (2024 Threading Guidelines)
    m.activeTasksCount = 0
    m.maxConcurrentTasks = 3  ' Limit per 2024 guidelines
    
    ' Error handling timer (Non-blocking)
    m.errorTimer = CreateObject("roSGNode", "Timer")
    m.errorTimer.duration = 5
    m.errorTimer.repeat = false
    m.errorTimer.observeField("fire", "onErrorTimer")
    
    ' Cape Verdean search configurations
    setupCategories()
    
    ' Event observers
    m.categoryList.observeField("itemSelected", "onCategorySelected")
    m.videoGrid.observeField("itemSelected", "onVideoSelected")
    
    ' Voice remote support (2024 Feature)
    m.top.observeField("voiceSearchText", "onVoiceSearch")
    
    ' Deep linking support
    handleInitialDeepLink()
    
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
    ' 2024 SceneGraph Best Practice: Use Task nodes for background operations
    
    ' Initialize pagination for category if needed
    categoryKey = categoryIndex.ToStr()
    if m.currentPage[categoryKey] = invalid then
        m.currentPage[categoryKey] = ""
        m.hasMoreContent[categoryKey] = true
    end if
    
    ' Thread management: Don't exceed concurrent task limit (2024 Guidelines)
    if m.activeTasksCount >= m.maxConcurrentTasks then
        showError("Muitas requisições simultâneas. Aguarde.")
        return
    end if
    
    ' Don't fetch if already loading more content
    if m.loadingMore and pageToken <> "" then return
    
    ' Set loading state
    if pageToken = "" then
        m.loadingOverlay.visible = true
    else
        m.loadingMore = true
    end if
    
    ' Create cache key
    cacheKey = createCacheKey(searchQuery, categoryIndex)
    
    ' Set up task parameters
    m.youtubeTask.searchQuery = searchQuery
    m.youtubeTask.categoryIndex = categoryIndex
    m.youtubeTask.pageToken = pageToken
    m.youtubeTask.config = m.config
    m.youtubeTask.cacheKey = cacheKey
    m.youtubeTask.isLoadMore = (pageToken <> "")
    
    ' Start background task
    m.youtubeTask.control = "RUN"
    m.activeTasksCount = m.activeTasksCount + 1
end function

function onYouTubeTaskResult()
    ' 2024 Best Practice: Handle task results in render thread
    result = m.youtubeTask.result
    m.activeTasksCount = m.activeTasksCount - 1
    
    if result <> invalid and result.success then
        if result.fromCache then
            processYouTubeResponse(
                FormatJSON(result.data),
                result.categoryIndex,
                true,
                "",
                result.isLoadMore
            )
        else
            processYouTubeResponse(
                FormatJSON(result.data),
                result.categoryIndex,
                false,
                "",
                result.isLoadMore
            )
        end if
    end if
end function

function onYouTubeTaskError()
    ' Handle task errors in render thread
    error = m.youtubeTask.error
    m.activeTasksCount = m.activeTasksCount - 1
    m.loadingMore = false
    
    if error <> invalid then
        showError(error)
    else
        showError("Erro desconhecido")
    end if
end function

function processYouTubeResponse(response as String, categoryIndex as Integer, fromCache = false as Boolean, cacheKey = "" as String, isLoadMore = false as Boolean)
    try
        jsonResponse = ParseJSON(response)
        categoryKey = categoryIndex.ToStr()
        
        if jsonResponse <> invalid and jsonResponse.items <> invalid then
            ' Update pagination info (2024 Performance Enhancement)
            if jsonResponse.nextPageToken <> invalid then
                m.currentPage[categoryKey] = jsonResponse.nextPageToken
                m.hasMoreContent[categoryKey] = true
            else
                m.hasMoreContent[categoryKey] = false
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
                    
                    ' Thumbnail with fallback (2024 Best Practice)
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
            
        else
            showError("Nenhum vídeo encontrado")
            m.loadingMore = false
        end if
        
    catch error
        showError("Erro ao processar resposta")
        m.loadingMore = false
    end try
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
    ' 2024 Best Practice: Non-blocking error display
    m.loadingOverlay.visible = false
    m.errorOverlay.visible = true
    m.top.findNode("errorText").text = message
    
    ' Start non-blocking timer for auto-hide
    m.errorTimer.control = "start"
end function

function onErrorTimer()
    ' Auto-hide error overlay
    m.errorOverlay.visible = false
end function

function loadMoreContent(categoryIndex as Integer)
    ' Load additional content when user scrolls near end
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
    ' Update UI to show if more content is available
    categoryKey = categoryIndex.ToStr()
    if m.hasMoreContent[categoryKey] = invalid then return
    
    sectionText = m.categories[categoryIndex].sectionTitle
    
    if m.hasMoreContent[categoryKey] then
        sectionText = sectionText + " (▼ Mais conteúdo disponível)"
    end if
    
    m.sectionTitle.text = sectionText
end function

function createCacheKey(searchTerms as String, categoryIndex as Integer) as String
    ' Create cache key for API responses
    return "category_" + categoryIndex.ToStr() + "_" + encodeUriComponent(searchTerms)
end function

function onVoiceSearch()
    ' Handle voice search input (2024 Voice Remote Support)
    searchText = m.top.voiceSearchText
    
    if searchText <> invalid and searchText <> "" then
        ' Perform voice search across all categories
        performVoiceSearch(searchText)
    end if
end function

function performVoiceSearch(searchQuery as String)
    ' Execute voice search with enhanced query
    enhancedQuery = searchQuery + ",cabo verde,cape verde"
    
    ' Show loading overlay
    m.loadingOverlay.visible = true
    m.sectionTitle.text = "Busca por Voz: '" + searchQuery + "'"
    
    ' Switch to search mode
    m.focusState = "search"
    
    ' Use task for voice search
    m.youtubeTask.searchQuery = enhancedQuery
    m.youtubeTask.categoryIndex = -1  ' Special index for voice search
    m.youtubeTask.pageToken = ""
    m.youtubeTask.config = m.config
    m.youtubeTask.cacheKey = "voice_search_" + encodeUriComponent(searchQuery)
    m.youtubeTask.isLoadMore = false
    
    m.youtubeTask.control = "RUN"
    m.activeTasksCount = m.activeTasksCount + 1
end function

function handleInitialDeepLink()
    ' Handle deep linking on app launch
    args = m.top.getScene().args
    if args <> invalid then
        deepLinkData = handleDeepLink(args)
        if deepLinkData.handled then
            executeDeepLink(deepLinkData, m.top)
        end if
    end if
end function

function navigateToCategory(categoryIndex as Integer)
    ' Deep link navigation to specific category
    if categoryIndex >= 0 and categoryIndex < m.categories.count() then
        m.currentCategory = categoryIndex
        m.categoryList.jumpToItem = categoryIndex
        loadCategoryContent(categoryIndex)
    end if
end function

function playVideoById(videoId as String)
    ' Deep link direct video playback
    ' Create content node for direct video play
    videoContent = CreateObject("roSGNode", "ContentNode")
    videoContent.videoId = videoId
    videoContent.url = "https://www.youtube.com/watch?v=" + videoId
    videoContent.title = "Vídeo Direto"
    
    ' Play video directly
    playVideoContent(videoContent)
end function

function performSearch(searchQuery as String)
    ' Deep link search functionality
    performVoiceSearch(searchQuery)
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
            ' 2024 Enhancement: Auto-load more content when scrolling
            if m.focusState = "video" and not m.loadingMore then
                selectedIndex = m.videoGrid.itemSelected
                totalItems = m.videoGrid.content.getChildCount()
                
                ' Load more when approaching end of list
                if selectedIndex >= totalItems - 4 then
                    loadMoreContent(m.currentCategory)
                end if
            end if
        end if
    end if
    
    return handled
end function
