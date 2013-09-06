class packHierarchy

  constructor: (data, options = {}) ->

    m = Math.min($(window).width(), $(window).height())
    w = h = r = m
    x = d3.scale.linear().range([0, r])
    y = d3.scale.linear().range([0, r])

    offset = options.offset || 0

    pack = d3.layout.pack()
      .size([r, r])
      .value((d) -> d.count || 0)
      .children((d) -> d.values)

    vis = d3.select("svg")
      .append("svg:g")
      .attr("class", options.class)
      .attr("transform", "translate(" + (w - r) / 2 + "," + (h - r) / 2 + ")")

    genderBalance = (d)->
      return "#666" if d.values? or !d.countWomen? or !d.countWomen?
      ratio = d.countMen / (d.countMen + d.countWomen)
      colorbrewer.RdBu[11][Math.floor(ratio * 11)]

    node = root = data
    nodes = pack.nodes(root)

    vis.selectAll("circle")
        .data(nodes)
      .enter().append("svg:circle")
        .attr("class", (d) -> if d.children then "parent" else "child")
        .style("fill", (d) -> genderBalance(d))
        .attr("cx", (d) -> d.x)
        .attr("cy", (d) -> d.y)
        .attr("r", (d) -> d.r)
        .on("click", (d) -> zoom(if d != node then d else root))
      .append("svg:title")
        .text((d) -> d.label)

    vis.selectAll("text")
        .data(nodes)
      .enter().append("svg:text")
        .attr("class", (d) -> if d.values then "parent" else "child")
        .attr("x", (d) -> d.x)
        .attr("y", (d) -> d.y)
        .attr("dy", ".35em")
        .attr("text-anchor", "middle")
        .style("opacity", (d) -> if d.r > 40 and d.depth == 1 then 1 else 0)
        .text((d) -> d.label )

    zoom = (d, i)->
      console.info (d)
      k = r / d.r / 2
      x.domain([d.x - d.r, d.x + d.r])
      y.domain([d.y - d.r, d.y + d.r])

      t = vis.transition()
          .duration(750)

      t.selectAll("circle")
          .attr("cx", (de) -> x(de.x))
          .attr("cy", (de) -> y(de.y))
          .attr("r", (de) -> k * de.r)

      t.selectAll("text")
          .attr("x", (de) -> x(de.x))
          .attr("y", (de) -> y(de.y))
          .style("opacity", (de) -> if (k * de.r > 30 && (de.depth == d.depth + 1 || !de.values)) then 1 else 0)

      node = d;
      d3.event.stopPropagation()


    d3.select(window).on("click", () -> zoom(root))


module.exports = packHierarchy