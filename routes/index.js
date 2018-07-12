var express = require("express");
var router = express.Router();
var bodyParser = require("body-parser");
var formidable = require("formidable");
var fs = require("fs");

var content = {
  title: "TinyCompiler",
  code:
    'extern int printf(string str);\nint main(){\n    printf("Hello World");\n    return 0;\n}',
  middle: "LLVM",
  assem: "ASM",
  result: "Result",
  hey: ""
};

var codeData = "";

router.use(bodyParser.urlencoded({ extended: false }));
router.use(bodyParser.json());

/* GET home page. */
router.get("/", function(req, res, next) {
  res.render("index", content);
});

// file upload

router.post("/fileupload", function(req, res, next) {
  var form = new formidable.IncomingForm();
  form.uploadDir = "./upload";
  form.parse(req, function(err, fields, files) {
      fs.readFile(files.srcFile.path, "utf8", (err, data) => {
        if (err) throw err;
        content.middle = "LLVM";
        content.result = "Result";
        content.assem = "ASM"
        content.code = data;
        res.render("index", content);
    });
  });
});


//compile
router.post("/compile", function (req, res, next) {
  // console.log("拿到的代码为",req.body.content, new Date().getTime());
  if(req.body.content !== undefined ){
    codeData= String(req.body.content);
  }
  console.log(codeData);
  // var form = new formidable.IncomingForm();
  // form.uploadDir = "./upload";
  var data = codeData;
  fs.writeFile("./tinyCompiler/test.tc", data, err => {
    if (err) throw err;
    var exec = require("child_process").exec;
    var cmdStr = "cd tinyCompiler && make clean && make test";
    exec(cmdStr, (err, stdout, stderr) => {
      if (err) {
        content.result = stderr;
        content.middle = "ERROR!";
        content.assem = "ERROR!";
        content.hey = "";
        content.code = codeData;
        res.render("index", content);
      } else {
        var i = stdout.indexOf("./test");
        content.result = stdout.substring(i + 6, stdout.length);
        var i1 = stdout.indexOf("Code generate success");
        var i2 = stdout.indexOf("Object code wrote to output.o");
        content.middle = stdout.substring(i1 + 21, i2);

        var ii1 = stdout.indexOf("\n--");
        var ii2 = stdout.indexOf("Generating IR code");
        var tree = stdout.substring(ii1, ii2);

        tree2json(tree);

        exec(
          "cd tinyCompiler && objdump -S output.o",
          (err, stdout, stderr) => {
            if (err) {
              content.assem = stderr;
              res.render("index", content);
            } else {
              content.assem = stdout;
              content.code = codeData;
              res.render("index", content);
            }
          }
        );
      }
    });
  })
});

function tree2json(str) {
  var a = str.split("\n");
  a.shift();
  a.pop();
  var num = a.length;
  var js = [];
  var depth = [];
  var maxd = 0;

  console.log(num);

  for (var i = 0; i < num; i++) {
    var numofchar = 0;
    var j;
    for (j = 0; j < a[i].length; j++) {
      if (a[i][j] == "-") {
        numofchar++;
      } else {
        break;
      }
    }
    depth.push(numofchar / 2);
    if (numofchar / 2 > maxd) maxd = numofchar / 2;
    js.push({ name: a[i].substring(j, a[i].length), children: new Array() });
  }

  for (var i = maxd - 1; i > 0; i--) {
    for (var j = 0; j < num; j++) {
      if (depth[j] == i) {
        for (var k = j + 1; k < num; k++) {
          if (depth[k] == i) break;
          if (depth[k] == i + 1) {
            js[j].children.push(js[k]);
          }
        }
      }
    }
  }

  content.hey = JSON.stringify(
    js[
      depth.findIndex(e => {
        return e == 1;
      })
    ]
  );
}

module.exports = router;
