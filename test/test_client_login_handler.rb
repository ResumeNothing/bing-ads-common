#!/usr/bin/env ruby
# Encoding: utf-8
#
# Author:: api.dklimkin@gmail.com (Danial Klimkin)
#
# Copyright:: Copyright 2012, Google Inc. All Rights Reserved.
#
# License:: Licensed under the Apache License, Version 2.0 (the "License");
#           you may not use this file except in compliance with the License.
#           You may obtain a copy of the License at
#
#           http://www.apache.org/licenses/LICENSE-2.0
#
#           Unless required by applicable law or agreed to in writing, software
#           distributed under the License is distributed on an "AS IS" BASIS,
#           WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
#           implied.
#           See the License for the specific language governing permissions and
#           limitations under the License.
#
# Tests client login handler methods.

require 'test/unit'

require 'ads_common_bing/config'
require 'ads_common_bing/auth/client_login_handler'

module AdsCommonBing
  module Auth
    class ClientLoginHandler

      public :parse_token_text
      public :handle_login_error
      public :validate_credentials
      public :create_token_from_string
    end
  end
end


# Stub class for HTTP response.
class ResponseStub

  attr_reader :code
  attr_reader :body

  def initialize(code, body)
    @code, @body = code, body
  end
end

class TestClientLoginHandler < Test::Unit::TestCase

  def setup()
    config = AdsCommonBing::Config.new({})
    @handler = AdsCommonBing::Auth::ClientLoginHandler.new(
        config, 'http://www.google.com', 'adwords')
  end

  def test_handle_login_error_captcha()
    assert_raises (AdsCommonBing::Errors::CaptchaRequiredError) do
      response = ResponseStub.new(403, '')
      results = {
          'Error' => 'CaptchaRequired',
          'CaptchaUrl' => '/account/test-captcha'
      }
      @handler.handle_login_error({}, response, results)
    end
  end

  def test_handle_login_error_other()
    assert_raises(AdsCommonBing::Errors::AuthError) do
      response = ResponseStub.new(403, 'Body')
      results = {'Error' => 'SomeError', 'Info' => 'SomeInfo'}
      @handler.handle_login_error({}, response, results)
    end
  end

  def test_parse_token_text_simple()
    error_str = "BadAuthentication"
    text = "Error=%s\n" % error_str
    result = @handler.parse_token_text(text)
    assert_equal(error_str, result['Error'])
    assert_equal(['Error'], result.keys)
  end

  def test_parse_token_text_captcha()
    captcha_token = "3u6_27iOel71j525g2tg252ge6t35g345XJtRuHYEYiTyAxsMPz2222442"
    captcha_url = "Captcha?ctoken=3u245245rgfwrg5g2fw5x3xGqQBrk_AoXXJtRuHY%3a-V"
    error_str = "CaptchaRequired"
    url_str = "https://www.google.com/accounts/ErrorMsg?Email=example%40goog" +
        "le.com&service=adwords&id=cr&timeStmp=1327400499&secTok=.AG5fkgtw45" +
        "25gfref25gttrefwwrPeB8Xw%3D%3D"
    text = "CaptchaToken=%s\nCaptchaUrl=%s\nError=%s\nUrl=%s\n" %
        [captcha_token, captcha_url, error_str, url_str]
    result = @handler.parse_token_text(text)
    assert_equal(captcha_token, result['CaptchaToken'])
    assert_equal(captcha_url, result['CaptchaUrl'])
    assert_equal(error_str, result['Error'])
    assert_equal(url_str, result['Url'])
    assert_equal(['CaptchaToken', 'CaptchaUrl', 'Error', 'Url'],
        result.keys.sort)
  end

  def test_validate_credentials_valid()
    credentials1 = {:email => 'email@example.com', :password => 'qwerty'}
    credentials2 = {:auth_token => 'QazSWXEDEDCE434234'}
    assert_nothing_raised do
      @handler.validate_credentials(credentials1)
    end
    assert_nothing_raised do
      @handler.validate_credentials(credentials2)
    end
  end

  def test_validate_credentials_invalid()
    credentials1 = {:email => 'email@example.com'}
    credentials2 = {:password => 'qwerty'}
    assert_raises(AdsCommonBing::Errors::AuthError) do
      @handler.validate_credentials(credentials1)
    end
    assert_raises(AdsCommonBing::Errors::AuthError) do
      @handler.validate_credentials(credentials2)
    end
  end

  def test_create_token_from_string()
    test_text = 'fooBar'
    assert_equal(test_text, @handler.create_token_from_string(test_text))
  end
end
