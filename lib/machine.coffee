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
    self = @
    @getUser(user.id).then (user) ->
      # Resetting catchAllCounter
      user.catchAllCounter = 0

      # call onEnter if defined
      if self.states[stateName] &&
      typeof self.states[stateName].onEnterCb == 'function'
        self.robot.logger.debug "Calling onEnter for state #{stateName}"
        args.unshift user
        self.states[stateName].onEnterCb.apply self.states[stateName], args

      user.state = stateName
    .catch (err) ->
      self.robot.logger.debug 'Error: ', err

  getState: (userId) ->
    self = @
    return new Promise (resolve, reject) ->
      self.getUser(userId).then (user) ->
        resolve user.state

  setUser: (userId) ->
    @users[userId] = new User @robot.brain, userId
    @users[userId].state = @getDefault()
    return @users[userId]

  getUser: (userId) ->
    self = @
    return new Promise (resolve, reject) ->
      if self.users[userId]
        resolve self.users[userId]
      else
        user = self.setUser userId
        self.robot.brain.get(userId).then (data) ->
          user.state = data['state'] if data && data['state']
          self.users[userId] = user
          resolve user

  dispatch: (res) ->
    self = @
    @getUser(res.envelope.user.id).then (user) ->
      self.robot.emit user.state, res
    .catch (err) ->
      self.robot.logger.debug 'Error: ', err

module.exports = stateMachine
