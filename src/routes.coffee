BaseController = null
isConfigured = false

@Routes =

  config: (args) ->
    if isConfigured
      throw new Error('Routes already configured')

    BaseController = RouteController.extend
      onBeforeAction: ->
        return unless @ready()
        args.onBeforeAction.call(@)
      # Don't render until we're ready (waitOn) resolved
      action: -> @render() if @ready()
      waitOn: -> Meteor.subscribe('userData')

    Router.onBeforeAction ->
      Router.initLastPath()

    # Allow storing the last route visited and switching back.
    origGoFunc = Router.go
    _lastPath = null
    Router.setLastPath = (path, params) ->
      _lastPath = {path: path, params: params}
      console.debug('last router path', _lastPath)
    Router.getLastPath = -> _lastPath
    Router.goToLastPath = ->
      currentPath = Router.getCurrentPath()
      lastPath = Router.getLastPath()
      if lastPath? && lastPath.path? && lastPath.path != currentPath.path
        origGoFunc.call(Router, lastPath.path, lastPath.params)
        true
      else
        false

    Router.setLastPathAsCurrent = ->
      current = Router.getCurrentPath()
      Router.setLastPath(current.path, current.params)

    Router.getCurrentName = -> Router.current().route.getName()
    Router.getCurrentPath = ->
      current = Router.current()
      # Remove the host prefix from the path, which is sometimes present.
      {
        path: Iron.Location.get().path
        params: current?.params
      }

    # When switching, remember the last route.
    Router.go = ->
      Router.setLastPathAsCurrent()
      origGoFunc.apply(@, arguments)

    Router.initLastPath = ->
      unless _lastPath?
        Router.setLastPathAsCurrent()

    isConfigured = true


  crudRoute: (collectionName, controller) ->
    unless BaseController?
      throw new Error('Call config() first')

    controller ?= BaseController
    collectionId = Strings.firstToLowerCase(collectionName)
    singularName = Strings.singular(collectionId)
    itemRoute = singularName + 'Item'
    editRoute = singularName + 'Edit'
    formName = singularName + 'Form'
    console.debug('crud routes', itemRoute, editRoute, formName)
    Router.route collectionId,
      path: '/' + collectionId, controller: controller, template: collectionId
    Router.route itemRoute,
      path: '/' + collectionId + '/create', controller: controller, template: formName, data: -> {}
    Router.route editRoute,
      # Reuse the itemRoute for editing.
      path: '/' + collectionId + '/:_id/edit', controller: controller, template: formName,
      data: -> {doc: window[collectionName].findOne(@params._id)}
