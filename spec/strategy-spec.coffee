RallyStrategy = require '../src'
OAuth2Strategy = require 'passport-oauth2'
InternalOAuthError = OAuth2Strategy.InternalOAuthError
OAuth2Strategy = require 'passport-oauth2'

describe 'strategy', ->
  beforeEach ->
    @spy OAuth2Strategy, 'call'

  it 'is named "rally"', ->
    strategy = new RallyStrategy
      clientID: 'client-id'
      clientSecret: 'client-secret'
      callbackURL: "http://some.callback/url"
    , ->

    should.exist strategy.name
    strategy.name.should.equal 'rally'

  it 'has default baseUrl, authorizationURL, tokenURL, userProfileURL, and User-Agent', ->
    new RallyStrategy
      clientID: 'client-id'
      clientSecret: 'client-secret'
      callbackURL: "http://some.callback/url"
    , ->

    OAuth2Strategy.call.callCount.should.equal 1
    OAuth2Strategy.call.firstCall.args[1].baseURL.should.eql 'https://rally1.rallydev.com'
    OAuth2Strategy.call.firstCall.args[1].authorizationURL.should.equal 'https://rally1.rallydev.com/login/oauth2/auth'
    OAuth2Strategy.call.firstCall.args[1].tokenURL.should.equal 'https://rally1.rallydev.com/login/oauth2/token'
    OAuth2Strategy.call.firstCall.args[1].userProfileURL.should.equal 'https://rally1.rallydev.com/slm/webservice/v2.0/user'
    OAuth2Strategy.call.firstCall.args[1].customHeaders['User-Agent'].should.equal 'passport-rally'
    
    OAuth2Strategy.call.firstCall.args[1].clientID.should.equal 'client-id'
    OAuth2Strategy.call.firstCall.args[1].clientSecret.should.equal 'client-secret'
    OAuth2Strategy.call.firstCall.args[1].callbackURL.should.equal 'http://some.callback/url'

  it 'configures baseUrl', ->
    new RallyStrategy
      clientID: 'client-id'
      clientSecret: 'client-secret'
      callbackURL: "http://some.callback/url"
      baseURL: 'http://other.base/url'
    , ->

    OAuth2Strategy.call.firstCall.args[1].baseURL.should.eql 'http://other.base/url'
    OAuth2Strategy.call.firstCall.args[1].authorizationURL.should.equal 'http://other.base/url/login/oauth2/auth'
    OAuth2Strategy.call.firstCall.args[1].tokenURL.should.equal 'http://other.base/url/login/oauth2/token'
    OAuth2Strategy.call.firstCall.args[1].userProfileURL.should.equal 'http://other.base/url/slm/webservice/v2.0/user'

  it 'configures authorizationURL, tokenURL, and userProfileURL apart from baseUrl', ->
    new RallyStrategy
      clientID: 'client-id'
      clientSecret: 'client-secret'
      callbackURL: "http://some.callback/url"
      baseURL: 'http://other.base/url'
      authorizationURL: 'authorization url'
      tokenURL: 'token url'
      userProfileURL: 'user profile url'
    , ->

    OAuth2Strategy.call.firstCall.args[1].baseURL.should.eql 'http://other.base/url'
    OAuth2Strategy.call.firstCall.args[1].authorizationURL.should.equal 'authorization url'
    OAuth2Strategy.call.firstCall.args[1].tokenURL.should.equal 'token url'
    OAuth2Strategy.call.firstCall.args[1].userProfileURL.should.equal 'user profile url'

  it 'configures custom headers without User-Agent', ->
    new RallyStrategy
      clientID: 'client-id'
      clientSecret: 'client-secret'
      callbackURL: "http://some.callback/url"
      customHeaders:
        'some-header': 'with value'
    , ->

    OAuth2Strategy.call.callCount.should.equal 1
    OAuth2Strategy.call.firstCall.args[1].customHeaders['User-Agent'].should.equal 'passport-rally'
    OAuth2Strategy.call.firstCall.args[1].customHeaders['some-header'].should.equal 'with value'
    
  it 'configures custom headers with User-Agent', ->
    new RallyStrategy
      clientID: 'client-id'
      clientSecret: 'client-secret'
      callbackURL: "http://some.callback/url"
      customHeaders:
        'some-header': 'with value'
        'User-Agent': '007'
    , ->

    OAuth2Strategy.call.callCount.should.equal 1
    OAuth2Strategy.call.firstCall.args[1].customHeaders['User-Agent'].should.equal '007'
    OAuth2Strategy.call.firstCall.args[1].customHeaders['some-header'].should.equal 'with value'

  describe '#userProfile', ->
    beforeEach ->
      @strategy = new RallyStrategy
        clientID: 'client-id'
        clientSecret: 'client-secret'
        callbackURL: "http://some.callback/url"
      , ->
      @stub @strategy._oauth2, 'get'
      @json = JSON.stringify require('./fixtures/alm-profile')


    it 'parses profile', ->
      @strategy._oauth2.get.yields null, @json

      @strategy.userProfile 'token', (err, profile) =>
        @strategy._oauth2.get.should.have.been.calledWith 'https://rally1.rallydev.com/slm/webservice/v2.0/user'
        should.not.exist err

        should.exist profile
        should.exist profile.id
        should.exist profile.username
        should.exist profile.displayName
        should.exist profile.emails
        should.exist profile.provider
        profile.provider.should.equal 'rally'

    it 'sets _raw and _json properties', ->
      @strategy._oauth2.get.yields null, @json

      @strategy.userProfile 'token', (err, profile) =>
        should.not.exist err

        should.exist profile
        should.exist profile._raw
        should.exist profile._json
        profile._raw.should.equal @json
        profile._json.should.eql JSON.parse(@json)

    it 'handles err fetching profile', ->
      @strategy._oauth2.get.yields 'some error'

      @strategy.userProfile 'token', (err, profile) ->
        should.exist err
        err.should.eql new InternalOAuthError('Failed to fetch user profile', 'some error')
        should.not.exist profile

    it 'handles err parsing profile', ->
      @strategy._oauth2.get.yields null, "<html><body>cannot be JSON.parse'd</body></html>"

      @strategy.userProfile 'token', (err, profile) ->
        should.exist err
        err.should.eql new Error('Failed to parse user profile')
        should.not.exist profile
