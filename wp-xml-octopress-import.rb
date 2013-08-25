require 'fileutils'
require 'date'
require 'yaml'
require 'rexml/document'
require 'ya2yaml'

include REXML

doc = Document.new(File.new(ARGV[0]))

FileUtils.rmdir "_posts"
FileUtils.mkdir_p "_posts"

doc.elements.each("rss/channel/item[wp:status = 'publish' and wp:post_type = 'post']") do |e|
  p e.elements['wp:post_name'].text
  post = e.elements
  wordpress_id = post['wp:post_id'].text
  slug = post['wp:post_name'].text
  date = DateTime.parse(post['wp:post_date'].text)
  name = "%02d-%02d-%02d-%s.markdown" % [date.year, date.month, date.day, slug]
  date_string = "#{date.year}-#{date.month}-#{date.day}"
  title_string = post['title'].text




  # convert all tags and categories into categories
  categories = []
  post.each('category') do |cat|
    categories << cat.text
  end


  content = post['content:encoded'].text.encode("UTF-8")

  content = content.gsub(/"(.*?)"\s*:\s*"(.*?[\S]+)"/, '[\1](\2)')
  content = content.gsub(/"(.*?)"\s*:\s*(.*?[\S]+)/, '[\1](\2)')

  # convert <code></code> blocks to {% ``` %}{% encodebloc %}
  #content = content.gsub(/<code>(.*?)<\/code>/, '`\1`')
  content = content.gsub(/<code>/, '{% codeblock %}')
  content = content.gsub(/<\/code>/, '{% endcodeblock %}')

  content = content.gsub(/\[cci\]/, '{% codeblock %}')
  content = content.gsub(/\[cci lang="([^"]*)"\]/, '{% codeblock lang:\1 %}')
  content = content.gsub(/\[cci lang='([^"]*)'\]/, '{% codeblock lang:\1 %}')
  content = content.gsub(/\[\/cci\]/, '{% endcodeblock %}')

  content = content.gsub(/@(.*+)@/, '`\1`')

  # convert <pre></pre> blocks to {% ``` %}{% encodebloc %}
  #content = content.gsub(/<pre lang="([^"]*)">(.*?)<\/pre>/m, '`\1`')
  content = content.gsub(/<pre>/, '{% codeblock %}')
  content = content.gsub(/<pre lang="([^"]*)">/, '{% codeblock ruby %}')
  content = content.gsub(/<\/pre>/m, '{% endcodeblock %}')

  content = content.gsub(/\[cc\]/, "```")
  content = content.gsub(/\[cc lang="([^"]*)"\]/, '``` \1')
  content = content.gsub(/\[cc lang='([^"]*)'\]/, '``` \1')
  content = content.gsub(/\[\/cc\]/, '```')


  content = content.gsub(/h1\.\s+/, '# ')
  content = content.gsub(/h2\.\s+/, '## ')
  content = content.gsub(/h3\.\s+/, '### ')
  content = content.gsub(/h4\.\s+/, '#### ')

  # convert headers
  (1..3).each do |i|
    content = content.gsub(/<h#{i}>([^<]*)<\/h#{i}>/, ('#'*i) + ' \1')
  end

  puts "Converting: #{name}"

  data = {
    'layout' => 'post',
    'title' => post['title'].text,
    'date' => date_string,
    'comments' => true,
    'categories' => categories,
  }.delete_if { |k,v| v.nil? || v == ''}.to_yaml

  File.open("_posts/#{name}", "w") do |f|
    f.puts data
    f.puts "---"
    f.puts content
  end

end
