// Generated by CoffeeScript 1.4.0
(function() {
  var TreeDatabase, UserDatabase, inspect, _, _ref;

  _ = require('underscore')._;

  inspect = require('util').inspect;

  _ref = require('../database'), TreeDatabase = _ref.TreeDatabase, UserDatabase = _ref.UserDatabase;

  module.exports = function(app, config) {
    var ensureAuth, myTreeFn, sendDatabaseError, treeDb, userDb, withAuth;
    console.log("Defining DATA routes");
    userDb = new UserDatabase(config);
    treeDb = new TreeDatabase(config);
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
          return callback(req, res, req.user._id);
        }
      };
    };
    sendDatabaseError = function(err, res) {
      console.error("ERROR: sendDatabaseError()\n" + inspect(err));
      console.trace('sendDatabaseError');
      return res.send("Database error", 500);
    };
    myTreeFn = ensureAuth(function(req, res, userId) {
      var createOrUpdateFn, data;
      data = req.body;
      createOrUpdateFn = function() {
        return userDb.findById(userId, function(err, userDoc) {
          if (err) {
            return sendDatabaseError(err, res);
          } else {
            return treeDb.createOrUpdate(userId, data, function(err, treeRes) {
              var treeIds;
              if (err) {
                sendDatabaseError(err, res);
              }
              if (treeRes && !err) {
                treeIds = userDoc.treeIds || (userDoc.treeIds = []);
                treeIds.push(treeRes.id);
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
    app.get(/^\/json\/users\/([a-z0-9]+)?$/, withAuth(function(req, res, userId) {
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
    return app.get(/^\/json\/trees\/([a-zA-Z0-9_]+)?$/, function(req, res) {
      if (req.params[0]) {
        return treeDb.findById(req.params[0], function(err, doc) {
          if (err) {
            sendDatabaseError(err, res);
          }
          if (doc) {
            res.json(doc);
          }
          if (!doc) {
            return res.send("Not found", 404);
          }
        });
      } else {
        return res.send("Not found", 404);
      }
    });
  };

}).call(this);
