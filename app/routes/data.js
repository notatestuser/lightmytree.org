// Generated by CoffeeScript 1.4.0
(function() {
  var JustGiving, TreeDatabase, UserDatabase, inspect, _, _ref;

  _ = require('underscore')._;

  inspect = require('util').inspect;

  _ref = require('../database'), TreeDatabase = _ref.TreeDatabase, UserDatabase = _ref.UserDatabase;

  JustGiving = require('./helpers/justgiving');

  module.exports = function(app, config) {
    var charityService, donateFn, ensureAuth, jg, myTreeFn, recentCharities, sendDatabaseError, treeDb, userDb, withAuth, wrapError;
    console.log("Defining DATA routes");
    userDb = new UserDatabase(config);
    treeDb = new TreeDatabase(config);
    jg = config.justgiving;
    charityService = new JustGiving(jg.siteUrl, jg.apiUrl, jg.apiKey);
    recentCharities = [];
    withAuth = function(callback) {
      return function(req, res) {
        if ((req.user != null) && (req.user._id != null)) {
          return callback(req, res, req.user._id);
        }
        return callback(req, res);
      };
    };
    ensureAuth = function(callback) {
      return function(req, res) {
        if (!(req.user != null) || !(req.user._id != null)) {
          return res.send("Please authenticate", 401);
        } else {
          return callback(req, res, req.user._id, req.user);
        }
      };
    };
    sendDatabaseError = function(err, res) {
      console.error("ERROR: sendDatabaseError()\n" + inspect(err));
      console.trace('sendDatabaseError');
      return res.send("Database error", 500);
    };
    wrapError = function(res, callback) {
      return function(err, doc) {
        if (err) {
          return sendDatabaseError(err, res);
        } else {
          return typeof callback === "function" ? callback(doc) : void 0;
        }
      };
    };
    app.get("/json/typeahead_charities/:query", function(req, res) {
      var query;
      if ((req.params.query != null) && req.params.query.length > 2) {
        query = req.params.query;
        return charityService.charitySearch(query, 8, 1, wrapError(res, function(docs) {
          var results;
          results = docs.charitySearchResults || [];
          res.json(_.pluck(results, 'name'));
          if (results.length) {
            return recentCharities = _.chain(recentCharities).union(_.first(results, 4)).last(4).value();
          }
        }));
      } else {
        return res.send("More query data required", 500);
      }
    });
    app.get("/json/recent_charities", function(req, res) {
      return res.json(_.first(recentCharities, 4));
    });
    myTreeFn = ensureAuth(function(req, res, userId) {
      var createOrUpdateFn, data;
      data = req.body;
      createOrUpdateFn = function() {
        return userDb.findById(userId, function(err, userDoc) {
          if (!err) {
            return treeDb.createOrUpdate(userDoc, data, function(err, treeRes) {
              var treeIds;
              if (err) {
                sendDatabaseError(err, res);
              }
              if (treeRes && !err) {
                treeIds = userDoc.treeIds || (userDoc.treeIds = []);
                if (treeIds.indexOf(treeRes.id) === -1) {
                  treeIds.push(treeRes.id);
                }
                return userDb.saveDocument(userDoc, function(err, userRes) {
                  if (err) {
                    sendDatabaseError(err, res);
                  }
                  if (treeRes) {
                    return res.json({
                      id: treeRes.id
                    });
                  }
                });
              } else {
                return res.send("Unknown error", 500);
              }
            });
          } else {
            return sendDatabaseError(err, res);
          }
        });
      };
      if ((data.id != null) && (data.id.length != null)) {
        return treeDb.findById(data.id, function(err, doc) {
          if (doc && doc.user.id !== req.user._id) {
            console.error("ERROR: attempt to sabotage another user's tree");
            console.error("(user: " + userId + ", target ID: " + data.id + ")");
            return res.send("Unauthorised", 401);
          } else {
            if (!doc) {
              console.error("ERROR: tree `" + data.id + "` doesn't exist but referenced by `" + userId + "`; removing ID");
              delete data.id;
            }
            return createOrUpdateFn();
          }
        });
      } else {
        return createOrUpdateFn();
      }
    });
    app.post("/json/my_tree", myTreeFn);
    app.put("/json/my_tree", myTreeFn);
    app.get(/^\/json\/users\/?([a-zA-Z0-9_.-]+)?$/, withAuth(function(req, res, userId) {
      var id;
      id = req.params[0] || userId;
      if (id) {
        return userDb.findById(req.params[0] || userId, function(err, doc) {
          if (err) {
            sendDatabaseError(err, res);
          }
          if (doc) {
            res.json(_.omit(doc, UserDatabase.PrivateFields));
          }
          if (!doc) {
            return res.send("Not found", 404);
          }
        });
      } else {
        return res.send("Please authenticate or supply a user ID", 401);
      }
    }));
    app.get(/^\/json\/trees\/?([a-zA-Z0-9_.-]+)?$/, function(req, res) {
      if (req.params[0]) {
        return treeDb.findById(req.params[0], function(err, doc) {
          if (err) {
            return sendDatabaseError(err, res);
          } else {
            if (doc) {
              res.json(doc);
            }
            if (!doc) {
              return res.send("Not found", 404);
            }
          }
        });
      } else {
        return res.send("Not found", 404);
      }
    });
    donateFn = function(req, res) {
      var data, treeId;
      data = req.body;
      if (req.params != null) {
        treeId = req.params[0];
      }
      if (treeId && data) {
        return treeDb.findById(treeId, wrapError(res, function(treeDoc) {
          var donation, ourRef;
          if (!treeDoc) {
            return res.send("Not found", 404);
          } else {
            donation = _.pick(data, 'charityId', 'name', 'message', 'gift', 'giftDropX', 'giftDropY');
            donation.treeId = treeId;
            if (Object.keys(donation).length !== 7) {
              return res.send("More data required", 500);
            } else {
              try {
                ourRef = new Buffer(JSON.stringify(donation)).toString('base64');
                return res.json({
                  id: (new Date()).getTime(),
                  redirectUrl: charityService.getDonationUrl(donation.charityId, jg.callbackUrl, ourRef)
                });
              } catch (err) {
                return res.send(err, 500);
              }
            }
          }
        }));
      } else {
        return res.send("Not found", 404);
      }
    };
    app.post(/^\/json\/trees\/([a-zA-Z0-9_.-]+)\/donations$/, donateFn);
    app.put(/^\/json\/trees\/([a-zA-Z0-9_.-]+)\/donations$/, donateFn);
    return app.get("/callback/jg", function(req, res) {
      var decodedData, donation;
      if ((req.query.id != null) && (req.query.data != null)) {
        try {
          decodedData = JSON.parse(new Buffer(req.query.data, 'base64').toString('utf8'));
        } catch (err) {
          return res.send(err, 500);
        }
        console.log(decodedData);
        donation = _.pick(decodedData, 'charityId', 'name', 'message', 'gift', 'giftDropX', 'giftDropY');
        if ((decodedData.treeId != null) && Object.keys(donation).length === 6) {
          return charityService.getDonationStatus(req.query.id, wrapError(res, function(statusData) {
            return treeDb.findById(decodedData.treeId, wrapError(res, function(treeDoc) {
              var action, base, donations, found, _ref1;
              if (!treeDoc) {
                return res.send("Tree record not found", 404);
              } else {
                donations = (_ref1 = treeDoc.donationData) != null ? _ref1 : treeDoc.donationData = [];
                found = _.where(donations, {
                  id: statusData.id
                });
                if (found && found.length) {
                  base = found[0];
                  action = "updating";
                } else {
                  base = _.extend(donation, {
                    id: statusData.id,
                    amount: statusData.amount,
                    time: (new Date()).getTime(),
                    giftVisible: true
                  });
                  donations.push(base);
                  action = "creating";
                }
                base.status = statusData.status;
                console.log("" + action + " donation record " + base.id + " of " + decodedData.treeId);
                return treeDb.saveDocument(treeDoc, wrapError(res, function(saveRes) {
                  return res.redirect("/" + treeDoc._id + "/donated");
                }));
              }
            }));
          }));
        } else {
          return res.send("Some required data was missing from the request", 500);
        }
      } else {
        return res.send("incorrectly formatted re-entry URL", 500);
      }
    });
  };

}).call(this);
