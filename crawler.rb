require 'open-uri'
require 'nokogiri'


class ITownCrawler

  @@default_path = 'http://itp.ne.jp/genre_dir/'
  @@name_count_per_page = 20

  def initialize
    @parser = ITownParser.new(@@name_count_per_page)
  end

  def get_corporation_name_list(genre)

    page_count = 0
    name_list = []
    loop do
      page_count += 1
      url = analyze_url(genre, page_count)
      html, charset = access(url)
      names = @parser.parse(html, charset)
      #p names
      break if names.length == 0
      break if page_count == 3
      p_progress page_count * @@name_count_per_page
      #if page_count % 2 == 0
      name_list.concat names
    end
    return name_list
  end

  def analyze_url(genre, page_count)
    return @@default_path + genre + '/pg/'+page_count.to_s+'/?num=' + @@name_count_per_page.to_s
  end

  def p_progress(count)
    message = "#{count} so far"
    print message
    print "\e[#{message.size}D"
    STDOUT.flush
  end

private
  def access(url)

    charset = nil
    html = open(url) do |f|
      charset = f.charset # 文字種別を取得
      f.read # htmlを読み込んで変数htmlに渡す
    end
    #sleep 1

    return  html, charset
  end

end


class ITownParser

  def initialize(name_count_per_page)
    @name_count = name_count_per_page
  end
  def parse(html, charset)
    results = []
    doc = Nokogiri::HTML.parse(html, nil, charset)
    (1..@name_count).each do |count|
      xpath_obj = doc.xpath("//*[@id='wrapAllInside']/div/div[2]/div/div[2]/div[#{count.to_s}]/article/section/h4/a")
      break if xpath_obj.length == 0
      results << xpath_obj.text()
    end
    results
  end

end

#html, charset = ITownCrawler.new.access('http://itp.ne.jp/genre_dir/medical/pg/3/?num=20')

#p ITownParser.new(20).parse(html, charset)


def load_genre_list()
  File.open('./genre_list')
end

def to_file(name_list, genre)
  File.open("#{genre}.txt", "w") do |file|
    name_list.each do |name|
      file.write name + "\n"
    end
  end
end
genre_list = load_genre_list()
name_list = []
genre_list.each do  |genre|
  p "start #{genre.chomp}"
  name_list = ITownCrawler.new.get_corporation_name_list(genre.chomp)
  to_file(name_list, genre.chomp)
end
