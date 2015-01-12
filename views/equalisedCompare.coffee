queue()
  .defer(d3.json, "data/data_equalised.json")
  .defer(d3.json, "data/data_equalised2.json")
  .defer(d3.json, "data/data_equalised3.json")
  .defer(d3.json, "data/data_equalised4.json")
  .defer(d3.json, "data/bjeanes_data_equalised1.json")
  .defer(d3.json, "data/bjeanes_data_equalised2.json")
  .defer(d3.json, "data/bjeanes_data_equalised3.json")
  .defer(d3.json, "data/bjeanes_data_equalised4.json")
.await(ready);

ready(e, r1, r2, r3, r4, b1, b2, b3, b4) ->
	