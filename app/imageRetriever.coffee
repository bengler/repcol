class ImageRetriever

  # constructor: ->
  #   $(".zoomedImage").click ->
  #     $(this).hide()

  getImages:(artist) ->
    @clear()
    console.info "-----"

    index = 0
    retrievedImages = 0
    chunkSize = 10
    while index < artist.works.length and retrievedImages < 50

      chunkSize = artist.works.length - index if index + chunkSize > artist.works.length
      console.info index + ":" + chunkSize

      for work in artist.works[index .. index + chunkSize]
        image = new Image()
        image.src = "data/images_lores_2/#{work.id}_0.JPG"
        image.work = work
        image.addEventListener "load", (event)->
          retrievedImages += 1
          link = $(this).wrap($("<a>").attr("href", "#"));

          $(".imageContainer").append(link)
          this.addEventListener "mouseenter", (event)->
            $(".zoomedImage").attr("src","data/images/#{this.work.id}_0.JPG")
            $(".zoomedImage").show()

          this.addEventListener "mouseleave", (event)->
            $(".zoomedImage").hide()


      index += chunkSize

  clear: ->
    $(".imageContainer").empty()
    $(".zoomedImage").hide()



module.exports = new ImageRetriever
