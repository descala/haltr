$(document).ready(function(){
  $("#chart_events").change(function() {
    var id = $(this).children(":selected").val();
    var params = 'name=chart_events&value='+id;
    $.ajax({
      url: $(this).data('url'),
      data: params
    })
  })
});
