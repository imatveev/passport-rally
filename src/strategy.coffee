util = require 'util'
Profile = require './profile'
OAuth2Strategy = require 'passport-oauth2'
InternalOAuthError = OAuth2Strategy.InternalOAuthError

###
 * `Strategy` constructor.
 *
 * The Rally authentication strategy authenticates requests by delegating to
 * Rally using the OAuth 2.0 protocol.
 *
 * Applications must supply a `verify` callback which accepts an `accessToken`,
 * `refreshToken` and service-specific `profile`, and then calls the `done`
 * callback supplying a `user`, which should be set to `false` if the
 * credentials are not valid.  If an exception occured, `err` should be set.
 *
 * Options:
 *   - `baseURL`       base url for Rally. defaults to 'https://rally1.rallydev.com'
 *   - `clientID`      your Rally application's Client ID
 *   - `clientSecret`  your Rally application's Client Secret
 *   - `callbackURL`   URL to which Rally will redirect the user after granting authorization
 *   - `scope`         array of permission scopes to request. only 'alm' for now
 *   — `userAgent`     All API requests MUST include a valid User Agent string.
 *                     e.g: domain name of your application.
 *
 * Examples:
 *
 *     RallyStrategy = require('passport-rally');
 *
 *     passport.use(new RallyStrategy({
 *         clientID: '123-456-789',
 *         clientSecret: 'shhh-its-a-secret'
 *         callbackURL: 'https://www.example.net/auth/rally/callback',
 *         userAgent: 'myapp.com'
 *       },
 *       function(accessToken, refreshToken, profile, done) {
 *         User.findOrCreate(..., function (err, user) {
 *           done(err, user);
 *         });
 *       }
 *     ));
 *
 * @param {Object} options
 * @param {Function} verify
 * @api public
###
Strategy = (options={}, verify) ->
  options.baseURL ?= 'https://rally1.rallydev.com'
  options.authorizationURL ?= "#{options.baseURL}/login/oauth2/auth"
  options.tokenURL ?= "#{options.baseURL}/login/oauth2/token"
  options.userProfileURL ?= "#{options.baseURL}/slm/webservice/v2.0/user"
  options.customHeaders ?= {}

  unless options.customHeaders['User-Agent']
    options.customHeaders['User-Agent'] = options.userAgent ? 'passport-rally'

  OAuth2Strategy.call this, options, verify
  @name = 'rally'
  @_userProfileURL = options.userProfileURL
  @_oauth2.useAuthorizationHeaderforGET true

  # ALM does not support the standard ways of passing OAuth tokens yet.
  # Work to pass the token as a header like {"Authentication": "Bearer <token>"}
  # and as an access_token in the query string are in the pipeline now and we
  # can remove these two overrides after that.
  @_oauth2.buildAuthHeader = (accessToken) -> accessToken
  @_oauth2.get = (url, access_token, callback) ->
    if @_useAuthorizationHeaderForGET
      headers = 'zsessionid': @buildAuthHeader(access_token)
      access_token= null
    else
      headers = {}

    @_request "GET", url, headers, "", access_token, callback
  @

###
 * Inherit from `OAuth2Strategy`.
###
util.inherits Strategy, OAuth2Strategy


###
 * Retrieve user profile from Rally.
 *
 * This function constructs a normalized profile, with the following properties:
 *
 *   - `provider`         always set to `rally`
 *   - `id`               the user's User ID (UUID)
 *   - `username`         the user's Rally username
 *   - `displayName`      the user's full name
 *   - `emails`           the user's email addresses
 *
 * @param {String} accessToken
 * @param {Function} done
 * @api protected
###
Strategy.prototype.userProfile = (accessToken, done) ->
  @_oauth2.get @_userProfileURL, accessToken, (err, body, res) ->
    if err?
      return done(new InternalOAuthError('Failed to fetch user profile', err))

    try
      json = JSON.parse(body)
    catch e
      return done(new Error('Failed to parse user profile'))
    
    profile = Profile.parse json
    profile.provider  = 'rally'
    profile._raw = body
    profile._json = json
    
    done null, profile

###
 * Expose `Strategy`.
###
module.exports = Strategy;