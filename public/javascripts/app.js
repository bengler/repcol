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
    function GeometryBuilder() {
      this.artistGeometry = new THREE.CubeGeometry(1, 1, 1);
      this.workGeometry = new THREE.PlaneGeometry(1, 40);
      this.selectedArtistMaterial = new THREE.MeshLambertMaterial({
        opacity: 0.50,
        wireframe: false,
        transparent: true
      });
      this.scaleX = 200;
      this.scaleY = 40;
    }

    GeometryBuilder.prototype.selectedArtistMesh = function(artist) {
      return this.artistMesh(artist, this.selectedArtistMaterial, 1.03);
    };

    GeometryBuilder.prototype.artistMesh = function(artist, texture, multiplier) {
      var mesh;

      if (multiplier == null) {
        multiplier = 0;
      }
      mesh = new THREE.Mesh(this.artistGeometry, texture);
      mesh.position.set(artist._x * this.scaleX, artist._y * this.scaleY, 0);
      mesh.scale.x = (artist._width * this.scaleX) + (artist._height * multiplier);
      mesh.scale.y = (artist._height * this.scaleY) + (artist._height * multiplier);
      mesh.scale.z = (1 + artist._height * this.scaleY * 10) + (artist._height * multiplier);
      return mesh;
    };

    GeometryBuilder.prototype.build = function(scene, data) {
      var artist, currentArtist, face, gender, geometry, materialProperties, mesh, offset, workMaterial, _i, _j, _k, _len, _len1, _len2, _ref, _ref1, _ref2,
        _this = this;

      this.scene = scene;
      this.data = data;
      this.collatedArtistGeometries = [new THREE.Geometry(), new THREE.Geometry(), new THREE.Geometry()];
      this.collatedWorkGeometry = new THREE.Geometry();
      this.data.artists.forEach(function(artist) {
        var face, mesh, _i, _len, _ref;

        mesh = _this.artistMesh(artist);
        _ref = mesh.geometry.faces;
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          face = _ref[_i];
          face.color.r = artist.id;
        }
        THREE.GeometryUtils.merge(_this.collatedArtistGeometries[artist.gender], mesh);
        return artist.works.forEach(function(work) {
          var workMesh;

          if (!work.invalid) {
            workMesh = new THREE.Mesh(_this.workGeometry);
            workMesh.position.set(work._x * _this.scaleX, work._y * _this.scaleY, (mesh.scale.z / 2) + 0.1);
            workMesh.scale.x = work._width * _this.scaleX;
            workMesh.scale.y = work._height * _this.scaleY * 0.1;
            return THREE.GeometryUtils.merge(_this.collatedWorkGeometry, workMesh);
          }
        });
      });
      materialProperties = {
        depthTest: true,
        wireframe: false
      };
      currentArtist = 0;
      offset = 0;
      _ref = this.collatedArtistGeometries;
      for (gender = _i = 0, _len = _ref.length; _i < _len; gender = ++_i) {
        geometry = _ref[gender];
        _ref1 = geometry.faces;
        for (_j = 0, _len1 = _ref1.length; _j < _len1; _j++) {
          face = _ref1[_j];
          artist = face.color.r;
          if (offset === 0) {
            this.data.artistsKeyed[artist].focusFace = face;
          }
          offset += 1;
          if (currentArtist !== artist) {
            offset = 0;
            currentArtist = artist;
            this.data.artistsKeyed[artist].faces = [];
          }
          this.data.artistsKeyed[artist].faces.push(face);
        }
      }
      _ref2 = this.collatedArtistGeometries;
      for (gender = _k = 0, _len2 = _ref2.length; _k < _len2; gender = ++_k) {
        geometry = _ref2[gender];
        switch (gender) {
          case 0:
            materialProperties.color = "#346";
            break;
          case 1:
            materialProperties.color = "#6068ff";
            break;
          case 2:
            materialProperties.color = "#ff7060";
        }
        mesh = new THREE.Mesh(geometry, new THREE.MeshLambertMaterial(materialProperties));
        mesh.material.ambient = mesh.material.color;
        mesh.material.shinyness = 1;
        mesh.castShadow = true;
        mesh.receiveShadow = true;
        this.scene.add(mesh);
      }
      workMaterial = new THREE.MeshLambertMaterial({
        depthTest: true,
        opacity: 0.30,
        emissive: "#eee",
        wireframe: false,
        transparent: true
      });
      mesh = new THREE.Mesh(this.collatedWorkGeometry, workMaterial);
      return this.scene.add(mesh);
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
      d3.csv("data/artists.csv", function(err, rows) {
        rows.forEach(function(row) {
          row.works = [];
          row.id = +row.id;
          row.gender = +row.gender;
          row.dob = +row.dob;
          row.dod = +row.dod;
          _this.data.artistsKeyed[row.id] = row;
          if (row.dob === row.dod) {
            return row.dod += 1;
          }
        });
        _this.data.artists = rows;
        return artistsLoaded.resolve();
      });
      artistsLoaded.then(function() {
        return d3.csv("data/works.csv", function(err, rows) {
          var missing;

          missing = 0;
          rows.forEach(function(row) {
            var value;

            row.artistId = +row.artistId;
            row.produced = +row.produced;
            row.acquired = +row.acquired;
            row.invalid = row.produced === 0 || row.acquired === 0;
            if (row.produced === row.acquired) {
              row.acquired += 1;
            }
            value = _this.data.artistsKeyed[row["artistId"]];
            if (value != null) {
              _this.data.artistsKeyed[row["artistId"]].works.push(row);
              return _this.data.works.push(row);
            } else {
              missing += 1;
              return console.info(row);
            }
          });
          console.info("Missing artists for " + missing + " works!");
          _this.data.artists = _.sortBy(_this.data.artists, function(artist) {
            return artist.dob;
          });
          _this.data.artists.forEach(function(artist, i) {
            return artist.index = i;
          });
          _this.data.artists.forEach(function(artist) {
            return artist.works = _.sortBy(artist.works, function(work) {
              return work.produced;
            });
          });
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
  var SceneKeeper,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  SceneKeeper = (function() {
    var SHOW_STATS, geometryBuilder, visualStructure;

    visualStructure = require('./visualStructure');

    geometryBuilder = require('./geometryBuilder');

    SHOW_STATS = true;

    function SceneKeeper() {
      this.resize = __bind(this.resize, this);
      this.updateArtistName = __bind(this.updateArtistName, this);
      this.blankArtistName = __bind(this.blankArtistName, this);
      this.mousemove = __bind(this.mousemove, this);
      this.tweenCamera = __bind(this.tweenCamera, this);
      this.click = __bind(this.click, this);
      this.keydown = __bind(this.keydown, this);
    }

    SceneKeeper.prototype.init = function(data) {
      this.data = data;
      visualStructure.init(data);
      this.initScene();
      return geometryBuilder.build(this.scene, this.data);
    };

    SceneKeeper.prototype.initScene = function() {
      var FAR, HEIGHT, MARGIN, SCREEN_HEIGHT, SCREEN_WIDTH, WIDTH, bluriness, container, effectVignette, hblur, light, renderModel, renderTargetParameters, vblur;

      this.scene = new THREE.Scene;
      WIDTH = window.innerWidth || 2;
      HEIGHT = window.innerHeight || (2 + 2 * MARGIN);
      MARGIN = 0;
      SCREEN_WIDTH = WIDTH;
      SCREEN_HEIGHT = HEIGHT - 2 * MARGIN;
      FAR = 10000;
      this.camera = new THREE.PerspectiveCamera(35, SCREEN_WIDTH / SCREEN_HEIGHT, 0.1, FAR);
      this.camera.position.set(-190, 75, 0);
      this.camera.lookAt(this.scene.position);
      this.controls = new THREE.TrackballControls(this.camera);
      this.controls.rotateSpeed = 1.0;
      this.controls.zoomSpeed = 1.2;
      this.controls.panSpeed = 0.8;
      this.controls.noZoom = false;
      this.controls.noPan = false;
      this.controls.staticMoving = false;
      this.controls.dynamicDampingFactor = 0.3;
      this.controls.keys = [65, 83, 68];
      this.scene.add(new THREE.AmbientLight(0x808080));
      light = new THREE.SpotLight(0xffffff, 1.0);
      light.position.set(50, 150, 0);
      light.castShadow = true;
      light.shadowCameraNear = 100;
      light.shadowCameraFar = this.camera.far;
      light.shadowCameraFov = 100;
      light.shadowBias = -0.00122;
      light.shadowDarkness = 0.1;
      light.shadowMapWidth = 4096;
      light.shadowMapHeight = 4096;
      this.scene.add(light);
      light = new THREE.SpotLight(0xffffff, 0.6);
      light.position.set(50, 150, 100);
      this.scene.add(light);
      this.renderer = new THREE.WebGLRenderer({
        antialias: true
      });
      this.renderer.setSize(SCREEN_WIDTH, SCREEN_HEIGHT);
      this.renderer.setClearColor(new THREE.Color(0xD0D0D8));
      this.renderer.shadowMapEnabled = true;
      this.renderer.shadowMapType = THREE.PCFShadowMap;
      this.renderer.sortObjects = false;
      this.renderer.autoClear = false;
      renderTargetParameters = {
        minFilter: THREE.LinearFilter,
        magFilter: THREE.LinearFilter,
        format: THREE.RGBFormat
      };
      this.renderTarget = new THREE.WebGLRenderTarget(SCREEN_WIDTH * 1, SCREEN_HEIGHT * 1, renderTargetParameters);
      effectVignette = new THREE.ShaderPass(THREE.VignetteShader);
      effectVignette.uniforms['darkness'].value = 0.4;
      hblur = new THREE.ShaderPass(THREE.HorizontalTiltShiftShader);
      vblur = new THREE.ShaderPass(THREE.VerticalTiltShiftShader);
      bluriness = 2;
      hblur.uniforms['h'].value = bluriness / SCREEN_WIDTH;
      vblur.uniforms['v'].value = bluriness / SCREEN_HEIGHT;
      hblur.uniforms['r'].value = vblur.uniforms['r'].value = 0.5;
      this.composer = new THREE.EffectComposer(this.renderer, this.renderTarget);
      renderModel = new THREE.RenderPass(this.scene, this.camera);
      this.composer.addPass(renderModel);
      this.composer.addPass(effectVignette);
      this.composer.addPass(hblur);
      this.composer.addPass(vblur);
      vblur.renderToScreen = true;
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
      this.mouse = new THREE.Vector2();
      this.projector = new THREE.Projector();
      this.animate();
      window.addEventListener('dblclick', this.click, false);
      window.addEventListener('mousemove', this.mousemove, false);
      window.addEventListener('resize', this.resize, false);
      window.addEventListener('resize', this.resize, false);
      window.addEventListener('keydown', this.keydown, false);
      return this.currentArtist = void 0;
    };

    SceneKeeper.prototype.keydown = function(event) {
      if (this.currentArtist) {
        console.info(event.keyCode);
        switch (event.keyCode) {
          case 37:
            if (this.currentArtist.index !== 0) {
              return this.focusArtist(this.data.artists[this.currentArtist.index - 1]);
            }
            break;
          case 39:
            if (this.currentArtist.index !== this.data.artists.length - 1) {
              return this.focusArtist(this.data.artists[this.currentArtist.index + 1]);
            }
        }
      }
    };

    SceneKeeper.prototype.click = function(event) {
      var res;

      res = this.findArtist(event);
      if (res == null) {
        if (this.currentArtist) {
          return this.defocusArtist();
        }
      } else {
        return this.focusArtist(res.artist);
      }
    };

    SceneKeeper.prototype.defocusArtist = function() {
      var vec;

      this.currentArtist = void 0;
      this.scene.remove(this.currentArtistMesh);
      $(".container h2").removeClass("selected");
      vec = new THREE.Vector3();
      vec.subVectors(this.camera.position, this.controls.target);
      vec.setLength(vec.length() * 3);
      vec.addVectors(vec, this.controls.target);
      return this.tweenCamera(vec, this.controls.target);
    };

    SceneKeeper.prototype.focusArtist = function(artist) {
      var distToCenter, lookAt, mesh, oldLookAt, size, v, vec;

      this.currentArtist = artist;
      this.updateArtistName(this.currentArtist);
      $(".container h2").addClass("selected");
      if (this.currentArtistMesh) {
        this.scene.remove(this.currentArtistMesh);
      }
      mesh = geometryBuilder.selectedArtistMesh(artist);
      this.scene.add(mesh);
      this.currentArtistMesh = mesh;
      oldLookAt = this.controls.target;
      lookAt = artist.focusFace.centroid.clone();
      v = new THREE.Vector3();
      v.subVectors(lookAt, this.controls.target);
      size = 1 + artist._height * 160;
      distToCenter = size / Math.sin(Math.PI / 180.0 * this.camera.fov * 0.5);
      vec = new THREE.Vector3();
      vec.subVectors(this.camera.position, oldLookAt);
      vec.setLength(distToCenter);
      vec.addVectors(vec, lookAt);
      return this.tweenCamera(vec, lookAt);
    };

    SceneKeeper.prototype.tweenCamera = function(position, target) {
      TWEEN.removeAll();
      new TWEEN.Tween(this.camera.position).to({
        x: position.x,
        y: position.y,
        z: position.z
      }, 1000).easing(TWEEN.Easing.Exponential.Out).start();
      return new TWEEN.Tween(this.controls.target).to({
        x: target.x,
        y: target.y,
        z: target.z
      }, 800).easing(TWEEN.Easing.Exponential.Out).start();
    };

    SceneKeeper.prototype.findArtist = function(event) {
      var artist, face, intersects, ray, res, vector;

      this.mouse.x = (event.clientX / window.innerWidth) * 2 - 1;
      this.mouse.y = -(event.clientY / window.innerHeight) * 2 + 1;
      vector = new THREE.Vector3(this.mouse.x, this.mouse.y, 0.5);
      this.projector.unprojectVector(vector, this.camera);
      ray = new THREE.Raycaster(this.camera.position, vector.sub(this.camera.position).normalize());
      intersects = ray.intersectObjects(this.scene.children);
      if (intersects.length > 0) {
        face = intersects[0].face;
        artist = this.data.artistsKeyed[face.color.r];
        res = {
          object: intersects[0],
          artist: artist,
          face: face
        };
        return res;
      }
      return void 0;
    };

    SceneKeeper.prototype.mousemove = function(event) {
      var res;

      if (this.currentArtist != null) {
        return;
      }
      res = this.findArtist(event);
      if (res != null) {
        return this.updateArtistName(res.artist);
      } else {
        return this.blankArtistName();
      }
    };

    SceneKeeper.prototype.blankArtistName = function() {
      $('.container h2').text("");
      return $('.container p').text("");
    };

    SceneKeeper.prototype.updateArtistName = function(artist) {
      var dod;

      $('.container h2').text(artist.firstname + " " + artist.lastname);
      dod = artist.dod === 2013 ? "" : artist.dod;
      return $('.container p').text(artist.dob + " - " + dod);
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
      TWEEN.update();
      return this.controls.update();
    };

    SceneKeeper.prototype.render = function() {
      return this.composer.render();
    };

    SceneKeeper.prototype.resize = function() {
      var SCREEN_HEIGHT, SCREEN_WIDTH;

      SCREEN_WIDTH = window.innerWidth;
      SCREEN_HEIGHT = window.innerHeight;
      this.renderer.setSize(SCREEN_WIDTH, SCREEN_HEIGHT);
      this.camera.aspect = SCREEN_WIDTH / SCREEN_HEIGHT;
      return this.camera.updateProjectionMatrix();
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
      var workHeight, workIndex,
        _this = this;

      this.data = data;
      this.tracks = [];
      console.info("Tally");
      console.info("Number of artists: " + this.data.artists.length);
      console.info("Number of works: " + this.data.works.length);
      this.startYear = this.data.artists[0].dob;
      this.endYear = new Date().getFullYear();
      console.info("Normalizing against: " + this.startYear + " - " + this.endYear);
      this.numberOfWorks = this.data.works.length;
      console.info("Allocating artist space");
      workHeight = 1 / this.numberOfWorks;
      workIndex = -0.5;
      this.data.artists.forEach(function(artist) {
        var height, width, x;

        height = artist.works.length / _this.numberOfWorks;
        x = _this.yearToFloat(artist.dob);
        width = _this.yearToFloat(artist.dod) - x;
        artist._x = x - 0.5 + (width / 2);
        artist._y = workIndex + height / 2;
        artist._height = height;
        artist._width = width;
        artist.works.forEach(function(work, i) {
          var wHeight, wWidth, wX, wY;

          if (!work.invalid) {
            wHeight = workHeight;
            wX = _this.yearToFloat(work.produced);
            wWidth = _this.yearToFloat(work.acquired) - wX;
            wY = workIndex + (workHeight * i);
            work._x = wX - 0.5 + (wWidth / 2);
            work._y = wY + wHeight / 2;
            work._height = wHeight;
            return work._width = wWidth;
          }
        });
        return workIndex += height + workHeight * 30;
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

