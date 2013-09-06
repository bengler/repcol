(function(/*! Brunch !*/) {
  'use strict';

  var globals = typeof window !== 'undefined' ? window : global;
  if (typeof globals.require === 'function') return;

  var modules = {};
  var cache = {};

  var has = function(object, name) {
    return ({}).hasOwnProperty.call(object, name);
  };

  var expand = function(root, name) {
    var results = [], parts, part;
    if (/^\.\.?(\/|$)/.test(name)) {
      parts = [root, name].join('/').split('/');
    } else {
      parts = name.split('/');
    }
    for (var i = 0, length = parts.length; i < length; i++) {
      part = parts[i];
      if (part === '..') {
        results.pop();
      } else if (part !== '.' && part !== '') {
        results.push(part);
      }
    }
    return results.join('/');
  };

  var dirname = function(path) {
    return path.split('/').slice(0, -1).join('/');
  };

  var localRequire = function(path) {
    return function(name) {
      var dir = dirname(path);
      var absolute = expand(dir, name);
      return globals.require(absolute);
    };
  };

  var initModule = function(name, definition) {
    var module = {id: name, exports: {}};
    definition(module.exports, localRequire(name), module);
    var exports = cache[name] = module.exports;
    return exports;
  };

  var require = function(name) {
    var path = expand(name, '.');

    if (has(cache, path)) return cache[path];
    if (has(modules, path)) return initModule(path, modules[path]);

    var dirIndex = expand(path, './index');
    if (has(cache, dirIndex)) return cache[dirIndex];
    if (has(modules, dirIndex)) return initModule(dirIndex, modules[dirIndex]);

    throw new Error('Cannot find module "' + name + '"');
  };

  var define = function(bundle) {
    for (var key in bundle) {
      if (has(bundle, key)) {
        modules[key] = bundle[key];
      }
    }
  }

  globals.require = require;
  globals.require.define = define;
  globals.require.brunch = true;
})();

window.require.define({"geometryBuilder": function(exports, require, module) {
  var GeometryBuilder;

  GeometryBuilder = (function() {
    function GeometryBuilder() {}

    GeometryBuilder.prototype.build = function(scene, data) {
      var geometry, material, scaleX, scaleY,
        _this = this;

      this.scene = scene;
      this.data = data;
      scaleX = 60;
      scaleY = 20;
      geometry = new THREE.CubeGeometry(1, 1, 1);
      material = new THREE.MeshLambertMaterial({
        color: 0xFF0000
      });
      return this.data.artists.forEach(function(artist) {
        var mesh;

        material = new THREE.MeshLambertMaterial();
        material.color.setRGB(Math.random(), 0, 0);
        mesh = new THREE.Mesh(geometry, material);
        mesh.position.set(artist._x * scaleX, artist._y * scaleY, 0);
        mesh.scale.x = artist._width * scaleX;
        mesh.scale.y = artist._height * scaleY;
        return _this.scene.add(mesh);
      });
    };

    GeometryBuilder.prototype.yearToFloat = function(year) {
      return (year - this.startYear) / this.endYear;
    };

    return GeometryBuilder;

  })();

  module.exports = new GeometryBuilder;
  
}});

