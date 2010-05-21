module ActiveMerchant #:nodoc:
  module Billing #:nodoc:
    # Bogus Paypal Express Gateway
    class BogusPaypalExpressGateway < Gateway
      AUTHORIZATION = '53433'
      
      SUCCESS_MESSAGE = "Bogus Paypal Express Gateway: Forced success"
      FAILURE_MESSAGE = "Bogus Paypal Express Gateway: Forced failure"
      ERROR_MESSAGE   = "Bogus Paypal Express Gateway: Use options.response number 1 for success, 2 for exception and anything else for error"
      
      self.supported_countries = ['US']
      self.supported_cardtypes = [:bogus]
      
      self.homepage_url = 'http://example.com'
      self.display_name = 'Bogus'
      
      def authorize(money, options = {})
        case options.response
        when '1'
          Response.new(true, SUCCESS_MESSAGE, {:authorized_amount => money.to_s}, :test => true, :authorization => AUTHORIZATION )
        when '2'
          Response.new(false, FAILURE_MESSAGE, {:authorized_amount => money.to_s, :error => FAILURE_MESSAGE }, :test => true)
        else
          raise Error, ERROR_MESSAGE
        end      
      end
      
      def details_for(token)
        case token
        when '1'
          Response.new(true, SUCCESS_MESSAGE, {:authorized_amount => money.to_s}, :test => true, :authorization => AUTHORIZATION )
        when '2'
          Response.new(false, FAILURE_MESSAGE, {:authorized_amount => money.to_s, :error => FAILURE_MESSAGE }, :test => true)
        else
          raise Error, ERROR_MESSAGE
        end
      end
  
      def purchase(money, options = {})
        case options.response
        when '1'
          Response.new(true, SUCCESS_MESSAGE, {:paid_amount => money.to_s}, :test => true)
        when '2'
          Response.new(false, FAILURE_MESSAGE, {:paid_amount => money.to_s, :error => FAILURE_MESSAGE }, :test => true)
        else
          raise Error, ERROR_MESSAGE
        end
      end
      
      def setup_authorization(money, options = {})
        case options.response
        when '1'
          Response.new(true, SUCCESS_MESSAGE, {:paid_amount => money.to_s}, :test => true)
        when '2'
          Response.new(false, FAILURE_MESSAGE, {:paid_amount => money.to_s, :error => FAILURE_MESSAGE }, :test => true)
        else
          raise Error, ERROR_MESSAGE
        end
      end
      
      def setup_purchase(money, options = {})
        case options.response
        when '1'
          Response.new(true, SUCCESS_MESSAGE, {:paid_amount => money.to_s}, :test => true)
        when '2'
          Response.new(false, FAILURE_MESSAGE, {:paid_amount => money.to_s, :error => FAILURE_MESSAGE }, :test => true)
        else
          raise Error, ERROR_MESSAGE
        end
      end
    end
  end
end
