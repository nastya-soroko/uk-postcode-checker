require 'rails_helper'

RSpec.describe PostcodesController, type: :controller do
  describe '#index' do
    it 'should be successful' do
      get :index
      expect(response).to be_successful
    end

    it 'renders index view' do
      get :index
      expect(response).to render_template(:index)
    end
  end

  describe '#check' do
    let(:valid_allowed_postcode) { 'AB0 1CD' }
    let(:valid_not_allowed_postcode) { 'AB0 1CC' }
    let(:valid_not_found_postcode) { 'AB00 1CC' }
    let(:invalid_postcode) { '3245435' }
    let(:allowed_postcode_body) do
      '{"status":200,"result":{"postcode":"AB0 1CD","lsoa":"Lsoa1 034A"}}'
    end
    let(:not_allowed_postcode_body) do
      '{"status":200,"result":{"postcode":"AB0 1CC","lsoa":"Lsoa2 034A"}}'
    end
    let(:not_found_postcode_body) do
      '{"status":404,"error":"Postcode not found"}'
    end

    context 'when required settings are present' do
      before do
        Setting.allowed_postcodes_lsoa = ['Lsoa1']
        Setting.specific_allowed_postcodes = ['AA00 0AA']

        stub_request(:get, "http://postcodes.io/postcodes/#{valid_allowed_postcode.gsub(/\s+/, '')}")
          .to_return(status: 200, body: allowed_postcode_body, headers: {})
        stub_request(:get, "http://postcodes.io/postcodes/#{valid_not_allowed_postcode.gsub(/\s+/, '')}")
          .to_return(status: 200, body: not_allowed_postcode_body, headers: {})
        stub_request(:get, "http://postcodes.io/postcodes/#{valid_not_found_postcode.gsub(/\s+/, '')}")
          .to_return(status: 404, body: not_found_postcode_body, headers: {})
      end

      it 'with valid, allowed postcode, should redirect to root with a correct flash message' do
        post :check, params: { postcode: valid_allowed_postcode }

        expect(response).to be_redirect
        expect(response).to redirect_to(root_url)
        expect(flash[:notice]).to eq("Postcode #{valid_allowed_postcode} is allowed.")
      end

      it 'with valid, not allowed postcode, should redirect to root with a correct flash message' do
        post :check, params: { postcode: valid_not_allowed_postcode }

        expect(response).to be_redirect
        expect(response).to redirect_to(root_url)
        expect(flash[:alert]).to eq("Postcode #{valid_not_allowed_postcode} isn't allowed.")
      end

      it 'with valid, not found postcode, should redirect to root with a correct flash message' do
        expect(Rails.logger).to receive(:error).with('Error at http://postcodes.io/postcodes/' \
                                                     "#{valid_not_found_postcode.gsub(/\s+/, '')} "\
                                                     '- 404 Postcode not found')

        post :check, params: { postcode: valid_not_found_postcode }

        expect(response).to be_redirect
        expect(response).to redirect_to(root_url)
        expect(flash[:alert]).to eq("Postcode #{valid_not_found_postcode} isn't allowed.")
      end

      it 'with invalid postcode, should redirect to root with a correct flash message' do
        post :check, params: { postcode: invalid_postcode }

        expect(response).to be_redirect
        expect(response).to redirect_to(root_url)
        expect(flash[:alert]).to eq("Postcode #{invalid_postcode} isn't allowed.")
      end
    end

    context "when required settings aren't present" do
      it 'should be successful' do
        post :check, params: { postcode: valid_allowed_postcode }

        expect(response).to be_redirect
      end

      it 'redirects to the root' do
        post :check, params: { postcode: valid_allowed_postcode }

        expect(response).to redirect_to(root_url)
      end

      it 'shows the correct flash message and triggers Rails logger' do
        expect(Rails.logger).to receive(:error).with('Runtime error: Required settings '\
                                                     'specific_allowed_postcodes or '\
                                                     'allowed_postcodes_lsoa are missing.')

        post :check, params: { postcode: valid_allowed_postcode }

        expect(flash[:alert]).to eq('Internal Error. Please try later.')
      end
    end
  end
end