window.require.define({"importer": function(exports, require, module) {
  var Importer;

  Importer = (function() {
    function Importer() {
      this.data = {
        artistsKeyed: {},
        works: []
      };
    }

    Importer.prototype.load = function() {
      var artistsLoaded,
        _this = this;

      artistsLoaded = $.Deferred();
      d3.csv("data/filtered_artists.csv", function(err, rows) {
        rows.forEach(function(row) {
          row.works = [];
          return _this.data.artistsKeyed[row["KunstnerNøkkel"]] = row;
        });
        _this.data.artists = rows;
        return artistsLoaded.resolve();
      });
      artistsLoaded.then(function() {
        return d3.csv("data/filtered_artwork.csv", function(err, rows) {
          var artists_before_filtering, missing;

          missing = 0;
          rows.forEach(function(row) {
            var value;

            value = _this.data.artistsKeyed[row["KunstnerNøkkel"]];
            if (value != null) {
              _this.data.artistsKeyed[row["KunstnerNøkkel"]].works.push(row);
              return _this.data.works.push(row);
            } else {
              return missing += 1;
            }
          });
          console.info("Missing artists for " + missing + " works!");
          artists_before_filtering = _this.data.artists.length;
          _this.data.artists = _this.data.artists.filter(function(artist) {
            var filter;

            filter = artist.works.length !== 0;
            if (!filter) {
              delete _this.data.artistsKeyed[artist["KunstnerNøkkel"]];
            }
            return filter;
          });
          console.info("Removed " + (artists_before_filtering - _this.data.artists.length) + " out of " + artists_before_filtering + " of artists as they didn't have works");
          _this.data.artists = _.sortBy(_this.data.artists, function(artist) {
            return artist["FØDT"];
          });
          _this.data.artists.forEach(function(artist) {
            return _.sortBy(artist.works, function(work) {
              return work["Avledet datering"];
            });
          });
          console.info(_this.data.artists[1]);
          console.info(_this.data.works[1]);
          return _this.dataLoaded.resolve(_this.data);
        });
      });
      return this.dataLoaded = $.Deferred();
    };

    return Importer;

  })();

  module.exports = new Importer;
  
}});

window.require.define({"initialize": function(exports, require, module) {
  var _ref, _ref1, _ref2, _ref3, _ref4;

  if ((_ref = this.Hipster) == null) {
    this.Hipster = {};
  }

  if ((_ref1 = Hipster.Routers) == null) {
    Hipster.Routers = {};
  }

  if ((_ref2 = Hipster.Views) == null) {
    Hipster.Views = {};
  }

  if ((_ref3 = Hipster.Models) == null) {
    Hipster.Models = {};
  }

  if ((_ref4 = Hipster.Collections) == null) {
    Hipster.Collections = {};
  }

  $(function() {
    var AppView, data, importer, packHierarchy, sceneKeeper;

    require('../lib/app_helpers');
    importer = require('./importer');
    sceneKeeper = require('./sceneKeeper');
    packHierarchy = require('./pack_hierarchy');
    Hipster.Views.AppView = new (AppView = require('views/app_view'));
    Backbone.history.start({
      pushState: true
    });
    console.info("Importing");
    return data = importer.load().then(function(data) {
      console.info("Done loading. Firing scene.");
      return sceneKeeper.init(data);
    });
  });
  
}});

window.require.define({"lib/app_helpers": function(exports, require, module) {
  (function() {
    Swag.Config.partialsPath = '../views/templates/';
    return (function() {
      var console, dummy, method, methods, _results;

      console = window.console = window.console || {};
      method = void 0;
      dummy = function() {};
      methods = 'assert,count,debug,dir,dirxml,error,exception,\
                     group,groupCollapsed,groupEnd,info,log,markTimeline,\
                     profile,profileEnd,time,timeEnd,trace,warn'.split(',');
      _results = [];
      while (method = methods.pop()) {
        _results.push(console[method] = console[method] || dummy);
      }
      return _results;
    })();
  })();
  
}});

window.require.define({"lib/view": function(exports, require, module) {
  var View, _ref,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  module.exports = View = (function(_super) {
    __extends(View, _super);

    function View() {
      _ref = View.__super__.constructor.apply(this, arguments);
      return _ref;
    }

    View.prototype.tagName = 'section';

    View.prototype.template = function() {};

    View.prototype.initialize = function() {
      return this.render();
    };

    View.prototype.getRenderData = function() {
      var _ref1;

      return (_ref1 = this.model) != null ? _ref1.toJSON() : void 0;
    };

    View.prototype.render = function() {
      this.beforeRender();
      this.$el.html(this.template(this.getRenderData()));
      this.afterRender();
      return this;
    };

    View.prototype.beforeRender = function() {};

    View.prototype.afterRender = function() {};

    View.prototype.destroy = function() {
      this.undelegateEvents();
      this.$el.removeData().unbind();
      this.remove();
      return Backbone.View.prototype.remove.call(this);
    };

    return View;

  })(Backbone.View);
  
}});

