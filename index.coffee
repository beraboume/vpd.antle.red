# Dependencies
Promise= require 'bluebird'
vpd= require 'vpvp-vpd'

# Environment
process.env.APP= 'nicolive.io'

# Setup app
angular.element document
.ready ->
  angular.bootstrap document,[process.env.APP]

app= angular.module process.env.APP,[
  'ui.router'
  'ngFileUpload'
]

app.factory 'stats',($window)->
  stats= new Stats # via stats.js
  stats.domElement.style.position= 'absolute'
  stats.domElement.style.left= '0px'
  stats.domElement.style.top= '0px'

  $window.document.body.appendChild stats.domElement

  stats

app.config ($urlRouterProvider)->
  $urlRouterProvider.when '','/'
app.config ($stateProvider)->
  $stateProvider.state 'viewer',
    url: '/'
    controller: 'viewer'

# Private
scene= new THREE.Scene
window.scene= scene

renderer=
  if window.WebGLRenderingContext
    new THREE.WebGLRenderer {antialias:yes}
  else
    new THREE.CanvasRenderer {antialias:yes}

# Main
app.controller 'viewer',($scope,$window,stats,Loaders)->
  $scope.endless= no

  dLight= new THREE.DirectionalLight 0xffffff,0.9
  dLight.position.set 0, 7, 10
  scene.add dLight
  $scope.dLight= dLight

  aLight= new THREE.AmbientLight 0x333333
  aLight.position.set dLight.position.x,dLight.position.y,dLight.position.z
  scene.add aLight

  camera= new THREE.PerspectiveCamera 45, innerWidth / innerHeight, 1, 1000
  camera.position.set 0,10,40

  controls= new THREE.OrbitControls camera,document.createElement('noop'),renderer.domElement
  controls.center.setY 10

  $scope.$watch 'zoom',(newZoom,oldZoom)->
    scale= newZoom/(oldZoom ? 1)
    controls.dollyIn scale unless isNaN scale 
    $scope.zoom?= 1.7

  $scope.$watch 'yaw',(newLeft,oldLeft)->
    controls.rotateLeft (~~oldLeft - ~~newLeft)/58
    $scope.yaw?= -40

  $scope.$watch 'pitch',(newUp,oldUp)->
    controls.rotateUp (~~oldUp - ~~(newUp))/100
    $scope.pitch?= -60

  $scope.$watch 'scroll',(newScroll,oldScroll)->
    controls.panUp -(~~oldScroll - ~~newScroll)
    $scope.scroll?= 2

  $scope.$watch 'slide',(newSlide,oldSlide)->
    controls.panLeft -(~~oldSlide - ~~newSlide)
    $scope.slide?= 0

  resize= ->
    renderer.setSize innerWidth,innerHeight
    camera.aspect= innerWidth / innerHeight if camera
    camera.updateProjectionMatrix() # Update camera.aspect
    $window.document.querySelector('main').appendChild renderer.domElement

  $window.addEventListener 'resize',-> resize()

  $scope.models= [
    'bower_components/j3/example/miku/index.pmx'
    'models/ginjishi_miku/index.pmx'
    'models/lat_miku/index.pmx'
    'models/lat_miku/summer.pmx'
    'models/lat_miku/white.pmx'
    'models/lat_miku/winter.pmx'
    'models/tda_miku_apend/index.pmx'
    'models/grpk_miku/index.pmx'
  ]
  $scope.pmxName= $scope.models[~~($scope.models.length*Math.random())]

  $scope.motions= [
    'poses/dio.vpd'
    'poses/jojo-2a.vpd'
    'poses/jojo-2b.vpd'
    'poses/jojo-3.vpd'
    'poses/jotaro.vpd'
    'poses/jyoruno.vpd'
    'poses/jyosuke.vpd'
    'poses/kakyoin.vpd'
    'poses/killer-queen.vpd'
    'poses/narciso-stand.vpd'
    'poses/narciso.vpd'
  ]
  $scope.vmdName= 'poses/kakyoin.vpd'#$scope.motions[~~($scope.motions.length*Math.random())]

  delta= 0
  loader= null

  $scope.$watch 'endless',->
    return unless loader?

    loader.model
    .then ({mesh,clock,morph,skin,ik,physi,physiPlugin,addTrans})->
      morph?.reset()
      skin.reset()
      physi.reset()

      morph?.play $scope.endless
      skin.play $scope.endless

  $scope.$watch 'pmxName',-> reload()
  $scope.$watch 'vmdName',-> reload()
  $scope.$watch 'files',(file)->
    return unless file instanceof File

    $scope.motions.push file
    $scope.vmdName= file

  reload= (useVpd=no)->
    return if loader? and not loader.model.isFulfilled()

    flush=
      if loader?.model.isFulfilled()
        loader.model.then ({mesh,physi})->
          scene.remove mesh
          mesh.geometry?.dispose()
          mesh.dispose()
          physi?.dispose()

      else
        Promise.resolve()

    motion=
      if $scope.vmdName instanceof File
        $window.URL.createObjectURL $scope.vmdName

      else
        $scope.vmdName

    filename= $scope.vmdName?.name ? $scope.vmdName
    if filename.slice(-4) is '.vmd'
      loader= new Loaders.Loader $scope.pmxName,motion
    else
      loader= new Loaders.VpdLoader $scope.pmxName,motion

    flush
    .then ->
      loader.model

    .then ({mesh,morph,skin,ik,physi,physiPlugin,addTrans})->
      $window.URL.revokeObjectURL motion if motion.slice(0,5) is 'blob:'

      resize()
      morph?.play $scope.endless
      skin?.play $scope.endless

      requestAnimationFrame ->
        scene.add mesh
        render()

      render= ->
        return unless loader.isFulfilled()
        stats.begin()

        requestAnimationFrame render

        loader.nextDelta()
        if skin?.playing
          for bone,i in mesh.geometry.bones
            mesh.bones[i].position.set bone.pos[0], bone.pos[1], bone.pos[2]
            mesh.bones[i].quaternion.set bone.rotq[0], bone.rotq[1], bone.rotq[2], bone.rotq[3]

          morph.update loader.delta if morph
          skin.update loader.delta if skin
          ik.update loader.delta if ik
          addTrans.update loader.delta if addTrans

        controls.update()

        renderer.render scene,camera

        stats.end()

