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
