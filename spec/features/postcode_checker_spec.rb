require 'rails_helper'

RSpec.describe PostcodeChecker, type: :feature do
  let(:valid_allowed_postcode) { 'AB0 2CD' }
  let(:valid_not_allowed_postcode) { 'AB0 2CC' }
  let(:invalid_postcode) { '3245r5' }

  before do
    Setting.allowed_postcodes_lsoa = ['Lsoa1']
    Setting.specific_allowed_postcodes = ['AA00 0AA']

    stub_request(:get, "http://postcodes.io/postcodes/#{valid_allowed_postcode.gsub(/\s+/, '')}")
      .to_return(status: 200, body: '{"status":200,"result":{"postcode":"AB0 2CD","lsoa":"Lsoa1 034A"}}', headers: {})
    stub_request(:get, "http://postcodes.io/postcodes/#{valid_not_allowed_postcode.gsub(/\s+/, '')}")
      .to_return(status: 200, body: '{"status":200,"result":{"postcode":"AB0 2CC","lsoa":"Lsoa2 034A"}}', headers: {})
  end

  describe 'main page' do
    it 'shows the required elements on the main page' do
      visit root_path

      expect(page).to have_content('Postcode:')

      expect(page).to have_css('input#postcode')
      expect(page.find('input#postcode')[:pattern]).to eq(::PostcodeChecker::POSTCODE_REGEX.source)
      expect(page.find('input#postcode')[:title]).to eq('Invalid postcode format')

      expect(page).to have_selector :button, 'Check'
    end

    it 'checks the allowed postcode with postcode.io' do
      visit root_path

      fill_in 'postcode', with: valid_allowed_postcode

      click_button 'Check'

      expect(page).to have_content("Postcode #{valid_allowed_postcode} is allowed.")
    end

    it 'checks the not allowed postcode with postcode.io' do
      visit root_path

      fill_in 'postcode', with: valid_not_allowed_postcode

      click_button 'Check'

      expect(page).to have_content("Postcode #{valid_not_allowed_postcode} isn't allowed.")
    end

    it "doesn't check the postcode without required settings" do
      Setting.allowed_postcodes_lsoa = nil

      visit root_path

      fill_in 'postcode', with: valid_allowed_postcode

      click_button 'Check'

      expect(page).to have_content('Internal Error. Please try later.')
    end
  end
end
