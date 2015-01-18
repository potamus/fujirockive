var playertype = "all";
var listurl ="";
var req;

jQuery(function($) {
    $("a.botan").click(function(){
      $("#player").prependTo("footer");
    });

    $("#player").hide();

    $("#next").click(function(){
        changePlaylist();
    });

    $("ul.year li a").click(function(){
        var url = "http://192.168.33.10:4567/year/" + this.id;
        describe(url,1);
    });

    $("ul.stage li a").click(function(){
        var url = "http://192.168.33.10:4567/stage/"+ $(this).parent().parent().attr('id') + "/" + this.id;
        describe(url,2);
    });

    $("#timetable").on('click','a.artist',function(){
        var url = "http://192.168.33.10:4567/artist/" + this.id;
        describeArtist(url);
    });

    $("#timetable").on('click','a.year',function(){
        var url = "http://192.168.33.10:4567/year/" + this.id;
        describe(url,1);
    });

    $("#playinginfo").on('click','a.artist',function(){
        var url = "http://192.168.33.10:4567/artist/" + this.id;
        describeArtist(url);
    });

    //----年ごと再生イベント----------------------------------
    //年指定
    $('#timetable').on('click','h1.year a',function(){
      $("#player").fadeOut();            
      $("#loading").fadeIn();
       $("div#playinginfo div.row").fadeOut();
     stopVideo();
      req.abort();
      video_list = [];
      index = 0;
      html = "";
      changeListurl("year",this.id,"all","all","");
      get_list(listurl,2,function(){
        $("#player").fadeIn();
        $("#loading").hide();
        play();
        get_list(listurl,3);
      });
    });

    //年,日付指定
    $('#timetable').on('click','h2.day a',function(){
      $("#player").fadeOut();            
      $("#loading").fadeIn();
       $("div#playinginfo div.row").fadeOut();
     stopVideo();
      var spliter
      req.abort();
      video_list = [];
      index = 0;
      html = "";

      spliter = this.id.split("_");
      changeListurl("year",spliter[0],spliter[1],"all","");
      get_list(listurl,2,function(){
        $("#player").fadeIn();
        $("#loading").hide();
        play();
        get_list(listurl,3);
      });
    });

    //年,日付,ステージ指定
    $('#timetable').on('click','h3.stage a',function(){
      $("#player").fadeOut();            
      $("#loading").fadeIn();
      $("div#playinginfo div.row").fadeOut();
     stopVideo();
      var spliter
      req.abort();
      video_list = [];
      index = 0;
      html = "";

      spliter = this.id.split("_");
      changeListurl("stage",spliter[0],spliter[1],spliter[2],"");
      get_list(listurl,2,function(){
        $("#player").fadeIn();
        $("#loading").hide();
        play();
        get_list(listurl,3);
      });
    });
    //----------------------------------------------------

    //----ステージごと再生イベント----------------------------
    //年指定
    $('#timetable').on('click','h1.stageyear a',function(){
      $("#player").fadeOut();            
      $("#loading").fadeIn();
      $("div#playinginfo div.row").fadeOut();

      stopVideo();
      var spliter
      req.abort();
      video_list = [];
      index = 0;
      html = "";

      spliter = this.id.split("_");
      changeListurl("stage",spliter[1],"all",spliter[0],"");
      get_list(listurl,2,function(){
        $("#player").fadeIn();
        $("#loading").hide();
        play();
        get_list(listurl,3);
      });
    });

    //年、日付指定
    $('#timetable').on('click','h2.stageday a',function(){
      $("#player").fadeOut();            
      $("#loading").fadeIn();
      $("div#playinginfo div.row").fadeOut();

      stopVideo();
      var spliter
      req.abort();
      video_list = [];
      index = 0;
      html = "";

      spliter = this.id.split("_");
      changeListurl("stage",spliter[0],spliter[2],spliter[1],"");
      get_list(listurl,2,function(){
        $("#player").fadeIn();
        $("#loading").hide();
        play();
        get_list(listurl,3);
      });
    });
    //----------------------------------------------------

    //アーティスト再生---------------------------------------
    $('#timetable').on('click','h1 a.artist',function(){
      $("#player").fadeOut();            
      $("#loading").fadeIn();
      $("div#playinginfo div.row").fadeOut();

      stopVideo();
      var spliter
      req.abort();
      video_list = [];
      index = 0;
      html = "";

      changeListurl("artist","","","",this.id);
      get_list(listurl,2,function(){
        $("#player").fadeIn();
        $("#loading").hide();
        play();
        get_list(listurl,3);
      });
    });
    //---------------------------------------------------- 
});

