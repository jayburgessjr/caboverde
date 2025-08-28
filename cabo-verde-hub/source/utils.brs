function encodeUriComponent(str as String) as String
    ' Simple URL encoding for search queries
    encoded = str
    encoded = encoded.Replace(" ", "%20")
    encoded = encoded.Replace(",", "%2C")
    encoded = encoded.Replace("&", "%26")
    encoded = encoded.Replace("ã", "%C3%A3")
    encoded = encoded.Replace("ç", "%C3%A7")
    encoded = encoded.Replace("é", "%C3%A9")
    encoded = encoded.Replace("í", "%C3%AD")
    encoded = encoded.Replace("ó", "%C3%B3")
    encoded = encoded.Replace("õ", "%C3%B5")
    return encoded
end function
