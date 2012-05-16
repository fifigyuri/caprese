require File.expand_path("../spec_helper", File.dirname(__FILE__))

describe OfflineCache do

  before do
    @action = OfflineCache.new([])
    current_path =
      Pathname.new(File.expand_path('../..', File.dirname(__FILE__)))
    CACHE_PATH = "#{current_path}/test_offline_cache"
    FileUtils.mkdir CACHE_PATH 
  end

  after do
    FileUtils.rm_r CACHE_PATH 
  end

  it 'should append cache with the finished pomodoro task' do
    open("#{CACHE_PATH}/2012-03-26.descriptions", 'w') do |file|
      file.write("bed/rest: deep sleeping\n")
    end
    Time.stub now: Time.new(2012, 3, 26, 15, 24)
    @action.stub description: 'kitchen/cook: tomato soup'
    @action.stop
    open("#{CACHE_PATH}/2012-03-26.descriptions", 'r') do |file|
      lines = file.readlines
      lines.count.should == 2
      lines.last.should == "kitchen/cook: tomato soup\n"
    end
  end
end
