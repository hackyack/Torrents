require 'spec_helper'

def rest_client(url, file = "recent")
  RestClient.should_receive(:get).with(url, {:timeout => 10}).at_least(1).times.and_return(File.read("spec/data/the_pirate_bay/#{file}.html"))
end

describe Torrents do  
  before(:each) do
    @torrents = Torrents.new
  end
  
  context "the exists? method" do
    it "should know if a tracker exists or not" do
      @torrents.exists?("the_pirate_bay").should be_true
      @torrents.exists?("random").should be_false
    end
  end
  
  context "the content method" do
    it "should return a nokogiri object" do
      @torrents.should_receive(:url).and_return("data")
      @torrents.should_receive(:download).with("data").and_return("more data")
      @torrents.content.should be_instance_of(Nokogiri::HTML::Document)
    end
  end
end