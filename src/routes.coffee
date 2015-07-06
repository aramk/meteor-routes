BaseController = null

Routes =

  config: (args) ->
    args = _.extend({}, args)

    if @_isConfigured then throw new Error('Routes already configured')

    BaseController = args.BaseController ? RouteController.extend
      onBeforeAction: ->
        return unless @ready()
        @next()
      action: -> @render() if @ready()

    Router.getCurrentName = -> Router.current()?.route?.getName()
    Router.getReactiveCurrentName = -> reactiveCurrentName.get()
    Router.getCurrentPath = ->
      current = Router.current()
      # Remove the host prefix from the path, which is sometimes present.
      {
        path: Iron.Location.get().path
        params: current?.params
      }

    reactiveCurrentName = new ReactiveVar(null)
    _lastPath = null
    _currentPath = null
    Tracker.autorun ->
      newPath = Router.getCurrentPath()
      unless _currentPath? && newPath? && _currentPath.path == newPath.path
        _lastPath = _currentPath
        _currentPath = newPath
      reactiveCurrentName.set(Router.getCurrentName())

    Router.getLastPath = -> _lastPath
    Router.goToLastPath = ->
      lastPath = Router.getLastPath()
      if lastPath
        Router.go(lastPath.path, lastPath.params)
        true
      else
        false

    @_isConfigured = true

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
      path: '/' + collectionId + '/create', controller: controller, template: formName,
      data: -> Setter.merge({}, args.data, args.createData)
    Router.route editRoute,
      # Reuse the createRoute for editing.
      path: '/' + collectionId + '/:_id/edit', controller: controller, template: formName,
      data: ->
        Setter.merge({doc: collection.findOne(_id: @params._id)}, args.data, args.editData)

  getBaseController: -> BaseController

