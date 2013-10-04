class ImageRetriever

  getImages:(artist) ->
    @clear()
    for work in artist.works[0..50]
      image = new Image()
      image.src = "data/images_lores_2/#{work.id}_0.JPG"
      image.addEventListener "load", (event)->
        this.addEventListener "onmousein", (event)->
          this.css({ opacity: 1 })
        this.addEventListener "onmouseout", (event)->
          this.css({ opacity: 0.5 })
        this.addEventListener "click", (event)->
          console.info("clicked")
        $(".imageContainer").append(this)

  clear: ->
    $(".imageContainer").empty()


module.exports = new ImageRetriever
