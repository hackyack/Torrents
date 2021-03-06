require 'spec_helper'

describe Container::Shared do
  before(:each) do
    @shared = Container::Shared.new
  end
  context "the download method" do
    def rest_client(data = "123")
      RestClient.should_receive(:get).with("http://example.com", {:timeout => 10, :cookies => nil}).exactly(1).times.and_return(data)
    end
    
    def char_det(encoding, confidence)
      CharDet.should_receive(:detect).with("123", silent: true).and_return(Struct.new(:encoding, :confidence).new(encoding, confidence))
    end
    
    it "should return an empty string when trying to download an empty or non valid URL" do
      @shared.download("non_working_url").should be_empty
      @shared.download(nil).should be_empty
    end

    it "should return the content of the site if called with the right url" do
      rest_client
      @shared.download("http://example.com").should eq("123")
    end
    
    it "should return an empty string when the confidence level is to low. encoding = Latin 1" do
      rest_client; char_det("Latin 1", 0.6)
      @shared.download("http://example.com").should be_empty
    end
    
    it "should not return an empty string when the confidence level is to low. encoding = UTF8" do
      rest_client; char_det("UTF8", 0.6)
      @shared.download("http://example.com").should eq("123")
    end
    
    it "should not return an empty string when the confidence level is okey. encoding = UTF-8" do
      rest_client; char_det("UTF-8", 0.9)
      @shared.download("http://example.com").should eq("123")
    end
    
    it "should try to encode the string if the confidence level is okey and the string isn't UTF8" do
      rest_client("123"); char_det("Latin 1", 0.9)
      Iconv.should_receive(:conv).with("Latin 1//IGNORE", "UTF-8", "123").and_return("my value")
      @shared.download("http://example.com").should eq("my value")
    end
  end  
  
  context "the error method" do
    it "should have a error method" do
      lambda {
        @shared.error("some message")
        @shared.error("some message", "other")
      }.should_not raise_error(Exception)
    end
  end
  
  context "the inner_call" do
    before(:each) do
      @load = mock(Object)
    end
    
    it "should call an example method with no arguments" do
      @shared.should_receive(:load).and_return(@load)
      @load.should_receive(:example).with.and_return("value") # No arguments
      @shared.inner_call(:example).should eq("value")
    end
    
    it "should call an example method with arguments" do
      @shared.should_receive(:load).and_return(@load)
      @load.should_receive(:example).with("abc").and_return("value") # No arguments
      @shared.inner_call(:example, "abc").should eq("value")
    end
    
    it "should call an example and rescue an exception" do
      @shared.should_receive(:load).and_return(lambda{
        raise NoMethodError.new
      })
      
      @shared.should_receive(:error)
      @shared.should_receive(:default_values).with(:call).and_return("error")
      @shared.inner_call(:call).should eq("error")
    end
    
    it "should only catch NoMethodError exception" do
      lambda {
        @shared.should_receive(:load).and_return(lambda{
          raise Exception.new
        })

        @shared.inner_call(:call).should eq("error")
      }.should raise_error(Exception)
    end
  end
  
  context "the default_values method" do
    it "should return the right value" do
      {torrent: "", torrents: [], seeders: 1, title: "", details: ""}.each do |method, value|
        @shared.default_values(method).should eq(value)
      end
    end
    
    it "should return an empty string if the value isn't in the hash" do
      @shared.default_values(:random).should eq("")
    end
  end
  
  context "the load method" do
    before(:all) do
      class Test < Container::Shared
        def initialize
          @tracker = "the_pirate_bay"
        end
      end
    end
    it "should create a new instance of any string" do
      Test.new.load.should be_instance_of(Trackers::ThePirateBay)
    end
  end
  
  context "the url_cleaner method" do
    # Read more about the cleaner here
    # http://stackoverflow.com/questions/4999322/escape-and-download-url-using-ruby
    it "should be able to clean urls" do
      list = {}
      ["{", "}", "|", "\\", "^", "[", "]", "`", " a"].each do |c|
        list.merge!("http://google.com/#{c}" => "http://google.com/#{CGI::escape(c)}")
      end
      
      list.each do |url, clean|
        lambda {
          URI.parse(url)
        }.should raise_error(URI::InvalidURIError)
        
        lambda {
          URI.parse(@shared.url_cleaner(url)).to_s.should eq(clean)
        }.should_not raise_error(URI::InvalidURIError)
      end
    end
  end
end