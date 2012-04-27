module ActiveMerchant
  module Billing
    module PaymentechOrbital
      module Request
        class MarkForCapture < PaymentechOrbital::Request::Base
          attr_reader :money, :tx_ref_num

          def initialize(money, tx_ref_num, options)
            @money = money
            @tx_ref_num = tx_ref_num
            super(options)
          end

          def request_type; "MarkForCapture"; end

          def to_s
            "MarkForCapture: $#{money} - TxRefNum #{tx_ref_num}"
          end

          private
          def request_body(xml)
            add_order_information(xml)
            add_meta_info(xml)
          end

          def add_meta_info(xml)
            xml.tag! "BIN", bin
            xml.tag! "MerchantID", merchant_id
            xml.tag! "TerminalID", terminal_id
            xml.tag! "TxRefNum", tx_ref_num
          end

          def add_order_information(xml)
            xml.tag! "OrderID", order_id
            xml.tag! "Amount", money
          end
        end
      end
    end
  end
end