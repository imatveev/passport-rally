_ = require 'lodash'
describe 'profile', ->

  beforeEach ->
    @profile = require '../src/profile'
    @json = _.cloneDeep require('./fixtures/alm-profile')

  describe '#parse', ->

    it 'should parse profile with email', ->
      profile = @profile.parse @json

      profile.id.should.equal @json.User._refObjectUUID
      profile.displayName.should.equal @json.User.DisplayName
      profile.username.should.equal @json.User.UserName
      profile.emails.should.eql [value: @json.User.EmailAddress]

    it 'should parse profile withough email', ->
      delete @json.User.EmailAddress
      profile = @profile.parse @json

      profile.id.should.equal @json.User._refObjectUUID
      profile.displayName.should.equal @json.User.DisplayName
      profile.username.should.equal @json.User.UserName
      should.not.exist profile.emails
