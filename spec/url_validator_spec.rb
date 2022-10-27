# frozen_string_literal: true

require 'spec_helper'
require 'active_model'

class Record
  extend ActiveModel::Translation
  include ActiveModel::Validations
  attr_accessor :field
end

RSpec.describe UrlValidator do
  before :each do
    @record = Record.new
  end

  context '[basic]' do
    it "allows nil if :allow_nil is set" do
      @validator = described_class.new(attributes: %i[field], allow_nil: true)
      @validator.validate_each(@record, :field, nil)
      expect(@record.errors).to be_empty
    end

    it "allows '' if :allow_blank is set" do
      @validator = described_class.new(attributes: %i[field], allow_blank: true)
      @validator.validate_each(@record, :field, "")
      expect(@record.errors).to be_empty
    end
  end

  context '[format]' do
    it "only allows HTTP URLs if :scheme is set to 'http'" do
      @validator = described_class.new(attributes: %i[field], scheme: 'http')
      @validator.validate_each(@record, :field, 'http://www.apple.com')
      expect(@record.errors).to be_empty

      @validator.validate_each(@record, :field, 'https://www.apple.com')
      expect(@record.errors[:field].first).to include('invalid_url')
    end

    it "onlies allow HTTP and HTTPS URLs if :scheme is set to %w(http https)" do
      @validator = described_class.new(attributes: %i[field], scheme: %w[http https])
      @validator.validate_each(@record, :field, 'http://www.apple.com')
      expect(@record.errors).to be_empty
      @validator.validate_each(@record, :field, 'https://www.apple.com')
      expect(@record.errors).to be_empty

      @validator.validate_each(@record, :field, 'ftp://www.apple.com')
      expect(@record.errors[:field].first).to include('invalid_url')
    end

    it "tries a default scheme if :default_scheme is set" do
      @validator = described_class.new(attributes: %i[field], scheme: 'http', default_scheme: 'http')
      @validator.validate_each(@record, :field, 'www.apple.com')
      expect(@record.errors).to be_empty
    end

    context '[HTTP(S)]' do
      it "does not allow garbage URLs that still somehow pass the ridiculously open-ended RFC" do
        @validator = described_class.new(attributes: %i[field])

        %w[
            http:sdg.sdfg/
            http/sdg.d
            http:://dsfg.dsfg/
            http//sdg..g
            http://://sdfg.f
        ].each do |uri|
          @record.errors.clear
          @validator.validate_each(@record, :field, uri)
          expect(@record.errors[:field].first).to include('invalid_url')
        end
      end

      it "does not allow invalid scheme formats" do
        @validator = described_class.new(attributes: %i[field])
        @validator.validate_each(@record, :field, ' https://www.apple.com')
        expect(@record.errors[:field].first).to include('invalid_url')
      end
    end
  end

  context '[accessibility]' do
    context '[:check_host]' do
      it "only validates if the host is accessible when :check_host is set" do
        @validator = described_class.new(attributes: %i[field])
        @validator.validate_each(@record, :field, 'http://www.invalid.tld')
        expect(@record.errors).to be_empty

        @validator = described_class.new(attributes: %i[field], check_host: true)
        @validator.validate_each(@record, :field, 'http://www.invalid.tld')
        expect(@record.errors[:field].first).to include('url_not_accessible')
      end

      it "does not perform the accessibility check if :check_host is set to 'http' and the URL scheme is not HTTP" do
        @validator = described_class.new(attributes: %i[field], check_host: 'http')
        @validator.validate_each(@record, :field, 'https://www.invalid.tld')
        expect(@record.errors).to be_empty
      end

      it "only validates if the host is accessible when :check_host is set to 'http' and the URL scheme is HTTP" do
        @validator = described_class.new(attributes: %i[field], check_host: 'http')
        @validator.validate_each(@record, :field, 'http://www.invalid.tld')
        expect(@record.errors[:field].first).to include('url_not_accessible')
      end

      it "does not perform the accessibility check if :check_host is set to %w(http https) and the URL scheme is not HTTP(S)" do
        @validator = described_class.new(attributes: %i[field], check_host: %w[http https], scheme: %w[ftp http https])
        @validator.validate_each(@record, :field, 'ftp://www.invalid.tld')
        expect(@record.errors).to be_empty
      end

      it "only validates if the host is accessible when :check_host is set to %w(http https) and the URL scheme is HTTP(S)" do
        @validator = described_class.new(attributes: %i[field], check_host: %w[http https])
        @validator.validate_each(@record, :field, 'http://www.invalid.tld')
        expect(@record.errors[:field].first).to include('url_not_accessible')

        @validator = described_class.new(attributes: %i[field], check_host: %w[http https])
        @validator.validate_each(@record, :field, 'https://www.invalid.tld')
        expect(@record.errors[:field].first).to include('url_not_accessible')
      end

      it "only validates the host" do
        @validator = described_class.new(attributes: %i[field], check_host: true)
        @validator.validate_each(@record, :field, 'http://www.google.com/sdgsdgf')
        expect(@record.errors).to be_empty
      end
    end

    context '[:check_path]' do
      it "does not validate if the response code is equal to the Integer value of this option" do
        @validator = described_class.new(attributes: %i[field], check_path: 404)
        @validator.validate_each(@record, :field, 'http://www.google.com/sdgsdgf')
        expect(@record.errors[:field].first).to include('url_invalid_response')

        @record.errors.clear

        @validator = described_class.new(attributes: %i[field], check_path: 405)
        @validator.validate_each(@record, :field, 'http://www.google.com/sdgsdgf')
        expect(@record.errors[:field]).to be_empty
      end

      it "does not validate if the response code is equal to the Symbol value of this option" do
        @validator = described_class.new(attributes: %i[field], check_path: :not_found)
        @validator.validate_each(@record, :field, 'http://www.google.com/sdgsdgf')
        expect(@record.errors[:field].first).to include('url_invalid_response')

        @record.errors.clear

        @validator = described_class.new(attributes: %i[field], check_path: :unauthorized)
        @validator.validate_each(@record, :field, 'http://www.google.com/sdgsdgf')
        expect(@record.errors[:field]).to be_empty
      end

      it "does not validate if the response code is within the Range value of this option" do
        @validator = described_class.new(attributes: %i[field], check_path: 400..499)
        @validator.validate_each(@record, :field, 'http://www.google.com/sdgsdgf')
        expect(@record.errors[:field].first).to include('url_invalid_response')

        @record.errors.clear

        @validator = described_class.new(attributes: %i[field], check_path: 500..599)
        @validator.validate_each(@record, :field, 'http://www.google.com/sdgsdgf')
        expect(@record.errors[:field]).to be_empty
      end

      it "does not validate if the response code is equal to the Integer value contained in the Array value of this option" do
        @validator = described_class.new(attributes: %i[field], check_path: [404, 405])
        @validator.validate_each(@record, :field, 'http://www.google.com/sdgsdgf')
        expect(@record.errors[:field].first).to include('url_invalid_response')

        @record.errors.clear

        @validator = described_class.new(attributes: %i[field], check_path: [405, 406])
        @validator.validate_each(@record, :field, 'http://www.google.com/sdgsdgf')
        expect(@record.errors[:field]).to be_empty
      end

      it "does not validate if the response code is equal to the Symbol value contained in the Array value of this option" do
        @validator = described_class.new(attributes: %i[field], check_path: %i[not_found unauthorized])
        @validator.validate_each(@record, :field, 'http://www.google.com/sdgsdgf')
        expect(@record.errors[:field].first).to include('url_invalid_response')

        @record.errors.clear

        @validator = described_class.new(attributes: %i[field], check_path: %i[unauthorized moved_permanently])
        @validator.validate_each(@record, :field, 'http://www.google.com/sdgsdgf')
        expect(@record.errors[:field]).to be_empty
      end

      it "does not validate if the response code is equal to the Range value contained in the Array value of this option" do
        @validator = described_class.new(attributes: %i[field], check_path: [400..499, 500..599])
        @validator.validate_each(@record, :field, 'http://www.google.com/sdgsdgf')
        expect(@record.errors[:field].first).to include('url_invalid_response')

        @record.errors.clear

        @validator = described_class.new(attributes: %i[field], check_path: [500..599, 300..399])
        @validator.validate_each(@record, :field, 'http://www.google.com/sdgsdgf')
        expect(@record.errors[:field]).to be_empty
      end

      it "skips validation by default" do
        @validator = described_class.new(attributes: %i[field], check_path: nil)
        @validator.validate_each(@record, :field, 'http://www.google.com/sdgsdgf')
        expect(@record.errors[:field]).to be_empty
      end

      it "does not validate 4xx and 5xx response codes if the value is true" do
        @validator = described_class.new(attributes: %i[field], check_path: true)
        @validator.validate_each(@record, :field, 'http://www.google.com/sdgsdgf')
        expect(@record.errors[:field].first).to include('url_invalid_response')
      end

      it "skips validation for non-HTTP URLs" do
        @validator = described_class.new(attributes: %i[field], check_path: true, scheme: %w[ftp http https])
        @validator.validate_each(@record, :field, 'ftp://ftp.sdgasdgohaodgh.com/sdgjsdg')
        expect(@record.errors[:field]).to be_empty
      end
    end

    context '[:httpi_adapter]' do
      it "uses the specified HTTPI adapter" do
        @validator = described_class.new(attributes: %i[field], httpi_adapter: :curl, check_host: true)
        expect(HTTPI).to receive(:get).once.with(an_instance_of(HTTPI::Request), :curl).and_return(false)
        @validator.validate_each(@record, :field, 'http://www.google.com/sdgsdgf')
      end
    end

    context '[:request_callback]' do
      it "is yielded the HTTPI request" do
        called     = false
        @validator = described_class.new(attributes: %i[field], check_host: true, request_callback: ->(request) { called = true; expect(request).to be_a(HTTPI::Request) })
        @validator.validate_each(@record, :field, 'http://www.google.com/sdgsdgf')
        expect(called).to be(true)
      end
    end
  end
end
