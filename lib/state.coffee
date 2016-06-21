{Listener,TextListener,CatchAllMessage,Response,TextMessage} = require 'hubot'
Async = require 'async'

class State

  constructor: (@robot, @stateName) ->
    @listeners        = []
    @catchAllCallback = null
    @robot.on @stateName, ((res) ->
      context = {response: res}
      @processListeners context
    ).bind(@)

  # callback = func with params: response, payload
  on: (event, callback) ->
    @robot.on event, ((envelope) ->
      state = @robot._fsm.getState envelope.user.id
      # if the user is currently in this state then execute event callback
      if state == @stateName
        res = new Response @robot, envelope, undefined
        callback.call @, res, envelope.payload
    ).bind @

  # user: Hubot user obj
  # state: string next state name
  next: (user, state) ->
    @robot._fsm.setNext user.id, state

  listen: (matcher, options, callback) ->
    @listeners.push new Listener(@robot, matcher, options, callback)

  hear: (regex, options, callback) ->
    @listeners.push new TextListener(@robot, regex, options, callback)

  catchAll: (callback) ->
    if typeof callback == 'function'
      @catchAllCallback = callback
    else
      @robot.logger.error "Parameter passed to catchAll is not a function in state #{@stateName}"

  processListeners: (context, done) ->
    Async.detectSeries(
      @listeners,
      (listener, cb) =>
        try
          # Hack to work when testing in local, because "listener.call" verifies if TextMessage(local repo) is the same as TextMessage(app using this lib)
          message = new TextMessage context.response.message.user, context.response.message.text, context.response.message.id
          listener.call message, (listenerExecuted) ->
            cb listenerExecuted
        catch err
          @robot.emit('error', err, new Response(@robot, context.response.message, []))
          # Continue to next listener when there is an error
          cb err
      ,
      (result) =>
        # If no registered Listener matched the message
        if !result or result == null
          @catchAllCallback.call @robot, context.response
    )
    return undefined

module.exports = State
