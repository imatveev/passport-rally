(function() {
  var InternalOAuthError, OAuth2Strategy, Profile, Strategy, util;

  util = require('util');

  Profile = require('./profile');

  OAuth2Strategy = require('passport-oauth2');

  InternalOAuthError = OAuth2Strategy.InternalOAuthError;


  /*
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
   */

  Strategy = function(options, verify) {
    var _ref;
    if (options == null) {
      options = {};
    }
    if (options.baseURL == null) {
      options.baseURL = 'https://rally1.rallydev.com';
    }
    if (options.authorizationURL == null) {
      options.authorizationURL = "" + options.baseURL + "/login/oauth2/auth";
    }
    if (options.tokenURL == null) {
      options.tokenURL = "" + options.baseURL + "/login/oauth2/token";
    }
    if (options.userProfileURL == null) {
      options.userProfileURL = "" + options.baseURL + "/slm/webservice/v2.0/user";
    }
    if (options.customHeaders == null) {
      options.customHeaders = {};
    }
    if (!options.customHeaders['User-Agent']) {
      options.customHeaders['User-Agent'] = (_ref = options.userAgent) != null ? _ref : 'passport-rally';
    }
    OAuth2Strategy.call(this, options, verify);
    this.name = 'rally';
    this._userProfileURL = options.userProfileURL;
    this._oauth2.useAuthorizationHeaderforGET(true);
    this._oauth2.buildAuthHeader = function(accessToken) {
      return accessToken;
    };
    this._oauth2.get = function(url, access_token, callback) {
      var headers;
      if (this._useAuthorizationHeaderForGET) {
        headers = {
          'zsessionid': this.buildAuthHeader(access_token)
        };
        access_token = null;
      } else {
        headers = {};
      }
      return this._request("GET", url, headers, "", access_token, callback);
    };
    return this;
  };


  /*
   * Inherit from `OAuth2Strategy`.
   */

  util.inherits(Strategy, OAuth2Strategy);


  /*
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
   */

  Strategy.prototype.userProfile = function(accessToken, done) {
    return this._oauth2.get(this._userProfileURL, accessToken, function(err, body, res) {
      var e, json, profile;
      if (err != null) {
        return done(new InternalOAuthError('Failed to fetch user profile', err));
      }
      try {
        json = JSON.parse(body);
      } catch (_error) {
        e = _error;
        return done(new Error('Failed to parse user profile'));
      }
      profile = Profile.parse(json);
      profile.provider = 'rally';
      profile._raw = body;
      profile._json = json;
      return done(null, profile);
    });
  };


  /*
   * Expose `Strategy`.
   */

  module.exports = Strategy;

}).call(this);
