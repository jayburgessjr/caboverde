function init()
    m.top.setFocus(true)
    
    ' Initialize UI components
    m.categoryList = m.top.findNode("categoryList")
    m.videoGrid = m.top.findNode("videoGrid")
    m.sectionTitle = m.top.findNode("sectionTitle")
    m.loadingOverlay = m.top.findNode("loadingOverlay")
    m.errorOverlay = m.top.findNode("errorOverlay")
    
    ' YouTube API Configuration
    m.apiKey = "AIzaSyDVKM9I7EAwJUO15eOrq_8a9sZ-94EG5aU"
    m.baseUrl = "https://www.googleapis.com/youtube/v3/search"
    
    ' Current state
    m.currentCategory = 0
    m.focusState = "category"  ' "category" or "video"
    
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

function fetchYouTubeVideos(searchQuery as String, categoryIndex as Integer)
    ' Build YouTube API URL
    url = m.baseUrl + "?"
    url = url + "part=snippet"
    url = url + "&type=video"
    url = url + "&maxResults=12"
    url = url + "&order=relevance"
    url = url + "&regionCode=PT"
    url = url + "&relevanceLanguage=pt"
    url = url + "&key=" + m.apiKey
    url = url + "&q=" + encodeUriComponent(searchQuery)
    
    ' Create HTTP request
    request = CreateObject("roUrlTransfer")
    request.SetUrl(url)
    request.SetRequest("GET")
    request.SetCertificatesFile("common:/certs/ca-bundle.crt")
    request.EnablePeerVerification(false)
    request.EnableHostVerification(false)
    
    ' Make request
    port = CreateObject("roMessagePort")
    request.SetPort(port)
    
    if request.AsyncGetToString() then
        ' Handle response in separate function
        m.pendingRequest = {
            port: port,
            request: request,
            categoryIndex: categoryIndex
        }
        
        ' Start response handler
        m.responseTimer = CreateObject("roTimespan")
        m.responseTimer.mark()
        checkResponse()
    else
        showError("Falha na conexão com YouTube")
    end if
end function

function checkResponse()
    if m.pendingRequest <> invalid then
        msg = m.pendingRequest.port.GetMessage()
        
        if msg <> invalid then
            if type(msg) = "roUrlEvent" then
                if msg.GetInt() = 1 then  ' Success
                    response = msg.GetString()
                    processYouTubeResponse(response, m.pendingRequest.categoryIndex)
                else  ' Error
                    showError("Erro ao carregar vídeos do YouTube")
                end if
                m.pendingRequest = invalid
            end if
        else
            ' Check for timeout (10 seconds)
            if m.responseTimer.TotalMilliseconds() > 10000 then
                showError("Tempo limite excedido")
                m.pendingRequest = invalid
            else
                ' Continue checking
                CreateObject("roTimespan").Sleep(100)
                checkResponse()
            end if
        end if
    end if
end function

function processYouTubeResponse(response as String, categoryIndex as Integer)
    try
        jsonResponse = ParseJSON(response)
        
        if jsonResponse <> invalid and jsonResponse.items <> invalid then
            ' Create video content
            videoContent = CreateObject("roSGNode", "ContentNode")
            
            for each item in jsonResponse.items
                if item.snippet <> invalid then
                    videoItem = CreateObject("roSGNode", "ContentNode")
                    
                    ' Basic info
                    videoItem.title = item.snippet.title
                    videoItem.description = item.snippet.description
                    
                    ' Thumbnail
                    if item.snippet.thumbnails <> invalid then
                        if item.snippet.thumbnails.high <> invalid then
                            videoItem.hdPosterUrl = item.snippet.thumbnails.high.url
                        else if item.snippet.thumbnails.medium <> invalid then
                            videoItem.hdPosterUrl = item.snippet.thumbnails.medium.url
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
                end if
            end for
            
            ' Update UI
            m.videoGrid.content = videoContent
            m.loadingOverlay.visible = false
            
            ' Set focus to video grid if we have content
            if videoContent.getChildCount() > 0 then
                m.focusState = "video"
                m.videoGrid.setFocus(true)
            end if
            
        else
            showError("Nenhum vídeo encontrado")
        end if
        
    catch error
        showError("Erro ao processar resposta")
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
    m.loadingOverlay.visible = false
    m.errorOverlay.visible = true
    m.top.findNode("errorText").text = message
    
    ' Auto-hide error after 5 seconds
    errorTimer = CreateObject("roTimespan")
    errorTimer.Sleep(5000)
    m.errorOverlay.visible = false
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
        end if
    end if
    
    return handled
end function
