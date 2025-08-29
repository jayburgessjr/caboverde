function init()
    ' 2024 Enhanced Video Player - Security & Performance Optimized
    
    ' Secure settings
    m.top.EnableCookies()
    m.top.setCertificatesFile("common:/certs/ca-bundle.crt")
    m.top.EnablePeerVerification(true)
    m.top.EnableHostVerification(true)
    
    ' Enhanced playback settings (2024 Features)
    m.top.bufferingStrategy = {
        initialBufferTarget: 2.0
        maxBufferTarget: 10.0
        rebufferTarget: 1.0
    }
    
    ' Caption support for accessibility
    m.top.globalCaptionMode = "On"
    m.top.availableAudioGuideLanguages = ["en", "pt"]
    
    ' Analytics tracking
    m.watchStartTime = 0
    m.totalWatchTime = 0
    m.videoStarted = false
    m.lastPosition = 0
    m.milestone25 = false
    m.milestone50 = false
    m.milestone75 = false
    
    ' Resume functionality
    m.resumePosition = 0
    
    ' Set up comprehensive observers
    m.top.observeField("state", "onVideoStateChange")
    m.top.observeField("position", "onVideoPositionChange")
    m.top.observeField("duration", "onVideoDurationChange")
    m.top.observeField("streamingSegment", "onStreamingSegmentChange")
end function

function onVideoStateChange()
    ' 2024 Enhanced State Management with Analytics
    state = m.top.state
    currentTime = CreateObject("roTimespan").TotalMilliseconds()
    
    if state = "playing" then
        if not m.videoStarted then
            m.videoStarted = true
            m.watchStartTime = currentTime
            print "[Analytics] Video playback started: " + m.top.content.title
            
            ' Track video start event
            trackVideoEvent("video_start", {
                videoId: m.top.content.videoId
                title: m.top.content.title
                position: m.top.position
            })
            
            ' Handle resume if available
            if m.resumePosition > 0 then
                m.top.seek = m.resumePosition
                print "[Player] Resuming from position: " + m.resumePosition.ToStr()
            end if
        end if
        
    else if state = "paused" then
        ' Save current position for resume
        saveResumePosition()
        print "[Analytics] Video paused at: " + m.top.position.ToStr()
        
    else if state = "stopped" or state = "finished" then
        ' Calculate total watch time
        if m.watchStartTime > 0 then
            m.totalWatchTime = currentTime - m.watchStartTime
        end if
        
        ' Track completion
        completionRate = 0
        if m.top.duration > 0 then
            completionRate = (m.top.position / m.top.duration) * 100
        end if
        
        print "[Analytics] Video ended - Watch time: " + m.totalWatchTime.ToStr() + "ms, Completion: " + completionRate.ToStr() + "%"
        
        trackVideoEvent("video_end", {
            videoId: m.top.content.videoId
            watchTime: m.totalWatchTime
            completionRate: completionRate
            endReason: state
        })
        
        ' Clear resume position if completed > 90%
        if completionRate > 90 then
            clearResumePosition()
        end if
        
    else if state = "error" then
        errorCode = m.top.errorCode
        errorMsg = m.top.errorMsg
        
        print "[Error] Video playback failed - Code: " + errorCode.ToStr() + ", Message: " + errorMsg
        
        trackVideoEvent("video_error", {
            videoId: m.top.content.videoId
            errorCode: errorCode
            errorMessage: errorMsg
            position: m.top.position
        })
        
    else if state = "buffering" then
        print "[Player] Buffering at position: " + m.top.position.ToStr()
        
    end if
end function

function onVideoPositionChange()
    ' 2024 Enhanced Position Tracking with Resume Support
    position = m.top.position
    duration = m.top.duration
    
    if duration > 0 then
        progressPercent = (position / duration) * 100
        
        ' Save resume position every 30 seconds
        if position - m.lastPosition >= 30 then
            saveResumePosition()
            m.lastPosition = position
        end if
        
        ' Track progress milestones
        if progressPercent >= 25 and not m.milestone25 then
            m.milestone25 = true
            trackVideoEvent("video_progress", {videoId: m.top.content.videoId, milestone: 25})
        else if progressPercent >= 50 and not m.milestone50 then
            m.milestone50 = true
            trackVideoEvent("video_progress", {videoId: m.top.content.videoId, milestone: 50})
        else if progressPercent >= 75 and not m.milestone75 then
            m.milestone75 = true
            trackVideoEvent("video_progress", {videoId: m.top.content.videoId, milestone: 75})
        end if
    end if
end function

function onVideoDurationChange()
    ' Handle duration availability
    duration = m.top.duration
    print "[Player] Video duration available: " + duration.ToStr() + "s"
    
    ' Load resume position if available
    loadResumePosition()
end function

function onStreamingSegmentChange()
    ' Monitor streaming quality for analytics
    segment = m.top.streamingSegment
    if segment <> invalid then
        print "[Streaming] Segment info - Bitrate: " + segment.segmentBitrate.ToStr() + ", Sequence: " + segment.segmentSequence.ToStr()
    end if
end function

function saveResumePosition()
    ' Save current position to registry for resume functionality
    if m.top.content <> invalid and m.top.content.videoId <> invalid then
        sec = CreateObject("roRegistrySection", "CaboVerdeHubResume")
        sec.Write(m.top.content.videoId, m.top.position.ToStr())
        sec.Flush()
    end if
end function

function loadResumePosition()
    ' Load saved position from registry
    if m.top.content <> invalid and m.top.content.videoId <> invalid then
        sec = CreateObject("roRegistrySection", "CaboVerdeHubResume")
        positionStr = sec.Read(m.top.content.videoId)
        
        if positionStr <> "" and positionStr <> invalid then
            m.resumePosition = positionStr.ToFloat()
            print "[Player] Resume position loaded: " + m.resumePosition.ToStr()
        end if
    end if
end function

function clearResumePosition()
    ' Clear resume position when video is completed
    if m.top.content <> invalid and m.top.content.videoId <> invalid then
        sec = CreateObject("roRegistrySection", "CaboVerdeHubResume")
        sec.Delete(m.top.content.videoId)
        sec.Flush()
    end if
end function

function trackVideoEvent(eventType as String, eventData as Object)
    ' Track video analytics events
    print "[Analytics] " + eventType + ": " + FormatJSON(eventData)
    
    ' Here you would send to your analytics service
    ' For now, just log to console for development
end function
