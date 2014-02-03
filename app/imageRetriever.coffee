class ImageRetriever

  maxImages = 60
  baseURL = "http://api.digitaltmuseum.no/artifact?owner=NMK-B&mapping=ESE&api.key=demo&identifier="

  getImages:(artist) ->
    @clear()

    retrievedImages = 0
  
    $(".imageContainer").on "mouseleave", (event)->
      $(".zoomedImageContainer").hide()
      $(".photographer").text("")
      $(".title").text("")


    for work in artist.works
      if work.imageCount > 0
        retrievedImages += 1
        image = new Image()
        image.src = "data/images_lores_2/#{work.id}_0.JPG"
        image.work = work
        image.addEventListener "load", (event)->
          $(".imageContainer").append(this)

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

      break if retrievedImages > maxImages



  clear: ->
    $(".imageContainer").empty()
    $(".zoomedImageContainer").hide()
    $(".photographer").text("")
    $(".title").text("")



module.exports = new ImageRetriever
