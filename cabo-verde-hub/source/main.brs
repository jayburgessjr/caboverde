function main()
    ' 2024 Enhanced Main Function with Analytics & Deep Linking
    appStartTime = CreateObject("roTimespan").TotalMilliseconds()
    print "Starting Cabo Verde Hub v1.0.2..."
    
    ' Initialize analytics system
    m.analytics = initAnalytics()
    
    ' Initialize secure configuration
    config = initializeConfig()
    print "Configuration loaded successfully"
    
    ' Handle deep linking parameters
    deepLinkArgs = {}
    if GetGlobalAA().DoesExist("args") then
        deepLinkArgs = GetGlobalAA().args
        print "Deep link parameters received: " + FormatJSON(deepLinkArgs)
        trackUserInteraction("deep_link_launch", "app", deepLinkArgs, m.analytics)
    end if
    
    screen = CreateObject("roSGScreen")
    m.port = CreateObject("roMessagePort")
    screen.setMessagePort(m.port)
    
    ' Create and show main scene
    scene = screen.CreateScene("MainScene")
    
    ' Pass analytics and deep link args to scene
    scene.analytics = m.analytics
    if deepLinkArgs.Count() > 0 then
        scene.deepLinkArgs = deepLinkArgs
    end if
    
    screen.show()
    
    ' Track app launch performance
    trackAppLaunchTime(appStartTime, m.analytics)
    print "Cabo Verde Hub scene created and displayed"
    
    ' Track memory usage periodically
    memoryTimer = CreateObject("roTimespan")
    memoryTimer.Mark()
    
    ' Main event loop
    while(true)
        msg = wait(0, m.port)
        msgType = type(msg)
        
        ' Check memory usage every 60 seconds
        if memoryTimer.TotalMilliseconds() > 60000 then
            trackMemoryUsage(m.analytics)
            memoryTimer.Mark()
        end if
        
        if msgType = "roSGScreenEvent" then
            if msg.isScreenClosed() then 
                print "App closing..."
                
                ' Track session end
                sessionDuration = CreateObject("roTimespan").TotalMilliseconds() - m.analytics.sessionStartTime
                trackEvent("session_end", {
                    duration: sessionDuration
                    reason: "user_exit"
                }, m.analytics)
                
                ' Final flush before exit
                flushAnalytics(m.analytics)
                
                ' Clean up resources
                if scene <> invalid then
                    scene = invalid
                end if
                
                return
            end if
        end if
    end while
end function
