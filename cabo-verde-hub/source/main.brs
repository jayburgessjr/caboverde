function main()
    print "Starting Cabo Verde Hub v1.0.2..."
    
    ' Initialize secure configuration on app start
    config = initializeConfig()
    print "Configuration loaded successfully"
    
    screen = CreateObject("roSGScreen")
    m.port = CreateObject("roMessagePort")
    screen.setMessagePort(m.port)
    
    ' Create and show main scene
    scene = screen.CreateScene("MainScene")
    screen.show()
    
    print "Cabo Verde Hub scene created and displayed"
    
    ' Main event loop
    while(true)
        msg = wait(0, m.port)
        msgType = type(msg)
        
        if msgType = "roSGScreenEvent" then
            if msg.isScreenClosed() then 
                print "App closing..."
                ' Clean up resources
                if scene <> invalid then
                    scene = invalid
                end if
                return
            end if
        end if
    end while
end function
