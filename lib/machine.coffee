User = require './user'
Promise = require 'bluebird'

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
      user.setCatchAllCounter(0).then (data) ->
        # call onEnter if defined
        if self.states[stateName] &&
        typeof self.states[stateName].onEnterCb == 'function'
          self.robot.logger.debug "Calling onEnter for state #{stateName}"
          args.unshift user
          self.states[stateName].onEnterCb.apply self.states[stateName], args

        user.setState stateName
    .catch (error) ->
      self.robot.logger.debug 'Error: ', error

  getState: (userId) ->
    self = @
    return new Promise (resolve, reject) ->
      self.getUser(userId).then (user) ->
        resolve user.state
      .catch (error) ->
        reject error

  setUser: (userId) ->
    self = @
    return new Promise (resolve, reject) ->
      newUser = new User self.robot.brain, userId
      self.robot.brain.get(userId).then (data) ->
        initialState = if data && data['state'] then data['state']
        else self.getDefault()

        newUser.setState(initialState).then (data) ->
          self.users[userId] = newUser
          resolve newUser
        .catch (error) ->
          reject error
      .catch (error) ->
        reject error

  getUser: (userId) ->
    self = @
    return new Promise (resolve, reject) ->
      if self.users[userId]
        resolve self.users[userId]
      else
        self.setUser(userId).then (user) ->
          resolve user
        .catch (error) ->
          reject error

  dispatch: (res) ->
    self = @
    @getUser(res.envelope.user.id).then (user) ->
      self.robot.emit user.state, res
    .catch (error) ->
      self.robot.logger.debug 'Error: ', error

module.exports = stateMachine
