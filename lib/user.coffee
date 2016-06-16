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
        @brain.set @userId, @context

module.exports = User
