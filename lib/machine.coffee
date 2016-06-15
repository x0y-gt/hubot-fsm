class Context
  constructor: (@brain, @userId) ->
    @context = {
      state: null
    }
  Object.defineProperties @prototype,
    state:
      get: -> @context.state
      set: (value) ->
        console.log 'next state: ' + value
        @context.state = value
        @brain.set @userId, @context


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

  setUser: (userId) ->
    @users[userId] = new Context @robot.brain, userId
    return @users[userId]

  getUser: (userId) ->
    if @users[userId]
      return @users[userId]
    else
      return @setUser userId

  dispatch: (res) ->
    user = @getUser res.envelope.user.id
    if user.state == null
      user.state = @getDefault()

    @robot.emit user.state, res

module.exports = stateMachine
