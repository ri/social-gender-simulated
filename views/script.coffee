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

    @force = null
    @width = 800
    @height = @width
    @center = {x: @width/2, y: @height/2}
    @rings = 6
    @innerRadius = 60
    @ringScale = d3.scale.linear().domain([0, @rings - 1]).range([@innerRadius, @width/2 - @maxCircle])
    @numNodes = numNodes
    @numFollowing = 10
    @ratioFem = 50
    @percFemFollow = 50
    @geo = new Geo()
    @selection = selection
    @nodes = []
    @links = []

  setup: () =>
    # @force = @forceLayout(@nodes, @links)
    # @force.start()

    @convertData(@numNodes, @ratioFem, @numFollowing, @percFemFollow)
    @contain = d3.select(@selection)
      .append("svg")
      .attr("width", @width)
      .attr("height", @height) 

    # @centerNode = @contain.append("circle")
    #   .attr(class: "center")
    #   .attr(r: @maxCircle)
    #   .attr(cx: @width/2)
    #   .attr(cy: @height/2)
    #   .attr(fill: @colours.pink)

    @numNodesSlider = d3.select("#num-nodes")
      .attr(min: 1)
      .attr(max: 300)
      .attr(value: @numNodes)
      .on("change", () => @numNodes = document.querySelector('#num-nodes').value; @update())

    @genderSlider = d3.select("#perc-gender")
      .attr(min: 0)
      .attr(max: 100)
      .attr(value: @ratioFem)
      .on("change", () => @ratioFem = document.querySelector('#perc-gender').value; @update()) 

    @followingSlider = d3.select("#following")
      .attr(min: 0)
      .attr(max: 100)
      .attr(value: @numFollowing)
      .on("change", () => @numFollowing = document.querySelector('#following').value;@updateLinks()) 

    @perFemSlider = d3.select("#following-female")
      .attr(min: 0)
      .attr(max: 100)
      .attr(value: @percFemFollow)
      .on("change", () => @percFemFollow = document.querySelector('#following-female').value;@updateLinks()) 

    @reset = d3.select("#reset")
      .on("click", () => @update())

    @drawRings()
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
  
  draw: (animate = false) =>
    if !animate
      @contain.selectAll("circle.node").remove()
      @drawForce()
    @nodesD3 = @contain.selectAll("circle.node")
      .data(@nodes)
    @contain.selectAll("line.link").remove()
    @drawForce()
    @drawNodes(animate)
    @drawLinks(animate)

  drawForce: =>
    @force = d3.layout.force()
      .nodes(@nodes)
      .friction(0.3)
      .links(@links)
      .size([@width, @height])
      .linkDistance(100)
    @force.start()

  drawNodes: (animate = false) =>
    if animate
      @nodesD3.transition()
        .duration(100)
        .attr(cx: (d) -> d.x)
        .attr(cy: (d) -> d.y)
    else
      @nodesD3.enter()
        .append("circle")
        .attr(class: "node")
        .attr(r: @maxCircle)
        .attr(fill: (d) => if d.gender is "female" then @colours.pink else @colours.blue)
        .on("mouseover", (node) -> console.log("femFollowing #{node.getFemFollowing()}, maleFollowing #{node.getMaleFollowing()}"))
        .attr(cx: (d) -> d.x)
        .attr(cy: (d) -> d.y)

  drawLinks: (animate = false) =>  
    @linksD3 = @contain.selectAll("line.link")
      .data(@links, (d) -> "#{d.source.index}_#{d.target.index}")

    @linksD3.enter()
      .append("line")
      .attr(class: "link")
      .attr(stroke: (d) =>
        if (d.target.gender == "female")
          stroke = @colours.pink
        else if (d.target.gender == "male")
          stroke = @colours.blue
        else if (d.target.gender == "brand")
          stroke = @colours.orange
        else 
          stroke = "#d3d3d3"
      )
      .attr("x1", (d) -> d.source.x)
      .attr("y1", (d) -> d.source.y)
      .attr("x2", (d) -> d.target.x)
      .attr("y2", (d) -> d.target.y)
      .attr("stroke-opacity": 0.5)

    if animate
      @linksD3.attr(opacity: 0)
        .transition()
        .delay(50)
        .duration(50)
        .attr(opacity: 0.5)
    else
      @linksD3.attr(opacity: 0.5)



  convertData: (count, ratio, numFollowing, perFem) =>
    indexOfFem = ratio/100 * count
    @nodes = (@genNodes(node, indexOfFem) for node in [0..count - 1])
    @calculateLinks(count, numFollowing, perFem)

  calculateLinks: (count, numFollowing, perFem) =>
    segment = 360/count
    @links = @nodes.mapcat (node) => @genLinks(node, numFollowing, perFem, @nodes)
    @calculateFollowers node, @links for node in @nodes
    maxFollowers = d3.max(@nodes, (n) -> n.numFollowers)
    followerScale = d3.scale.linear().domain([0, maxFollowers]).range([0, @rings-1])
    @genLayout(node, @links, segment, followerScale) for node in @nodes

  genNodes: (i, indexOfFem) =>
    gender = "male"
    if i < indexOfFem then gender = "female"
    node = new Node(i, gender, [])

  genLinks: (node, numFollowing, perFem, nodeData) =>
    node.clearFollowing()
    numFem = Math.floor(perFem/100 * numFollowing)
    numMale = Math.floor(numFollowing - numFem)
    nodePool = nodeData.slice(0, node.index - 1).concat(nodeData.slice(node.index + 1, nodeData.length))
    maleNodes = nodePool.filter((n) -> n.gender is "male")
    femaleNodes = nodePool.filter((n) -> n.gender is "female")

    @addFollowing(node, femaleNodes) for i in [0...numFem]
    @addFollowing(node, maleNodes) for i in [0...numMale]
    node.getOutbound()

  calculateFollowers: (node, links) =>
    node.numFollowers = links.filter((l) -> l.target is node.index).length

  genLayout: (node, links, segment, followerScale) =>
    r = @ringScale Math.floor(followerScale node.numFollowers)
    coords = @geo.p2c(r, node.index*segment)
    node.setCoords({x: coords.x + @center.x, y: coords.y + @center.y})

  addFollowing: (node, nodePool) ->
    # #remove already following
    updatedPool = nodePool.filter((n) -> node.following.filter((f) -> f.index is n.index).length is 0)
    # console.log("remove following", updatedPool.length)
    
    if updatedPool.length < 1
      false
    else
      randIndex = Math.floor Math.random() * updatedPool.length
      randNode = updatedPool[randIndex]
      node.followNode(randNode)

  drawRings: () =>
    @contain.selectAll('circle.ring')
      .data([0..@rings - 1])
      .enter()
      .append('circle')
      .attr(class: 'ring')
      .attr(r: (d) => @ringScale d)
      .attr(cx: @center.x)
      .attr(cy: @center.y)
      .attr(fill: 'none')
      .attr(stroke: '#000000')
      .attr(opacity: 0.1)

  update: () =>
    @convertData(@numNodes, @ratioFem, @numFollowing, @percFemFollow)
    @draw()

  updateLinks: () =>
    @calculateLinks(@numNodes, @numFollowing, @percFemFollow)
    @draw(true)

class Node
  constructor: (index, gender, following, x, y) ->
    @index = index
    @gender = gender
    @following = following
    @numFollowers = 0
    @x = x
    @y = y

  followNode: (node) =>
    @following.push node

  clearFollowing: =>
    @following = []

  getOutbound: =>
    {source: @index, target: node.index} for node in @following

  getFemFollowing: => 
    @following.filter((n) -> n.gender is "female")

  getMaleFollowing: => 
    @following.filter((n) -> n.gender is "male")

  setCoords: (coords) ->
    @x = coords.x
    @y = coords.y


selection = "body"
chart = new circleChart(selection, 20)
chart.setup()