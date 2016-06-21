User = require './user'

class stateMachine
  constructor: (@robot) ->
    @states = []
    @users = {}
    @defaultState = null
    @robot._fsm = @

  setDefault: (@defaultState) ->
    @robot.logger.debug "Setting default state to #{@defaultState}"

  getDefault: () ->
    if @defaultState
      @defaultState
    else if @states[0]
      @states[0]
    else
      @robot.logger.error 'Default state not defined'

  registerState: (state) ->
    @robot.logger.debug "Registering state #{state}"
    @states.push state

  setNext: (userId, state) ->
    user = @getUser userId
    user.state = state

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
