class ImageRetriever

  maxImages = 30

  getImages:(artist) ->
    @clear()
    console.info "-----"

    retrievedImages = 0

    for work in artist.works
      console.info work
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

          this.addEventListener "mouseleave", (event)->
            $(".zoomedImageContainer").hide()
      break if retrievedImages > maxImages



  clear: ->
    $(".imageContainer").empty()
    $(".zoomedImageContainer").hide()



module.exports = new ImageRetriever
