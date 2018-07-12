var cEditor = CodeMirror.fromTextArea(document.getElementById("c-code"), {
    lineNumbers: true,
    matchBrackets: true,
    mode: "text/x-csrc"
});

$("#compile").click(function () {
    var codeContent = cEditor.getValue();
    $.ajax({
        type: "POST",
        dataType: 'json',
        url: "/compile",
        data: { content: codeContent }
    })
});


var codeSection = document.getElementsByClassName("CodeMirror")[0];
codeSection.className += " col-md-6";