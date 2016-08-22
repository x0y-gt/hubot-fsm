{Listener,TextListener,CatchAllMessage,Response,TextMessage} = require 'hubot'
Async = require 'async'

class State

  constructor: (@robot, @name) ->
    @listeners        = []
    @catchAllCallback = null
    @onEnterCb        = null
    @onExitCb         = null
    @onHelpCb         = null

    @robot.on @name, ((res) ->
      context = {response: res}
      @processListeners context
    ).bind(@)

    @robot._fsm.addState @

  _onEnter: (callback) ->
    if typeof callback == 'function'
      @onEnterCb = callback
    else
      @robot.logger.error 'onEnter parameter is not a function'

  # TODO
  _onExit: (callback) ->
    if typeof callback == 'function'
      @onExitCb = callback
    else
      @robot.logger.error 'onExit parameter is not a function'

  _onHelp: (callback) ->
    if typeof callback == 'function'
      @onHelpCb = callback
    else
      @robot.logger.error 'onHelp parameter is not a function'

  # callback = func with params: response, payload
  on: (event, callback) ->
    @robot.on event, ((envelope) ->
      state = @robot._fsm.getState envelope.user.id
      # if the user is currently in this state then execute event callback
      if state == @name
        res = new Response @robot, envelope, undefined
        callback.call @, res, envelope.payload
    ).bind @

  # user: Hubot user obj
  # state: string next state name
  next: (user, state) ->
    extraArgs = Array.prototype.slice.call(arguments).slice 2
    @robot._fsm.setNext user, state, extraArgs

  listen: (matcher, options, callback) ->
    @listeners.push new Listener(@robot, matcher, options, callback)

  hear: (regex, options, callback) ->
    @listeners.push new TextListener(@robot, regex, options, callback)

  catchAll: (callback) ->
    if typeof callback == 'function'
      @catchAllCallback = callback
    else
      @robot.logger.error "Parameter passed to catchAll is not a function in state #{@name}"

  processListeners: (context, done) ->
    user = @robot._fsm.getUser context.response.envelope.user.id
    Async.detectSeries(
      @listeners,
      (listener, cb) =>
        try
          # Hack to work when testing in local, because "listener.call" verifies if TextMessage(local repo) is the same as TextMessage(app using this lib)
          message = new TextMessage context.response.message.user, context.response.message.text, context.response.message.id
          listener.call message, (listenerExecuted) ->
            if listenerExecuted
              user.catchAllCounter = 0
            cb listenerExecuted
        catch err
          @robot.emit('error', err, new Response(@robot, context.response.message, []))
          # Continue to next listener when there is an error
          cb err
      ,
      (result) =>
        # If no registered Listener matched the message
        if !result or result == null
          user.catchAllCounter = if user.catchAllCounter? then user.catchAllCounter + 1 else 1
          if user.catchAllCounter >= 2
            if @onHelpCb
              @robot.logger.info 'Catchall executed twice; executing HELP cb'
              @onHelpCb.call @robot, context.response
              return 0
            else
              @robot.logger.info 'Catchall executed twice; No HELP cb defined'
          @catchAllCallback.call @robot, context.response
    )
    return undefined

module.exports = State
