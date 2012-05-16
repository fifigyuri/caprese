class OfflineCache < CapreseAction
  include ConfigHelpers

  def stop
    filename = "#{CACHE_PATH}/#{Time.now.strftime('%Y-%m-%d')}.descriptions"
    open(filename, 'a') do |file|
      file.write("#{description}\n")
    end
  end
end
