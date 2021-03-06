# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Slack::Web::Faraday::Response::RaiseError do
  subject(:raise_error_obj) { described_class.new }

  describe '#on_complete' do
    let(:status) { 200 }
    let(:response) { nil }
    let(:body) { {} }
    let(:env) { double status: status, response: response, body: body }

    context 'with status of 429' do
      let(:status) { 429 }

      it 'raises a TooManyRequestsError' do
        expect { raise_error_obj.on_complete(env) }.to(
          raise_error(Slack::Web::Api::Errors::TooManyRequestsError)
        )
      end
    end

    context 'with an ok payload in the body' do
      let(:body) { { 'ok' => 'true' } }

      it 'is nil' do
        expect(raise_error_obj.on_complete(env)).to eq nil
      end
    end

    context 'with a single error in the body' do
      let(:body) { { 'error' => 'already_in_channel' } }

      it 'raises a SlackError with the error message' do
        expect { raise_error_obj.on_complete(env) }.to(
          raise_error(Slack::Web::Api::Errors::SlackError, 'already_in_channel')
        )
      end
    end

    context 'with multiple errors in the body' do
      let(:body) do
        {
          'errors' => [
            { 'error' => 'already_in_channel' },
            { 'error' => 'something_else_terrible' }
          ]
        }
      end

      it 'raises a SlackError with the concatenated error messages' do
        expect { raise_error_obj.on_complete(env) }.to(
          raise_error(
            Slack::Web::Api::Errors::SlackError,
            'already_in_channel,something_else_terrible'
          )
        )
      end
    end

    context 'with non-JSON response body' do
      let(:body) do
        '<!DOCTYPE html> <html lang="en"> <head> <meta charset="utf-8"> <title>Server Error | Slack</title> <meta name="author" content="Slack"> etc.'
      end

      it 'raises a Slack-domain error' do
        expect { subject.on_complete(env) }.to raise_error(Slack::Web::Api::Errors::SlackError)
      end
    end
  end
end
