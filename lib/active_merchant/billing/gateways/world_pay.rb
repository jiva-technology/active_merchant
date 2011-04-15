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
    
      self.supported_cardtypes  = [:visa, :master, :american_express, :discover, :jcb, :switch, :solo, :maestro, :diners_club]
      self.supported_countries  = ['GB']
      self.default_currency     = 'GBP'
      # self.supports_3d_secure   = true
      self.homepage_url         = 'http://www.worldpay.com'
      self.display_name         = 'WorldPay'

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
      
      private
      def map_card_type(credit_card)
        raise ArgumentError, "The credit card type must be provided" if card_brand(credit_card).blank?
        
        card_type = card_brand(credit_card).to_sym
        CREDIT_CARDS[card_type]
      end
      
      def commit(action, request)
        url = test? ? TEST_URL : LIVE_URL
        
        headers = { 'Content-Type' => 'text/xml',
	                  'Authorization' => encoded_credentials }
        
        response = parse( ssl_post(url, request, headers) )
        
        # Response.new([APPROVED, REGISTERED].include?(response['Status']), message_from(response), response,
        #   :test => test?,
        #   :authorization => authorization_from(response, parameters, action),
        #   :avs_result => { 
        #     :street_match => AVS_CVV_CODE[ response["AddressResult"] ],
        #     :postal_match => AVS_CVV_CODE[ response["PostCodeResult"] ],
        #   },
        #   :cvv_result => AVS_CVV_CODE[ response["CV2Result"] ],
        #   :three_d_secure => response["Status"] == '3DAUTH',
        #   :pa_req => response["PAReq"],
        #   :md => response["MD"],
        #   :acs_url => response["ACSURL"]
        # )
        
        Response.new(true, response, response,
          :test => test?,
          :avs_result => { 
            :street_match => '',
            :postal_match => '',
          },
          :cvv_result => '',
          :three_d_secure => response["Status"] == '3DAUTH',
          :pa_req => response["PAReq"],
          :md => response["MD"],
          :acs_url => response["ACSURL"]
        )
      end
      
      def encoded_credentials
        credentials = [@options[:login], @options[:password]].join(':')
        "Basic " << Base64.encode64(credentials).strip
      end
      
      # Read the XML message from the gateway and check if it was successful,
			# and also extract required return values from the response.
      def parse(xml)
        basepath = '/paymentService/reply"'
        response = {}

        xml = REXML::Document.new(xml)
        if root = REXML::XPath.first(xml, basepath)
          parse_response(response, root)
        elsif root = REXML::XPath.first(xml, "//ERROR")
          parse_error(response, root)
        else
          response[:message] = "No valid XML response message received. \
                                Propably wrong credentials supplied with HTTP header."
        end

        response
      end
      
      # Parse the <orderStatus> Element which containts all important information
      def parse_response(response, root)
        puts "-------"
        puts root
        status = nil
        # get the root element for this Transaction
        root.elements.to_a.each do |node|
          if node.name =~ /FNC_CC_/
            status = REXML::XPath.first(node, "CC_TRANSACTION/PROCESSING_STATUS")
          end
        end
        message = ""
        if status
          if info = status.elements['Info']
            message << info.text
          end
          # Get basic response information
          status.elements.to_a.each do |node|
            response[node.name.to_sym] = (node.text || '').strip
          end
        end
        # parse_error(root, message)
        response[:message] = message
      end
      
      def build_purchase_request(money, credit_card, options={})
        
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
              order.orderContent { |t| t.cdata! options[:invoice] }
              xml.paymentDetails do
                xml.tag!(options[:card_type]) do |card|
                  card.cardNumber credit_card.number
                  card.expiryDate do
                    xml.date(:month => credit_card.month, :year => credit_card.year)
                  end
                  card.cardHolderName [credit_card.first_name, credit_card.last_name].delete_if {|x| x.blank? }.join(' ')
                  card.cvc credit_card.verification_value
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
                xml.session(:shopperIPAddress => options[:ip], :id => options[:session_id])
              end
              xml.shopper do |shopper|
                shopper.shopperEmailAddress options[:email]
                shopper.browser do |browser|
                  browser.acceptHeader "text/html"
                  browser.userAgentHeader options[:user_agent]
                end
              end
            end
          end
        end
      end
      
    end
  end
end

ActiveMerchant::Billing::WorldPayGateway.logger = Logger.new(STDOUT)
