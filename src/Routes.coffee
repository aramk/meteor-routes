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

  isConfigured: -> @_isConfigured

  crudRoute: (collection, args) ->
    args = _.extend({}, args)

    controller = args.controller ? BaseController
    unless controller?
      throw new Error('No controller provided')

    collectionId = args.collectionId ? Collections.getName(collection)
    singularName = args.singularName ? Strings.singular(collectionId)
    
    createRouteName = singularName + 'Create'
    editRouteName = singularName + 'Edit'
    if Types.isString(args.createRoute) then createRouteName = args.createRoute
    if Types.isString(args.editRoute) then editRouteName = args.editRoute
    
    formName = args.formName ? singularName + 'Form'

    # Avoid creating a duplicate route for the collection if one already exists.
    unless Router.routes[collectionId]?
      Router.route collectionId,
        path: '/' + collectionId, controller: controller, template: collectionId

    createRoute =
      path: '/' + collectionId + '/create', controller: controller, template: formName,
      action: ->
        # Prevent re-rendering things outside the {{> yield}} by providing the data here.
        @render formName, data: ->
          data = Setter.merge({}, args.data, args.createData)
          args.onCreateData?.call(@, data)
          return data

    editRoute =
      # Reuse the createRoute for editing.
      path: '/' + collectionId + '/:_id/edit', controller: controller, template: formName,
      action: ->
        # Prevent re-rendering things outside the {{> yield}} by providing the data here.
        @render formName, data: ->
          data = Setter.merge({doc: collection.findOne(_id: @params._id)}, args.data, args.editData)
          args.onEditData?.call(@, data)
          return data

    if Types.isObject(args.createRoute) then Setter.merge createRoute, args.createRoute
    if Types.isObject(args.editRoute) then Setter.merge editRoute, args.editRoute

    Router.route createRouteName, createRoute
    Router.route editRouteName, editRoute

  getBaseController: -> BaseController
