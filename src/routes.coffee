BaseController = null
isConfigured = false

Routes =

  config: (args) ->
    args = _.extend({}, args)

    if isConfigured
      throw new Error('Routes already configured')

    BaseController = args.BaseController ? RouteController.extend
      onBeforeAction: ->
        return unless @ready()
        @next()
      action: -> @render() if @ready()

    onBeforeAction = ->
      Router.initLastPath()
      (args.onBeforeAction ? this.next)()
    Router.onBeforeAction(onBeforeAction)

    reactiveCurrentName = new ReactiveVar(null)
    Router.onAfterAction ->
      reactiveCurrentName.set(Router.getCurrentName())

    # Allow storing the last route visited and switching back.
    origGoFunc = Router.go
    _lastPath = null
    Router.setLastPath = (path, params) ->
      _lastPath = {path: path, params: params}
      Logger.debug('Last router path', _lastPath)
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

    Router.getCurrentName = -> Router.current().route?.getName()
    Router.getReactiveCurrentName = -> reactiveCurrentName.get()
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

  crudRoute: (collection, args) ->
    args = _.extend({}, args)

    controller = args.controller ? BaseController
    unless controller?
      throw new Error('No controller provided')

    collectionId = args.collectionId ? Collections.getName(collection)
    singularName = args.singularName ? Strings.singular(collectionId)
    createRoute = args.createRoute ? singularName + 'Create'
    editRoute = args.editRoute ? singularName + 'Edit'
    formName = args.formName ? singularName + 'Form'
    Logger.debug('CRUD Routes', createRoute, editRoute, formName)
    Router.route collectionId,
      path: '/' + collectionId, controller: controller, template: collectionId
    Router.route createRoute,
      path: '/' + collectionId + '/create', controller: controller, template: formName, data: -> {}
    Router.route editRoute,
      # Reuse the createRoute for editing.
      path: '/' + collectionId + '/:_id/edit', controller: controller, template: formName,
      data: -> {doc: collection.findOne(@params._id)}

  getBaseController: -> BaseController

