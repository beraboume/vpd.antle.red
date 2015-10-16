# Environment
process.env.APP= 'vpd.berabou.me'

modelDefault= 'models/mamama_miku/index.pmx'
models= [
  'bower_components/j3/example/miku/index.pmx'
  'models/ginjishi_miku/index.pmx'
  'models/lat_miku/index.pmx'
  'models/lat_miku/summer.pmx'
  'models/lat_miku/white.pmx'
  'models/lat_miku/winter.pmx'
  'models/tda_miku_apend/index.pmx'
  'models/mamama_miku/index.pmx'
  'models/grpk_miku/index.pmx'
]

motionDefault= 'poses/kakyoin.vpd'
motions= [
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

available= [
  'zoom'
  'yaw'
  'pitch'
  'scroll'
  'slide'
  'pmxName'
  'vmdName'
  'loop'
  'physics'
]

# Boot after DOMContentLoaded
app= require './app'
angular.element document
.ready ->
  angular.bootstrap document,[app.name]

# Routes
app.config ($urlRouterProvider)->
  $urlRouterProvider.when '','/'
app.config ($stateProvider)->
  $stateProvider.state 'viewer',
    url: '/'
    controller: 'viewer'

# Main
app.controller 'viewer',($scope,$window,$location,$timeout,stats,renderer,Loaders)->
  scene= new THREE.Scene

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

  # controlls
  query= do $location.search
  $scope.$watch ->
    autoSave= $timeout ->
      values= {}
      values[key]= $scope[key] for key in available

      $location.search values
      $location.replace()
    ,100
    return

  $scope.loop= query.loop ? no
  $scope.physics= query.physics ? yes
  $scope.reset= ->
    $window.location.href= '/'
    return
  $scope.models= models
  $scope.pmxName= query.pmxName ? modelDefault
  $scope.motions= motions
  $scope.vmdName= query.vmdName ? motionDefault

  $scope.$watch 'zoom',(newZoom,oldZoom)->
    scale= newZoom/(oldZoom ? 1)
    controls.dollyIn scale unless isNaN scale 
    $scope.zoom?= query.zoom ? 1.7

  $scope.$watch 'yaw',(newLeft,oldLeft)->
    controls.rotateLeft (~~oldLeft - ~~newLeft)/58
    $scope.yaw?= query.yaw ? -40

  $scope.$watch 'pitch',(newUp,oldUp)->
    controls.rotateUp (~~oldUp - ~~(newUp))/100
    $scope.pitch?= query.pitch ? -60

  $scope.$watch 'scroll',(newScroll,oldScroll)->
    controls.panUp -(~~oldScroll - ~~newScroll)
    $scope.scroll?= query.scroll ? 2

  $scope.$watch 'slide',(newSlide,oldSlide)->
    controls.panLeft -(~~oldSlide - ~~newSlide)
    $scope.slide?= query.slide ? 0

  resize= ->
    renderer.setSize innerWidth,innerHeight
    camera.aspect= innerWidth / innerHeight if camera
    camera.updateProjectionMatrix() # Update camera.aspect
    $window.document.querySelector('main').appendChild renderer.domElement

  $window.addEventListener 'resize',-> resize()

  delta= 0
  loader= null

  $scope.$watch 'loop',->
    return unless loader?

    loader.model
    .then ({mesh,clock,morph,skin,ik,physi,physiPlugin,addTrans})->
      morph?.reset()
      skin.reset()
      physi.reset()

      morph?.play $scope.loop
      skin.play $scope.loop

  $scope.$watch 'physics',-> reload()
  $scope.$watch 'pmxName',-> reload()
  $scope.$watch 'vmdName',-> reload()
  $scope.$watch 'files',(file)->
    return unless file instanceof File

    $scope.motions.push file
    $scope.vmdName= file

  reload= ->
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

    url= $scope.vmdName
    url= $window.URL.createObjectURL $scope.vmdName if $scope.vmdName instanceof File

    filename= $scope.vmdName?.name ? $scope.vmdName
    isBase64= filename.slice(0,4) is 'b64:'
    isVpd= filename.slice(-4) is '.vpd'

    if isBase64
      loader= new Loaders.Base64Loader $scope.pmxName,url

    else
      unless isVpd
        loader= new Loaders.Loader $scope.pmxName,url

      else
        loader= new Loaders.VpdLoader $scope.pmxName,url
        loader.base64= $scope.vmdName instanceof File

    flush
    .then ->
      loader.model

    .then ({mesh,morph,skin,ik,physi,physiPlugin,addTrans,base64})->
      $window.URL.revokeObjectURL url if url.slice(0,5) is 'blob:'

      if base64
        $scope.vmdName= base64
        return

      $timeout ->
        resize()
        morph?.play $scope.loop
        skin?.play $scope.loop

        requestAnimationFrame ->
          scene.add mesh
          renderer.renderPluginsPre.length= 0
          renderer.renderPluginsPre.unshift physiPlugin if $scope.physics && $scope.physics isnt 'false'

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
