function main()
    print "Starting Cabo Verde Hub..."
    
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
                return
            end if
        end if
    end while
end function
