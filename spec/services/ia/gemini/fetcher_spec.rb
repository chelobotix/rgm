# frozen_string_literal: true

require "rails_helper"
require "webmock/rspec"

RSpec.describe ::Ia::Gemini::Fetcher, type: :service do
  let(:message) { "<h1>Hello, world!</h1>" }
  let(:context) { ::Ia::Gemini::Contexts::PostTraductionEs.generate_context }
  let(:valid_gemini_response) do
    {
      candidates: [
        {
          content: {
            parts: [
              {
                text: { translated_html: "<p>Translated content</p>" }.to_json
              }
            ]
          }
        }
      ]
    }.to_json
  end

  describe "#call" do
    context "when request succeeds" do
      it "sets valid? to true" do
        VCR.use_cassette("ia/gemini/fetcher/success") do
          service = described_class.new(message: message, context: context)
          service.call

          expect(service.valid?).to be_truthy
          expect(service.errors).to be_nil
          expect(service.result).to eq("<h1>¡Hola, mundo!</h1>")
        end
      end
    end

    context "when request fails then succeeds on retry" do
      before do
        call_count = 0
        stub_request(:post, %r{generativelanguage\.googleapis\.com/v1beta/models/gemini-3-flash-preview:generateContent})
          .to_return do
            call_count += 1
            call_count < 2 ? { status: 500, body: "Internal error" } : { status: 200, body: valid_gemini_response }
          end
      end

      it "sets valid? to true" do
        service = described_class.new(message: message, context: context)
        service.call

        expect(service.valid?).to be_truthy
      end

      it "does not set errors" do
        service = described_class.new(message: message, context: context)
        service.call

        expect(service.errors).to be_nil
      end

      it "sets result with translated_html after retry" do
        service = described_class.new(message: message, context: context)
        service.call

        expect(service.result).to eq("<p>Translated content</p>")
      end
    end

    context "when all retries fail" do
      let(:error_stub) do
        stub_request(:post, %r{generativelanguage\.googleapis\.com/v1beta/models/gemini-3-flash-preview:generateContent})
          .to_return(status: 500, body: "Error")
      end

      before { error_stub }

      it "makes 4 attempts (1 initial + 3 retries)" do
        service = described_class.new(message: message, context: context)
        service.call

        expect(error_stub).to have_been_requested.times(4)
      end

      it "sets valid? to false" do
        service = described_class.new(message: message, context: context)
        service.call

        expect(service.valid?).to be_falsey
      end

      it "sets errors with FETCH_ERROR code" do
        service = described_class.new(message: message, context: context)
        service.call

        expect(service.errors[:code]).to eq(::Ia::Gemini::ErrorCodes::CODES[:FETCH_ERROR])
      end
    end

    context "when response has no candidates" do
      let(:empty_candidates_response) { { candidates: [] }.to_json }

      before do
        stub_request(:post, %r{generativelanguage\.googleapis\.com/v1beta/models/gemini-3-flash-preview:generateContent})
          .to_return(status: 200, body: empty_candidates_response)
      end

      it "sets valid? to false" do
        service = described_class.new(message: message, context: context)
        service.call

        expect(service.valid?).to be_falsey
      end

      it "sets errors with NO_GEMINI_CANDIDATE code" do
        service = described_class.new(message: message, context: context)
        service.call

        expect(service.errors[:code]).to eq(::Ia::Gemini::ErrorCodes::CODES[:NO_GEMINI_CANDIDATE])
      end
    end

    context "when response has blank translated_html" do
      let(:no_translated_html_response) do
        {
          candidates: [
            {
              content: {
                parts: [
                  {
                    text: { translated_html: "" }.to_json
                  }
                ]
              }
            }
          ]
        }.to_json
      end

      before do
        stub_request(:post, %r{generativelanguage\.googleapis\.com/v1beta/models/gemini-3-flash-preview:generateContent})
          .to_return(status: 200, body: no_translated_html_response)
      end

      it "sets valid? to false" do
        service = described_class.new(message: message, context: context)
        service.call

        expect(service.valid?).to be_falsey
      end

      it "sets errors with NO_GEMINI_CANDIDATE code" do
        service = described_class.new(message: message, context: context)
        service.call

        expect(service.errors[:code]).to eq(::Ia::Gemini::ErrorCodes::CODES[:NO_GEMINI_CANDIDATE])
      end
    end

    context "when response has invalid JSON in text" do
      let(:invalid_json_response) do
        {
          candidates: [
            {
              content: {
                parts: [
                  {
                    text: "not valid json"
                  }
                ]
              }
            }
          ]
        }.to_json
      end

      before do
        stub_request(:post, %r{generativelanguage\.googleapis\.com/v1beta/models/gemini-3-flash-preview:generateContent})
          .to_return(status: 200, body: invalid_json_response)
      end

      it "sets valid? to false" do
        service = described_class.new(message: message, context: context)
        service.call

        expect(service.valid?).to be_falsey
      end

      it "sets errors with PARSE_ERROR code" do
        service = described_class.new(message: message, context: context)
        service.call

        expect(service.errors[:code]).to eq(::Ia::Gemini::ErrorCodes::CODES[:PARSE_ERROR])
      end
    end

    context "when connection raises timeout" do
      before do
        stub_request(:post, %r{generativelanguage\.googleapis\.com/v1beta/models/gemini-3-flash-preview:generateContent})
          .to_raise(Net::OpenTimeout)
      end

      it "sets valid? to false" do
        service = described_class.new(message: message, context: context)
        service.call

        expect(service.valid?).to be_falsey
      end

      it "sets errors with CONNECTION_ERROR code" do
        service = described_class.new(message: message, context: context)
        service.call

        expect(service.errors[:code]).to eq(::Ia::Gemini::ErrorCodes::CODES[:CONNECTION_ERROR])
      end
    end

    context "when connection raises ECONNREFUSED" do
      before do
        stub_request(:post, %r{generativelanguage\.googleapis\.com/v1beta/models/gemini-3-flash-preview:generateContent})
          .to_raise(Errno::ECONNREFUSED)
      end

      it "sets valid? to false" do
        service = described_class.new(message: message, context: context)
        service.call

        expect(service.valid?).to be_falsey
      end

      it "sets errors with CONNECTION_ERROR code" do
        service = described_class.new(message: message, context: context)
        service.call

        expect(service.errors[:code]).to eq(::Ia::Gemini::ErrorCodes::CODES[:CONNECTION_ERROR])
      end
    end
  end
end
