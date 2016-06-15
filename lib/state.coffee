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

  next: (userId, state) ->
    @robot._fsm.setNext userId, state

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
          # Chapus para probar local, porque TextMessage(repo local) es diferente a TextMessage(repo del app que use esta librería)
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
        if result == null
          @catchAllCallback.call @robot, context.response
    )
    return undefined

module.exports = State
