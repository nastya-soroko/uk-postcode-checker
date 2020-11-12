class PostcodeChecker
  class SettingsMissing < StandardError; end

  # basic regex for UK postcode according to http://postcodes.io/ docs
  POSTCODE_REGEX = /^\s*[a-zA-Z]{1,2}\d[a-zA-Z\d]?\s*\d[a-zA-Z]{2}\s*$/.freeze
  POSTCODES_API_URL = 'http://postcodes.io/postcodes'.freeze

  def initialize(postcode)
    @postcode = postcode.gsub(/\s+/, '')
  end

  def allowed?
    check_required_settings!

    valid? && (in_specific_allowed_list? || in_allowed_lsoa_list?)
  end

  def valid?
    !!(@postcode =~ POSTCODE_REGEX)
  end

  private

  def check_required_settings!
    return if required_settings_present?

    raise SettingsMissing, 'Required settings specific_allowed_postcodes or allowed_postcodes_lsoa are missing.'
  end

  def in_allowed_lsoa_list?
    RestClient.get url do |response|
      return !!(body(response).dig('result', 'lsoa') =~ allowed_lsoa_regexp) if response.code == 200

      Rails.logger.error "Error at #{url} - #{body(response)['status']} #{body(response)['error']}"
      false
    end
  end

  def in_specific_allowed_list?
    specific_allowed_postcodes.map { |postcode| postcode.gsub(/\s+/, '') }.include?(@postcode)
  end

  def body(response)
    JSON.parse(response.body)
  end

  def url
    "#{POSTCODES_API_URL}/#{@postcode}"
  end

  def required_settings_present?
    specific_allowed_postcodes && allowed_postcodes_lsoa
  end

  def specific_allowed_postcodes
    @specific_allowed_postcodes ||= Setting.specific_allowed_postcodes
  end

  def allowed_postcodes_lsoa
    @allowed_postcodes_lsoa ||= Setting.allowed_postcodes_lsoa
  end

  def allowed_lsoa_regexp
    /#{allowed_postcodes_lsoa.map { |w| "^#{Regexp.escape(w)}" }.join('|')}/i
  end
end
