slinky_require('../main.coffee')

class Source extends Backbone.Model
  select: ->
    msg =
      resource: "source"
      var: "source"#{Tp.devices.selected_projector}"
      value: this.get('name')
      projectors: Tp.devices.selected_projector
    Tp.server.trigger("state_set", msg)

  selected: ->
    Tp.room.source1 == @name
    Tp.room.source2 == @name
    Tp.room.source3 == @name

Tp.Source = Source
Tp.SourceController = Backbone.Collection.extend({ model: Tp.Source })
Tp.sources = new Tp.SourceController
