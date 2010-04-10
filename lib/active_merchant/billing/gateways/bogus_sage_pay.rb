module ActiveMerchant #:nodoc:
  module Billing #:nodoc:
    # Bogus Gateway
    class BogusSagePayGateway < Gateway
      AUTHORIZATION = '53433'
      
      SUCCESSFUL_CARD_NUMBER      = '1111111111111111'
      EXCEPTION_CARD_NUMBER       = '2222222222222222'
      THREE_D_SECURE_CARD_NUMBER  = '4444444444444444'
      
      SUCCESS_MESSAGE = "Bogus Gateway: Forced success"
      FAILURE_MESSAGE = "Bogus Gateway: Forced failure"
      ERROR_MESSAGE = "Bogus Gateway: Use CreditCard number #{SUCCESSFUL_CARD_NUMBER} for success, #{EXCEPTION_CARD_NUMBER} for exception, #{THREE_D_SECURE_CARD_NUMBER} for 3D secure and anything else for error"
      CREDIT_ERROR_MESSAGE = "Bogus Gateway: Use trans_id 1 for success, 2 for exception and anything else for error"
      UNSTORE_ERROR_MESSAGE = "Bogus Gateway: Use trans_id 1 for success, 2 for exception and anything else for error"
      CAPTURE_ERROR_MESSAGE = "Bogus Gateway: Use authorization number 1 for exception, 2 for error and anything else for success"
      VOID_ERROR_MESSAGE = "Bogus Gateway: Use authorization number 1 for exception, 2 for error and anything else for success"
      
      THREE_D_SECURE_MESSAGE = "Bogus Gateway: Requires additional 3D secure authentication"
      
      THREE_D_MD = 'md'
      THREE_D_PA_REQ = 'pa_req'
      THREE_D_PA_RES = 'pa_res'
      THREE_D_ACS_URL = 'https://domain.com/3d_secure_page'
      
      SUCCESS_RESPONSE_PARAMS = { "SecurityKey"     => "6ECLRDRPUZ",
                                  "VPSTxId"         => "{7BE883EC-ACDF-C42E-A040-8F1B38E07177}",
                                  "StatusDetail"    => "0000 : The Authorisation was Successful.",
                                  "TxAuthNo"        => "5222192" }
      
      self.supported_countries = ['US']
      self.supported_cardtypes = [:bogus]
      self.supports_3d_secure = true
      
      self.homepage_url = 'http://example.com'
      self.display_name = 'Bogus'
      
      def authorize(money, creditcard, options = {})
        case creditcard.number
        when SUCCESSFUL_CARD_NUMBER
          Response.new(true, SUCCESS_MESSAGE, {:authorized_amount => money.to_s}, :test => true, :authorization => AUTHORIZATION )
        when EXCEPTION_CARD_NUMBER
          Response.new(false, FAILURE_MESSAGE, {:authorized_amount => money.to_s, :error => FAILURE_MESSAGE }, :test => true)
        when THREE_D_SECURE_CARD_NUMBER
          Response.new(false, THREE_D_SECURE_MESSAGE, {:authorized_amount => money.to_s}, :three_d_secure => true, :pa_req => THREE_D_PA_REQ, :md => THREE_D_MD, :acs_url => THREE_D_ACS_URL, :test => true)
        else
          raise Error, ERROR_MESSAGE
        end      
      end
  
      def purchase(money, creditcard, options = {})
        case creditcard.number
        when SUCCESSFUL_CARD_NUMBER
          Response.new(true, SUCCESS_MESSAGE, SUCCESS_RESPONSE_PARAMS, :test => true)
        when EXCEPTION_CARD_NUMBER
          Response.new(false, FAILURE_MESSAGE, {:paid_amount => money.to_s, :error => FAILURE_MESSAGE },:test => true)
        when THREE_D_SECURE_CARD_NUMBER
          Response.new(false, THREE_D_SECURE_MESSAGE, {:paid_amount => money.to_s}, :three_d_secure => true, :pa_req => THREE_D_PA_REQ, :md => THREE_D_MD, :acs_url => THREE_D_ACS_URL, :test => true)
        else
          raise Error, ERROR_MESSAGE
        end
      end
 
      def three_d_complete(pa_res, md)
        if pa_res == THREE_D_PA_RES && md == THREE_D_MD
          Response.new(true, SUCCESS_MESSAGE, SUCCESS_RESPONSE_PARAMS, :test => true, :authorization => AUTHORIZATION)
        else
          Response.new(false, FAILURE_MESSAGE, {},:test => true)
        end
      end
  
      def credit(money, ident, options = {})
        case ident
        when '1'
          raise Error, CREDIT_ERROR_MESSAGE
        when '2'
          Response.new(false, FAILURE_MESSAGE, {:paid_amount => money.to_s, :error => FAILURE_MESSAGE }, :test => true)
        else
          Response.new(true, SUCCESS_MESSAGE, {:paid_amount => money.to_s}, :test => true)
        end
      end
 
      def capture(money, ident, options = {})
        case ident
        when '1'
          raise Error, CAPTURE_ERROR_MESSAGE
        when '2'
          Response.new(false, FAILURE_MESSAGE, {:paid_amount => money.to_s, :error => FAILURE_MESSAGE }, :test => true)
        else
          Response.new(true, SUCCESS_MESSAGE, {:paid_amount => money.to_s}, :test => true)
        end
      end

      def void(ident, options = {})
        case ident
        when '1'
          raise Error, VOID_ERROR_MESSAGE
        when '2'
          Response.new(false, FAILURE_MESSAGE, {:authorization => ident, :error => FAILURE_MESSAGE }, :test => true)
        else
          Response.new(true, SUCCESS_MESSAGE, {:authorization => ident}, :test => true)
        end
      end
      
      def store(creditcard, options = {})
        case creditcard.number
        when SUCCESSFUL_CARD_NUMBER
          Response.new(true, SUCCESS_MESSAGE, {:billingid => '1'}, :test => true, :authorization => AUTHORIZATION )
        when EXCEPTION_CARD_NUMBER
          Response.new(false, FAILURE_MESSAGE, {:billingid => nil, :error => FAILURE_MESSAGE }, :test => true)
        else
          raise Error, ERROR_MESSAGE
        end              
      end
      
      def unstore(identification, options = {})
        case identification
        when '1'
          Response.new(true, SUCCESS_MESSAGE, {}, :test => true)
        when '2'
          Response.new(false, FAILURE_MESSAGE, {:error => FAILURE_MESSAGE },:test => true)
        else
          raise Error, UNSTORE_ERROR_MESSAGE
        end
      end
    end
  end
end
