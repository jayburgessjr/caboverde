function init()
    ' Enhanced Video Player with Security & Analytics
    m.top.EnableCookies()
    m.top.setCertificatesFile("common:/certs/ca-bundle.crt")
    
    ' CRITICAL: Enable certificate verification for security
    m.top.EnablePeerVerification(true)
    m.top.EnableHostVerification(true)
    
    ' Enhanced features
    m.top.observeField("state", "onVideoStateChange")
    m.top.observeField("position", "onVideoPositionChange")
    
    ' Resume functionality tracking
    m.resumePosition = 0
    m.lastPosition = 0
end function

function onVideoStateChange()
    state = m.top.state
    
    if state = "playing" then
        print "[Player] Video started: " + m.top.content.title
        ' Handle resume if available
        if m.resumePosition > 0 then
            m.top.seek = m.resumePosition
            print "[Player] Resuming from: " + m.resumePosition.ToStr()
        end if
        
    else if state = "error" then
        print "[Error] Video playback failed: " + m.top.errorMsg
        
    else if state = "finished" then
        ' Clear resume position when completed
        clearResumePosition()
        print "[Player] Video completed"
        
    else if state = "paused" then
        saveResumePosition()
    end if
end function

function onVideoPositionChange()
    position = m.top.position
    ' Save resume position every 30 seconds
    if position - m.lastPosition >= 30 then
        saveResumePosition()
        m.lastPosition = position
    end if
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
