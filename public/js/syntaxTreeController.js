$('#syntaxTree').click(function () {
  $('#treeModal').modal();//点击按钮弹出模态框
  $("#tree").css("display", "block");
})

$("#treeModel").on('shown.bs.modal', draw());
// 路径配置
function draw() {
  console.log("begin drawing");
  require.config({
    paths: {
      echarts: 'http://echarts.baidu.com/build/dist'
    }
  });

  // 使用
  require(
    [
      'echarts',
      'echarts/chart/tree' // 使用柱状图就加载bar模块，按需加载
    ],
    function (ec) {
      // 基于准备好的dom，初始化echarts图表
      var myChart = ec.init(document.getElementById('tree'));

      var option = {
        title: {
          text: '语法树'
        },
        toolbox: {
          show: true,
          feature: {
            mark: { show: true },
            dataView: { show: true, readOnly: false },
            restore: { show: true },
            saveAsImage: { show: true }
          }
        },
        series: [
          {
            name: '树图',
            type: 'tree',
            orient: 'horizontal',  // vertical horizontal
            rootLocation: { x: 100, y: 230 }, // 根节点位置  {x: 100, y: 'center'}
            nodePadding: 8,
            layerPadding: 100,
            hoverable: false,
            roam: true,
            symbolSize: 6,
            itemStyle: {
              normal: {
                color: '#4883b4',
                label: {
                  show: true,
                  position: 'right',
                  formatter: "{b}",
                  textStyle: {
                    color: '#000',
                    fontSize: 5
                  }
                },
                lineStyle: {
                  color: '#ccc',
                  type: 'curve' // 'curve'|'broken'|'solid'|'dotted'|'dashed'
                }
              },
              emphasis: {
                color: '#4883b4',
                label: {
                  show: false
                },
                borderWidth: 0
              }
            },
            data: [JSON.parse(document.getElementById('json').innerHTML)]
          }
        ]
      };
      // 为echarts对象加载数据
      myChart.setOption(option);
    }
  );
}