var tag = document.createElement('script');
tag.src = "https://www.youtube.com/iframe_api";
var firstScriptTag = document.getElementsByTagName('script')[0];
firstScriptTag.parentNode.insertBefore(tag, firstScriptTag);

var video_list = []; 
var index = 0;
var html = "";

var player;
function onYouTubeIframeAPIReady() {
  player = new YT.Player('player', {
  events: {
      'onReady': onPlayerReady,
      'onStateChange': onPlayerStateChange,
      'onError': onErrorState
    }
  });
}

function describe(url,id){

  var html = "";
  var flg = 0;
  $("div#timetable").fadeOut(500,function(){
    $(this).empty();
    flg += 1;
  });

  $.getJSON(url, function(json){
    for(var i in json){

      //h1要素編集
      if( i == 0 || (i >= 1 && json[i-1].year != json[i].year) ){
          if (i != 0){
            html += '</ul></div></div>'
          }
          if (id == 2){
            html += '<h1 class="stageyear">' + getStagename(json[i].stage_id) + " "
            html += json[i].year +' <a id="' +json[i].stage_id + '_' + json[i].year + '" href="#">';
          }else{
            html += '<h1 class="year">' + json[i].year +' <a id="' + json[i].year + '" href="#">';
          }
          html += '<span class="glyphicon glyphicon-play-circle" aria-hidden="true"></span></a></h1>';
          html += '<hr>';    
      }

      //h2要素編集
      if( i == 0 || (i >= 1 && json[i-1].day != json[i].day) ){
          if (i != 0 && json[i].year == json[i-1].year){
            html += '</ul></div></div>'
          }
          if (id == 2){
            html += '<h2 class="stageday">Day' + json[i].day +' <a id="' + json[i].year + '_' + json[i].stage_id + '_' + json[i].day + '" href="#">';
          }else{
            html += '<h2 class="day">Day' + json[i].day +' <a id="' + json[i].year + '_' + json[i].day + '" href="#">';
          }
          html += '<span class="glyphicon glyphicon-play-circle" aria-hidden="true"></span></a></h2>';
          html += '<div class="row">';

          //ステージごとのとき
          if (id == 2){
            if (i != 0 && json[i].day == json[i-1].day){
              html += '</div>'
            }
            html += '<div class="col-md-3 col-sm-4">';
            html += '<ul class="list-unstyled artist">';
          }
      }

      //h3要素編集
      if( (i == 0 && id == 1)|| (i >= 1 && json[i-1].stage_id != json[i].stage_id) ){
          if (i != 0 && json[i].day == json[i-1].day){
            html += '</div>';
          }
          html += '<div class="col-md-3 col-sm-4">';
          html += '<h3 class="stage ' + getStagename(json[i].stage_id) + '">' + getStagename(json[i].stage_id) + '<a id="' + json[i].year + '_' + json[i].day + '_' + json[i].stage_id + '" href="#">';
          html += ' <span class="glyphicon glyphicon-play-circle" aria-hidden="true"></span></a></h3>';
          html += '<ul class="list-unstyled artist">';
      }
      html += '<li><a href="#" class="artist" id="' + json[i].artist_id + '">' + json[i].artist_name + '</a></h5></li>';
    }
    html += '</ul></div></div><hr><footer><p>&copy; Company 2014</p></footer>';
    flg += 1;
  });

  function show(){
    if( flg == 2) {
      $("div#timetable").html(html);
      $("div#timetable").fadeIn(1000);             
    } else {
      setTimeout( function() {
        show();
      }, 200 );
    }
  }
  show();
}

