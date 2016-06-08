
class stateMachine

  constructor: (@robot) ->
    @states = []
    @defaultState = null
    @defaultContext = {
      state: null
    }
    @robot.stateMachine = @

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

  dispatch: (res) ->
    # context = @robot.brain.get(res.envelope.user.id)
    # if !context
      # context = @defaultContext
      # context.state = @getDefault()

    # @robot.emit context.state, res
    @robot.emit @getDefault(), res


module.exports = stateMachine
