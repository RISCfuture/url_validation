require 'addressable/uri'
require 'httpi'
require 'active_support/core_ext/hash/except'
require 'active_model/validator'

# Validates URLs. Uses the following I18n error message keys:
#
# | @invalid_url@ | URL is improperly formatted. |
# | @url_not_accessible@ | Couldn't connect to the URL. |
# | @url_invalid_response@ | Got a bad HTTP response (not of an acceptable type, e.g., 2xx). |
#
# @example Checks the syntax only
#   validates :link, :url => true
#
# @example Ensures the host is available but does not check the path
#   validates :link, :url => { :check_host => true }
#
# @example Ensures that the host is available and that a request for the path does not return a 4xx or 5xx response
#   validates :link, :url => { :check_path => true }
#
# @example Ensures that the host is available and that a request for the path does not return a 3xx, 4xx, or 5xx response
#   validates :link, :url => { :check_path => [ 300..399, 400..499, 500..599 ] }
#
# @example Checks for host accessibility with a custom timeout
#   validates :link, :url => {
#     :check_host => true,
#     :request_callback => lambda { |request| request.timeout = 30 }
#   }
#
# h2. Options
#
# h3. Basic options
#
# | @:allow_nil@ | If @true@, @nil@ values are allowed. |
# | @:allow_blank@ | If @true@, @nil@ or empty values are allowed. |
#
# h3. Error messages
#
# | @:invalid_url_message@ | A custom message to use in place of @:invalid_url@. |
# | @:incorrect_url_type_message@ | A custom message to use in place of @:incorrect_url_type@. |
# | @:url_not_accessible_message@ | A custom message to use in place of @:url_not_accessible@. |
# | @:url_invalid_response_message@ | A custom message to use in place of @:url_invalid_response@. |
#
# h3. Networkless URL validation
#
# | @:scheme@ | A string or array of strings, such as "http" or "ftp", indicating which URL schemes are valid. By default only ==HTTP(S)== URLs are accepted. |
# | @:default_scheme@ | A default URL scheme to try for improper URLs. If this is set to, e.g., "http", then when  a URL like "whoops.com" is given (which would otherwise fail due to an improper format), "http://whoops.com" will be tried instead. |
#
# h3. Over-the-network URL validation
#
# The HTTPI gem is used to provide a generic interface to whatever HTTP client
# you wish to use. This allows you to drop in, e.g., a Curl client if you want.
# You can set the HTTPI adapter with the @:httpi_adapter@ option.
#
# | @:check_host@ | If @true@, the validator will perform a network test to verify that it can connect to the server and access the host (at the "/" path). This check will only be performed for ==HTTP(S)== URLs. |
# | @:check_path@ | An integer or symbol (or array of integers or symbols), such as 301 or @:moved_permanently@, indicating what response codes are unacceptable. You can also use ranges, and include them in an array, such as @[ :moved_permanently, 400..404, 500..599 ]@. By default, this is @nil@, and therefore only host accessibility is checked. If @true@ is given, uses a default set of invalid error codes (4xx and 5xx). Implies @:check_host@ is also true. |
# | @:httpi_adapter@ | The HTTPI adapter to use for checking HTTP and HTTPS URLs (default set by the HTTPI gem). |
#
# h3. Other options
#
# | @:request_callback@ | A proc that receives the request object (for ==HTTP(S)== requests, the @HTTPI::Request@ object) before it is executed. You can use this proc to set, e.g., custom headers or timeouts on the request. |

class UrlValidator < ActiveModel::EachValidator
  # @private
  CODES = {
    :continue => 100,
    :switching_protocols => 101,
    :processing => 102,
    :ok => 200,
    :created => 201,
    :accepted => 202,
    :non_authoritative_information => 203,
    :no_content => 204,
    :reset_content => 205,
    :partial_content => 206,
    :multi_status => 207,
    :im_used => 226,
    :multiple_choices => 300,
    :moved_permanently => 301,
    :found => 302,
    :see_other => 303,
    :not_modified => 304,
    :use_proxy => 305,
    :reserved => 306,
    :temporary_redirect => 307,
    :bad_request => 400,
    :unauthorized => 401,
    :payment_required => 402,
    :forbidden => 403,
    :not_found => 404,
    :method_not_allowed => 405,
    :not_acceptable => 406,
    :proxy_authentication_required => 407,
    :request_timeout => 408,
    :conflict => 409,
    :gone => 410,
    :length_required => 411,
    :precondition_failed => 412,
    :request_entity_too_large => 413,
    :request_uri_too_long => 414,
    :unsupported_media_type => 415,
    :requested_range_not_satisfiable => 416,
    :expectation_failed => 417,
    :unprocessable_entity => 422,
    :locked => 423,
    :failed_dependency => 424,
    :upgrade_required => 426,
    :internal_server_error => 500,
    :not_implemented => 501,
    :bad_gateway => 502,
    :service_unavailable => 503,
    :gateway_timeout => 504,
    :http_version_not_supported => 505,
    :variant_also_negotiates => 506,
    :insufficient_storage => 507,
    :not_extended => 510
  }
  
        
  # @private
  def validate_each(record, attribute, value)
    return if value.blank?

    begin
      uri = Addressable::URI.parse(value)
      if uri.scheme.nil? and options[:default_scheme] then
        uri = Addressable::URI.parse("#{options[:default_scheme]}://#{value}")
      end
    rescue Addressable::URI::InvalidURIError
      record.errors.add(attribute, options[:invalid_url_message]          || :invalid_url)          unless url_format_valid?(uri, options)
      return
    end
    
    record.errors.add(attribute, options[:invalid_url_message]          || :invalid_url)          unless url_format_valid?(uri, options)
    record.errors.add(attribute, options[:url_not_accessible_message]   || :url_not_accessible)   unless response = url_accessible?(uri, options)
    record.errors.add(attribute, options[:url_invalid_response_message] || :url_invalid_response) unless url_response_valid?(response, options)
  end
  
  private
  
  def url_format_valid?(uri, options)
    return false unless Array.wrap(options[:scheme] || %w( http https )).include?(uri.scheme)
    
    case uri.scheme
      when 'http', 'https'
        return http_url_format_valid?(uri)
      else
        return true
    end
  end
  
  def http_url_format_valid?(uri)
    uri.host.present? and not uri.path.nil?
  end
  
  def url_accessible?(uri, options)
    return true unless options[:check_host] or options[:check_path]
    
    check_host = options[:check_host]
    check_host ||= %w( http https ) if options[:check_path]
    if (schemes = Array.wrap(check_host)) and schemes.all? { |scheme| scheme.kind_of?(String) } then
      return true unless schemes.include?(uri.scheme)
    end
    
    case uri.scheme
      when 'http', 'https'
        return http_url_accessible?(uri, options)
      else
        return true
    end
  end

  def http_url_accessible?(uri, options)
    request = HTTPI::Request.new(uri.to_s)
    options[:request_callback].call(request) if options[:request_callback].respond_to?(:call)
    return HTTPI.get(request, options[:httpi_adapter])
  rescue
    return false
  end
  
  def url_response_valid?(response, options)
    return true unless response.kind_of?(HTTPI::Response) and options[:check_path]
    response_codes = options[:check_path] == true ? [400..499, 500..599] : Array.wrap(options[:check_path]).flatten
    return response_codes.none? do |code| # it's good if it's not a bad response
      case code # and it's a bad response if...
        when Range
          code.include? response.code
        when Fixnum
          code == response.code
        when Symbol
          CODES.include?(code) && CODES[code] == response.code
        else # be generous and treat it as a non-match if we don't know what it is
          false
      end
    end
  end
end
