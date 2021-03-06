require File.dirname(__FILE__) + '/paypal/paypal_express_response'
require File.dirname(__FILE__) + '/paypal_express_common'

module ActiveMerchant #:nodoc:
  module Billing #:nodoc:
    # Bogus Paypal Express Gateway
    class BogusPaypalExpressGateway < Gateway
      include PaypalExpressCommon
      
      AUTHORIZATION = '53433'
      
      SUCCESS_MESSAGE = "Bogus Paypal Express Gateway: Forced success"
      FAILURE_MESSAGE = "Bogus Paypal Express Gateway: Forced failure"
      ERROR_MESSAGE   = "Bogus Paypal Express Gateway: Use options.ip 1.1.1.1 for success, 2.2.2.2 for exception and anything else for error"
      
      self.supported_countries = ['US']
      self.supported_cardtypes = [:bogus]
      
      self.homepage_url = 'http://example.com'
      self.display_name = 'Bogus'
      
      def authorize(money, options = {})
        case options[:ip]
        when '1.1.1.1'
          PaypalExpressResponse.new(true, SUCCESS_MESSAGE, {:authorized_amount => money.to_s}, :test => true, :authorization => AUTHORIZATION )
        when '2.2.2.2'
          PaypalExpressResponse.new(false, FAILURE_MESSAGE, {:authorized_amount => money.to_s, :error => FAILURE_MESSAGE }, :test => true)
        else
          raise Error, ERROR_MESSAGE
        end      
      end
      
      def details_for(token)
        case token
        when '1'
          PaypalExpressResponse.new(true, SUCCESS_MESSAGE, {}, :test => true, :authorization => AUTHORIZATION )
        when '2'
          PaypalExpressResponse.new(false, FAILURE_MESSAGE, {:error => FAILURE_MESSAGE }, :test => true)
        else
          raise Error, ERROR_MESSAGE
        end
      end
  
      def purchase(money, options = {})
        case options[:ip]
        when '1.1.1.1'
          PaypalExpressResponse.new(true, SUCCESS_MESSAGE, {:paid_amount => money.to_s}, :test => true)
        when '2.2.2.2'
          PaypalExpressResponse.new(false, FAILURE_MESSAGE, {:paid_amount => money.to_s, :error => FAILURE_MESSAGE }, :test => true)
        else
          raise Error, ERROR_MESSAGE
        end
      end
      
      def setup_authorization(money, options = {})
        case options[:ip]
        when '1.1.1.1'
          PaypalExpressResponse.new(true, SUCCESS_MESSAGE, {:paid_amount => money.to_s}, :test => true)
        when '2.2.2.2'
          PaypalExpressResponse.new(false, FAILURE_MESSAGE, {:paid_amount => money.to_s, :error => FAILURE_MESSAGE }, :test => true)
        else
          raise Error, ERROR_MESSAGE
        end
      end
      
      def setup_purchase(money, options = {})
        case options[:ip]
        when '1.1.1.1'
          PaypalExpressResponse.new(true, SUCCESS_MESSAGE, {:paid_amount => money.to_s, :token => '1'}, :test => true)
        when '2.2.2.2'
          PaypalExpressResponse.new(false, FAILURE_MESSAGE, {:paid_amount => money.to_s, :error => FAILURE_MESSAGE }, :test => true)
        when '3.3.3.3' # return a success but set the token value to a failure
          PaypalExpressResponse.new(true, SUCCESS_MESSAGE, {:paid_amount => money.to_s, :token => '2'}, :test => true)
        else
          raise Error, ERROR_MESSAGE
        end
      end
    end
  end
end
