module ActiveMerchant
  module Billing
    module PaymentechOrbital
      module Request
        class NewOrder < PaymentechOrbital::Request::Base
          attr_reader :message_type, :money, :credit_card

          def initialize(message_type, money, credit_card, options)
            @message_type = message_type
            @money = money
            @credit_card = credit_card
            super(options)
          end

          delegate :industry_type, :mb_type, :recurring_start_date,
            :recurring_end_date, :recurring_end_date_flag,
            :recurring_max_billings, :recurring_frequency,
            :deferred_bill_date, :soft_descriptors, :tx_ref_num,
            :to => :options

          def request_type; "NewOrder"; end

          def to_s
            "#{self.class.message_map[@message_type]}: Credit Card (#{credit_card.cc_type if credit_card})"
          end

          def self.message_map
            { "A"  => "Auth",
              "AC" => "Auth/Capture",
              "R"  => "Refund" }
          end

          def recurring?
            industry_type == "RC"
          end

          private
          def request_body(xml)
            add_meta_info(xml)
            add_credit_card(xml)
            add_billing_address(xml)
            add_profile_management_options(xml)
            add_order_information(xml)
            add_soft_descriptor_info(xml)
            add_managed_billing_info(xml)
          end

          def add_meta_info(xml)
            xml.tag! "IndustryType", industry_type || "EC"
            xml.tag! "MessageType", message_type
            xml.tag! "BIN", bin
            xml.tag! "MerchantID", merchant_id
            xml.tag! "TerminalID", terminal_id
          end

          def add_credit_card(xml)
            if credit_card
              # CardBrand field is not to be used for standard credit card transactions
              # xml.tag! "CardBrand", credit_card.respond_to?(:brand) ? credit_card.brand : credit_card.cc_type
              xml.tag! "AccountNum", numbers_only(credit_card.number).first(19)
              xml.tag! "Exp", "#{("0" + credit_card.month.to_s)[-2..-1]}#{credit_card.year.to_s[-2..-1]}"
              add_currency(xml)
              if @message_type != 'R' # CVV not validated for refunds
                # CardSecValInd is only applicable to Visa and Discover
                # Also only sent when CardSecVal is present
                if ["american_express","discover"].include?(credit_card.cc_type) && credit_card.verification_value.present?
                  xml.tag! "CardSecValInd", "1"
                end
                xml.tag! "CardSecVal", numbers_only(credit_card.verification_value).first(4)
              end
            else
              add_currency(xml)
            end
          end

          def add_currency(xml)
            xml.tag! "CurrencyCode", currency_code
            xml.tag! "CurrencyExponent", currency_exponent
          end

          def add_billing_address(xml)
            return if address.blank? || @message_type == 'R'
            xml.tag! "AVSzip", format_zipcode(address[:zip], address[:country]) if address[:zip]
            xml.tag! "AVSaddress1", a_n_and_spaces_only(address[:address1]).first(30) if address[:address1]
            xml.tag! "AVSaddress2", a_n_and_spaces_only(address[:address2]).first(30) if address[:address2]
            xml.tag! "AVScity", a_n_and_spaces_only(address[:city]).first(20) if address[:city]
            xml.tag! "AVSstate", uc_letters_only(address[:state]).first(2) if address[:state]
            xml.tag! "AVSphoneNum", numbers_only(address[:phone]).first(14) if address[:phone]
            xml.tag! "AVSname", a_n_and_spaces_only(address[:name]).first(30) if address[:name]
            xml.tag! "AVScountryCode", uc_letters_only(address[:country]).first(2) if address[:country]
          end

          def add_profile_management_options(xml)
            if customer_ref_num
              xml.tag! "CustomerRefNum", customer_ref_num
            elsif @message_type != 'R'
              xml.tag! "CustomerProfileFromOrderInd", "A"
              xml.tag! "CustomerProfileOrderOverrideInd", "NO"
            end
          end

          def add_order_information(xml)
            xml.tag! "OrderID", a_n_and_spaces_only(order_id).first(22)
            xml.tag! "Amount", money
            xml.tag! "TxRefNum", tx_ref_num if tx_ref_num.present?
          end

          def add_soft_descriptor_info(xml)
            if soft_descriptors
              xml.tag! "SDMerchantName", soft_descriptors[:merchant_name]
              xml.tag! "SDProductDescription", soft_descriptors[:production_description]
              xml.tag! "SDMerchantCity", soft_descriptors[:merchant_city]
              xml.tag! "SDMerchantPhone", soft_descriptors[:merchant_phone]
              xml.tag! "SDMerchantURL", soft_descriptors[:merchant_url]
              xml.tag! "SDMerchantEmail", soft_descriptors[:merchant_email]
            end
          end

          def add_managed_billing_info(xml)
            if recurring?
              xml.tag! "MBType", mb_type || "R"
              xml.tag! "MBOrderIdGenerationMethod", "DI"
              xml.tag! "MBRecurringStartDate", recurring_start_date || (Date.today + 1).strftime("%m%d%Y")
              xml.tag! "MBRecurringEndDate", recurring_end_date
              xml.tag! "MBRecurringNoEndDateFlag", recurring_end_date_flag # || (recurring_end_date ? "N" : "Y")
              xml.tag! "MBRecurringMaxBillings", recurring_max_billings
              xml.tag! "MBRecurringFrequency", recurring_frequency
              xml.tag! "MBDeferredBillDate", deferred_bill_date
            end
          end
        end
      end
    end
  end
end
