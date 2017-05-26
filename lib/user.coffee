class User
  constructor: (@brain, @userId) ->
    @context = {
      state: null
    }
  Object.defineProperties @prototype,
    state:
      get: -> @context.state
      set: (value) ->
        @context.state = value
    catchAllCounter:
      get: -> @context.catchAllCounter
      set: (value) ->
        @context.catchAllCounter = value

  setState: (newState) ->
    @context.state = newState
    @brain.set @userId, @context

  setCatchAllCounter: (counter) ->
    @context.catchAllCounter = counter
    @brain.set @userId, @context

module.exports = User
