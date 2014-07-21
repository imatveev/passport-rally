sinon = require 'sinon'

before ->
  # give the test object stub() and spy() functions from sinon
  @[key] = value for key, value of sinon.sandbox.create()

afterEach ->
  @restore()
