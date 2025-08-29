function main()
    ' Cabo Verde Hub v1.0.2 - Post-Merge Conflict Resolution
    appStartTime = CreateObject("roTimespan").TotalMilliseconds()
    print "Starting Cabo Verde Hub v1.0.2..."
    
    ' Handle deep linking if present
    args = {}
    if GetGlobalAA().DoesExist("args") then
        args = GetGlobalAA().args
        print "Deep link args: " + FormatJSON(args)
    end if
    
    screen = CreateObject("roSGScreen")
    m.port = CreateObject("roMessagePort")
    screen.setMessagePort(m.port)
    
    ' Create and show main scene
    scene = screen.CreateScene("MainScene")
    
    ' Pass launch args to scene
    if args.Count() > 0 then
        scene.launchArgs = args
    end if
    
    screen.show()
    
    launchTime = CreateObject("roTimespan").TotalMilliseconds() - appStartTime
    print "App launched in: " + launchTime.ToStr() + "ms"
    
    ' Main event loop with memory monitoring
    memoryCheckTimer = CreateObject("roTimespan")
    memoryCheckTimer.Mark()
    
    while(true)
        msg = wait(0, m.port)
        msgType = type(msg)
        
        ' Monitor memory usage every 60 seconds
        if memoryCheckTimer.TotalMilliseconds() > 60000 then
            deviceInfo = CreateObject("roDeviceInfo")
            print "Memory usage: " + deviceInfo.GetGeneralMemoryLevel().ToStr()
            memoryCheckTimer.Mark()
        end if
        
        if msgType = "roSGScreenEvent" then
            if msg.isScreenClosed() then 
                print "App closing gracefully..."
                
                ' Cleanup
                if scene <> invalid then
                    scene = invalid
                end if
                
                return
            end if
        end if
    end while
end function
