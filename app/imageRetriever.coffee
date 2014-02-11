class ImageRetriever

  baseURL = "http://api.digitaltmuseum.no/artifact?owner=NMK-B&mapping=ESE&api.key=demo&identifier="

  constructor: ->
    $(".imageContainer").on "mouseleave", (event)->
      $(".zoomedImageContainer").hide()
      $(".photographer").text("")
      $(".title").text("")

    $(".navBlock .next").click(@nextBlock)
    $(".navBlock .prev").click(@previousBlock)

    @maxImages = 30

  getImages:(artist) ->
    @clear()

    @works = artist.works

    # .sort (a,b)->
    #   a.kind == "Maleri" < b.kind == "Maleri"

    @works = @works.filter (a)->
      a.imageCount > 0

    @currentOffset = 0
    @getImageBlock(@works.slice(@currentOffset, @currentOffset + @maxImages))
    @updateArrows()

  updateArrows:() ->
    if @currentOffset == 0
      $('.navBlock .prev').addClass("deactivated")
    else
      $('.navBlock .prev').removeClass("deactivated")

    if @currentOffset + @maxImages >= @works.length

      $('.navBlock .next').addClass("deactivated")
    else
      $('.navBlock .next').removeClass("deactivated")

  nextBlock:(event) =>
    event.stopPropagation()
    return if @currentOffset + @maxImages >= @works.length
    @clear()
    @currentOffset += @maxImages
    @getImageBlock(@works.slice(@currentOffset, @currentOffset + @maxImages))
    @updateArrows()

  previousBlock:(event) =>
    event.stopPropagation()
    return if @currentOffset == 0
    @clear()
    @currentOffset -= @maxImages
    @getImageBlock(@works.slice(@currentOffset, @currentOffset + @maxImages))
    @updateArrows()

  getImageBlock:(works) ->
    for work in works
      image = new Image()
      image.src = "data/images_lores_2/#{work.id}_0.JPG"
      image.work = work
      image.addEventListener "load", (event)->
        $(".imageContainerInner").append(this)

        this.addEventListener "mouseenter", (event)->
          $(".zoomedImage").attr("src","data/images/#{this.work.id}_0.JPG")
          $(".zoomedImageContainer").show()
          $(".photographer").text("Imaging by " + this.work.photographer)
          $(".title").text("")
          $.get baseURL + this.work.id, {}, (xml)=>

            xml = $(xml)
            n = xml.find "dc\\:title, title"
            engTitle = norTitle = undefined

            n.each (n,m)->
              title = $(m)
              if title.context.outerHTML.indexOf("xml:lang=\"NOR\"") >= 0
                norTitle = title.text()

              if title.context.outerHTML.indexOf("xml:lang=\"ENG\"") >= 0
                engTitle = title.text()

            title = engTitle
            title ||= norTitle
            if !title?
              title = "Archive reference: " + this.work.id
              $(".title").addClass("onlyReference")                
            else
              $(".title").removeClass("onlyReference")                

            $(".title").text(title)

  clear: ->
    $(".imageContainerInner").empty()
    $(".zoomedImageContainer").hide()
    $(".photographer").text("")
    $(".title").text("")



module.exports = new ImageRetriever