window.require.define({"lib/view_collection": function(exports, require, module) {
  var View, ViewCollection, methods, _ref,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  View = require('./view');

  ViewCollection = (function(_super) {
    __extends(ViewCollection, _super);

    function ViewCollection() {
      this.renderOne = __bind(this.renderOne, this);    _ref = ViewCollection.__super__.constructor.apply(this, arguments);
      return _ref;
    }

    ViewCollection.prototype.collection = new Backbone.Collection();

    ViewCollection.prototype.view = new View();

    ViewCollection.prototype.views = [];

    ViewCollection.prototype.length = function() {
      return this.views.length;
    };

    ViewCollection.prototype.add = function(views, options) {
      var view, _i, _len;

      if (options == null) {
        options = {};
      }
      views = _.isArray(views) ? views.slice() : [views];
      for (_i = 0, _len = views.length; _i < _len; _i++) {
        view = views[_i];
        if (!this.get(view.cid)) {
          this.views.push(view);
          if (!options.silent) {
            this.trigger('add', view, this);
          }
        }
      }
      return this;
    };

    ViewCollection.prototype.get = function(cid) {
      return this.find(function(view) {
        return view.cid === cid;
      }) || null;
    };

    ViewCollection.prototype.remove = function(views, options) {
      var view, _i, _len;

      if (options == null) {
        options = {};
      }
      views = _.isArray(views) ? views.slice() : [views];
      for (_i = 0, _len = views.length; _i < _len; _i++) {
        view = views[_i];
        this.destroy(view);
        if (!options.silent) {
          this.trigger('remove', view, this);
        }
      }
      return this;
    };

    ViewCollection.prototype.destroy = function(view, options) {
      var _views;

      if (view == null) {
        view = this;
      }
      if (options == null) {
        options = {};
      }
      _views = this.filter(_view)(function() {
        return view.cid !== _view.cid;
      });
      this.views = _views;
      view.undelegateEvents();
      view.$el.removeData().unbind();
      view.remove();
      Backbone.View.prototype.remove.call(view);
      if (!options.silent) {
        this.trigger('remove', view, this);
      }
      return this;
    };

    ViewCollection.prototype.reset = function(views, options) {
      var view, _i, _j, _len, _len1, _ref1;

      if (options == null) {
        options = {};
      }
      views = _.isArray(views) ? views.slice() : [views];
      _ref1 = this.views;
      for (_i = 0, _len = _ref1.length; _i < _len; _i++) {
        view = _ref1[_i];
        this.destroy(view, options);
      }
      if (views.length !== 0) {
        for (_j = 0, _len1 = views.length; _j < _len1; _j++) {
          view = views[_j];
          this.add(view, options);
        }
        if (!options.silent) {
          this.trigger('reset', view, this);
        }
      }
      return this;
    };

    ViewCollection.prototype.renderOne = function(model) {
      var view;

      view = new this.view({
        model: model
      });
      this.$el.append(view.render().el);
      this.add(view);
      return this;
    };

    ViewCollection.prototype.renderAll = function() {
      this.collection.each(this.renderOne);
      return this;
    };

    return ViewCollection;

  })(View);

  methods = ['forEach', 'each', 'map', 'reduce', 'reduceRight', 'find', 'detect', 'filter', 'select', 'reject', 'every', 'all', 'some', 'any', 'include', 'contains', 'invoke', 'max', 'min', 'sortBy', 'sortedIndex', 'toArray', 'size', 'first', 'initial', 'rest', 'last', 'without', 'indexOf', 'shuffle', 'lastIndexOf', 'isEmpty', 'groupBy'];

  _.each(methods, function(method) {
    return ViewCollection.prototype[method] = function() {
      return _[method].apply(_, [this.views].concat(_.toArray(arguments)));
    };
  });

  module.exports = ViewCollection;
  
}});

