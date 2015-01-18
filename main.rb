require 'sinatra'
require 'sinatra/cross_origin'
require 'sinatra/reloader'
require 'active_record'
require 'mysql2'
require 'youtube_search'
require 'json'
require 'rexml/document'
require "cgi"
require 'kconv'

enable :cross_origin
set :bind, '0.0.0.0'

# DB設定の読み込み
ActiveRecord::Base.establish_connection(
  "adapter" => "mysql2",
  "database" => "fujirock",
  "host" => "localhost",
  "username" => "root",
  "password" => "ab1054",
  "encoding" => "utf8",
)

get '/' do
    erb :index
end

#年指定きょく
get '/yearsong/:y/:d/:list' do |y, d, list|
  cross_origin

  class Artist < ActiveRecord::Base
  end

  class Timetable < ActiveRecord::Base
  end

  result = []

  #検索用ハッシュ
  hash = {}
  if y != "all" then
    hash.store(:year, y)
  end
  if d != "all" then
    hash.store(:day, d)
  end

  until  result.length == list.to_i do
    timetable = Timetable.where(hash)
    artistid = timetable[rand(timetable.count)].artist_id
    artist = Artist.where(:id => artistid)

    query =[]
    artist.each do |data|
      #検索クエリの作成
      #ランダムに作成した数字から1ずつ引いてデータがあれば出力、０になれば終了
      num = rand(5) + 1
      until num <= 0 do
        favorite = "favorite" + num.to_s
        if data.send(favorite.to_sym) != nil then
          query = [data.name,data.send(favorite.to_sym)]
          break
        end
        num -= 1
      end
    end

    #動画IDの検索取得
    keyword = "#{query[0]} #{query[1]}"
    video = YoutubeSearch::search(keyword).first

    if video then
      unless video["title"].scan(/#{query[0]}/i).empty? then
        h = { "video_id" => video["video_id"],
              "title" => video["title"],
              "artist" => query[0],
              "artist_id" => artistid
        }
        result.push(h)
      end
    end
  end
  result.to_json
end

#stage指定
get '/stagesong/:sid/:y/:d/:list' do |sid, y, d, list|
  cross_origin

  class Artist < ActiveRecord::Base
  end

  class Timetable < ActiveRecord::Base
  end

  result = []

  #検索用ハッシュ
  hash = {}
  hash.store(:stage_id, sid)
  if y != "all" then
    hash.store(:year, y)
  end
  if d != "all" then
    hash.store(:day, d)
  end

  until  result.length == list.to_i do
    timetable = Timetable.where(hash)
    artistid = timetable[rand(timetable.count)].artist_id
    artist = Artist.where(:id => artistid)

    query =[]
    artist.each do |data|
      #検索クエリの作成
      #ランダムに作成した数字から1ずつ引いてデータがあれば出力、０になれば終了
      num = rand(5) + 1
      until num <= 0 do
        favorite = "favorite" + num.to_s
        if data.send(favorite.to_sym) != nil then
          query = [data.name,data.send(favorite.to_sym)]
          break
        end
        num -= 1
      end
    end

    #動画IDの検索取得
    keyword = "#{query[0]} #{query[1]}"
    video = YoutubeSearch::search(keyword).first

    if video then
      unless video["title"].scan(/#{query[0]}/i).empty? then
        h = { "video_id" => video["video_id"],
              "title" => video["title"],
              "artist" => query[0],
              "artist_id" => artistid
        }
        result.push(h)
      end
    end
  end
  result.to_json
end

#artist指定json
get '/artistsong/:aid/:list' do |aid, list|
  cross_origin

  class Artist < ActiveRecord::Base
  end

  query =[]
  result = []

  artist = Artist.where(:id => aid)
  artist.each do |data|
    #検索クエリの作成
    #ランダムに作成した数字から1ずつ引いてデータがあれば出力、０になれば終了
    num = 5
    until num <= 0 do
      favorite = "favorite" + num.to_s
      if data.send(favorite.to_sym) != nil then
        query = [data.name,data.send(favorite.to_sym)]

        #動画IDの検索取得
        keyword = "#{query[0]} #{query[1]}"
        video = YoutubeSearch::search(keyword).first

        if video then
          unless video["title"].scan(/#{query[0]}/i).empty? then
            h = { "video_id" => video["video_id"],
                  "title" => video["title"],
                  "artist" => query[0],
                  "artist_id" => aid
            }
            result.push(h)
          end
        end
      end
      num -= 1
    end
  end

  result.to_json
end

#年情報
get '/year/:y' do |y|
  class Artist < ActiveRecord::Base
    has_many :timetables
  end

  class Timetable < ActiveRecord::Base
    belongs_to :artist
  end
  result = []

  #検索用ハッシュ
  hash = {}
  if y != "all" then
    hash.store(:year, y)
    timetable = Timetable.where(hash).order("day asc, stage_id asc, num asc")
  else
    timetable = Timetable.all.order("year desc, day asc, stage_id asc, num asc")
  end

  timetable.each do |data|
      if data != nil then
        artist = Artist.where(:id => data.artist_id)
        h = { "year" => data.year,
              "day" => data.day,
              "stage_id" => data.stage_id,
              "order" => data.num,
              "artist_id" => data.artist_id,
              "artist_name" => artist[0].name
            }
        result.push(h)
      end
  end

  result.to_json
end

#ステージ情報
get '/stage/:sid/:y' do |sid, y|
  class Artist < ActiveRecord::Base
    has_many :timetables
  end

  class Timetable < ActiveRecord::Base
    belongs_to :artist
  end
  result = []

  #検索用ハッシュ
  hash = {}
  if y != "all" then
    hash.store(:stage_id, sid)
    hash.store(:year, y)
    timetable = Timetable.where(hash).order("day asc, num asc")
  else
    hash.store(:stage_id, sid)
    timetable = Timetable.where(hash).order("year desc, day asc, num asc")
  end

  timetable.each do |data|
      if data != nil then
        artist = Artist.where(:id => data.artist_id)
        h = { "year" => data.year,
              "day" => data.day,
              "stage_id" => data.stage_id,
              "order" => data.num,
              "artist_id" => data.artist_id,
              "artist_name" => artist[0].name
            }
        result.push(h)
      end
  end

  result.to_json
end

#アーティスト情報
get '/artist/:aid' do |aid|
  class Artist < ActiveRecord::Base
  end
  
  class Timetable < ActiveRecord::Base
  end


  result = {}
  artist = Artist.where(:id => aid)

  artist.each do |data|
    if data != nil then
      result.store(:name, data.name)
      result.store(:info, data.info)
      result.store(:aid, data.id)

      #人気曲
      favorites = []
      1.upto(5).each do |i|
        favorite = "favorite" + i.to_s
        if data.send(favorite.to_sym) != nil then
          favorites.push(data.send(favorite.to_sym))
        end
      end
      result.store(:favorite, favorites)

      #関連アーティスト検索
      similars = []
      1.upto(10).each do |i|
        sim = "similar" + i.to_s
        if data.send(sim.to_sym) != nil then
          simartist = Artist.where(:lastname => data.send(sim.to_sym))
          if simartist[0] != nil then
            similars.push([simartist[0].id, simartist[0].name])
          end
        end
      end
      result.store(:similar,similars)

      #出演年
      actyears = []
      timetable = Timetable.where(:artist_id => aid)
      timetable.each do |data|
        actyears.push(data.year)
      end
      result.store(:actyear,actyears)

      #lastfmから写真を取得
      pictures = []
      if data.lastname != nil then
      qartist = CGI.escape(Kconv.toutf8(data.lastname))
      begin
        open('http://ws.audioscrobbler.com/2.0/?method=artist.getinfo&artist='+ qartist +'&lang=jp&autocorrect=1&api_key=3b7599fb321f51cb3f6532095e85decd&format=json') do |file|
          infodoc = JSON.parse(file.read)

          if infodoc.has_key?('artist') then
            pictureurls = infodoc['artist']['image']
            pictureurls.each do |pic|
              if pic['size'] == "large" then
                pictures.push(pic['#text'])
              end
            end
          end
        end
      rescue
      end
      end
      result.store(:picture,pictures)

      #setlistfmから最新セットリストを取得
      setlists = []
      if data.mbid != "" then

        mbid = data.mbid
        begin
          open('http://api.setlist.fm/rest/0.1/artist/' + mbid + '/setlists') do |file|

              sets = REXML::Document.new(file.read)
              sets.elements.each('setlists/setlist[1]/sets/set/song') do |element|
                if element != nil then
                  setlists.push(element.attributes['name'])
                end
              end
          end          
        rescue 
        end

      end

      result.store(:setlist,setlists)

    end
  end
  result.to_json
end