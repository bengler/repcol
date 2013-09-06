window.THREE = require("three");

var fs = require("fs");


var scene = new THREE.Scene();

var WIDTH = window.innerWidth;
var HEIGHT = window.innerHeight;

var camera = new THREE.PerspectiveCamera( 30, WIDTH / HEIGHT, 1, 10000);

var renderer = new THREE.WebGLRenderer({antialias: true});
renderer.setSize( WIDTH, HEIGHT );
document.body.appendChild( renderer.domElement );

var geometry = new THREE.SphereGeometry(200, 50, 50);

var material = (function() {
  return new THREE.ShaderMaterial({
    uniforms: {
      texture: { type: "t", value: THREE.ImageUtils.loadTexture("res/world.jpg") }
    },
    vertexShader: fs.readFileSync(__dirname + '/shaders/vertex_shader.glsl'),
    fragmentShader: fs.readFileSync(__dirname + '/shaders/fragment_shader.glsl'),
    blending: THREE.AdditiveBlending,
    depthTest: false,
    transparent: false
  });
}());

var mesh = new THREE.Mesh(geometry, material);

scene.add(mesh);

var curZoomSpeed = 0;
var mouse = { x: 0, y: 0 }, mouseOnDown = { x: 0, y: 0 };
var rotation = { x: 0, y: 0 },
  target = { x: Math.PI*0.6, y: Math.PI / 3.5 },
  targetOnDown = { x: 0, y: 0 };

var distance = 100000, distanceTarget = 100000;

camera.position.z = distance;

var padding = 40;
var PI_HALF = Math.PI / 2;

function animate() {
  requestAnimationFrame(animate);
  render();
}
var overRenderer;

(function(){

  function onMouseDown(event) {
    event.preventDefault();

    container.addEventListener('mousemove', onMouseMove, false);
    container.addEventListener('mouseup', onMouseUp, false);
    container.addEventListener('mouseout', onMouseOut, false);

    mouseOnDown.x = - event.clientX;
    mouseOnDown.y = event.clientY;

    targetOnDown.x = target.x;
    targetOnDown.y = target.y;

    container.style.cursor = 'move';
  }

  function onMouseMove(event) {
    mouse.x = - event.clientX;
    mouse.y = event.clientY;

    var zoomDamp = distance/1000;

    target.x = targetOnDown.x + (mouse.x - mouseOnDown.x) * 0.005 * zoomDamp;
    target.y = targetOnDown.y + (mouse.y - mouseOnDown.y) * 0.005 * zoomDamp;

    target.y = target.y > PI_HALF ? PI_HALF : target.y;
    target.y = target.y < - PI_HALF ? - PI_HALF : target.y;
  }

  function onMouseUp(event) {
    container.removeEventListener('mousemove', onMouseMove, false);
    container.removeEventListener('mouseup', onMouseUp, false);
    container.removeEventListener('mouseout', onMouseOut, false);
    container.style.cursor = 'auto';
  }

  function onMouseOut(event) {
    container.removeEventListener('mousemove', onMouseMove, false);
    container.removeEventListener('mouseup', onMouseUp, false);
    container.removeEventListener('mouseout', onMouseOut, false);
  }

  function onMouseWheel(event) {
    event.preventDefault();
    if (overRenderer) {
      zoom(event.wheelDeltaY * -0.3);
    }
    return false;
  }

  function onDocumentKeyDown(event) {
    switch (event.keyCode) {
      case 38:
        zoom(100);
        event.preventDefault();
        break;
      case 40:
        zoom(-100);
        event.preventDefault();
        break;
    }
  }

  function onWindowResize( event ) {
    camera.aspect = window.innerWidth / window.innerHeight;
    camera.updateProjectionMatrix();
    renderer.setSize( window.innerWidth, window.innerHeight );
  }

  var container = renderer.domElement;
  container.addEventListener('mousedown', onMouseDown, false);
  container.addEventListener('mousewheel', onMouseWheel, false);

  document.addEventListener('keydown', onDocumentKeyDown, false);

  window.addEventListener('resize', onWindowResize, false);

  container.addEventListener('mouseover', function() {
    overRenderer = true;
  }, false);

  container.addEventListener('mouseout', function() {
    overRenderer = false;
  }, false);

})() 

function zoom(delta) {
  distanceTarget -= delta;
  distanceTarget = Math.min(1000, distanceTarget);
  distanceTarget = Math.max(distanceTarget, 300);
}

function render() {
  zoom(curZoomSpeed);
  rotation.x += (target.x - rotation.x) * 0.05;
  rotation.y += (target.y - rotation.y) * 0.05;
  distance += (distanceTarget - distance) * 0.1;

  camera.position.x = distance * Math.sin(rotation.x) * Math.cos(rotation.y);
  camera.position.y = distance * Math.sin(rotation.y);
  camera.position.z = distance * Math.cos(rotation.x) * Math.cos(rotation.y);
  
  camera.lookAt(scene.position);
  renderer.render(scene, camera);
}

// Kickoff
animate();
