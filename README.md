# My Chart

<canvas id="myChart"></canvas>
<script src="https://cdn.jsdelivr.net/npm/chart.js@2.9.3/dist/Chart.min.js"></script>
<script>
  // Parse the CSV file and create the data for the chart
  var data = [];
  var labels = [];
  var csv = "https://raw.githubusercontent.com/vpereira01/electricalgridptqos/master/data/records/records.csv";
  Papa.parse(csv, {
    header: true,
    download: true,
    complete: function(results) {
      data = results.data.map(function(d) { return d[".fields.municipality"] });
      labels = results.data.map(function(d) { return d[".record_timestamp"] });
    }
  });

  // Create the chart using the Chart.js library
  var ctx = document.getElementById('myChart').getContext('2d');
  var chart = new Chart(ctx, {
    type: 'line',
    data: {
      labels: labels,
      datasets: [{
        label: "[CHART_LABEL]",
        data: data
      }]
    },
    options: {
      responsive: true,
      maintainAspectRatio: false
    }
  });
</script>
