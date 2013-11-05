require 'coffee-trace'
mongoose = require 'mongoose'
Model    = mongoose.Model
Query    = mongoose.Query

setHooks = (hooks) ->
  modifyCallback = ->
    args = Array.prototype.slice.call arguments

    args.forEach (arg, index) ->
      if typeof arg is 'function'
        oldCb = arg
        return args[index] = (err, results) ->
          return oldCb err if err

          addHook = (index, err, data) ->
            if err then return oldCb err
            if not hooks[index] then return oldCb err, data
            hooks[index] data, addHook.bind null, index + 1

          addHook 0, err, results

    return args

createFind = (hooks) ->
  modifiedFind = ->
    args = hooks.apply null, arguments
    result = Model.find.apply @, args
    result.exec = createExec hooks
    result

createFindOne = (hooks) ->
  modifiedFindOne = ->
    args = hooks.apply null, arguments
    result = Model.findOne.apply @, args
    result.exec = createExec hooks
    result

createExec = (hooks) ->
  modifiedExec = ->
    args = hooks.apply null, arguments
    Query.prototype.exec.apply @, args

module.exports = (schema, options) ->
  if not options then return console.log "No options passed for postFind"
  keys = Object.keys options

  validOptions = keys.every (key) -> key is 'find' or key is 'findOne'

  if not validOptions then return console.log """
    Missing valid postFind options. (find, findOne)
  """

  keys.forEach (key) ->
    hooks = options[key]
    hooks = [hooks] if not Array.isArray hooks
    hooks = setHooks hooks

    switch key
      when 'find' then schema.statics.find = createFind hooks
      when 'findOne' then schema.statics.findOne = createFindOne hooks
