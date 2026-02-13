# frozen_string_literal: true

require "rails_helper"

RSpec.describe ::Ia::Gemini::Validator, type: :service do
  let(:message) { "Translate this text" }
  let(:context_type) { :post_traduction_es }

  before do
    allow(ENV).to receive(:fetch).with("GEMINI_API_KEY").and_return("test_api_key")
    allow(ENV).to receive(:fetch).with("GEMINI_BASE_URL").and_return("https://generativelanguage.googleapis.com")
  end

  describe "#call" do
    context "when all validations pass" do
      it "sets valid? to true" do
        service = described_class.new(message: message, context_type: context_type)
        service.call

        expect(service.valid?).to be_truthy
      end

      it "does not set errors" do
        service = described_class.new(message: message, context_type: context_type)
        service.call

        expect(service.errors).to be_nil
      end
    end

    context "when message is invalid" do
      context "with blank message" do
        let(:message) { "" }

        it "sets valid? to false" do
          service = described_class.new(message: message, context_type: context_type)
          service.call

          expect(service.valid?).to be_falsey
        end

        it "sets errors with MESSAGE_ERROR code" do
          service = described_class.new(message: message, context_type: context_type)
          service.call

          expect(service.errors[:code]).to eq(::Ia::Gemini::ErrorCodes::CODES[:MESSAGE_ERROR])
        end
      end

      context "with nil message" do
        let(:message) { nil }

        it "sets valid? to false" do
          service = described_class.new(message: message, context_type: context_type)
          service.call

          expect(service.valid?).to be_falsey
        end

        it "sets MESSAGE_ERROR in errors" do
          service = described_class.new(message: message, context_type: context_type)
          service.call

          expect(service.errors[:code]).to eq(::Ia::Gemini::ErrorCodes::CODES[:MESSAGE_ERROR])
        end
      end

      context "when message is not a String" do
        let(:message) { 123 }

        it "sets valid? to false" do
          service = described_class.new(message: message, context_type: context_type)
          service.call

          expect(service.valid?).to be_falsey
        end

        it "sets MESSAGE_ERROR in errors" do
          service = described_class.new(message: message, context_type: context_type)
          service.call

          expect(service.errors[:code]).to eq(::Ia::Gemini::ErrorCodes::CODES[:MESSAGE_ERROR])
        end
      end
    end

    context "when context_type is invalid" do
      context "with blank context_type" do
        let(:context_type) { "" }

        it "sets valid? to false" do
          service = described_class.new(message: message, context_type: context_type)
          service.call

          expect(service.valid?).to be_falsey
        end

        it "sets errors with CONTEXT_TYPE_ERROR code" do
          service = described_class.new(message: message, context_type: context_type)
          service.call

          expect(service.errors[:code]).to eq(::Ia::Gemini::ErrorCodes::CODES[:CONTEXT_TYPE_ERROR])
        end
      end

      context "with nil context_type" do
        let(:context_type) { nil }

        it "sets valid? to false" do
          service = described_class.new(message: message, context_type: context_type)
          service.call

          expect(service.valid?).to be_falsey
        end

        it "sets CONTEXT_TYPE_ERROR in errors" do
          service = described_class.new(message: message, context_type: context_type)
          service.call

          expect(service.errors[:code]).to eq(::Ia::Gemini::ErrorCodes::CODES[:CONTEXT_TYPE_ERROR])
        end
      end

      context "when context_type is not a Symbol" do
        let(:context_type) { "post_traduction_es" }

        it "sets valid? to false" do
          service = described_class.new(message: message, context_type: context_type)
          service.call

          expect(service.valid?).to be_falsey
        end

        it "sets CONTEXT_TYPE_ERROR in errors" do
          service = described_class.new(message: message, context_type: context_type)
          service.call

          expect(service.errors[:code]).to eq(::Ia::Gemini::ErrorCodes::CODES[:CONTEXT_TYPE_ERROR])
        end
      end
    end

    context "when API key is invalid" do
      before do
        allow(ENV).to receive(:fetch).with("GEMINI_API_KEY").and_return("")
      end

      it "sets valid? to false" do
        service = described_class.new(message: message, context_type: context_type)
        service.call

        expect(service.valid?).to be_falsey
      end

      it "sets errors with API_KEY_ERROR code" do
        service = described_class.new(message: message, context_type: context_type)
        service.call

        expect(service.errors[:code]).to eq(::Ia::Gemini::ErrorCodes::CODES[:API_KEY_ERROR])
      end
    end

    context "when base URL is invalid" do
      before do
        allow(ENV).to receive(:fetch).with("GEMINI_BASE_URL").and_return("")
      end

      it "sets valid? to false" do
        service = described_class.new(message: message, context_type: context_type)
        service.call

        expect(service.valid?).to be_falsey
      end

      it "sets errors with BASE_URL_ERROR code" do
        service = described_class.new(message: message, context_type: context_type)
        service.call

        expect(service.errors[:code]).to eq(::Ia::Gemini::ErrorCodes::CODES[:BASE_URL_ERROR])
      end
    end

    context "when multiple validations fail" do
      let(:message) { nil }
      let(:context_type) { nil }

      it "fails on first validation (message)" do
        service = described_class.new(message: message, context_type: context_type)
        service.call

        expect(service.valid?).to be_falsey
        expect(service.errors[:code]).to eq(::Ia::Gemini::ErrorCodes::CODES[:MESSAGE_ERROR])
      end
    end

    context "errors structure" do
      let(:message) { "" }

      it "includes service class in errors" do
        service = described_class.new(message: message, context_type: context_type)
        service.call

        expect(service.errors[:service]).to eq(Ia::Gemini::Validator)
      end
    end
  end
end
