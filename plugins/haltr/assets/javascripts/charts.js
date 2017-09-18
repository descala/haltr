$(document).ready(function(){
  //TODO duplicated code in update_chart_preference.js.erb
  $("select.chart_prefs").change(function() {
    var id = $(this).children(":selected").val();
    var params = 'name='+$(this)[0].id+'&value='+id;
    $.ajax({
      url: $(this).data('url'),
      data: params
    })
  })
});
