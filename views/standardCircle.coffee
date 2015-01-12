class circleChart

  constructor: (data) ->
    @radius = 2
    @gravity = 0
    @chargeFactor = 0
    @linkDistance = 200
    @linkStrength = 0
    @colours = {
      pink: "#FE0557"
      blue: "#0AABBA"
      orange: "#FE8B05"
    }

    #containers
    @nodesData = data.nodes.filter((d) -> d.gender is "female" or d.gender is "male")
    @linksData = data.links.filter((d) -> d.type is 'mtom' or d.type is 'mtof' or d.type is 'ftof' or d.type is 'ftom')
    @width = 800
    @height = @width
    @center = {x: @width/2, y: @height/2}
    @geo = new Geo()
    @rings = 8
    @innerRadius = 80
    @ringScale = d3.scale.linear().domain([@rings - 1, 0]).range([@innerRadius, @width/2 - @radius])

    @contain = d3.select(selection)
      .append("svg")
      .attr("width", @width)
      .attr("height", @height) 

  setup: () =>

    @force = d3.layout.force()
      .charge(@chargeFactor)
      .gravity(@gravity)
      .linkDistance(@linkDistance)
      .linkStrength(@linkStrength)
      .size([@width, @height])
      .nodes(@nodesData)
      .links(@linksData)

    @links = @contain.selectAll("path.link")
      .data(@linksData)
      .enter()
      .append("path")
      .attr(class: 'link')
      .attr(fill: 'none')
    @nodes = @contain.selectAll("circle.node")
      .data(@nodesData)
      .enter()
      .append("circle")
      .attr("class", "node")
      .call(@force.drag)
    #me node
    @me = d3.select(@nodes[0][0])
    @me.datum((d) => d.targetX = @center.x; d.targetY = @center.y; d)

    @nodes.each((d, i) =>
      d.followersCount = @links.filter((l) -> l.target is i)[0].length
    )
    followerMax = d3.max(@nodes.data(), (d, i) -> unless i is 0 then d.followersCount)
    followerMin = d3.min(@nodes.data(), (d, i) -> unless i is 0 then d.followersCount)
    @followerScale = d3.scale.log().domain([followerMin, followerMax]).range([0, @rings - 1])
    @males = @nodes.filter((d) -> d.gender is "male")
    @females = @nodes.filter((d , i) -> i != 0 and d.gender is "female")
    @allButMe = @nodes.filter((d, i) -> i != 0)
                      .sort((a , b) -> if a.gender is 'male' then -1 else 1)
    @mtof = @links.filter((d) -> d.type is 'mtof')
    @mtom = @links.filter((d) -> d.type is 'mtom')
    @metof = @links.filter((d) -> d.source is 0 and d.type is 'ftof')
    @metom = @links.filter((d) -> d.source is 0 and d.type is 'ftom')
    @ftom =  @links.filter((d) -> d.type is 'ftom' and d.source isnt 0)
    @ftof =  @links.filter((d) -> d.type is 'ftof' and d.source isnt 0)

    @showNodes(@allButMe)
    @showLinks(@metof)
    @showLinks(@metom)
    # Set force layout
    # manually set location

    # @contain.selectAll('circle.ring')
    #   .data([0..@rings - 1])
    #   .enter()
    #   .append('circle')
    #   .attr(class: 'ring')
    #   .attr(r: (d) => @ringScale d)
    #   .attr(cx: @center.x)
    #   .attr(cy: @center.y)
    #   .attr(fill: 'none')
    #   .attr(stroke: '#000000')
    #   .attr(opacity: 0.1)
    @drawNodes(@me)
    @drawNodes(@allButMe)
    @drawLinks(@metof)
    @drawLinks(@metom)
    @force.start()
    @circularLayout(@allButMe)
    @drawStraightLinks(@links)


    # # @links = @metom
    @force.on("tick", (e) =>
      k = e.alpha * 0.5


      @nodes.each((d) ->
        d.x += (d.targetX - d.x) * k
        d.y += (d.targetY - d.y) * k
      )
      @nodes
        .attr("cx", (d) -> d.x)
        .attr("cy", (d) -> d.y)
  
      @drawStraightLinks(@links)
    )

  showNodes: (nodes) => 
    nodes.datum((d) -> d.visible = true; d)
    @arrangeVisible(@allButMe)
    nodes.transition().attr(r: @radius)
  hideNodes: (nodes) =>
    nodes.datum((d) -> d.visible = false; d)
    @arrangeVisible(@allButMe)
    nodes.transition().attr(r: 0)
  drawStraightLinks: (links) =>
    links.attr(d: (d) =>
      if d.visible
        dx = d.target.x - d.source.x
        dy = d.target.y - d.source.y
        "M #{d.source.x}, #{d.source.y}L #{d.target.x}, #{d.target.y}"
      else
        "M #{d.source.x}, #{d.source.y}L #{d.source.x}, #{d.source.y}"
      )
  drawArcLinks: (links) =>
    links.attr(d: (d) =>
      if d.visible
        dx = d.target.x - d.source.x
        dy = d.target.y - d.source.y
        dr = Math.sqrt(dx * dx + dy * dy)
        nodesLength = @nodes[0].length
        mid = nodesLength/2
        posTarget = (d.target.index - d.source.index + nodesLength) % nodesLength
        if posTarget < mid
          dir = 1
        else
          dir = 0
        "M #{d.source.x}, #{d.source.y}A#{dr},#{dr} 0 0,#{dir} #{d.target.x}, #{d.target.y}"
      else
        "M #{d.source.x}, #{d.source.y}L #{d.source.x}, #{d.source.y}"
      )
  showLinks: (links) =>
    links.each((d) -> d.visible = true)
  hideLinks: (links) =>
    links.each((d) -> d.visible = false)


  reset: => @showNodes(@allButMe); @hideLinks(@links);
  showMales: => @showNodes(@males); @showLinks(@metom);
  hideMales: => @hideNodes(@males); @hideLinks(@metom);
  showFemales: => @showNodes(@females); @showLinks(@metof);
  hideFemales: => @hideNodes(@females); @hideLinks(@metof);
  mToF: => @drawLinks(@mtof); @showLinks(@mtof)
  fToM: => @drawLinks(@ftom); @showLinks(@ftom)
  mToM: => @drawLinks(@mtom); @showLinks(@mtom)
  fToF: => @drawLinks(@ftof); @showLinks(@ftof)

  drawNodes: (nodes) =>
    nodes
      .attr(r: @radius)
      .attr("fill", (d) =>
        if (d.gender == "female")
          fill = @colours.pink
        else if (d.gender == "male")
          fill = @colours.blue
        else if (d.gender == "brand")
          fill = @colours.orange
        else 
          fill = "#d3d3d3"
      )

  drawLinks: (links) =>
    links.attr(stroke: (d) =>
        if (d.target.gender == "female")
          stroke = @colours.pink
        else if (d.target.gender == "male")
          stroke = @colours.blue
        else 
          stroke = "#d3d3d3"
      )
      .attr(opacity: 0.2)

  drawArcedLinks: (links) =>
    links.attr(stroke: (d) =>
        if (d.target.gender == "female")
          stroke = @colours.pink
        else if (d.target.gender == "male")
          stroke = @colours.blue
        else 
          stroke = "#d3d3d3"
      )
      .attr(opacity: 0.5)
  circularLayout: (nodes) =>
    count = nodes[0].length
    segment = 360/count


    nodes.datum((d, i) =>
      r = @width/2.2
      coord = @geo.p2c(r, i*segment)
      d.targetX = coord.x + @center.x
      d.targetY = coord.y + @center.y
      d.x = d.targetX
      d.y = d.targetY
      d
    )

  arrangeVisible: (nodes) =>
    @force.stop()
    @circularLayout(nodes.filter((d) -> d.visible is true))
    @force.start()

chart = null
selection = "body"

d3.json("/data/data2.json", (e, data) ->
  chart = new circleChart(data)
  chart.setup()

  d3.select('#reset').on("click", () -> chart.reset())
  d3.select('#males_on').on("click", () -> chart.showMales())
  d3.select('#males_off').on("click", () -> chart.hideMales())
  d3.select('#females_on').on("click", () -> chart.showFemales())
  d3.select('#females_off').on("click", () -> chart.hideFemales())
  d3.select('#m_to_f').on("click", () -> chart.mToF())
  d3.select('#f_to_m').on("click", () -> chart.fToM())
  d3.select('#m_to_m').on("click", () -> chart.mToM())
  d3.select('#f_to_f').on("click", () -> chart.fToF())
)