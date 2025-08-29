function init()
    ' Enhanced Video Player with Security & Resume Features
    m.top.EnableCookies()
    m.top.setCertificatesFile("common:/certs/ca-bundle.crt")
    
    ' CRITICAL: Enable certificate verification for security
    m.top.EnablePeerVerification(true)
    m.top.EnableHostVerification(true)
    
    ' Enhanced buffering strategy
    m.top.bufferingStrategy = {
        initialBufferTarget: 2.0
        maxBufferTarget: 10.0
        rebufferTarget: 1.0
    }
    
    ' Resume functionality tracking
    m.resumePosition = 0
    m.lastPosition = 0
    m.videoStarted = false
    
    ' Set up observers
    m.top.observeField("state", "onVideoStateChange")
    m.top.observeField("position", "onVideoPositionChange")
    m.top.observeField("duration", "onVideoDurationChange")
end function

function onVideoStateChange()
    state = m.top.state
    
    if state = "playing" then
        if not m.videoStarted then
            m.videoStarted = true
            print "[Player] Video started: " + m.top.content.title
            
            ' Handle resume if available
            if m.resumePosition > 0 then
                m.top.seek = m.resumePosition
                print "[Player] Resuming from: " + m.resumePosition.ToStr()
            end if
        end if
        
    else if state = "error" then
        errorCode = m.top.errorCode
        errorMsg = m.top.errorMsg
        print "[Error] Video playback failed - Code: " + errorCode.ToStr() + ", Message: " + errorMsg
        
    else if state = "finished" then
        ' Clear resume position when completed
        clearResumePosition()
        print "[Player] Video completed"
        
    else if state = "paused" then
        saveResumePosition()
        print "[Player] Video paused at: " + m.top.position.ToStr()
        
    else if state = "buffering" then
        print "[Player] Buffering at position: " + m.top.position.ToStr()
        
    end if
end function

function onVideoPositionChange()
    position = m.top.position
    
    ' Save resume position every 30 seconds
    if position - m.lastPosition >= 30 then
        saveResumePosition()
        m.lastPosition = position
    end if
    
    ' Track progress for analytics
    duration = m.top.duration
    if duration > 0 then
        progressPercent = (position / duration) * 100
        ' Could implement milestone tracking here
    end if
end function

function onVideoDurationChange()
    duration = m.top.duration
    print "[Player] Video duration available: " + duration.ToStr() + "s"
    
    ' Load resume position if available
    loadResumePosition()
end function

function saveResumePosition()
    if m.top.content <> invalid and m.top.content.videoId <> invalid then
        sec = CreateObject("roRegistrySection", "CaboVerdeResume")
        sec.Write(m.top.content.videoId, m.top.position.ToStr())
        sec.Flush()
    end if
end function

function loadResumePosition()
    if m.top.content <> invalid and m.top.content.videoId <> invalid then
        sec = CreateObject("roRegistrySection", "CaboVerdeResume")
        positionStr = sec.Read(m.top.content.videoId)
        
        if positionStr <> "" and positionStr <> invalid then
            m.resumePosition = positionStr.ToFloat()
            print "[Player] Resume position loaded: " + m.resumePosition.ToStr()
        end if
    end if
end function

function clearResumePosition()
    if m.top.content <> invalid and m.top.content.videoId <> invalid then
        sec = CreateObject("roRegistrySection", "CaboVerdeResume")
        sec.Delete(m.top.content.videoId)
        sec.Flush()
    end if
end function
