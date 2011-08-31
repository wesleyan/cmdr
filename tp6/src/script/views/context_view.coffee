slinky_require '../core.coffee'

Tp.ContextView = Backbone.View.extend
  initialize: () ->
    Tp.actions.bind "change:selection", @actionChanged

  actionChanged: () ->
    action = Tp.actions.selection
    module = Tp.modules[action?.get?('module')]
    Tp.log(module)
    $(".context-area").html module?.render?() or ""
    module?.module_loaded?()
