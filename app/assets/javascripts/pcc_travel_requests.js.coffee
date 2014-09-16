jQuery ->
  $("input.datetimepicker").each (i) ->
    $(this).datetimepicker
      dateFormat: "yy-mm-dd"
      timeFormat: "h:mm TT"
      altFieldTimeOnly: false
      altFormat: "yy-mm-dd"
      altTimeFormat: "HH:mm"
      altField: $(this).next()