module ActiveMerchant #:nodoc:
  module Billing #:nodoc:
    class WorldPayGateway < Gateway  
      
      TEST_URL = 'https://secure-test.wp3.rbsworldpay.com/jsp/merchant/xml/paymentService.jsp'
      LIVE_URL = 'https://secure.wp3.rbsworldpay.com/jsp/merchant/xml/paymentService.jsp'
      
      CREDIT_CARDS = {
        :visa             => "VISA-SSL",
        :master           => "ECMC-SSL",
        :solo             => "SOLO_GB-SSL",
        :maestro          => "MAESTRO-SSL",
        :american_express => "AMEX-SSL",
        :diners_club      => "DINERS-SSL",
        :jcb              => "JCB-SSL"
      }
    
      self.supported_cardtypes  = [:visa, :master, :maestro, :solo, :american_express, :jcb, :diners_club]
      self.supported_countries  = ['GB']
      self.default_currency     = 'GBP'
      # self.supports_3d_secure   = true
      self.homepage_url         = 'http://www.worldpay.com'
      self.display_name         = 'WorldPay'
      self.supports_3d_secure   = true

      def initialize(options = {})
        requires!(options, :login, :password, :installation_id)
        @options = options
        super
      end
      
      def test?
        @options[:test] || super
      end
      
      def purchase(money, credit_card, options = {})
        requires!(options, :order_id)
        options[:card_type] = map_card_type(credit_card)
        commit(:purchase, build_purchase_request(money, credit_card, options))
      end
      
      # Completes a 3D Secure transaction
      # def three_d_complete(money, credit_card, options = {})
      def three_d_complete(pa_res, md, options={})
        requires!(options, :order_id, :money, :credit_card, :cookie)
        options[:card_type] = map_card_type(options[:credit_card])
        options[:pa_res]    = pa_res
        options[:md]        = md
        commit(:three_d_complete, build_purchase_request(options[:money], options[:credit_card], options), options)
      end
      
      private
      def map_card_type(credit_card)
        raise ArgumentError, "The credit card type must be provided" if card_brand(credit_card).blank?
        
        card_type = card_brand(credit_card).to_sym
        CREDIT_CARDS[card_type]
      end
      
      def commit(action, request, options={})
        url = test? ? TEST_URL : LIVE_URL
        
        headers = { 'Content-Type'  => 'text/xml',
	                  'Authorization' => encoded_credentials }
	      
        # add the cookie header if it's been passed in
	      headers['Cookie'] = options[:cookie] if options.has_key? :cookie
        
        begin
          response = parse( ssl_post(url, request, headers) )
        rescue ActiveMerchant::ResponseError => e
          response = {
            :status => "ERROR",
            :message => e.message
          }
        end
        
        Response.new(response[:status] == "AUTHORISED", response[:message], response,
          :test           => test?,
          :three_d_secure => response[:status] == '3DAUTH',
          :pa_req         => response[:pa_req],
          :md             => response[:md],
          :acs_url        => response[:acs_url]
        )
      end
      
      def encoded_credentials
        credentials = [@options[:login], @options[:password]].join(':')
        "Basic " << Base64.encode64(credentials).strip
      end
      
      # Read the XML message from the gateway and check if it was successful,
			# and also extract required return values from the response.
      def parse(xml)
        basepath    = "/paymentService/reply"
        orderpath   = "#{basepath}/orderStatus"
        errorpath   = "#{basepath}/error"
        paymentpath = "#{orderpath}/payment"
        threedpath  = "#{orderpath}/requestInfo"
        
        response = {}
        
        parse_session_cookie(xml, response)

        xml = REXML::Document.new(xml)
        
        # first check for an error
        if root = REXML::XPath.first(xml, errorpath)
          parse_error(response, root)
        
        # next check for a 3d secure response
        elsif REXML::XPath.first(xml, threedpath)
          root = REXML::XPath.first(xml, orderpath)
          parse_three_d_response(response, root)
          
        # next check for a normal response
        elsif root = REXML::XPath.first(xml, orderpath)
          parse_response(response, root)
          
        else
          response[:message] = "No valid XML response message received. \
                                Propably wrong credentials supplied with HTTP header."
        end

        response
      end
      
      def parse_session_cookie(obj, response)
        if obj.respond_to? :each_header
          obj.each_header do |k,v|
            if k =~ /set-cookie/i
              cookie = v.split(';')[0]
              response[:cookie] = cookie
            end
          end
        end
      end
      
      # Parse the <payment> Element which containts all important information
      def parse_response(response, root)
        # check for an order error
        if node = REXML::XPath.first(root, "error")
          parse_error(response, node)
          
        # parse a normal response
        elsif node = REXML::XPath.first(root, "payment")
          response[:status] = REXML::XPath.first(node, "lastEvent").text
          if node = REXML::XPath.first(node, "ISO8583ReturnCode")
            response[:message] = node.attributes['description']
          else
            response[:message] = response[:status]
          end
        end
      end
      
      def parse_three_d_response(response, root)
        if node = REXML::XPath.first(root, "requestInfo/request3DSecure")
          response[:status] = "3DAUTH"
          if ed = REXML::XPath.first(root, "echoData")
            response[:md]  = ed.text
          end
          if pa = REXML::XPath.first(node, "paRequest")
            response[:pa_req] = pa.text
          end
          if url = REXML::XPath.first(node, "issuerURL")
            response[:acs_url] = url.text
          end
        else
          response[:status]   = "ERROR"
          response[:message]  = "Unexpected XML format"
        end
      end
      
      def parse_error(response, root)
        response[:status]     = "ERROR"
        response[:error_code] = root.attributes['code']
        response[:message]    = root.text
      end
      
      def build_purchase_request(money, credit_card, options={})
        requires!(options, :card_type, :order_id)
        
        billing_address   = options[:billing_address] || options[:address]
        shipping_address  = options[:shipping_address]
        
        xml = Builder::XmlMarkup.new(:indent => 2)
        xml.instruct!(:xml, :version => '1.0')
        xml.declare!(:DOCTYPE, :paymentService, :PUBLIC, "-//WorldPay/DTD WorldPay PaymentService v1//EN", "http://dtd.wp3.rbsworldpay.com/paymentService_v1.dtd")
        
        xml.paymentService(:version => "1.4") do
          xml.submit do
            xml.order(:orderCode => options[:order_id], :installationId => @options[:installation_id]) do |order|
              order.description options[:description]
              order.amount(:value => money, :currencyCode => default_currency, :exponent => "2")
              order.orderContent { |t| t.cdata! options[:invoice] } unless options[:invoice].blank?
              xml.paymentDetails do
                xml.tag!(options[:card_type]) do |card|
                  card.cardNumber credit_card.number
                  card.expiryDate do
                    xml.date(:month => credit_card.month, :year => credit_card.year)
                  end
                  card.cardHolderName [credit_card.first_name, credit_card.last_name].delete_if {|x| x.blank? }.join(' ')
                  card.cvc credit_card.verification_value unless credit_card.verification_value.blank?
                  if billing_address
                    card.cardAddress do
                      xml.address do |address|
                        address.firstName       billing_address[:first_name]
                        address.lastName        billing_address[:last_name]
                        address.street          billing_address[:address1]
                        address.postalCode      billing_address[:zip]
                        address.city            billing_address[:city]
                        address.countryCode     billing_address[:country]
                        address.telephoneNumber billing_address[:phone]
                      end
                    end
                  end
                end
                xml.session(:shopperIPAddress => options[:ip], :id => options[:session_id])
                # 3D secure response
                if options[:pa_res]
                  xml.info3DSecure do |info3DSecure|
                    info3DSecure.paResponse options[:pa_res]
                  end
                end
              end
              xml.shopper do |shopper|
                shopper.shopperEmailAddress options[:email] unless options[:email].blank?
                shopper.browser do |browser|
                  browser.acceptHeader "text/html"
                  browser.userAgentHeader options[:user_agent]
                end
              end
              
              # 3D secure echo data
              xml.echoData options[:md] if options[:md]
              
            end
          end
        end
      end
      
    end
  end
end

# uncomment to turn on debug logging
# ActiveMerchant::Billing::WorldPayGateway.logger = Logger.new(STDOUT)

module ActiveMerchant
  
  # create a worldpay response object that acts like a string but has the each_header method
  # so that we can access the headers that worldpay returns

  class WorldPayResponse < String

    def initialize(resp)
      @resp = resp
      super(resp.body)
    end

    def each_header(&block)
      @resp.each_header &block
    end

  end
  
  # overwrite the handle_response method so that it returns a WorldPayResponse object rather
  # than the response.body string, this acts the same as a string but includes the each_header
  # method for accessing the returned headers
  class Connection
    private
    def handle_response(response)
      case response.code.to_i
      when 200...300
        WorldPayResponse.new(response)
      else
        raise ResponseError.new(response)
      end
    end
  end
end
