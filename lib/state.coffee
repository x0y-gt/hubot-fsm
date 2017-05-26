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
    self = @
    @robot.on event, ((envelope) ->
      self.robot._fsm.getState(envelope.user.id).then (state) ->
        # if the user is currently in this state then execute event callback
        if state == self.name
          res = new Response self.robot, envelope, undefined
          callback.call self, res, envelope.payload
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
    self = @
    @robot._fsm.getUser(context.response.envelope.user.id).then (user) ->
      Async.detectSeries(
        self.listeners,
        (listener, cb) =>
          try
            # Hack to work when testing in local, because "listener.call" verifies if TextMessage(local repo) is the same as TextMessage(app using this lib)
            message = new TextMessage context.response.message.user, context.response.message.text, context.response.message.id
            listener.call message, (listenerExecuted) ->
              if listenerExecuted
                user.setCatchAllCounter(0).then (data) ->
                  cb listenerExecuted
              else
                cb listenerExecuted
          catch err
            self.robot.emit('error', err, new Response(self.robot, context.response.message, []))
            # Continue to next listener when there is an error
            cb err
        ,
        (result) =>
          # If no registered Listener matched the message
          if !result or result == null
            user.setCatchAllCounter(if user.catchAllCounter? then user.catchAllCounter + 1 else 1).then (data) ->
              if user.catchAllCounter >= 2
                if self.onHelpCb
                  self.robot.logger.info 'Catchall executed twice; executing HELP cb'
                  self.onHelpCb.call self.robot, context.response
                  return 0
                else
                  self.robot.logger.info 'Catchall executed twice; No HELP cb defined'
              self.catchAllCallback.call self.robot, context.response if self.catchAllCallback
      )
      return undefined

module.exports = State
