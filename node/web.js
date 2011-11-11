// exec NODE_ENV="production" node web.js >> ../log/node.log 2>&1
var express = require('express');
var mongoose = require('mongoose');

var app = express.createServer();


var musicdb = mongoose.createConnection('mongodb://192.168.110.7/misic-mongoid');
var mediadb2 = mongoose.createConnection('mongodb://192.168.110.7/media-mongoid4');

var MusicmodelSchema = new mongoose.Schema({
     _id : mongoose.Schema.ObjectId
    ,path : String
});
var MediamodelSchema = new mongoose.Schema({
     _id : mongoose.Schema.ObjectId
    ,path : String
});

var Musicmodel = musicdb.model('Musicmodel',MusicmodelSchema) ;
var Mediamodel = mediadb2.model('Mediamodel',MediamodelSchema) ;


app.get('/', function(req, res) {
    res.send('HerokuでNode.jsとExpressを使ってHello world!');
});

app.get("/musicdb/:mid/:param",function(req,res){
  Musicmodel.findById(req.params.mid,function(err,doc){
     if(doc)
       res.sendfile(doc.path,function(ferr){
            if(ferr)
              next(ferr);
            else
              console.log("transfered %s",doc.path);
       });
     else
       res.send("no file error ");
  });
});

app.get("/mediadb2/:mid/:param",function(req,res){
  Mediamodel.findById(req.params.mid,function(err,doc){
     if(doc)
       res.sendfile(doc.path,function(ferr){
            if(ferr)
              next(ferr);
            else
              console.log("transfered %s",doc.path);
       });
     else
       res.send("no file error ");
  });
});


app.get("/stream/musicdb/:mid/:param",function(req,res){
  Musicmodel.findById(req.params.mid,function(err,doc){
     if(doc)
       res.sendfile(doc.path,function(ferr){
            if(ferr)
              next(ferr);
            else
              console.log("transfered %s",doc.path);
       });
     else
       res.send("no file error ");
  });
});

app.get("/stream/mediadb2/:mid/:param",function(req,res){
  Mediamodel.findById(req.params.mid,function(err,doc){
     if(doc)
       res.sendfile(doc.path,function(ferr){
            if(ferr)
              next(ferr);
            else
              console.log("transfered %s",doc.path);
       });
     else
       res.send("no file error ");
  });
});

app.get("/stream/02.mp3",function(req,res){
    res.sendfile("/var/www/resource/music/iTunesMac/Vocaloid/impacts/02.mp3");
  });



var port = process.env.PORT || 23001;
app.listen(port, function(){
  console.log("Listening on " + port);
});

