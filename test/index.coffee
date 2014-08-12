async     = require 'async'
assert    = require 'assert'
mongoose  = require 'mongoose'
mockgoose = require 'mockgoose'
mockgoose(mongoose)

postFind = require '../index.coffee'
Schema   = mongoose.Schema

mocks = [{name: 'The Scranton Strangler'}, {name: 'Jack the Ripper'}]

describe 'Mongoose Post Find', ->

  it 'should work with arrays of hooks', (done) ->
    itemsFetched = {}

    ArraySchema = new Schema
      name: String

    ArraySchema.plugin postFind,
      find: [
        (options, results, done) ->
          results.forEach (result) -> result.name = result.name.toUpperCase()
          done null, results
        (options, results, done) ->
          results.forEach (result) -> result.status = 'found'
          done null, results
      ]

      findOne: [
        (options, result, done) ->
          itemsFetched[result._id] = true
          done null, result
      ]

    ArrayModel = mongoose.model "ArrayModel", ArraySchema

    async.each mocks, (mock, done) ->
      (new ArrayModel(mock)).save done
    , (err) ->
      assert.ifError

      upperMocks = mocks.map (mock) -> mock.name.toUpperCase()

      # test find call
      ArrayModel.find {}, null, {lean: true}, (err, results) ->
        assert.ifError err
        results.forEach (result) ->
          assert.ok result.name in upperMocks

        # test exec call
        ArrayModel.find().lean().exec (err, results) ->
          assert.ifError err
          results.forEach (result) ->
            assert.ok result.name in upperMocks

          # test find one
          ArrayModel.findOne {name: 'The Scranton Strangler'}, (err, result) ->
            assert.ifError err
            assert.ok itemsFetched[result._id]

            # test findOne exec
            ArrayModel.findOne({name: 'Jack the Ripper'}).exec (err, result) ->
              assert.ifError err
              assert.ok itemsFetched[result._id]

              done()

  it 'should work with a single function for hooks', (done) ->

    mustaches = {'Jack the Ripper': true, 'The Scranton Strangler': false}

    SingleSchema = new Schema
      name: String

    SingleSchema.plugin postFind,
      find: (options, results, done) ->
        results.forEach (result) -> result.name = result.name.toLowerCase()
        done null, results

      findOne: (options, result, done) ->
        result.hasMustache = mustaches[result.name]
        done null, result

    SingleModel = mongoose.model 'SingleModel', SingleSchema

    async.each mocks, (mock, done) ->
      (new SingleModel(mock)).save done
    , (err) ->
      assert.ifError

      lowerMocks = mocks.map (mock) -> mock.name.toLowerCase()

      # test find call
      SingleModel.find {}, null, {lean: true}, (err, results) ->
        assert.ifError err
        results.forEach (result) ->
          assert.ok result.name in lowerMocks

        # test exec call
        SingleModel.find().lean().exec (err, results) ->
          assert.ifError err
          results.forEach (result) ->
            assert.ok result.name in lowerMocks

          # test find one
          SingleModel.findOne {name: 'The Scranton Strangler'}, (err, result) ->
            assert.ifError err
            assert.equal false, result.hasMustache

            # test findOne exec
            SingleModel.findOne({name: 'Jack the Ripper'}).exec (err, result) ->
              assert.ifError err
              assert.ok result.hasMustache

              done()
