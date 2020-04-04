# frozen_string_literal: true

require_relative '../spec_helper'

RSpec.describe HTTPRestAdapter do
  describe '#initialize' do
    let(:base_url) { 'http://localhost:4567' }
    subject { HTTPRestAdapter.new(base_url) }
    let(:path) { 'parser' }

    it 'set base_url attribute' do
      expect(subject.base_url).to eq(base_url)
    end

    context 'when attribute is not set' do
      let(:base_url) { nil }

      it 'raises an exeception' do
        expect { subject.base_url }.to raise_error(RuntimeError, 'Not base url set')
      end
    end
  end

  describe 'GET, POST requests' do
    context 'when the response was not successfully' do
      let(:base_url) { 'http://localhost:4567' }
      subject { HTTPRestAdapter.new(base_url) }

      let(:body_args) do
        { 'tokens': %w[LPAR DIGIT] }
      end

      let(:body) { nil }

      describe '#http_get' do
        before do
          stub_request(:get, base_url + '/guiZZZ')
            .with(body: body_args.to_json)
            .to_return(status: 404, body: body)
        end

        let(:response) { subject.http_get('guiZZZ', body_args) }

        it 'raises an exception' do
          expect { response }.to raise_error(RuntimeError, 'Status code was 404')
        end
      end

      describe '#http_post' do
        before do
          stub_request(:post, base_url + '/guiZ')
            .with(body: body_args.to_json)
            .to_return(status: 404, body: body)
        end

        let(:response) { subject.http_post('guiZ', body_args) }

        it 'raises an exception' do
          expect { response }.to raise_error(RuntimeError, 'Status code was 404')
        end
      end
    end

    context 'when the response was successfully' do
      let(:base_url) { 'http://localhost:4567' }
      subject { HTTPRestAdapter.new(base_url) }

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

      describe '#http_get' do
        before do
          stub_request(:get, base_url + '/gui')
            .with(body: body_args.to_json)
            .to_return(body: body.to_json, headers: headers)
        end

        let(:response) { subject.http_get('gui', body_args) }

        it 'returns expected body hash' do
          expect(response.body).to eq(body.to_json)
        end

        it 'returns OK status code' do
          expect(response.code).to eq(200)
        end

        it 'returns expected headers hash' do
          expect(response.headers).to eq(headers)
        end
      end

      describe '#http_post' do
        before do
          stub_request(:post, base_url + '/gui')
            .with(body: body_args.to_json)
            .to_return(body: body.to_json, headers: headers)
        end

        let(:response) { subject.http_post('gui', body_args) }

        it 'returns expected body hash' do
          expect(response.body).to eq(body.to_json)
        end

        it 'returns OK status code' do
          expect(response.code).to eq(200)
        end

        it 'returns expected headers hash' do
          expect(response.headers).to eq(headers)
        end
      end
    end
  end
end
