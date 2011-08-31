slinky_require('../main.coffee')

Tp.Action = Backbone.Model.extend
  select: ->
    this.get('source')?.select()
    # TODO: other stuff, like prompting for projector and switching
    # the context view
  icon: ->
    this.get('icon') or this.get('source')?.get('icon')

Tp.ActionController = Backbone.Collection.extend
  model: Tp.Action
  select: (id) ->
    action = this.get(id)
    if action
      Tp.log("Selecting %s", action)
      action.select()
      @selection = action
      this.trigger("change:selection")

Tp.actions = new Tp.ActionController
