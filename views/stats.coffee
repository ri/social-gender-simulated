d3.json("/data/stats.json", (e, data) ->
	ri = data.ri
	bo = data.bo
	graphHeight = 200
	y = d3.scale.linear().domain([0, 1]).range([0, graphHeight])

	compareToFData = { label: "Women following Women vs Men Following Women", data: [{ name: "ri", vals: [{val: d3.mean(ri, (x) -> x.ftof/x.alltof), gender: 'f'}, {val: d3.mean(ri, (x) -> x.mtof/x.alltof), gender: 'm'}, ]}, { name: "bo", vals: [ {val: d3.mean(bo, (x) -> x.ftof/x.alltof), gender: 'f'}, {val: d3.mean(bo, (x) -> x.mtof/x.alltof), gender: 'm'},]}]}

	compareToMData = { label: "Men Following Men vs Women following Men", data: [{ name: "ri", vals: [{val: d3.mean(ri, (x) -> x.mtom/x.alltom), gender: 'm'}, {val: d3.mean(ri, (x) -> x.ftom/x.alltom), gender: 'f'}]}, { name: "bo", vals: [{val: d3.mean(bo, (x) -> x.mtom/x.alltom), gender: 'm'}, {val: d3.mean(bo, (x) -> x.ftom/x.alltom), gender: 'f'}]}]}

	compareFToData = { label: "Women following Women vs Women following Men", data: [ { name: "ri", vals: [{val: d3.mean(ri, (x) -> x.ftof/ (x.ftof + x.ftom)), gender: 'f'}, {val: d3.mean(ri, (x) -> x.ftom/(x.ftof + x.ftom)), gender: 'm'}]}, 
					   { name: "bo", vals: [{val: d3.mean(bo, (x) -> x.ftof/(x.ftof + x.ftom)), gender: 'f'}, {val: d3.mean(bo, (x) -> x.ftom/(x.ftof + x.ftom)), gender: 'm'}]}]}

	compareMToData = { label: "Men following Men vs Men Following Women", data: [{ name: "ri", vals: [{val: d3.mean(ri, (x) -> x.mtom/ (x.mtof + x.mtom)), gender: 'm'}, {val: d3.mean(ri, (x) -> x.mtof/ (x.mtof + x.mtom)), gender: 'f'}]}, 
					   { name: "bo", vals: [{val: d3.mean(bo, (x) -> x.mtom/ (x.mtof + x.mtom)), gender: 'm'}, {val: d3.mean(bo, (x) -> x.mtof/ (x.mtof + x.mtom)), gender: 'f'}]}]}

	allToData = { label: "Following Men vs Following Women", data: [{ name: "ri", vals: [{val: d3.mean(ri, (x) -> x.alltom / (x.alltof + x.alltom)), gender: 'm'}, {val: d3.mean(ri, (x) -> x.alltof / (x.alltof + x.alltom)), gender: 'f'}]}, 
					   { name: "bo", vals: [{val: d3.mean(bo, (x) -> x.alltom / (x.alltof + x.alltom)), gender: 'm'}, {val: d3.mean(bo, (x) -> x.alltof / (x.alltof + x.alltom)), gender: 'f'}]}]}

	combinedData = [compareToFData, compareToMData, compareFToData, compareMToData, allToData]

	container = d3.select("body").append("div").attr(class: "graphs")

	graphs = container.selectAll("svg")
		.data(combinedData)
		.enter()
		.append("svg")
		.attr(height: graphHeight)
		.attr(width: 300)
		.attr(class: (d,i) -> console.log d; "graph-#{i+1}")

	graphs.append("text").attr(class: "label")
		.text((d) -> d.label)
		.attr(y: 10)
		.attr("font-size": 12)
		# .attr(fill: "#ffffff")

	users = graphs.selectAll("g.user").data((d) -> d.data)
		.enter()
		.append("g")
		.attr("class", (d) -> d.name)
		.attr(transform: (d, i) -> "translate(#{i*60}, 0)")

	users.append("text").text((d) -> d.name).attr(y: 30).attr(width: 10).attr(height: 10).attr("font-size": 10)

	users.selectAll("rect").data((d) -> d.vals)
		.enter()
		.append("rect")
		.attr(height: (d) -> y d.val)
		.attr(width: 10)
		.attr(y: (d) -> graphHeight - (y d.val))
		.attr(x: (d, i) -> i* 20)
		.attr(fill: (d) -> if d.gender is "f" then "#FE0557" else "#0AABBA")

)