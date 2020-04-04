# frozen_string_literal: true

require_relative '../spec_helper'

RSpec.describe HTTPRestAdapter do
  describe '#initialize' do
    let(:base_url) { 'http://localhost:4567' }
    subject { base_url }

    context 'when request successful' do
      let(:path) { 'parser' }

      it ''
    end
  end

  describe '#http_post' do
  end
end