app.factory 'Loaders',($window)->
  class Loader
    constructor: (pmxName,vmdName)->
      @clock= new THREE.Clock

      @pmx= @loadPmx pmxName
      @vmd= @loadVmd vmdName
      @model= @createModel()

    isFulfilled: ->
      @pmx.isFulfilled() and @vmd.isFulfilled()

    nextDelta: ->
      @delta= @clock.getDelta()

    loadPmx: (pmxName,params={})->
      new Promise (resolve)->
        pmx= new THREE.MMD.PMX
        pmx.load pmxName,(pmx)->
          pmx.createMesh params,(mesh)->
            resolve {pmx,mesh}

    loadVmd: (vmdName)->
      new Promise (resolve)->
        vmd= new THREE.MMD.VMD
        vmd.load vmdName,resolve

    loadVpd: (vpdName)->
      new Promise (resolve)->
        xhr= new XMLHttpRequest
        xhr.open 'GET',vpdName,yes
        xhr.responseType= 'arraybuffer'
        xhr.send()
        xhr.onload= ->
          resolve vpd.parse new Buffer xhr.response

    generateSkinAnimation: (pmx,vpd)->
      duration= 0.03333333333333333
      targets= []

      for pBone in pmx.bones
        keys= []

        for vBone in vpd.bones
          continue unless pBone.name is vBone.name

          pos= vBone.position.slice()
          rot= vBone.quaternion.slice()
          rot[0]*= -1
          rot[1]*= -1
          interp= new Uint8Array [20,20,0,0,20,20,20,20,107,107,107,107,107,107,107,107]

          keys.push
            name: vBone.name
            time: 0
            pos: pos
            rot: rot
            interp: interp

          keys.push
            name: vBone.name
            time: duration
            pos: pos
            rot: rot
            interp: interp

        targets.push {keys}

      {duration,targets}

    createModel: ->
      Promise.all [@pmx,@vmd]
      .spread ({pmx,mesh},vmd)=>
        mAnimation= vmd.generateMorphAnimation pmx
        morph= new THREE.MMD.MMDMorph mesh, mAnimation if mAnimation

        sAnimation= vmd.generateSkinAnimation pmx
        skin= new THREE.MMD.MMDSkin mesh, sAnimation if sAnimation

        if mesh.geometry.MMDIKs.length
          ik= new THREE.MMD.MMDIK mesh

        if mesh.geometry.MMDIKs.length and window.Ammo
          physi= new THREE.MMD.MMDPhysi mesh
          physiPlugin=
            render: =>
              physi.preSimulate @delta
              THREE.MMD.btWorld.stepSimulation @delta
              physi.postSimulate @delta

          renderer.renderPluginsPre.length= 0
          renderer.renderPluginsPre.unshift physiPlugin

        hasAd= pmx.bones.some (bone)-> bone.additionalTransform
        addTrans= new THREE.MMD.MMDAddTrans pmx, mesh if hasAd

        {mesh,morph,skin,ik,physi,physiPlugin,addTrans}

  class VpdLoader extends Loader
    constructor: (pmxName,vpdName)->
      @clock= new THREE.Clock

      @pmx= @loadPmx pmxName
      @vpd= @loadVpd vpdName
      @model= @createModel()

    isFulfilled: ->
      @pmx.isFulfilled() and @vpd.isFulfilled()

    createModel: ->
      Promise.all [@pmx,@vpd]
      .spread ({pmx,mesh},vpd)=>
        morph= null

        sAnimation= @generateSkinAnimation pmx,vpd
        skin= new THREE.MMD.MMDSkin mesh, sAnimation if sAnimation

        if mesh.geometry.MMDIKs.length
          ik= new THREE.MMD.MMDIK mesh

        if mesh.geometry.MMDIKs.length and window.Ammo
          physi= new THREE.MMD.MMDPhysi mesh
          physiPlugin=
            render: =>
              physi.preSimulate @delta
              THREE.MMD.btWorld.stepSimulation @delta
              physi.postSimulate @delta

          renderer.renderPluginsPre.length= 0
          renderer.renderPluginsPre.unshift physiPlugin

        hasAd= pmx.bones.some (bone)-> bone.additionalTransform
        addTrans= new THREE.MMD.MMDAddTrans pmx, mesh if hasAd

        {mesh,morph,skin,ik,physi,physiPlugin,addTrans}

  {Loader,VpdLoader}
