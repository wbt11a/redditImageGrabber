require 'rubygems'
require 'selenium-webdriver'
require 'down'
require 'fileutils'

SUBREDDIT="EarthPorn"
DATADIR='./downloads'
SCROLL_LENGTH = 10
OPTIONS = Selenium::WebDriver::Chrome::Options.new(
  args: ['--headless', '--disable-gpu', 'window-size=1280x800', 'user-data-dir='+DATADIR]
)

def testPreviewString(myString)

  if myString.match(/https:\/\/preview.redd.it\/\w+.jpg/)
    puts "Found! #{myString}"
    #download file
    downloadFile(myString)
  end

end

def downloadFile(myFile)

  filename = myFile.split("jpg")[0].split("/")[-1] + "jpg"
  webUrl = myFile.split("jpg?")[0] + "jpg"
  webUrl.sub!('preview','i')
  secretKey = myFile.split("&s=")[1].to_s

  savedFile = File.join(DATADIR, filename)
  puts "Checking #{File.join(DATADIR,savedFile)}"

  if File.exist?(savedFile)
    puts "Duplicate found #{savedFile}"
  else
    puts "Downloading #{webUrl}?&s=#{secretKey}"
    tempFile = Down.download(webUrl)
    puts "Moving tempFile val: #{tempFile.path.to_s} to #{savedFile}"

    FileUtils.cp(tempFile.path, savedFile)

  end

end


begin

  Selenium::WebDriver::Chrome::Service.driver_path = '/usr/local/bin/chromedriver'
  driver = Selenium::WebDriver.for :chrome, options: OPTIONS
  
  
  driver.navigate.to('https://reddit.com/r/'+SUBREDDIT)

  counter = 1
  myElements = []

  while counter <= SCROLL_LENGTH do
    puts "Scroll count: #{counter}"
    myElements = driver.find_elements(:tag_name, "img")
    scrollHeight = driver.execute_script("return document.documentElement.scrollHeight").to_i
    driver.execute_script("window.scrollTo(0, document.body.scrollHeight);")

    while ( scrollHeight == driver.execute_script("return document.documentElement.scrollHeight").to_i)
      sleep(2)
    end


    counter+=1
  end

  myElements.uniq!
  puts "Found #{myElements.count.to_s} images."

  myElements.each do |myEle|
    next if myEle.attribute("src") == nil || myEle.attribute("src").to_s.empty?
    puts testPreviewString(myEle.attribute("src"))
  end

ensure
  driver.quit
end



