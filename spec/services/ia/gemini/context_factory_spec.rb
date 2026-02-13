# frozen_string_literal: true

require "rails_helper"

RSpec.describe ::Ia::Gemini::ContextFactory, type: :service do
  let(:dependencies_contexts) do
    {
      post_traduction_es: ::Ia::Gemini::Contexts::PostTraductionEs,
      post_traduction_pt: ::Ia::Gemini::Contexts::PostTraductionPt
    }
  end

  describe "#call" do
    context "when context_type is post_traduction_es" do
      it "succeeds" do
        service = described_class.new(
          context_type: :post_traduction_es,
          dependencies_contexts: dependencies_contexts
        )
        service.call

        expect(service.valid?).to be_truthy
        expect(service.errors).to be_nil
      end

      it "sets context with Spanish translation prompt" do
        service = described_class.new(
          context_type: :post_traduction_es,
          dependencies_contexts: dependencies_contexts
        )
        service.call

        expect(service.context).to include("Translate the provided HTML content from English to Spanish")
        expect(service.context).to include("translated_html")
      end
    end

    context "when context_type is post_traduction_pt" do
      it "succeeds" do
        service = described_class.new(
          context_type: :post_traduction_pt,
          dependencies_contexts: dependencies_contexts
        )
        service.call

        expect(service.valid?).to be_truthy
        expect(service.errors).to be_nil
      end

      it "sets context with Portuguese translation prompt" do
        service = described_class.new(
          context_type: :post_traduction_pt,
          dependencies_contexts: dependencies_contexts
        )
        service.call

        expect(service.context).to include("Translate the provided HTML content from English to Brazilian Portuguese")
        expect(service.context).to include("translated_html")
      end
    end

    context "when context_type is blank" do
      let(:context_type) { "" }

      it "sets valid? to false" do
        service = described_class.new(
          context_type: context_type,
          dependencies_contexts: dependencies_contexts
        )
        service.call

        expect(service.valid?).to be_falsey
      end

      it "sets errors with CONTEXT_TYPE_ERROR code" do
        service = described_class.new(
          context_type: context_type,
          dependencies_contexts: dependencies_contexts
        )
        service.call

        expect(service.errors[:code]).to eq(::Ia::Gemini::ErrorCodes::CODES[:CONTEXT_TYPE_ERROR])
      end
    end

    context "when context_type is nil" do
      let(:context_type) { nil }

      it "sets valid? to false" do
        service = described_class.new(
          context_type: context_type,
          dependencies_contexts: dependencies_contexts
        )
        service.call

        expect(service.valid?).to be_falsey
      end

      it "sets errors with CONTEXT_TYPE_ERROR code" do
        service = described_class.new(
          context_type: context_type,
          dependencies_contexts: dependencies_contexts
        )
        service.call

        expect(service.errors[:code]).to eq(::Ia::Gemini::ErrorCodes::CODES[:CONTEXT_TYPE_ERROR])
      end
    end

    context "when context_type is not allowed" do
      let(:context_type) { :invalid_context }

      it "sets valid? to false" do
        service = described_class.new(
          context_type: context_type,
          dependencies_contexts: dependencies_contexts
        )
        service.call

        expect(service.valid?).to be_falsey
      end

      it "sets errors with CONTEXT_TYPE_ERROR code" do
        service = described_class.new(
          context_type: context_type,
          dependencies_contexts: dependencies_contexts
        )
        service.call

        expect(service.errors[:code]).to eq(::Ia::Gemini::ErrorCodes::CODES[:CONTEXT_TYPE_ERROR])
      end
    end

    context "when using default dependencies" do
      it "succeeds for post_traduction_es" do
        service = described_class.new(context_type: :post_traduction_es)
        service.call

        expect(service.valid?).to be_truthy
        expect(service.errors).to be_nil
      end
    end
  end
end