function describeArtist(url){
  var html = "";
  var flg = 0;
  var imageurl = "./img/load.gif";
  $("div#timetable").fadeOut(500,function(){
    $(this).empty();
    flg += 1;
  });

  $.getJSON(url, function(json){
    var imageurl = "./img/notfound.jpg";
    html += '<h1>' + json.name + ' <a class="artist" id="' + json.aid + '"><span class="glyphicon glyphicon-play-circle " aria-hidden="true"></span></a></h1><hr>';
    html += '<div class="row"><div class="col-sm-2 col-xs-12">';
    if(json.picture != null){
     imageurl = json.picture; 
    }
    html += '<img src="' + imageurl + '" class="img-responsive img-circle" alt="Responsive image"></div>';

    html += '<div class="col-sm-10 col-xs-12"><p>';
    html += (json.info != null)? json.info : "";
    html += '</p></div><div class="col-sm-12"><hr>';

    for (var i = 0; i < json.actyear.length; i++) {
      if(i != 0){
        html += ' , ';
      }
      html += '<a class="year" id="' + json.actyear[i] + '" href="#"><strong>' + json.actyear[i] + '</strong></a>';
    }
      
    html += '</div><div class="col-sm-6 col-xs-12"><hr><h2>Popular Songs</h2><table class="table table-hover">';
    for (var i = 0; i < json.favorite.length; i++) {
      html += '<tr><td>' + (i+1) + '</td><td>' + json.favorite[i] + '</td></tr>';
    }
    html += '</table></div><div class="col-sm-6 col-xs-12"><hr><h2>Recent Setlist</h2><table class="table table-hover">';

    for (var i = 0; i < json.setlist.length; i++) {
      html += '<tr><td>' + (i+1) + '</td><td>' + json.setlist[i] + '</td></tr>';
    }

    html += '</table></div><div class="col-sm-12"><hr><h2>Similar</h2>';
    for (var i = 0; i < json.similar.length; i++) {
      if(i != 0){
        html += ' , ';
      }
      html += '<a class="artist" id="' + json.similar[i][0] + '" href="#"><strong>' + json.similar[i][1] + '</strong></a>';
    }
    html += '</div></div>';
    html += '<hr><footer><p>&copy; Company 2014</p></footer>';
    flg += 1;
  });

  function show(){
    if( flg == 2) {
      $("div#timetable").html(html);
      $("div#timetable").fadeIn(1000);             
    } else {
      setTimeout( function() {
        show();
      }, 200 );
    }
  }
  show();  
}

function getStagename(stage_id){
  switch (stage_id){
    case 1:
      return "Green Stage";
      break;
    case 2:
      return "White Stage";
      break;
    case 3:
      return "Red Marquee";
      break;
    case 4:
      return "Field Of Heaven";
      break;
    case 5:
      return "Orange Court";
      break;
  }
}

//プレイリスト取得先urlの変更
function changeListurl(type,year,day,stage,aid) {
    switch (type){
      case "year":
        listurl = "http://192.168.33.10:4567/yearsong/" + year + "/" + day + "/";
        break;
      case "stage":
        listurl = "http://192.168.33.10:4567/stagesong/" + stage + "/" + year + "/" + day + "/";
        break;
      case "artist":
        listurl = "http://192.168.33.10:4567/artistsong/" + aid + "/";
        break;
    }
}

function get_list(url,list,func) {
  var geturl;
  geturl = listurl + list;
  req = $.getJSON(geturl, function(json){
    for(var i in json){
      video_list.push([json[i].artist, json[i].video_id, json[i].title, json[i].artist_id])
//              html += "<span id=\"trac_" + i + "\">" + json[i].artist + "," + json[i].video_id + "," + json[i].title + "</span><br />";
    }
//            $("#list").html(html);
    if (typeof(func) === 'function') {
      func()
    }
  });
}

function onPlayerReady() {
  changeListurl("year","all","all","","");
  get_list(listurl,2,function(){
    $("#player").fadeIn();
    $("#loading").hide();
    play();
    changeListurl("year","all","all","","");
    get_list(listurl,3);            
  });
}

function onPlayerStateChange(event) {
  if (event.data == 0) { 
    next();
  } 
}

function next() {
  ++index;
  play();
  //動画リストが少なくなってきたら読み込み
  if ( video_list.length < (index + 3) ) {
    get_list(listurl,5);
  }
}

var errflg =0;
function play() {
  var playinghtml = "";
  //埋め込み無効ばっかりのとき対策                  
  if( video_list.length == (index) ) {
      $("#player").fadeOut();            
      $("#loading").fadeIn();
      $("div#playinginfo div.row").fadeOut();
      errflg = 1;
    setTimeout( function() {
     play() 
    }, 2000 );
  } else {
    if(errflg == 1){
        $("#player").fadeIn();
        $("#loading").hide();
        errflg = 0;              
    }
    player.loadVideoById(video_list[index][1]);
    playinghtml = '<div class="col-md-12 col-sm-12"><strong>Now Playing : </strong>' + video_list[index][2] + '</div>';
    playinghtml += '<div class="col-md-12 col-sm-12"><strong>Artist : </strong><a href="#timetable" class="artist"';
    playinghtml += 'id="' + video_list[index][3] + '">'+ video_list[index][0]; + '</a></div><hr>';

    $("div#playinginfo div.row").fadeOut(300,function(){
      $("div#playinginfo div.row").html(playinghtml);
      $("div#playinginfo div.row").fadeIn(500);                           
    });

  }
}

function onErrorState() {
    next();
}

function stopVideo(){
    player.stopVideo();         
}
