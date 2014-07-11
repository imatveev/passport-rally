_ = require 'lodash'

###
 * Parse profile.
 *
 * @param {Object|String} json
 * @return {Object}
 * @api private
###
exports.parse = (json) ->
  if _.isString json
    json = JSON.parse json

  profile =
    id: String(json.User._refObjectUUID)
    displayName: json.User.DisplayName
    username: json.User.UserName

  if json.User.EmailAddress?
    profile.emails = [{ value: json.User.EmailAddress }]
  
  return profile
