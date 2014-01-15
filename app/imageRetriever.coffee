class ImageRetriever

  maxImages = 30


  getImages:(artist) ->
    @clear()

    retrievedImages = 0
  
    $(".imageContainer").on "mouseleave", (event)->
      console.info("hi")
      $(".zoomedImageContainer").hide()

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

      break if retrievedImages > maxImages



  clear: ->
    $(".imageContainer").empty()
    $(".zoomedImageContainer").hide()



module.exports = new ImageRetriever
