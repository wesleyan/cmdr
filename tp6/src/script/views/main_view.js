(function() {
  $(document).ready(function() {
    Tp.projectorPane = new Tp.ProjectorPaneView;
    Tp.actionListView = new Tp.ActionListView;
    return Tp.contextView = new Tp.ContextView;
  });

}).call(this);
