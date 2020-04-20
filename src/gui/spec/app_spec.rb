# frozen_string_literal: true

require_relative './spec_helper'

RSpec.describe 'GUI - Frontend' do
  describe 'Endpoints' do
    let(:base_url) { 'http://localhost:5000' }

    context 'GET /gui' do
      let(:body_args) do
        { 'tokens': %w[LPAR DIGIT] }
      end

      let(:headers) do
        {
          'Accept' => 'application/json',
          'Content-Type' => 'application/json'
        }
      end

      let(:body) do
        { 'tokens': %w[LPAR DIGIT], error: nil }
      end

      before do
        stub_request(:get, base_url + '/gui')
          .with(body: body_args.to_json)
          .to_return(body: body.to_json)
      end
      it
    end
  end
end
