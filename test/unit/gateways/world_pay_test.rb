require File.dirname(__FILE__) + '/../../test_helper'

class WorldPayTest < Test::Unit::TestCase
  def setup
    @gateway = WorldPayGateway.new fixtures(:world_pay)

    @credit_card = credit_card
    @amount = 100
    
    @options = { 
      :order_id => '1',
      :billing_address => address,
      :description => 'Store Purchase'
    }
  end
  
  def test_successful_purchase
    @gateway.expects(:ssl_post).returns(successful_purchase_response)
    
    assert response = @gateway.purchase(@amount, @credit_card, @options)
    assert_instance_of Response, response 
    assert response.success?
    
    # Replace with authorization number from the successful response
    # assert_equal '', response.authorization
    assert response.test?
  end

  def test_unsuccessful_request
    @gateway.expects(:ssl_post).returns(failed_purchase_response)
    
    assert response = @gateway.purchase(@amount, @credit_card, @options)
    assert !response.success?
    assert response.test?
  end
  
  def test_supports_3d_secure
    assert @gateway.supports_3d_secure
  end
  
  def test_response_requires_three_d_secure_authentication
    @gateway.stubs(:ssl_post).returns(three_d_secure_response)
    
    response = @gateway.purchase(100, @credit_card, @options)
    assert !response.success?
    assert response.three_d_secure?
    
    assert_equal 'eJxVUtuOgjAQ/RXi865tEcGYsUZXoyTrJQofUGGiJFKwwK7+/bYIss7TnHOmcy1M7+nV+kFVJJmc9Fif9qwph+CiEBdHjCqFHDZYFOKMVhLriAG1R649cFyPeT0O+9kBbxyaDFwn6NtAWqifqugiZMlBRLe5v+WsMyANBykqf/FfMvbZxT11yEVR/GYq5kzXH7reCMiLAilS5EEY7A7rcG7ttt/+dmnV2N+ugNQyRFklS/XgI9sF0gKo1JVfyjIfE3JCIU/ifEWhZCLP/ShLgRgdSDfKvjJeofPdk5hvguVwE4SPzSJks3ebADEREIsSuU0Zow4bWoyOmT02HdQ8iNQ0wlfzvcU+KNVreRKQmzqzJ2BG+E+Avo1CGbXDtAjwnmcSdYS+w8uHGIuIH8tMoZU37ev6hgTSzfO1NoeKSr1txxk51KMvM9eqBVMg0WtjNnXrCgYAMU9J8xtI82O09/aT/gDjv8V7',
    response.pa_req
    assert_equal '-80629129826908893',
    response.md
    assert_equal 'https://secure-test.wp3.rbsworldpay.com/jsp/test/shopper/VbV_TestIssuer.jsp',
    response.acs_url
  end
  
  def test_three_d_complete
    @gateway.expects(:ssl_post).with(anything, anything, has_entries('Cookie' => 'machine=12345')).returns(successful_purchase_response)
    @options[:money]        = 100
    @options[:credit_card]  = @credit_card
    @options[:cookie]       = 'machine=12345'
    response = @gateway.three_d_complete('paRes', 'md', @options)
    assert response.success?
  end

  private
  
  def successful_purchase_response
    <<-XML
      <?xml version="1.0" encoding="UTF-8"?>
      <!DOCTYPE paymentService PUBLIC "-//Bibit//DTD Bibit PaymentService v1//EN" "http://dtd.bibit.com/paymentService_v1.dtd">
      <paymentService version="1.4" merchantCode="SOMETHING">
        <reply>
          <orderStatus orderCode="0ababec02f255964b4fbe761cfc5823c">
            <payment>
              <paymentMethod>AMEX-SSL</paymentMethod>
              <amount value="100" currencyCode="GBP" exponent="2" debitCreditIndicator="credit"/>
              <lastEvent>AUTHORISED</lastEvent>
              <CVCResultCode description="UNKNOWN"/>
              <AVSResultCode description="UNKNOWN"/>
              <balance accountType="IN_PROCESS_AUTHORISED">
                <amount value="100" currencyCode="GBP" exponent="2" debitCreditIndicator="credit"/>
              </balance>
              <cardNumber>3700*******0000</cardNumber>
            </payment>
          </orderStatus>
        </reply>
      </paymentService>
    XML
  end
  
  def failed_purchase_response
    <<-XML
      <?xml version="1.0" encoding="UTF-8"?>
      <!DOCTYPE paymentService PUBLIC "-//Bibit//DTD Bibit PaymentService v1//EN" "http://dtd.bibit.com/paymentService_v1.dtd">
      <paymentService version="1.4" merchantCode="SOMETHING">
        <reply>
          <orderStatus orderCode="0e4098691e838ed8c1e76b61ff4bc477">
            <payment>
              <paymentMethod>AMEX-SSL</paymentMethod>
              <amount value="100" currencyCode="GBP" exponent="2" debitCreditIndicator="credit"/>
              <lastEvent>REFUSED</lastEvent>
              <ISO8583ReturnCode code="5" description="REFUSED"/>
              <CVCResultCode description="UNKNOWN"/>
              <AVSResultCode description="UNKNOWN"/>
            </payment>
          </orderStatus>
        </reply>
      </paymentService>
    XML
  end
  
  def three_d_secure_response
    <<-XML
      <!DOCTYPE paymentService PUBLIC "-//Bibit//DTD Bibit PaymentService v1//EN" "http://dtd.bibit.com/paymentService_v1.dtd">
      <paymentService version="1.4" merchantCode="SOMETHING">
        <reply>
          <orderStatus orderCode="446a0cda5738cf912eee7abb73808456">
            <requestInfo>
              <request3DSecure>
                <paRequest>eJxVUtuOgjAQ/RXi865tEcGYsUZXoyTrJQofUGGiJFKwwK7+/bYIss7TnHOmcy1M7+nV+kFVJJmc9Fif9qwph+CiEBdHjCqFHDZYFOKMVhLriAG1R649cFyPeT0O+9kBbxyaDFwn6NtAWqifqugiZMlBRLe5v+WsMyANBykqf/FfMvbZxT11yEVR/GYq5kzXH7reCMiLAilS5EEY7A7rcG7ttt/+dmnV2N+ugNQyRFklS/XgI9sF0gKo1JVfyjIfE3JCIU/ifEWhZCLP/ShLgRgdSDfKvjJeofPdk5hvguVwE4SPzSJks3ebADEREIsSuU0Zow4bWoyOmT02HdQ8iNQ0wlfzvcU+KNVreRKQmzqzJ2BG+E+Avo1CGbXDtAjwnmcSdYS+w8uHGIuIH8tMoZU37ev6hgTSzfO1NoeKSr1txxk51KMvM9eqBVMg0WtjNnXrCgYAMU9J8xtI82O09/aT/gDjv8V7</paRequest>
                <issuerURL><![CDATA[https://secure-test.wp3.rbsworldpay.com/jsp/test/shopper/VbV_TestIssuer.jsp]]></issuerURL>
              </request3DSecure>
            </requestInfo>
            <echoData>-80629129826908893</echoData>
          </orderStatus>
        </reply>
      </paymentService>
    XML
  end
end
