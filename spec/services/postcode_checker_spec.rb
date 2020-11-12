require 'rails_helper'

RSpec.describe PostcodeChecker do
  let(:valid_allowed_postcode) { 'AB0 1CD' }
  let(:valid_not_allowed_postcode) { 'AB0 1CC' }
  let(:valid_not_found_postcode) { 'AB00 1CC' }
  let(:invalid_postcode) { '3245435' }
  let(:specific_allowed_postcode) { 'AA00 0AA' }

  describe '#valid?' do
    it 'should return true for a valid postcode' do
      checker = described_class.new(valid_allowed_postcode)

      expect(checker.valid?).to be true
    end

    it 'should return false for an invalid postcode' do
      checker = described_class.new(invalid_postcode)

      expect(checker.valid?).to be false
    end
  end

  describe '#allowed?' do
    before do
      Setting.allowed_postcodes_lsoa = ['Lsoa1']
      Setting.specific_allowed_postcodes = [specific_allowed_postcode]
    end

    it 'should raise an exception without required settings' do
      Setting.allowed_postcodes_lsoa = nil
      checker = described_class.new(valid_allowed_postcode)

      expect { checker.allowed? }.to raise_error(PostcodeChecker::SettingsMissing,
                                                 'Required settings specific_allowed_postcodes '\
                                                 'or allowed_postcodes_lsoa are missing.')
    end

    it 'should return false with invalid postcode' do
      checker = described_class.new(invalid_postcode)

      expect(checker.allowed?).to be false
    end

    it 'should return true for a specific allowed postcode' do
      checker = described_class.new(specific_allowed_postcode)

      expect(checker.allowed?).to be true
    end

    context 'with postcodes.io API request' do
      before do
        allowed_postcode_body = '{"status":200,"result":{"postcode":"AB0 1CD","lsoa":"Lsoa1 034A"}}'
        not_allowed_postcode_body = '{"status":200,"result":{"postcode":"AB0 1CC","lsoa":"Lsoa2 034A"}}'
        not_found_postcode_body = '{"status":404,"error":"Postcode not found"}'

        stub_request(:get, "http://postcodes.io/postcodes/#{valid_allowed_postcode.gsub(/\s+/, '')}")
          .to_return(status: 200, body: allowed_postcode_body, headers: {})
        stub_request(:get, "http://postcodes.io/postcodes/#{valid_not_allowed_postcode.gsub(/\s+/, '')}")
          .to_return(status: 200, body: not_allowed_postcode_body, headers: {})
        stub_request(:get, "http://postcodes.io/postcodes/#{valid_not_found_postcode.gsub(/\s+/, '')}")
          .to_return(status: 404, body: not_found_postcode_body, headers: {})
      end

      it 'should return true for an allowed postcode' do
        checker = described_class.new(valid_allowed_postcode)

        expect(checker.allowed?).to be true
      end

      it 'should return false for a not allowed postcode' do
        checker = described_class.new(valid_not_allowed_postcode)

        expect(checker.allowed?).to be false
      end

      it 'should return false for not found postcode' do
        checker = described_class.new(valid_not_found_postcode)

        expect(checker.allowed?).to be false
      end

      it 'should trigger Rails logger with not found error message' do
        expect(Rails.logger).to receive(:error).with('Error at http://postcodes.io/postcodes/' \
                                                       "#{valid_not_found_postcode.gsub(/\s+/, '')} "\
                                                       '- 404 Postcode not found')

        described_class.new(valid_not_found_postcode).allowed?
      end
    end
  end
end
