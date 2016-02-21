require_relative "spec_helper"

describe "PDF::Core::Text" do
  before do
    class TextMock
      include PDF::Core::Text

      attr_reader :text

      def add_content(str)
        @text ||= ""
        @text << str
      end
    end
    @mock = TextMock.new
  end
  describe "character_spacing" do
    describe "called without argument" do
      before do
        @result = @mock.character_spacing
      end
      it "functions as accessor" do
        expect(@result).to eq(0)
      end
    end
    describe "called with argument" do
      before do
        @mock.character_spacing(10) do
          @mock.add_content("TEST")
        end
      end
      it "resets character_spacing to original value" do
        expect(@mock.character_spacing).to eq(0)
      end
      it "outputs correct PDF content" do
        expect(@mock.text).to eq("\n10.0 TcTEST\n0.0 Tc")
      end
    end
  end
end