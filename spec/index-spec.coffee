describe 'index', ->

  beforeEach ->
    @strategy = require '../src/index'

  it 'exports strategy from package', ->
    should.exist @strategy
    @strategy.should.be.a 'function'

  it 'exports strategy on Strategy property', ->
    should.exist @strategy.Strategy
    @strategy.Strategy.should.be.a 'function'
    @strategy.Strategy.should.equal @strategy
