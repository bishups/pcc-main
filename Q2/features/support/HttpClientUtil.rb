class HttpClientUtil

  #sample code to make get/post requests

  #httpClient = HttpClientUtil.createAuthenticatedClient($hciUser, $hciPswd)

  #dataPath =  HttpClientUtil.getFullUrl('/itspaces/api/1.0/user')
  #response = httpClient.get(dataPath)
  #puts response.body
  #authenticates to ljs using given user and password and returns HTTPClient object which has the session cookies set
  def HttpClientUtil.createAuthenticatedClient(user, password, options = {})
    proxy = nil
      if Capybara.app_host.index("https://") == 0
        proxy = "http://proxy:8080"
      end
      
    
    context = options[:context] || "itspaces";
    loginPath = '/'+context+'/j_security_check';
    require 'httpclient'
    
    if(proxy)
      httpClient = HTTPClient.new(proxy)
    else
      httpClient = HTTPClient.new
    end

    uri =  getFullUrl(loginPath)
    loginResponse = httpClient.post(uri, {"j_username" => user, "j_password" => password });
    return httpClient
  end

  #gets the full url by combining capybara.app_host and relativePath
  def HttpClientUtil.getFullUrl(relativePath)
    return URI.join(Capybara.app_host, relativePath)
  end

end