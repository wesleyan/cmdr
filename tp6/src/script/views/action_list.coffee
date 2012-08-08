slinky_require('../core.coffee')

Tp.ActionListView = Backbone.View.extend
  initialize: () ->
    $.get '../script/templates/action_list.html', (template) =>
      $.template "action-list-template", template
      Tp.server.bind "loaded", this.render
      Tp.actions.bind "add", this.render
      Tp.actions.bind "change", this.render
      Tp.actions.bind "change:selection", this.selectionChanged

  render: () ->
    $('.action-list').html ($.tmpl "action-list-template", Tp.actions?.map (action) ->
      {
        id: action.get('id'),
        name: action.get('name'),
        icon: action.icon()
      })

    actionItemClicked = (event) ->
      console.log("Trying to select " + event.currentTarget.id)
      Tp.actions.select event.currentTarget.id

    window.setTimeout (() =>
      $('.action-list-item').unbind('click').click(actionItemClicked)), 500

  selectionChanged: () ->
    $('.action-list-item').removeClass 'selected'
    $("#" + Tp.actions.selection?.id).addClass 'selected'
