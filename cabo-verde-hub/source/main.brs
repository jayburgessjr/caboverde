function main()
    print "Starting Cabo Verde Hub..."
    
    screen = CreateObject("roSGScreen")
    m.port = CreateObject("roMessagePort")
    screen.setMessagePort(m.port)
    
    ' Create and show main scene
    scene = screen.CreateScene("MainScene")
    screen.show()
    
    ' Main event loop
    while(true)
        msg = wait(0, m.port)
        msgType = type(msg)
        
        if msgType = "roSGScreenEvent" then
            if msg.isScreenClosed() then 
                print "App closing..."
                return
            end if
        end if
    end while
end function