window.require.define({"pack_hierarchy": function(exports, require, module) {
  var packHierarchy;

  packHierarchy = (function() {
    function packHierarchy(data, options) {
      var genderBalance, h, m, node, nodes, offset, pack, r, root, vis, w, x, y, zoom;

      if (options == null) {
        options = {};
      }
      m = Math.min($(window).width(), $(window).height());
      w = h = r = m;
      x = d3.scale.linear().range([0, r]);
      y = d3.scale.linear().range([0, r]);
      offset = options.offset || 0;
      pack = d3.layout.pack().size([r, r]).value(function(d) {
        return d.count || 0;
      }).children(function(d) {
        return d.values;
      });
      vis = d3.select("svg").append("svg:g").attr("class", options["class"]).attr("transform", "translate(" + (w - r) / 2 + "," + (h - r) / 2 + ")");
      genderBalance = function(d) {
        var ratio;

        if ((d.values != null) || (d.countWomen == null) || (d.countWomen == null)) {
          return "#666";
        }
        ratio = d.countMen / (d.countMen + d.countWomen);
        return colorbrewer.RdBu[11][Math.floor(ratio * 11)];
      };
      node = root = data;
      nodes = pack.nodes(root);
      vis.selectAll("circle").data(nodes).enter().append("svg:circle").attr("class", function(d) {
        if (d.children) {
          return "parent";
        } else {
          return "child";
        }
      }).style("fill", function(d) {
        return genderBalance(d);
      }).attr("cx", function(d) {
        return d.x;
      }).attr("cy", function(d) {
        return d.y;
      }).attr("r", function(d) {
        return d.r;
      }).on("click", function(d) {
        return zoom(d !== node ? d : root);
      }).append("svg:title").text(function(d) {
        return d.label;
      });
      vis.selectAll("text").data(nodes).enter().append("svg:text").attr("class", function(d) {
        if (d.values) {
          return "parent";
        } else {
          return "child";
        }
      }).attr("x", function(d) {
        return d.x;
      }).attr("y", function(d) {
        return d.y;
      }).attr("dy", ".35em").attr("text-anchor", "middle").style("opacity", function(d) {
        if (d.r > 40 && d.depth === 1) {
          return 1;
        } else {
          return 0;
        }
      }).text(function(d) {
        return d.label;
      });
      zoom = function(d, i) {
        var k, t;

        console.info(d);
        k = r / d.r / 2;
        x.domain([d.x - d.r, d.x + d.r]);
        y.domain([d.y - d.r, d.y + d.r]);
        t = vis.transition().duration(750);
        t.selectAll("circle").attr("cx", function(de) {
          return x(de.x);
        }).attr("cy", function(de) {
          return y(de.y);
        }).attr("r", function(de) {
          return k * de.r;
        });
        t.selectAll("text").attr("x", function(de) {
          return x(de.x);
        }).attr("y", function(de) {
          return y(de.y);
        }).style("opacity", function(de) {
          if (k * de.r > 30 && (de.depth === d.depth + 1 || !de.values)) {
            return 1;
          } else {
            return 0;
          }
        });
        node = d;
        return d3.event.stopPropagation();
      };
      d3.select(window).on("click", function() {
        return zoom(root);
      });
    }

    return packHierarchy;

  })();

  module.exports = packHierarchy;
  
}});

window.require.define({"routers/app_router": function(exports, require, module) {
  var AppRouter, _ref,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  module.exports = AppRouter = (function(_super) {
    __extends(AppRouter, _super);

    function AppRouter() {
      _ref = AppRouter.__super__.constructor.apply(this, arguments);
      return _ref;
    }

    AppRouter.prototype.routes = {
      '': function() {}
    };

    return AppRouter;

  })(Backbone.Router);
  
}});

