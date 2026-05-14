# frozen_string_literal: true

require "spec_helper"
require "active_model"

class Record
  extend ActiveModel::Translation
  include ActiveModel::Validations

  attr_accessor :field
end

RSpec.describe UrlValidator do
  before :each do
    @record = Record.new
  end

  # Stub helpers --------------------------------------------------------------

  def stub_invalid_tld_unreachable(scheme: "http")
    stub_request(:any, %r{\A#{scheme}://www\.invalid\.tld}).to_raise(SocketError.new("not reachable"))
  end

  def stub_ok(url, method: :head)
    stub_request(method, url).to_return(status: 200, body: "", headers: {})
  end

  def stub_status(url, status, method: :head)
    stub_request(method, url).to_return(status: status, body: "", headers: {})
  end

  # ---------------------------------------------------------------------------

  context "[basic]" do
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

    it "does NOT short-circuit on blank values when :allow_blank is explicitly false" do
      @validator = described_class.new(attributes: %i[field], allow_blank: false)
      @validator.validate_each(@record, :field, "")
      expect(@record.errors[:field].first).to include("invalid_url")
    end

    it "short-circuits on blank values by default (allow_blank defaults to true in this validator)" do
      @validator = described_class.new(attributes: %i[field])
      @validator.validate_each(@record, :field, "")
      expect(@record.errors).to be_empty
    end
  end

  context "[format]" do
    it "only allows HTTP URLs if :scheme is set to 'http'" do
      @validator = described_class.new(attributes: %i[field], scheme: "http")
      @validator.validate_each(@record, :field, "http://www.apple.com")
      expect(@record.errors).to be_empty

      @validator.validate_each(@record, :field, "https://www.apple.com")
      expect(@record.errors[:field].first).to include("invalid_url")
    end

    it "only allows HTTP and HTTPS URLs if :scheme is set to %w(http https)" do
      @validator = described_class.new(attributes: %i[field], scheme: %w[http https])
      @validator.validate_each(@record, :field, "http://www.apple.com")
      expect(@record.errors).to be_empty
      @validator.validate_each(@record, :field, "https://www.apple.com")
      expect(@record.errors).to be_empty

      @validator.validate_each(@record, :field, "ftp://www.apple.com")
      expect(@record.errors[:field].first).to include("invalid_url")
    end

    it "tries a default scheme if :default_scheme is set" do
      @validator = described_class.new(attributes: %i[field], scheme: "http", default_scheme: "http")
      @validator.validate_each(@record, :field, "www.apple.com")
      expect(@record.errors).to be_empty
    end

    it "reports invalid_url when default_scheme prepending still yields an unparseable URI" do
      @validator = described_class.new(attributes: %i[field], default_scheme: "http")
      # "user@" parses successfully with a nil scheme on the first pass, but
      # raises when the validator prepends "http://" and tries again. This is
      # the rescue-branch regression: before the fix, the rescue would call
      # `url_format_valid?` against a URI that was already partially mutated.
      @validator.validate_each(@record, :field, "user@")
      expect(@record.errors[:field].first).to include("invalid_url")
    end

    context "[HTTP(S)]" do
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
          expect(@record.errors[:field].first).to include("invalid_url")
        end
      end

      it "does not allow invalid scheme formats" do
        @validator = described_class.new(attributes: %i[field])
        @validator.validate_each(@record, :field, " https://www.apple.com")
        expect(@record.errors[:field].first).to include("invalid_url")
      end
    end
  end

  context "[accessibility]" do
    context "[:check_host]" do
      it "only validates if the host is accessible when :check_host is set" do
        @validator = described_class.new(attributes: %i[field])
        @validator.validate_each(@record, :field, "http://www.invalid.tld")
        expect(@record.errors).to be_empty

        stub_invalid_tld_unreachable
        @validator = described_class.new(attributes: %i[field], check_host: true)
        @validator.validate_each(@record, :field, "http://www.invalid.tld")
        expect(@record.errors[:field].first).to include("url_not_accessible")
      end

      it "does not perform the accessibility check if :check_host is set to 'http' and the URL scheme is not HTTP" do
        @validator = described_class.new(attributes: %i[field], check_host: "http")
        @validator.validate_each(@record, :field, "https://www.invalid.tld")
        expect(@record.errors).to be_empty
      end

      it "only validates if the host is accessible when :check_host is set to 'http' and the URL scheme is HTTP" do
        stub_invalid_tld_unreachable
        @validator = described_class.new(attributes: %i[field], check_host: "http")
        @validator.validate_each(@record, :field, "http://www.invalid.tld")
        expect(@record.errors[:field].first).to include("url_not_accessible")
      end

      it "does not perform the accessibility check if :check_host is set to %w(http https) and the URL scheme is not HTTP(S)" do
        @validator = described_class.new(attributes: %i[field], check_host: %w[http https], scheme: %w[ftp http https])
        @validator.validate_each(@record, :field, "ftp://www.invalid.tld")
        expect(@record.errors).to be_empty
      end

      it "only validates if the host is accessible when :check_host is set to %w(http https) and the URL scheme is HTTP(S)" do
        stub_invalid_tld_unreachable(scheme: "http")
        stub_invalid_tld_unreachable(scheme: "https")

        @validator = described_class.new(attributes: %i[field], check_host: %w[http https])
        @validator.validate_each(@record, :field, "http://www.invalid.tld")
        expect(@record.errors[:field].first).to include("url_not_accessible")

        @record.errors.clear
        @validator = described_class.new(attributes: %i[field], check_host: %w[http https])
        @validator.validate_each(@record, :field, "https://www.invalid.tld")
        expect(@record.errors[:field].first).to include("url_not_accessible")
      end

      it "only validates the host" do
        stub_ok("http://www.google.com/sdgsdgf")
        @validator = described_class.new(attributes: %i[field], check_host: true)
        @validator.validate_each(@record, :field, "http://www.google.com/sdgsdgf")
        expect(@record.errors).to be_empty
      end
    end

    context "[:check_path]" do
      it "does not validate if the response code is equal to the Integer value of this option" do
        stub_status("http://www.google.com/sdgsdgf", 404)
        @validator = described_class.new(attributes: %i[field], check_path: 404)
        @validator.validate_each(@record, :field, "http://www.google.com/sdgsdgf")
        expect(@record.errors[:field].first).to include("url_invalid_response")

        @record.errors.clear
        WebMock.reset!
        stub_status("http://www.google.com/sdgsdgf", 404)
        @validator = described_class.new(attributes: %i[field], check_path: 405)
        @validator.validate_each(@record, :field, "http://www.google.com/sdgsdgf")
        expect(@record.errors[:field]).to be_empty
      end

      it "does not validate if the response code is equal to the Symbol value of this option" do
        stub_status("http://www.google.com/sdgsdgf", 404)
        @validator = described_class.new(attributes: %i[field], check_path: :not_found)
        @validator.validate_each(@record, :field, "http://www.google.com/sdgsdgf")
        expect(@record.errors[:field].first).to include("url_invalid_response")

        @record.errors.clear
        WebMock.reset!
        stub_status("http://www.google.com/sdgsdgf", 404)
        @validator = described_class.new(attributes: %i[field], check_path: :unauthorized)
        @validator.validate_each(@record, :field, "http://www.google.com/sdgsdgf")
        expect(@record.errors[:field]).to be_empty
      end

      it "does not validate if the response code is within the Range value of this option" do
        stub_status("http://www.google.com/sdgsdgf", 404)
        @validator = described_class.new(attributes: %i[field], check_path: 400..499)
        @validator.validate_each(@record, :field, "http://www.google.com/sdgsdgf")
        expect(@record.errors[:field].first).to include("url_invalid_response")

        @record.errors.clear
        WebMock.reset!
        stub_status("http://www.google.com/sdgsdgf", 404)
        @validator = described_class.new(attributes: %i[field], check_path: 500..599)
        @validator.validate_each(@record, :field, "http://www.google.com/sdgsdgf")
        expect(@record.errors[:field]).to be_empty
      end

      it "does not validate if the response code is equal to the Integer value contained in the Array value of this option" do
        stub_status("http://www.google.com/sdgsdgf", 404)
        @validator = described_class.new(attributes: %i[field], check_path: [404, 405])
        @validator.validate_each(@record, :field, "http://www.google.com/sdgsdgf")
        expect(@record.errors[:field].first).to include("url_invalid_response")

        @record.errors.clear
        WebMock.reset!
        stub_status("http://www.google.com/sdgsdgf", 404)
        @validator = described_class.new(attributes: %i[field], check_path: [405, 406])
        @validator.validate_each(@record, :field, "http://www.google.com/sdgsdgf")
        expect(@record.errors[:field]).to be_empty
      end

      it "does not validate if the response code is equal to the Symbol value contained in the Array value of this option" do
        stub_status("http://www.google.com/sdgsdgf", 404)
        @validator = described_class.new(attributes: %i[field], check_path: %i[not_found unauthorized])
        @validator.validate_each(@record, :field, "http://www.google.com/sdgsdgf")
        expect(@record.errors[:field].first).to include("url_invalid_response")

        @record.errors.clear
        WebMock.reset!
        stub_status("http://www.google.com/sdgsdgf", 404)
        @validator = described_class.new(attributes: %i[field], check_path: %i[unauthorized moved_permanently])
        @validator.validate_each(@record, :field, "http://www.google.com/sdgsdgf")
        expect(@record.errors[:field]).to be_empty
      end

      it "does not validate if the response code is equal to the Range value contained in the Array value of this option" do
        stub_status("http://www.google.com/sdgsdgf", 404)
        @validator = described_class.new(attributes: %i[field], check_path: [400..499, 500..599])
        @validator.validate_each(@record, :field, "http://www.google.com/sdgsdgf")
        expect(@record.errors[:field].first).to include("url_invalid_response")

        @record.errors.clear
        WebMock.reset!
        stub_status("http://www.google.com/sdgsdgf", 404)
        @validator = described_class.new(attributes: %i[field], check_path: [500..599, 300..399])
        @validator.validate_each(@record, :field, "http://www.google.com/sdgsdgf")
        expect(@record.errors[:field]).to be_empty
      end

      it "skips validation by default" do
        @validator = described_class.new(attributes: %i[field], check_path: nil)
        @validator.validate_each(@record, :field, "http://www.google.com/sdgsdgf")
        expect(@record.errors[:field]).to be_empty
      end

      it "does not validate 4xx and 5xx response codes if the value is true" do
        stub_status("http://www.google.com/sdgsdgf", 404)
        @validator = described_class.new(attributes: %i[field], check_path: true)
        @validator.validate_each(@record, :field, "http://www.google.com/sdgsdgf")
        expect(@record.errors[:field].first).to include("url_invalid_response")
      end

      it "skips validation for non-HTTP URLs" do
        @validator = described_class.new(attributes: %i[field], check_path: true, scheme: %w[ftp http https])
        @validator.validate_each(@record, :field, "ftp://ftp.sdgasdgohaodgh.com/sdgjsdg")
        expect(@record.errors[:field]).to be_empty
      end
    end

    context "[:httpi_adapter]" do
      it "uses the specified HTTPI adapter" do
        @validator = described_class.new(attributes: %i[field], httpi_adapter: :curl, check_host: true)
        expect(HTTPI).to receive(:request).once.with(:head, an_instance_of(HTTPI::Request), :curl).and_return(false)
        @validator.validate_each(@record, :field, "http://www.google.com/sdgsdgf")
      end
    end

    context "[:request_callback]" do
      it "is yielded the HTTPI request" do
        stub_ok("http://www.google.com/sdgsdgf")
        called     = false
        @validator = described_class.new(attributes: %i[field], check_host: true, request_callback: ->(request) { called = true; expect(request).to be_a(HTTPI::Request) })
        @validator.validate_each(@record, :field, "http://www.google.com/sdgsdgf")
        expect(called).to be(true)
      end
    end

    context "[:http_method]" do
      it "uses HEAD requests by default" do
        stub_ok("http://example.com/path", method: :head)
        @validator = described_class.new(attributes: %i[field], check_host: true)
        @validator.validate_each(@record, :field, "http://example.com/path")
        expect(@record.errors).to be_empty
        expect(WebMock).to have_requested(:head, "http://example.com/path")
      end

      it "uses the supplied HTTP method when :http_method is set" do
        stub_ok("http://example.com/path", method: :get)
        @validator = described_class.new(attributes: %i[field], check_host: true, http_method: :get)
        @validator.validate_each(@record, :field, "http://example.com/path")
        expect(@record.errors).to be_empty
        expect(WebMock).to have_requested(:get, "http://example.com/path")
      end

      it "passes the HTTP method through to HTTPI.request" do
        @validator = described_class.new(attributes: %i[field], check_host: true, http_method: :get)
        expect(HTTPI).to receive(:request).once.with(:get, an_instance_of(HTTPI::Request), nil).and_return(false)
        @validator.validate_each(@record, :field, "http://example.com/path")
      end
    end
  end
end
