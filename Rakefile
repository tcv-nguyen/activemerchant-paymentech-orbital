require 'rake'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "activemerchant-paymentech-orbital"
    gem.summary = "A gem to provide a ruby interface for Chase Paymentech Orbital payment gateway."
    gem.description = "A gem to provide a ruby interface for Chase Paymentech Orbital payment gateway. It has been development thus far to meet specific ends, so not all functionality is present."
    gem.email = "john@mintdigital.com"
    gem.homepage = "http://github.com/johnideal/activemerchant-paymentech-orbital"
    gem.authors = ["John Corrigan"]
    gem.add_dependency("activemerchant", ">= 1.4.2")
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: sudo gem install jeweler"
end

require 'rake/testtask'
Rake::TestTask.new(:unit) do |test|
  test.libs << 'test'
  test.pattern = 'test/units/**/*_test.rb'
  test.verbose = true
end

Rake::TestTask.new(:remote) do |test|
  test.libs << 'test'
  test.pattern = 'test/remote/**/*_test.rb'
  test.verbose = true
end

begin
  require 'rcov/rcovtask'
  Rcov::RcovTask.new do |test|
    test.libs << 'test'
    test.pattern = 'test/**/*_test.rb'
    test.verbose = true
  end
rescue LoadError
  task :rcov do
    abort "RCov is not available. In order to run rcov, you must: sudo gem install spicycode-rcov"
  end
end

task :test => :check_dependencies

task :default => :test

require 'rdoc/task'
Rake::RDocTask.new do |rdoc|
  if File.exist?('VERSION')
    version = File.read('VERSION')
  else
    version = ""
  end

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "activemerchant-paymentech-orbital #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

task :verify do
  $:.unshift File.join(File.dirname(__FILE__), 'test')
  $:.unshift File.join(File.dirname(__FILE__), 'lib')
  require 'remote_helper'
  @gateway = remote_gateway
  tx_ref = {}
  {
    authorize: [
      ['1', 'Visa', '11111', '111', 30.00],
      ['2', 'Visa', 'L6L2X9', '', 38.01],
      ['3', 'Visa', '22222', '222', 85.00],
      ['4', 'Visa', '66666', '', 0.00],
      ['9', 'MC', 'L6L2X9', '', 41.00],
      ['10', 'MC', '88888', '666', 11.02],
      ['11', 'MC', '88888', '', 0.00],
      ['16', 'Amex', 'L6L2X9', '', 1055.00],
      ['17', 'Amex', '66666', '2222', 75.00],
      ['18', 'Amex', '22222', '', 0.00],
      ['19', 'DS', '77777', '', 10.00],
      ['20', 'DS', 'L6L2X9', '444', 63.03],
      ['21', 'DS', '11111', '', 0.00],
      ['22', 'JCB', '33333', '', 29.00]
    ],
    purchase: [
      ['1', 'Visa', 'L6L2X9', '111', 30.00],
      ['2', 'Visa', '33333', '', 38.01],
      ['7', 'MC', '44444', '', 41.00],
      ['8', 'MC', 'L6L2X9', '666', 11.02],
      ['13', 'Amex', 'L6L2X9', '', 1055.00],
      ['14', 'Amex', '66666', '2222', 75.00],
      ['15', 'DS', '77777', '', 10.00],
      ['16', 'DS', 'L6L2X9', '444', 63.03],
      ['17', 'JCB', '33333', '', 29.0]
    ],
    refund: [
      ['1', 'Visa', 'L6L2X9', '111', 12.00],
      ['2', 'MC', '44444', '', 11.00],
      ['3', 'Amex', 'L6L2X9', '', 1055.00],
      ['4', 'DS', '77777', '', 10.00],
      ['5', 'JCB', '33333', '', 29.0]
    ]
  }.each_pair do |request_type, tests|
    puts
    puts request_type
    tx_ref[request_type] = {}
    tests.each do |parameters|
      tx_ref[request_type][parameters.first] = submit_request(request_type, *parameters)
    end
  end
  
  # Section C - Mark for Capture
  puts
  puts 'Section C - Mark for Capture'
  tx_ref[:capture] = {}
  [              # Ref # for Sec. C
    ['3', 85],   # 1
    ['9', 41],   # 6
    ['16', 500], # 10
    ['17', 75],  # 11
    ['19', 10],  # 12
    ['22', 29]   # 13
  ].each do |order_id, money|
    tx_ref_num = tx_ref[:authorize][order_id]
    r = @gateway.capture((money * 100).round, tx_ref_num, :order_id => order_id)
    if r.tx_ref_num.nil?
      puts "#{order_id}: #{r.status_msg}"
      puts r.to_xml
    else
      puts [order_id, r.resp_code, r.tx_ref_num].join(', ')
    end
    tx_ref[:capture][order_id] = r.tx_ref_num
  end
  
  # Section F - Voids
  puts
  puts 'Section F - Voids'
  [
    ['1', :authorize], # 1
    ['16', :capture],  # 5
    ['19', :capture],  # 6
    ['15', :purchase], # 7
    ['14', :purchase]  # 8
  ].each do |order_id, request_type|
    tx_ref_num = tx_ref[request_type][order_id]
    r = @gateway.void(tx_ref_num, {:order_id => order_id})
    if r.tx_ref_num.nil?
      puts "#{order_id}: #{r.status_msg}"
      puts r.to_xml
    else
      puts [order_id, r.tx_ref_num].join(', ')
    end
  end
  
end

def submit_request(request_type, index, card_type, zip, cvd, amount)
  country = zip[0] == 'L' ? 'CA' : 'US' # check for Canada zipcode
  # activemrechant expects the amount to be in cents so multiply by 100
  r = @gateway.send(request_type, (amount * 100).round,
    Factory(card_type.downcase, :verification_value => cvd), {
    :address => Options(:billing_address, :zip => zip, :country => country ),
    :order_id => index
  })
  if r.tx_ref_num.nil?
    puts "#{order_id}: #{r.status_msg}"
    puts r.to_xml
  else
    puts [index.to_s, r.auth_code || r.resp_msg, r.resp_code, r.AVSRespCode, r.CVV2RespCode, r.tx_ref_num].join(', ')
  end
  return r.tx_ref_num
end