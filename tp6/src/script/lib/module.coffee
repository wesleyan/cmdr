slinky_require('../core.coffee')

Tp.Module = Backbone.View.extend
  initialize: () ->
    @template_name = "action_template_" + @name
    if $.template(@template_name) instanceof Function
      @template_loaded()
    else
      $.get '../script/templates/modules/' + @name + '.html', (template) =>
        $.template @template_name, template
        @template_loaded()

   template_loaded: ->
   module_loaded: ->
