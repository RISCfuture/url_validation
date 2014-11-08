require 'spec_helper'

class Record
  extend ActiveModel::Translation
  include ActiveModel::Validations
  attr_accessor :field
end

describe UrlValidator do
  before :each do
    @record = Record.new
  end

  context "[basic]" do
    it "should allow nil if :allow_nil is set" do
      @validator = UrlValidator.new(:attributes => [ :field ], :allow_nil => true)
      @validator.validate_each(@record, :field, nil)
      expect(@record.errors).to be_empty
    end

    it "should allow \"\" if :allow_blank is set" do
      @validator = UrlValidator.new(:attributes => [ :field ], :allow_blank => true)
      @validator.validate_each(@record, :field, "")
      expect(@record.errors).to be_empty
    end
  end
  
  context "[format]" do
    it "should only allow HTTP URLs if :scheme is set to 'http'" do
      @validator = UrlValidator.new(:attributes => [ :field ], :scheme => 'http')
      @validator.validate_each(@record, :field, "http://www.apple.com")
      expect(@record.errors).to be_empty

      @validator.validate_each(@record, :field, "https://www.apple.com")
      expect(@record.errors[:field].first).to include('invalid_url')
    end

    it "should only allow HTTP and HTTPS URLs if :scheme is set to %w( http https )" do
      @validator = UrlValidator.new(:attributes => [ :field ], :scheme => %w( http https ))
      @validator.validate_each(@record, :field, "http://www.apple.com")
      expect(@record.errors).to be_empty
      @validator.validate_each(@record, :field, "https://www.apple.com")
      expect(@record.errors).to be_empty

      @validator.validate_each(@record, :field, "ftp://www.apple.com")
      expect(@record.errors[:field].first).to include('invalid_url')
    end

    it "should try a default scheme if :default_scheme is set" do
      @validator = UrlValidator.new(:attributes => [ :field ], :scheme => 'http', :default_scheme => 'http')
      @validator.validate_each(@record, :field, "www.apple.com")
      expect(@record.errors).to be_empty
    end
    
    context "[HTTP(S)]" do
      it "should not allow garbage URLs that still somehow pass the ridiculously open-ended RFC" do
        @validator = UrlValidator.new(:attributes => [ :field ])
        
        [
          'http:sdg.sdfg/',
          'http/sdg.d',
          'http:://dsfg.dsfg/',
          'http//sdg..g',
          'http://://sdfg.f',
          'http://dsaf.com://sdg.com'
        ].each do |uri|
          @record.errors.clear
          @validator.validate_each(@record, :field, "www.apple.com")
          expect(@record.errors[:field].first).to include('invalid_url')
        end
      end
    end
  end
  
  context "[accessibility]" do
    context "[:check_host]" do
      it "should only validate if the host is accessible when :check_host is set" do
        @validator = UrlValidator.new(:attributes => [ :field ])
        @validator.validate_each(@record, :field, "http://www.invalid.tld")
        expect(@record.errors).to be_empty

        @validator = UrlValidator.new(:attributes => [ :field ], :check_host => true)
        @validator.validate_each(@record, :field, "http://www.invalid.tld")
        expect(@record.errors[:field].first).to include('url_not_accessible')
      end

      it "should not perform the accessibility check if :check_host is set to 'http' and the URL scheme is not HTTP" do
        @validator = UrlValidator.new(:attributes => [ :field ], :check_host => 'http')
        @validator.validate_each(@record, :field, "https://www.invalid.tld")
        expect(@record.errors).to be_empty
      end

      it "should only validate if the host is accessible when :check_host is set to 'http' and the URL scheme is HTTP" do
        @validator = UrlValidator.new(:attributes => [ :field ], :check_host => 'http')
        @validator.validate_each(@record, :field, "http://www.invalid.tld")
        expect(@record.errors[:field].first).to include('url_not_accessible')
      end

      it "should not perform the accessibility check if :check_host is set to %w( http https ) and the URL scheme is not HTTP(S)" do
        @validator = UrlValidator.new(:attributes => [ :field ], :check_host => %w( http https ), :scheme => %w( ftp http https ))
        @validator.validate_each(@record, :field, "ftp://www.invalid.tld")
        expect(@record.errors).to be_empty
      end
      
      it "should only validate if the host is accessible when :check_host is set to %w( http https ) and the URL scheme is HTTP(S)" do
        @validator = UrlValidator.new(:attributes => [ :field ], :check_host => %w( http https ))
        @validator.validate_each(@record, :field, "http://www.invalid.tld")
        expect(@record.errors[:field].first).to include('url_not_accessible')

        @validator = UrlValidator.new(:attributes => [ :field ], :check_host => %w( http https ))
        @validator.validate_each(@record, :field, "https://www.invalid.tld")
        expect(@record.errors[:field].first).to include('url_not_accessible')
      end

      it "should only validate the host" do
        @validator = UrlValidator.new(:attributes => [ :field ], :check_host => true)
        @validator.validate_each(@record, :field, "http://www.google.com/sdgsdgf")
        expect(@record.errors).to be_empty
      end
    end
    
    context "[:check_path]" do
      it "should not validate if the response code is equal to the Fixnum value of this option" do
        @validator = UrlValidator.new(:attributes => [ :field ], :check_path => 404)
        @validator.validate_each(@record, :field, "http://www.google.com/sdgsdgf")
        expect(@record.errors[:field].first).to include('url_invalid_response')
        
        @record.errors.clear
        
        @validator = UrlValidator.new(:attributes => [ :field ], :check_path => 405)
        @validator.validate_each(@record, :field, "http://www.google.com/sdgsdgf")
        expect(@record.errors[:field]).to be_empty
      end
      
      it "should not validate if the response code is equal to the Symbol value of this option" do
        @validator = UrlValidator.new(:attributes => [ :field ], :check_path => :not_found)
        @validator.validate_each(@record, :field, "http://www.google.com/sdgsdgf")
        expect(@record.errors[:field].first).to include('url_invalid_response')
        
        @record.errors.clear
        
        @validator = UrlValidator.new(:attributes => [ :field ], :check_path => :unauthorized)
        @validator.validate_each(@record, :field, "http://www.google.com/sdgsdgf")
        expect(@record.errors[:field]).to be_empty
      end
      
      it "should not validate if the response code is within the Range value of this option" do
        @validator = UrlValidator.new(:attributes => [ :field ], :check_path => 400..499)
        @validator.validate_each(@record, :field, "http://www.google.com/sdgsdgf")
        expect(@record.errors[:field].first).to include('url_invalid_response')
        
        @record.errors.clear
        
        @validator = UrlValidator.new(:attributes => [ :field ], :check_path => 500..599)
        @validator.validate_each(@record, :field, "http://www.google.com/sdgsdgf")
        expect(@record.errors[:field]).to be_empty
      end
      
      it "should not validate if the response code is equal to the Fixnum value contained in the Array value of this option" do
        @validator = UrlValidator.new(:attributes => [ :field ], :check_path => [ 404, 405 ])
        @validator.validate_each(@record, :field, "http://www.google.com/sdgsdgf")
        expect(@record.errors[:field].first).to include('url_invalid_response')
        
        @record.errors.clear
        
        @validator = UrlValidator.new(:attributes => [ :field ], :check_path => [ 405, 406 ])
        @validator.validate_each(@record, :field, "http://www.google.com/sdgsdgf")
        expect(@record.errors[:field]).to be_empty
      end
      
      it "should not validate if the response code is equal to the Symbol value contained in the Array value of this option" do
        @validator = UrlValidator.new(:attributes => [ :field ], :check_path => [ :not_found, :unauthorized ])
        @validator.validate_each(@record, :field, "http://www.google.com/sdgsdgf")
        expect(@record.errors[:field].first).to include('url_invalid_response')
        
        @record.errors.clear
        
        @validator = UrlValidator.new(:attributes => [ :field ], :check_path => [ :unauthorized, :moved_permanently ])
        @validator.validate_each(@record, :field, "http://www.google.com/sdgsdgf")
        expect(@record.errors[:field]).to be_empty
      end
      
      it "should not validate if the response code is equal to the Range value contained in the Array value of this option" do
        @validator = UrlValidator.new(:attributes => [ :field ], :check_path => [ 400..499, 500..599 ])
        @validator.validate_each(@record, :field, "http://www.google.com/sdgsdgf")
        expect(@record.errors[:field].first).to include('url_invalid_response')
        
        @record.errors.clear
        
        @validator = UrlValidator.new(:attributes => [ :field ], :check_path => [ 500..599, 300..399 ])
        @validator.validate_each(@record, :field, "http://www.google.com/sdgsdgf")
        expect(@record.errors[:field]).to be_empty
      end
      
      it "should skip validation by default" do
        @validator = UrlValidator.new(:attributes => [ :field ], :check_path => nil)
        @validator.validate_each(@record, :field, "http://www.google.com/sdgsdgf")
        expect(@record.errors[:field]).to be_empty
      end
      
      it "should not validate 4xx and 5xx response codes if the value is true" do
        @validator = UrlValidator.new(:attributes => [ :field ], :check_path => true)
        @validator.validate_each(@record, :field, "http://www.google.com/sdgsdgf")
        expect(@record.errors[:field].first).to include('url_invalid_response')
      end
      
      it "should skip validation for non-HTTP URLs" do
        @validator = UrlValidator.new(:attributes => [ :field ], :check_path => true, :scheme => %w( ftp http https ))
        @validator.validate_each(@record, :field, "ftp://ftp.sdgasdgohaodgh.com/sdgjsdg")
        expect(@record.errors[:field]).to be_empty
      end
    end
    
    context "[:httpi_adapter]" do
      it "should use the specified HTTPI adapter" do
        @validator = UrlValidator.new(:attributes => [ :field ], :httpi_adapter => :curl, :check_host => true)
        expect(HTTPI).to receive(:get).once.with(an_instance_of(HTTPI::Request), :curl).and_return(false)
        @validator.validate_each(@record, :field, "http://www.google.com/sdgsdgf")
      end
    end
    
    context "[:request_callback]" do
      it "should be yielded the HTTPI request" do
        called = false
        @validator = UrlValidator.new(:attributes => [ :field ], :check_host => true, :request_callback => lambda { |request| called = true; expect(request).to be_kind_of(HTTPI::Request) })
        @validator.validate_each(@record, :field, "http://www.google.com/sdgsdgf")
        expect(called).to eql(true)
      end
    end
  end
end
