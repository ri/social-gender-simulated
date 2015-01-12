Array.prototype.mapcat = (fn) -> [].concat.apply([], @map fn)

class circleChart

  constructor: (selection, numNodes) ->
    @maxCircle = 6
    # @gravity = 0.2
    # @chargeFactor = -400
    # @linkDistance = 200
    @colours = {
      pink: "#FE0557"
      blue: "#0AABBA"
      orange: "#FE8B05"
    }

    #containers
    # @links = data.links
    @force = null
    #calculated
    @width = 800
    @height = @width
    @center = {x: @width/2, y: @height/2}
    @numNodes = numNodes
    @numFollowing = 10
    @ratioFem = 50
    # @maxTweets = d3.max(@nodes, (f) -> f.tweets)
    # @scale = d3.scale.log().domain([1, @maxTweets])
    # @sectionLength = 360/@data.length
    @geo = new Geo()
    @selection = selection

  setup: () =>
    # @force = @forceLayout(@nodes, @links)
    # @force.start()

    @data = @convertData(@numNodes, @ratioFem, @numFollowing)
    console.log @data
    @contain = d3.select(@selection)
      .append("svg")
      .attr("width", @width)
      .attr("height", @height) 
    @centerNode = @contain.append("circle")
      .attr(class: "center")
      .attr(r: @maxCircle)
      .attr(cx: @width/2)
      .attr(cy: @height/2)
      .attr(fill: @colours.pink)
    @nodes = @contain.selectAll("circle.node")
      .data(@data)
      .enter

    @numNodesSlider = d3.select("#num-nodes")
      .attr(min: 1)
      .attr(max: 300)
      .attr(value: @numNodes)
      .on("core-change", () => @numNodes = d3.select("#num-nodes").attr('aria-valuenow'); @updateNodes())

    @genderSlider = d3.select("#perc-gender")
      .attr(min: 0)
      .attr(max: 100)
      .attr(value: @ratioFem)
      .on("core-change", () => @ratioFem = d3.select("#perc-gender").attr('aria-valuenow'); @updateNodes()) 

    @draw()
    # @curNodes = @drawCircles(@contain, @nodes)
      # @curLinks = d3.selectAll([])
      # @nodes.each((d) ->
      #   d.centerX = 0
      #   d.centerY = 0
      # )
      # @force.on("tick", (e) =>
      #   # @nodes.each((d) ->
      #   #   if (d.centerX > 0 && d.centerY > 0)
      #   #     d.x += (d.centerX - d.x) * 0.2 * e.alpha
      #   #     d.y += (d.centerY - d.y) * 0.2 * e.alpha
      #   # )

      #   @nodes
      #     .attr("cx", (d) -> d.x)
      #     .attr("cy", (d) -> d.y)

      #   # @curLinks
      #   #   .transition()
      #   #   .attr("x1", (d) -> d.source.x)
      #   #   .attr("y1", (d) -> d.source.y)
      #   #   .attr("x2", (d) -> d.target.x)
      #   #   .attr("y2", (d) -> d.target.y)
      # )

  draw: () =>
    @contain.selectAll("circle.node").remove()

    @nodes = @contain.selectAll("circle.node")
      .data(@data)

    @nodes.enter()
      .append("circle")
      .attr(class: "node")
      .attr(cx: (d) -> d.x)
      .attr(cy: (d) -> d.y)
      .attr(r: @maxCircle)
      .attr(fill: (d) => if d.gender is "female" then @colours.pink else @colours.blue)

  convertData: (count, ratio, numFollowing) =>
    segment = 360/count
    indexOfFem = ratio/100 * count
    nodes = (@genNodes(node, segment, indexOfFem) for node in [0..count])
    links = nodes.mapcat (node) => @genLinks(node, numFollowing, nodes)
    {nodes: nodes, links: links}

  genNodes: (i, segment, indexOfFem) =>
    r = @width/2.2
    coord = @geo.p2c(r, i*segment)
    gender = "male"
    if i < indexOfFem then gender = "female"
    node = new Node(i, gender, [], coord.x + @center.x, coord.y + @center.y)

  genLinks: (node, numFollowing, nodeData) =>
    nodePool = nodeData.slice(0, node.index - 1).concat(nodeData.slice(node.index + 1, nodeData.length))
    @addFollowing(node, nodePool) for i in [0..numFollowing]
    node.getFollowing()

  addFollowing: (node, nodePool) ->
    randNode = Math.floor Math.random() * nodePool.length
    node.followNode(nodePool[randNode])

  updateNodes: () =>
    @data = @convertData(@numNodes, @ratioFem, @numFollowing)
    @draw()

  updateLinks: () =>
    #for number of links and link ratio updates

class Node
  constructor: (index, gender, following, x, y) ->
    @index = index
    @gender = gender
    @following = following
    @x = x
    @y = y

  followNode: (node) =>
    @following.push node

  getFollowing: ->
    {source: @index, target: node.index} for node in @following



selection = "body"
chart = new circleChart(selection, 60)
chart.setup()