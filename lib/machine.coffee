User = require './user'

class stateMachine
  constructor: (@robot) ->
    @states       = {}
    @users        = {}
    @defaultState = null
    @robot._fsm   = @

  setDefault: (@defaultState) ->
    @robot.logger.debug "Setting default state to #{@defaultState}"

  getDefault: () ->
    if @defaultState
      @defaultState
    else
      @robot.logger.error 'Default state not defined'
      process.exit 1

  addState: (state) ->
    @robot.logger.debug "Registering state #{state.name}"
    @states[state.name] = state

  setNext: (user, stateName, args=[]) ->
    user = @getUser user.Id

    # call onEnter if defined
    if @states[stateName] && typeof @states[stateName].onEnterCb == 'function'
      @robot.logger.debug "Calling onEnter for state #{stateName}"
      args.unshift user
      @states[stateName].onEnterCb.apply @states[stateName], args

    user.state = stateName

  getState: (userId) ->
    user = @getUser userId
    return user.state

  setUser: (userId) ->
    @users[userId] = new User @robot.brain, userId
    @users[userId].state = @getDefault()
    return @users[userId]

  getUser: (userId) ->
    if @users[userId]
      return @users[userId]
    else
      return @setUser userId

  dispatch: (res) ->
    user = @getUser res.envelope.user.id
    @robot.emit user.state, res

module.exports = stateMachine
