require 'sinatra'
require 'sinatra/cross_origin'
require 'sinatra/reloader'
require 'active_record'
require 'mysql2'
require 'youtube_search'
require 'json'
require 'rexml/document'
require 'cgi'
require 'kconv'
require 'yaml'

enable :cross_origin
set :bind, '0.0.0.0'

# DB設定の読み込み
ActiveRecord::Base.establish_connection(ENV['DATABASE_URL'] || YAML.load_file(File.join(__dir__, 'database.yml'))['development'])

#ActiveRecord設定
class Artist < ActiveRecord::Base
  has_many :timetables
end

class Timetable < ActiveRecord::Base
  belongs_to :artist
end

#Youtube情報検索メソッド
def youtube_search(aid,artistsong,seq=5)

  artist = Artist.where(:id => aid)

  #動画の検索クエリ作成
  #ランダムに作成した数字から1ずつ引いてデータがあれば出力、０になれば終了
  query =[]
  num = artistsong == true ? seq : rand(5) + 1
  favorite_song = ("favorite" + num.to_s).to_sym

  until num <= 0 do
    if artist[0].send(favorite_song)
      query = [artist[0].name, artist[0].send(favorite_song)]
      break
    end
    num -= 1
  end

  #動画IDの検索取得
  keyword = "#{query[0]} #{query[1]}"
  video = YoutubeSearch::search(keyword).first
  h = {}

  if video then
    unless video["title"].scan(/#{query[0]}/i).empty?
      h = { "video_id" => video["video_id"],
            "title" => video["title"],
            "artist" => query[0],
            "artist_id" => aid
      }
    end
  end
  return h
end

#トップ
get '/' do
    erb :index
end

#年指定での曲リスト取得
get '/yearsong/:y/:d/:list' do |y, d, list|
  result = []

  #検索用ハッシュの作成
  hash = {}
  hash.store(:year, y) unless y == "all"
  hash.store(:day, d) unless d == "all"

  timetable = Timetable.where(hash)
  timetable_count = timetable.count

  #listの数だけ曲を取得する(10回検索してだめならおわり)
  10.times do
    artistid = timetable[rand(timetable_count)].artist_id
    video = youtube_search(artistid,false) 
    unless video.empty?
      result.push(video)
    end
    break if result.length == list.to_i
  end

  result.to_json
end

#ステージ指定での曲リスト取得
get '/stagesong/:sid/:y/:d/:list' do |sid, y, d, list|
  result = []

  #検索用ハッシュ
  hash = {}
  hash.store(:stage_id, sid)
  hash.store(:year, y) unless y == "all"
  hash.store(:day, d) unless d == "all"

  timetable = Timetable.where(hash)
  timetable_count = timetable.count

  #listの数だけ曲を取得する(10回検索してだめならおわり)
  10.times do
    artistid = timetable[rand(timetable_count)].artist_id
    video = youtube_search(artistid,false) 
    unless video.empty?
      result.push(video)
    end
    break if result.length == list.to_i
  end

  result.to_json
end

#artist指定での曲リスト取得
get '/artistsong/:aid' do |aid|
  result = []

  5.downto(1) do |i|
    video = youtube_search(aid,true,i) 
    unless video.empty?
      result.push(video)
    end
  end

  result.to_json
end

#年指定で情報取得
get '/year/:y' do |y|
  result = []

  if y == "all" then
    timetable = Timetable.all.order("year desc, day asc, stage_id asc, num asc")
  else
    timetable = Timetable.where(year: y).order("day asc, stage_id asc, num asc")
  end

  timetable.each do |data|
    if data
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
  result = []

  if y == "all" then
    timetable = Timetable.where(stage_id: sid).order("year desc, day asc, num asc")
  else
    timetable = Timetable.where(stage_id: sid, year: y).order("day asc, num asc")
  end

  timetable.each do |data|
      if data
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
  result = {}
  artist = Artist.where(:id => aid)

  if artist[0] 
    result.store(:name, artist[0].name)
    result.store(:info, artist[0].info)
    result.store(:aid, artist[0].id)

    #人気曲
    favorites = []
    1.upto(5).each do |i|
      favorite = "favorite" + i.to_s
      if fsong = artist[0].send(favorite.to_sym)
        favorites.push(fsong)
      end
    end

    result.store(:favorite, favorites)

    #関連アーティスト検索
    similars = []
    1.upto(10).each do |i|
      sim = "similar" + i.to_s
      if simartist = Artist.where(:lastname => artist[0].send(sim.to_sym))
        if simartist[0]
          similars.push([simartist[0].id, simartist[0].name])
        end
      end
    end

    result.store(:similar,similars)

    #出演年
    actyears = []
    timetable = Timetable.where(:artist_id => aid)
    actyears.push(timetable[0].year)

    result.store(:actyear,actyears)

    #lastfmから写真を取得
    pictures = []
    if lname = artist[0].lastname
      qartist = CGI.escape(Kconv.toutf8(lname))
      begin 
        open('http://ws.audioscrobbler.com/2.0/?method=artist.getinfo&artist='+ qartist +'&lang=jp&autocorrect=1&api_key=3b7599fb321f51cb3f6532095e85decd&format=json') do |file|
          infodoc = JSON.parse(file.read)

          if infodoc.has_key?('artist')
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
    unless artist[0].mbid.empty? or artist[0].mbid.nil?
      mbid = artist[0].mbid
      begin
        open('http://api.setlist.fm/rest/0.1/artist/' + mbid + '/setlists') do |file|

            sets = REXML::Document.new(file.read)
            sets.elements.each('setlists/setlist[1]/sets/set/song') do |element|
              if element
                setlists.push(element.attributes['name'])
              end
            end
        end          
      rescue 
      end
    end

    result.store(:setlist,setlists)

  end
  result.to_json
end