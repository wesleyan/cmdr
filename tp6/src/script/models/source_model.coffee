slinky_require('main')

class Source extends Backbone.Model
  select: ->
    msg =
      resource: "source"
      var: "source"
      value: this.get('name')
    Tp.server.trigger("state_set", msg)

  selected: ->
    Tp.room.source == @name

Tp.Source = Source
Tp.SourceController = Backbone.Collection.extend({ model: Tp.Source })
Tp.sources = new Tp.SourceController
