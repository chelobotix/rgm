# frozen_string_literal: true

require "rails_helper"
require "webmock/rspec"

RSpec.describe ::Ia::Gemini::Base, type: :service do
  let(:message) { "<h1>Hello, world!</h1>" }
  let(:context_type) { :post_traduction_es }
  let(:validator_service) { instance_double(Ia::Gemini::Validator) }
  let(:context_factory_service) { instance_double(Ia::Gemini::ContextFactory) }
  let(:fetcher_service) { instance_double(Ia::Gemini::Fetcher) }

  describe "#call" do
    context "when full flow succeeds (integration)" do
      it "succeeds" do
        VCR.use_cassette("ia/gemini/fetcher/success") do
          service = described_class.new(message: message, context_type: context_type)
          service.call

          expect(service.valid?).to be_truthy
          expect(service.errors).to be_nil
        end
      end

      it "sets result with translated content" do
        VCR.use_cassette("ia/gemini/fetcher/success") do
          service = described_class.new(message: message, context_type: context_type)
          service.call

          expect(service.result).to eq("<h1>¡Hola, mundo!</h1>")
        end
      end
    end

    context "when fetcher fails after retries (integration)" do
      it "fails" do
        VCR.use_cassette("ia/gemini/fetcher/failure") do
          service = described_class.new(message: message, context_type: context_type)
          service.call

          expect(service.valid?).to be_falsey
        end
      end

      it "sets errors with FETCH_ERROR code" do
        VCR.use_cassette("ia/gemini/fetcher/failure") do
          service = described_class.new(message: message, context_type: context_type)
          service.call

          expect(service.errors[:code]).to eq(::Ia::Gemini::ErrorCodes::CODES[:FETCH_ERROR])
        end
      end

      it "does not set result" do
        VCR.use_cassette("ia/gemini/fetcher/failure") do
          service = described_class.new(message: message, context_type: context_type)
          service.call

          expect(service.result).to be_nil
        end
      end
    end

    context "when validator is the failing dependency" do
      let(:error_code) { ::Ia::Gemini::ErrorCodes::CODES[:API_KEY_ERROR] }

      before do
        allow(Ia::Gemini::Validator).to receive(:new).and_return(validator_service)
        allow(validator_service).to receive(:call)
        allow(validator_service).to receive(:valid?).and_return(false)
        allow(validator_service).to receive(:errors).and_return({ code: error_code })

        allow(Ia::Gemini::ContextFactory).to receive(:new).and_return(context_factory_service)
        allow(context_factory_service).to receive(:call)
      end
      it "fails" do
        service = described_class.new(message: message, context_type: context_type)
        service.call

        expect(service.valid?).to be_falsey
        expect(service.errors[:code]).to eq(error_code)
      end

      it "does not set result" do
        service = described_class.new(message: message, context_type: context_type)
        service.call

        expect(service.result).to be_nil
      end

      it "does not call context_factory" do
        service = described_class.new(message: message, context_type: context_type)
        service.call

        expect(context_factory_service).not_to have_received(:call)
      end
    end

    context "when context_factory is the failing dependency" do
      let(:error_code) { ::Ia::Gemini::ErrorCodes::CODES[:CONTEXT_TYPE_ERROR] }
      let(:context_factory_errors) { { code: error_code } }

      before do
        allow(Ia::Gemini::Validator).to receive(:new).and_return(validator_service)
        allow(validator_service).to receive(:call)
        allow(validator_service).to receive(:valid?).and_return(true)

        allow(Ia::Gemini::ContextFactory).to receive(:new).and_return(context_factory_service)
        allow(context_factory_service).to receive(:call)
        allow(context_factory_service).to receive(:valid?).and_return(false)
        allow(context_factory_service).to receive(:errors).and_return(context_factory_errors)

        allow(Ia::Gemini::Fetcher).to receive(:new).and_return(fetcher_service)
        allow(fetcher_service).to receive(:call)
      end

      it "fails" do
        service = described_class.new(message: message, context_type: context_type)
        service.call

        expect(service.valid?).to be_falsey
        expect(service.errors[:code]).to eq(error_code)
      end

      it "does not set result" do
        service = described_class.new(message: message, context_type: context_type)
        service.call

        expect(service.result).to be_nil
      end

      it "does not call fetcher" do
        service = described_class.new(message: message, context_type: context_type)
        service.call

        expect(fetcher_service).not_to have_received(:call)
      end
    end

    context "when fetcher is the failing dependency" do
      let(:error_code) { ::Ia::Gemini::ErrorCodes::CODES[:FETCH_ERROR] }

      before do
        allow(Ia::Gemini::Validator).to receive(:new).and_return(validator_service)
        allow(validator_service).to receive(:call)
        allow(validator_service).to receive(:valid?).and_return(true)

        allow(Ia::Gemini::ContextFactory).to receive(:new).and_return(context_factory_service)
        allow(context_factory_service).to receive(:call)
        allow(context_factory_service).to receive(:valid?).and_return(true)
        allow(context_factory_service).to receive(:context).and_return("fake context")

        allow(Ia::Gemini::Fetcher).to receive(:new).and_return(fetcher_service)
        allow(fetcher_service).to receive(:call)
        allow(fetcher_service).to receive(:valid?).and_return(false)
        allow(fetcher_service).to receive(:errors).and_return({ code: error_code })
      end

      it "fails" do
        service = described_class.new(message: message, context_type: context_type)
        service.call

        expect(service.valid?).to be_falsey
        expect(service.errors[:code]).to eq(error_code)
      end

      it "does not set result" do
        service = described_class.new(message: message, context_type: context_type)
        service.call

        expect(service.result).to be_nil
      end
    end
  end
end