window.require.define({"sceneKeeper": function(exports, require, module) {
  var SceneKeeper;

  SceneKeeper = (function() {
    var SHOW_STATS, geometryBuilder, visualStructure;

    visualStructure = require('./visualStructure');

    geometryBuilder = require('./geometryBuilder');

    SHOW_STATS = true;

    function SceneKeeper() {}

    SceneKeeper.prototype.init = function(data) {
      this.data = visualStructure.init(data);
      this.initScene();
      return geometryBuilder.build(this.scene, this.data);
    };

    SceneKeeper.prototype.initScene = function() {
      var container, geometry, light, material, mesh;

      this.scene = new THREE.Scene;
      this.camera = new THREE.PerspectiveCamera(35, window.innerWidth / window.innerHeight, 0.1, 10000);
      this.camera.position.set(0, 0, -90);
      this.camera.lookAt(this.scene.position);
      this.controls = new THREE.TrackballControls(this.camera);
      this.controls.rotateSpeed = 1.0;
      this.controls.zoomSpeed = 1.2;
      this.controls.panSpeed = 0.8;
      this.controls.noZoom = false;
      this.controls.noPan = false;
      this.controls.staticMoving = true;
      this.controls.dynamicDampingFactor = 0.3;
      this.controls.keys = [65, 83, 68];
      this.scene.fog = new THREE.FogExp2(0xcccccc, 0.001103);
      geometry = new THREE.CubeGeometry(1, 1, 1);
      material = new THREE.MeshLambertMaterial({
        color: 0xFF0000
      });
      mesh = new THREE.Mesh(geometry, material);
      this.scene.add(mesh);
      light = new THREE.PointLight(0xFFFF00);
      light.position.set(10, 6, 15);
      this.scene.add(light);
      this.renderer = new THREE.WebGLRenderer({
        antialias: true
      });
      this.renderer.setSize(window.innerWidth, window.innerHeight);
      this.renderer.setClearColor(new THREE.Color(0xFFFFFF));
      container = document.createElement('div');
      document.body.appendChild(container);
      container.appendChild(this.renderer.domElement);
      if (SHOW_STATS) {
        this.stats = new Stats();
        this.stats.domElement.style.position = 'absolute';
        this.stats.domElement.style.top = '0px';
        this.stats.domElement.style.left = '0px';
        container.appendChild(this.stats.domElement);
      }
      return this.animate();
    };

    SceneKeeper.prototype.animate = function() {
      var _this = this;

      this.render();
      if (SHOW_STATS) {
        this.stats.update();
      }
      if (!this.stopped) {
        requestAnimationFrame(function() {
          return _this.animate();
        });
      }
      return this.controls.update();
    };

    SceneKeeper.prototype.render = function() {
      return this.renderer.render(this.scene, this.camera);
    };

    return SceneKeeper;

  })();

  module.exports = new SceneKeeper;
  
}});

window.require.define({"views/app_view": function(exports, require, module) {
  var AppRouter, AppView, View, _ref,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  View = require('../lib/view');

  AppRouter = require('../routers/app_router');

  module.exports = AppView = (function(_super) {
    __extends(AppView, _super);

    function AppView() {
      _ref = AppView.__super__.constructor.apply(this, arguments);
      return _ref;
    }

    AppView.prototype.el = 'body.application';

    AppView.prototype.initialize = function() {
      var _ref1;

      this.router = new AppRouter();
      return typeof Hipster !== "undefined" && Hipster !== null ? (_ref1 = Hipster.Routers) != null ? _ref1.AppRouter = this.router : void 0 : void 0;
    };

    return AppView;

  })(View);
  
}});

window.require.define({"visualStructure": function(exports, require, module) {
  var VisualStructure;

  VisualStructure = (function() {
    function VisualStructure() {}

    VisualStructure.prototype.init = function(data) {
      var workIndex,
        _this = this;

      this.data = data;
      this.tracks = [];
      console.info("Tally");
      console.info("Number of artists: " + this.data.artists.length);
      console.info("Number of works: " + this.data.works.length);
      this.startYear = this.data.artists[0]["FØDT"];
      this.endYear = new Date().getFullYear();
      console.info("Normalizing against: " + this.startYear + " - " + this.endYear);
      this.numberOfWorks = this.data.works.length;
      console.info("Allocating artist space");
      workIndex = -0.5;
      this.data.artists.forEach(function(artist) {
        var height, width, x;

        height = artist.works.length / _this.numberOfWorks;
        x = _this.yearToFloat(artist["FØDT"]);
        width = _this.yearToFloat(artist["DØD"]) - x;
        artist._x = x - 0.5 - (width / 2);
        artist._y = workIndex + height / 2;
        artist._height = height;
        artist._width = _this.yearToFloat(artist["DØD"]) - x;
        return workIndex += height;
      });
      console.info("Done");
      return this.data;
    };

    VisualStructure.prototype.yearToFloat = function(year) {
      return (year - this.startYear) / (this.endYear - this.startYear);
    };

    return VisualStructure;

  })();

  module.exports = new VisualStructure;
  
}});

