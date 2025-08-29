function init()
    m.top.EnableCookies()
    m.top.setCertificatesFile("common:/certs/ca-bundle.crt")
    m.top.EnablePeerVerification(false)
    m.top.EnableHostVerification(false)
end function
